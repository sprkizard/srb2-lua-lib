--[[
* mobjmover.lua
* (Author: sprki_zard)
* (June 13, 2020 00:24)
* Desc: n/a
*
* Notes: n/a
]]

rawset(_G, "MobjMover", {travelling={}})

-- Sets up a new mover (pls be stable and worth using)
function MobjMover.moveto(n, source, mtarget, args, usedupe)
	
	local dist = FixedHypot(mtarget.z-source.z, 
				FixedHypot(mtarget.x-source.x, 
				mtarget.y-source.y))

	local tspeed = (args and args.speed) or 8*FU
	local _movepercent = FixedDiv(tspeed, dist+1)

	-- End duplicates
	if not (usedupe) then
		for i,mover in ipairs(MobjMover.travelling) do
			if (mover.name == n) then
				mover.ended = true
			end
		end
	end

	local mt = {
		name=n,
		mobj=source,
		angle=args and args.angle,
		noangle=args and args.noangle,
		startpos={x=source.x, y=source.y, z=source.z},
		ease=args and args.ease or "linear",
		harc=((args and args.harc) and not nil) and args.harc or 0,
		varc=((args and args.varc) and not nil) and args.varc or 0,
		target=mtarget,
		speed=tspeed,
		locked=(args and args.locked),
		movepercent=_movepercent,
		movetime=0,
		stopped=false,
		ended=false,
	}

	-- (This will be ignored if the companion script does not exist at all)
	-- Add a reference to a target event if the library exists
	if ((args and args.eventref) and MobjMover.EventExists()) then
		mt.eventref = args.eventref
	end

	table.insert(MobjMover.travelling, mt)
end

function MobjMover.seek(n, callback)
	for i,mover in ipairs(MobjMover.travelling) do
		if (mover.name == n) then
			if (callback) then 
				do callback(mover) end
			end
			return true
		end
		-- TODO: no requiring name case to affect all movers
	end
	return false
end

-- Removes one or all animations
function MobjMover.stop(n, removeall)
	if (removeall) then
		for i=1, #MobjMover.travelling do
			MobjMover.travelling[i].ended = true 
		end
	else
		MobjMover.seek(n, function(mv) mv.ended = true end)
	end
end

-- Pause
function MobjMover.pause(n, isstopped)
	MobjMover.seek(n, function(mv) mv.stopped = isstopped end)
end

-- Checks if object is still travelling
function MobjMover.ismoving(n)
	return MobjMover.seek(n)
end

-- ================
-- Event Extension
-- Checks if a certain script is loaded to extend some of it's features
function MobjMover.EventExists()
	if not _G["Event"] then print("(!)\x82 This function requires 'Event' to work!") return false else return true end
end

-- Add a custom wrapper event + others when the companion script exists
if MobjMover.EventExists() then

	-- Check if an object is still moving
	function MobjMover.waitmovedone(event, n, callback)
		if (MobjMover.ismoving(n) and MobjMover.EventExists()) then Event.pause(event) else Event.resume(event) if (callback) then callback(event.vars) end end
	end

	-- Sets a mobj moveto target with the ability to stop an event
	-- until movement is finished when the library is added
	-- (Replacement for Event.newsub moveto calls)
	function MobjMover.moveto_ev(n, source, mtarget, args)
		Event.start("_ev_mobjmover", {movername=n, moversource=source, movertarget=mtarget, moverargs=args or {}})
	end

	Event.new("_ev_mobjmover", {
	function(c, e)
		c.moverargs.eventref = e -- set self ref
		MobjMover.moveto(c.movername, c.moversource, c.movertarget, c.moverargs)
	end})

end


-- ================

function MobjMover.Thinker()
	
	for i=1, #MobjMover.travelling do
		
		local mover = MobjMover.travelling[i]

		-- Remove if set to be ended
		if (mover and mover.ended) then

			-- event library is added: Resume event when ended to prevent locking or accidentally resuming
			if (mover.eventref and MobjMover.EventExists()) then
				Event.resume(mover.eventref)
			end

			table.remove(MobjMover.travelling, i)
		end

		-- no mobj means to not continue
		if mover and not (mover.mobj and mover.mobj.valid) then 
			mover.ended = true
		end

		-- Continue next iteration if set to be ended, otherwise continue
		(function()
		if (mover and not mover.ended) then

			-- Lock to final target position and end the movement
			if (mover.movetime >= FRACUNIT) then
				-- TODO: run a net-safe callback when ended?
				if not (mover.locked) then
					-- Locks the object to it's final position for safety
					P_SetOrigin(mover.mobj, mover.target.x, mover.target.y, mover.target.z) -- (2.2.11 interpolation patch)
				end
				mover.ended = true
				return
			end
			
			if (mover.stopped) then return end -- stop movement

			-- event library is added: Allow the event to pause if the mover passes the reference to it
			if (mover.eventref and MobjMover.EventExists()) then
				Event.stop(mover.eventref)
			end

			mover.movetime = $1+mover.movepercent -- percent to move per frame

			-- Interpolate the constant movement on all axis based on the distance
			local movex = ease[mover.ease](mover.movetime, mover.startpos.x, mover.target.x)
			local movey = ease[mover.ease](mover.movetime, mover.startpos.y, mover.target.y)
			local movez = ease[mover.ease](mover.movetime, mover.startpos.z, mover.target.z)
			local moveangle = R_PointToAngle2(mover.mobj.x, mover.mobj.y, mover.target.x, mover.target.y)

			-- Set mobj angle (if only a number exists :v)
			if (mover.noangle) then
				mover.mobj.angle = (mover.angle and not nil) and $1 or $1
			else
				mover.mobj.angle = (mover.angle and not nil) and $1 or moveangle --R_PointToAngle2(mover.mobj.x, mover.mobj.y, mover.target.x, mover.target.y)
			end
			--[[if (type(mover.angle) == "number") then
				mover.mobj.angle = mover.noangle and $1 or mover.angle
			else
				mover.mobj.angle = mover.noangle and $1 or R_PointToAngle2(mover.mobj.x, mover.mobj.y, mover.target.x, mover.target.y)
			end--]]

			-- Move in a curve motion horizontally or vertically
			-- 12/15/2022: having two separate values instead of a table which can be invalidated at any time is better
			if (mover.harc or mover.varc) then
				local harc = mover.harc or 0
				local varc = mover.varc or 0
				local arcAngle = R_PointToAngle2(mover.startpos.x, mover.startpos.y, mover.target.x, mover.target.y)

				-- Get current angle for our movetime, eased to the easing type
				local ang = ease[mover.ease](mover.movetime, FRACUNIT)
				ang = FixedMul(ANGLE_180, $)
				ang = sin($)

				-- Apply horizontal and vertical arc movements
				local arcX = P_ReturnThrustX(nil, arcAngle + ANGLE_90, FixedMul(harc, ang))
				local arcY = P_ReturnThrustY(nil, arcAngle + ANGLE_90, FixedMul(harc, ang))
				local arcZ = -FixedMul(varc, ang)

				-- Update the position
				movex = movex + arcX
				movey = movey + arcY
				movez = movez + arcZ
			end

			-- Apply the movement
			-- (2.2.11 interpolation patch)
			P_MoveOrigin(mover.mobj,
				movex,
				movey,
				movez
			)
		end
		end)()
	end
end

function MobjMover.netvars(n)
	MobjMover.travelling = n($)

	--[[local a = #MobjMover.travelling
	a = n(a)
	for i = 1, a do
		MobjMover.travelling[i] = n($)
	end--]]
end


-- Example code
--[[addHook("NetVars", function(network)
	MobjMover.netvars(network)
end)

addHook("ThinkFrame", function()
MobjMover.Thinker()
end)--]]
--[[addHook("ThinkFrame", function()
	-- Moves directly to 0,0,56
	if leveltime == 2*TICRATE then
		server.mo.s = P_SpawnMobj(server.mo.x, server.mo.y, server.mo.z, MT_THOK)
		local sd = P_SpawnMobj(0, 0, 56*FU, MT_THOK)
		server.mo.s.tics = FU
		server.mo.s.sprite = SPR_EGGM
		sd.tics = FU
		sd.sprite = SPR_DRWN
		sd.scale = 2*FU
		MobjMover.moveto("test", server.mo.s, {x=0,y=0,z=56*FU}, {angle=0})
	end
	-- Starts a new, arc movement after the first
	if leveltime == 6*TICRATE then
		local sd = P_SpawnMobj(0, 2000*FU, 56*FU, MT_THOK)
		sd.tics = FU
		sd.sprite = SPR_DRWN
		sd.scale = 2*FU
		MobjMover.moveto("test", server.mo.s, {x=0,y=2000*FU,z=56*FU}, {varc=128*FU})
	end
	-- Pauses movement for 3 seconds
	if (leveltime == 10*TICRATE) then
		MobjMover.pause("test", true)
	end
	-- Unpauses and finishes
	if (leveltime == 13*TICRATE) then
		MobjMover.pause("test", false)
	end
end)
--]]



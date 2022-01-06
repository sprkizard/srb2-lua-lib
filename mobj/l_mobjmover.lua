--[[
* mobjmover.lua
* (Author: sprki_zard)
* (June 13, 2020 00:24)
* Desc: n/a
*
* Notes: n/a
]]

rawset(_G, "MobjMover", {travelling={}})

-- TODO: replace with easing when the time comes
function MobjMover._lerp(a, b, t)
	return a + FixedMul(b - a, t)
end

-- Sets up a new mover (pls be stable and worth using)
function MobjMover.moveto(n, source, mtarget, args)
	
	local dist = FixedHypot(mtarget.z-source.z, 
				FixedHypot(mtarget.x-source.x, 
				mtarget.y-source.y))

	local tspeed = (args and args.speed) or 8*FU
	local _movepercent = FixedDiv(tspeed, dist)

	-- End duplicates
	for i,mover in ipairs(MobjMover.travelling) do
		if (mover.name == n) then
			mover.ended = true
		end
	end

	local mt = {
		name=n,
		mobj=source,
		angle=args and args.angle,
		startpos={x=source.x, y=source.y, z=source.z},
		arc=args and args.arc,
		target=mtarget,
		speed=tspeed,
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
	function MobjMover.waitmovedone(event, n)
		if (MobjMover.ismoving(n) and MobjMover.EventExists()) then Event.pause(event) else Event.resume(event) end
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
			if (mover.movetime > FRACUNIT) then
				-- TODO: run a net-safe callback when ended?
				P_TeleportMove(mover.mobj, mover.target.x, mover.target.y, mover.target.z)
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
			local movex = MobjMover._lerp(mover.startpos.x, mover.target.x, mover.movetime)
			local movey = MobjMover._lerp(mover.startpos.y, mover.target.y, mover.movetime)
			local movez = MobjMover._lerp(mover.startpos.z, mover.target.z, mover.movetime)
			local moveangle = R_PointToAngle2(mover.mobj.x, mover.mobj.y, mover.target.x, mover.target.y)

			-- Set mobj angle (if only a number exists :v)
			if (type(mover.angle) == "number") then
				mover.mobj.angle = mover.angle
			else
				mover.mobj.angle = R_PointToAngle2(mover.mobj.x, mover.mobj.y, mover.target.x, mover.target.y)
			end

			-- Move in an arc motion horizontally or vertically
			if mover.arc then
				local ang = FixedMul(ANGLE_180, mover.movetime)
				movex = $+P_ReturnThrustX(nil, moveangle + ANGLE_90, FixedMul((mover.arc.horz or 0), sin(ang)))
				movey = $+P_ReturnThrustY(nil, moveangle + ANGLE_90, FixedMul((mover.arc.horz or 0), sin(ang)))
				movez = $-FixedMul(mover.arc.vert or 0, sin(ang))
			end

			-- Apply the movement
			P_TeleportMove(mover.mobj, 
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
		MobjMover.moveto("test", server.mo.s, {x=0,y=2000*FU,z=56*FU}, {arc={vert=128*FU}})
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



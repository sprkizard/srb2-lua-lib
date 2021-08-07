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

	table.insert(MobjMover.travelling,
	{
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
	})
end

function MobjMover.seek(n, callback)
	for i,mover in ipairs(MobjMover.travelling) do
		if (mover.name == n) then
			if (callback) then 
				do callback(mover) end
			end
			return true
		end
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

function MobjMover.waitmovedone(event, n)
	if not _G["Event"] then print("Event script is not loaded!") return end
	if (MobjMover.ismoving(n)) then Event.pause(event) else Event.resume(event) end
end

function MobjMover.Thinker()

	for i=1, #MobjMover.travelling do
		
		local mover = MobjMover.travelling[i]

		-- Remove if set to be ended
		if (mover and mover.ended) then
			table.remove(MobjMover.travelling, i)
		end

		-- no mobj means to not continue
		if mover and not (mover.mobj and mover.mobj.valid) then 
			mover.ended = true
		end

		-- Continue next iteration if set to be ended, otherwise continue
		(function()
		if (mover and not mover.ended) then

			if (mover.movetime > FRACUNIT) then
				P_TeleportMove(mover.mobj, mover.target.x, mover.target.y, mover.target.z)
				mover.ended = true
				return
			end
			
			if (mover.stopped) then return end

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
				movex = $+P_ReturnThrustX(nil, moveangle+ANGLE_90, FixedMul((mover.arc.horz or 0), sin(ang)))
				movey = $+P_ReturnThrustY(nil, moveangle+ANGLE_90, FixedMul((mover.arc.horz or 0), sin(ang)))
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

-- Example code
--[[addHook("ThinkFrame", function()
MobjMover.Thinker()
end)

addHook("ThinkFrame", function()
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
end)--]]

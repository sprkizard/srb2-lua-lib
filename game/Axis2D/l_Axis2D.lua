-- Axis2D, by chi.miru (Pac) and RedEnchilada
-- Public release version 1.2 (refactored somewhat on the afternoon of April 19, 2015)
-- Feel free to use it for your own purposes! In exchange, if you make a change that improves it, please share it with us!

-- Killswitch to avoid the script loading multiple times
if axis2d then
	print ("Axis2D already loaded. Aborting...")
	-- axis2d.legacymode = false -- See below, this line can be uncommented if you need it
	return
end

rawset(_G, "axis2d", {legacymode = false}) -- Set legacymode on if you need rings and etc to check the LE method of axis switching (maybe you have an older A2D map that you don't wanna convert to the new system?)

-- Toggle for spinning spring animation (for giggles)
--local springspin = CV_RegisterVar({"springspin", 1, 0, CV_OnOff})
local springspin = CV_RegisterVar({"springspin", 0, 0, CV_OnOff})

-- Axes found, so we don't have to look them up later
local axes = {lastmap = 0}

-- Refreshes the axis cache if needed
function axis2d.CheckAxes()
	if axes.lastmap ~= gamemap then
		axes = {lastmap = gamemap}
		print("Preparing Axis2D cache...")
		for mo in thinkers.iterate("mobj") do
			if mo.type == MT_AXIS then
				--print("Axis found!")
				local axisinfo = {}
				axisinfo.x = mo.x
				axisinfo.y = mo.y
				axisinfo.radius = mo.spawnpoint.angle
				axisinfo.flipped = false
				if axisinfo.radius >= 16384 then
					axisinfo.radius = $1-16384
					axisinfo.flipped = true
				end
				axes[mo.spawnpoint.options] = axisinfo
				--print("Storing axis #" .. mo.spawnpoint.options .. " in table...")
				--print(axisinfo.x .. " " .. axisinfo.y .. " " .. axisinfo.radius)
			elseif mo.type == MT_AXISTRANSFERLINE then
				--print("Line axis found!")
				local axisinfo = {}
				axisinfo.basex = mo.x
				axisinfo.basey = mo.y
				axisinfo.angle = mo.angle
				axes[mo.spawnpoint.options] = axisinfo
				--print("Storing axis #" .. mo.spawnpoint.options .. " in table...")
				--print(axisinfo.basex .. " " .. axisinfo.basey .. " " .. axisinfo.angle)
			elseif mo.type == MT_AXISTRANSFER then
				continue -- Ignore these, but keep going in the list
			else
				--print("End of list.")
				break -- Axis objects always start off the list, so now we know there are no more to parse
			end
			axes[mo.spawnpoint.options].number = mo.spawnpoint.options
		end
	end
end

addHook("MapLoad", axis2d.CheckAxes) -- Refresh axes on new map

-- Function to get the vector of a given object's axis
function axis2d.GetVector(mo)
	if mo.currentaxis == nil then
		return nil
	end
	if mo.currentaxis.angle ~= nil then
		mo.currentaxis.x = mo.x+cos(mo.currentaxis.angle-ANGLE_90)
		mo.currentaxis.y = mo.y+sin(mo.currentaxis.angle-ANGLE_90)
		mo.currentaxis.radius = 1
		mo.currentaxis.flipped = false
		return mo.currentaxis.angle-ANGLE_90
	else -- Circular axes
		return R_PointToAngle2(mo.currentaxis.x, mo.currentaxis.y, mo.x, mo.y)
	end
end

-- Function to switch object to a particular axis, or eject them from the Axis2D system
function axis2d.SwitchAxis(mo, axisnum)
	axis2d.CheckAxes() -- For starters, make the axis table if it's not already done
	
	local player = mo.player -- Special handling for players
	local oldangle
	
	if player then
		oldangle = axis2d.GetVector(mo)
		if mo.currentaxis and mo.currentaxis.flipped then
			oldangle = $1+ANGLE_180
		end
	end
	
	-- This grabs another linedef from the tag
	-- on the Call Lua Function effect
	-- can be used for settings, etc
	if axisnum == 0 then
		--print("Ejecting the player from the 2D track...")
		if player and mo.currentaxis then
			player.normalspeed = skins[mo.skin].normalspeed
			player.thrustfactor = skins[mo.skin].thrustfactor
			player.accelstart = skins[mo.skin].accelstart
			player.acceleration = skins[mo.skin].acceleration
			player.movevars = nil
			if player.charability == CA_THOK then
				player.actionspd = skins[mo.skin].actionspd
			end
			player.runspeed = skins[mo.skin].runspeed
			player.jumpfactor = skins[mo.skin].jumpfactor
			player.pflags = $1&~PF_FORCESTRAFE
		end
		mo.currentaxis = nil
		return
	end
	
	if mo.currentaxis and mo.currentaxis.number == axisnum then
		return -- We're already on this axis, so no need to reset everything
	end
	
	local axis = axes[axisnum]
	if not axis then
		print("ERROR: Axis " .. axisnum .. " does not exist! Please create it!")
		return
	end
	
	-- Get extra properties from linedef
	local linegrab = P_FindSpecialLineFromTag(9000, axisnum, -1)
	if linegrab ~= -1 then
		linegrab = lines[linegrab]

		axis.camangle = R_PointToAngle2(0, 0, linegrab.dx, linegrab.dy)
		if linegrab.flags & ML_NOCLIMB then
			axis.camangleabs = true
		else
			axis.camangleabs = false
		end
		if linegrab.flags & ML_EFFECT1 then
			axis.camdist = R_PointToDist2(0, 0, linegrab.dx, linegrab.dy)
		else
			axis.camdist = false
		end
		
		--cmiru: camheight?
		if linegrab.flags & ML_EFFECT2 then
			axis.camheight = linegrab.frontsector.floorheight
		else
			axis.camheight = false
		end
	end
	
	mo.currentaxis = axis
	--print("Changing to axis " .. l.tag)
	--if axis.angle then
	--	print("Axis is a straight line.")
	--end
	
	if player and (oldangle ~= nil) then
		local newangle = axis2d.GetVector(mo)
		if mo.currentaxis and mo.currentaxis.flipped then
			oldangle = $1+ANGLE_180
		end
		
		if mo.glidediff ~= nil then
			mo.glidediff = $1-newangle+oldangle
		end
		
		if -abs(newangle-oldangle) < ANGLE_270-(32<<16) then
			if mo.controlflip then
				mo.controlflip = 0
			elseif player.cmd.sidemove < 0 then
				mo.controlflip = -1
			else
				mo.controlflip = 1
			end
		end
	end
end


addHook("LinedefExecute", function(l, mo)
	axis2d.SwitchAxis(mo, l.tag)
end, "P_DoAngleSpin")

-- Snap mobj to axis
function axis2d.SnapMobj(mo)
	if not mo.currentaxis then return end -- Safety precaution!

	local angle
		
	-- Straight line axes
	if mo.currentaxis.angle ~= nil then
		angle = mo.currentaxis.angle-ANGLE_90
		mo.currentaxis.x = mo.x+cos(angle)
		mo.currentaxis.y = mo.y+sin(angle)
		mo.currentaxis.radius = 1
		mo.currentaxis.flipped = false
	else -- Circular axes
		angle = R_PointToAngle2(mo.currentaxis.x, mo.currentaxis.y, mo.x, mo.y)
	end
	
	-- Snap player to position on axis
	local snapx, snapy
	angle = axis2d.GetVector(mo)
	if mo.currentaxis.angle ~= nil then
		local pangle = R_PointToAngle2(mo.currentaxis.basex, mo.currentaxis.basey, mo.x, mo.y)
		pangle = $1-mo.currentaxis.angle
		local pdist = R_PointToDist2(mo.currentaxis.basex, mo.currentaxis.basey, mo.x, mo.y)
		pdist = FixedMul(cos(pangle), pdist)
		snapx = mo.currentaxis.basex + FixedMul(pdist, cos(mo.currentaxis.angle))
		snapy = mo.currentaxis.basey + FixedMul(pdist, sin(mo.currentaxis.angle))
	else
		local distfactor = R_PointToDist2(mo.currentaxis.x, mo.currentaxis.y, mo.x, mo.y)/mo.currentaxis.radius
		snapx = mo.currentaxis.x + FixedDiv(mo.x - mo.currentaxis.x, distfactor)
		snapy = mo.currentaxis.y + FixedDiv(mo.y - mo.currentaxis.y, distfactor)
		-- Replace old cos/sin to prevent drifting
	end
	
	if P_AproxDistance(mo.x-snapx, mo.y-snapy) < FRACUNIT*2 then
		mo.oldpos = {
			x = mo.x,
			y = mo.y--,
			--z = mo.z
		}
		return -- Close enough, let's just not worry about moving them around
	end
	
	if mo.oldpos and not P_TryMove(mo, snapx, snapy, true) then
		-- There was an issue adjusting the player to the axis. Figure this part out later!
		P_TeleportMove(mo, mo.oldpos.x, mo.oldpos.y, mo.z)
		--mo.momx = $1/-5
		--mo.momy = $1/-5
		--print("HIT")
	end
	mo.oldpos = {
		x = mo.x,
		y = mo.y
	}
	
	if mo.player then return end -- The player mobj handles this already!
	-- Normalize momentum to angle
	local vectordist = R_PointToDist2(0, 0, mo.momx, mo.momy)
	local vectorang = R_PointToAngle2(0, 0, mo.momx, mo.momy)-angle
	if vectorang > 0 then
		vectorang = ANGLE_90
	else
		vectorang = -ANGLE_90
	end
	P_InstaThrust(mo, angle+vectorang, vectordist)
end

local function SetCamera(player, x, y, z)
	local mo = player.mo
	if not (player.camera and player.camera.valid) then
		player.camera = P_SpawnMobj(mo.x, mo.y, mo.z, MT_GFZFLOWER1)
		player.camera.flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOTHINK
		player.camera.flags2 = MF2_DONTDRAW
		P_TeleportMove(player.camera, x, y, z)
	end
	P_TeleportMove(player.camera, player.camera.x+(x-player.camera.x)/4, player.camera.y+(y-player.camera.y)/4, z)
end

-- Player management!
addHook("MobjThinker", function(mo)
	local player = mo.player
	
	if mo.flags2 & MF2_TWOD then
		SetCamera(player, mo.x, mo.y - 448*FRACUNIT, mo.z + 20*FRACUNIT)
		if player.awayviewtics <= 2 then
			player.awayviewtics = 2
			player.awayviewmobj = player.camera
			player.awayviewmobj.angle = R_PointToAngle2(player.awayviewmobj.x, player.awayviewmobj.y, mo.x, mo.y)
		end
		player.awayviewmobj.momz = 0
	end
	
	if mo.currentaxis then
		axis2d.ScanForAxes(mo)
		player.pflags = $1|PF_FORCESTRAFE
		local sidemove = player.cmd.sidemove
		
		if mo.controlflip then -- Flip controls on axis flip, until the player stops holding their direction
			if mo.controlflip == -1 and sidemove >= 0 then
				mo.controlflip = 0
			elseif mo.controlflip == 1 and sidemove <= 0 then
				mo.controlflip = 0
			else
				sidemove = -$
			end
		end
		
		if not player.climbing then
			if sidemove < 0 then
				mo.isfacingleft = true
			elseif sidemove > 0 then
				mo.isfacingleft = false
			end
			if player.onwall and (player.cmd.buttons & BT_JUMP) and not (player.onwall & BT_JUMP) then
				mo.isfacingleft = not mo.isfacingleft
			end
			player.onwall = false
		else
			player.onwall = 1|(player.cmd.buttons & BT_JUMP)
			-- Remove all horizontal momentum to prevent player from falling off walls when pushing horizontal input as climbing starts
			mo.momx = 0
			mo.momy = 0
		end
	
		local angle
		
		-- Straight line axes
		if mo.currentaxis.angle ~= nil then
			angle = mo.currentaxis.angle-ANGLE_90
			mo.currentaxis.x = mo.x+cos(angle)
			mo.currentaxis.y = mo.y+sin(angle)
			mo.currentaxis.radius = 1
			mo.currentaxis.flipped = false
		else -- Circular axes
			angle = R_PointToAngle2(mo.currentaxis.x, mo.currentaxis.y, mo.x, mo.y)
		end
		
		-- Snap player to position on axis
		axis2d.SnapMobj(mo)
		
		-- Handle camera
		if player.health then -- Don't move the camera when the player's dead!
			--local factor = 1
			local camangle = angle
			if mo.currentaxis.flipped then
				--factor = -1
				camangle = $1+ANGLE_180
			end
			if mo.currentaxis.camangle ~= nil then
				if mo.currentaxis.camangleabs then
					camangle = 0
				end
				camangle = $1+mo.currentaxis.camangle
			end
			if not mo.currentaxis.camdist then
				mo.currentaxis.camdist = 448*FRACUNIT
			end
			if not mo.currentaxis.camheight then
				mo.currentaxis.camheight = 0*FRACUNIT
			end
			SetCamera(player, 
				mo.currentaxis.x+(cos(angle)*mo.currentaxis.radius)+FixedMul(cos(camangle), mo.currentaxis.camdist),
				mo.currentaxis.y+(sin(angle)*mo.currentaxis.radius)+FixedMul(sin(camangle), mo.currentaxis.camdist),
				mo.z+20*FRACUNIT+(mo.currentaxis.camheight)
			)
		end
		if player.awayviewtics <= 2 then
			player.awayviewtics = 2
			player.awayviewmobj = player.camera
			player.awayviewmobj.angle = R_PointToAngle2(player.awayviewmobj.x, player.awayviewmobj.y, mo.x, mo.y)
		end
		player.awayviewmobj.momz = 0
		
		-- Set player angle
		if(player.pflags & PF_GLIDING) then
			local tangle = angle
			if mo.currentaxis.flipped then
				tangle = $1^^ANGLE_180
			end
			
			if not mo.glidediff then
				mo.glidediff = mo.angle-tangle
			end
			
			if abs(sidemove) < 3 then -- Default angle to what it's at now
				mo.isfacingleft = mo.glidediff < 0
			end
			
			if mo.isfacingleft then
				mo.glidediff = $1-(ANG10/2)
				if mo.glidediff < ANGLE_270 then
					mo.glidediff = ANGLE_270
				end
			else
				mo.glidediff = $1+(ANG10/2)
				if mo.glidediff > ANGLE_90 then
					mo.glidediff = ANGLE_90
				end
			end
			
			mo.angle = tangle+mo.glidediff
			
			-- Fuck this game's shitty latching-on code! I'm rewriting it myself!
			local waterfactor = 1
			if mo.eflags & MFE_UNDERWATER then
				waterfactor = 2
			end
			
			if not player.skidtime then
				P_InstaThrust(mo, mo.angle, FixedMul(FixedMul(player.actionspd + player.glidetime*1500, mo.scale)/waterfactor, abs(sin(mo.angle-angle))))
				if P_TryMove(mo, mo.x+mo.momx, mo.y+mo.momy, true) then -- Check if this will send the player into a wall
					P_TeleportMove(mo, mo.x-mo.momx, mo.y-mo.momy, mo.z) -- Now put them back for reasons.
				elseif not player.lastglideattempt or abs(player.lastglideattempt.x-mo.x)+abs(player.lastglideattempt.y-mo.y) > FRACUNIT then -- Don't check if we've already checked, for optimization reasons
					player.lastglideattempt = {
						x = mo.x,
						y = mo.y
					}
					--print("Climb, damn you!")
					
					-- Move player as close as we can to the wall
					mo.momx = $1/32
					mo.momy = $1/32
					local moves = 31
					while P_TryMove(mo, mo.x+mo.momx, mo.y+mo.momy, true) and moves do moves = $1-1 end
					
					if moves then
						-- Look for climbable wall
						local line, dist, x, y = nil, 40<<FRACBITS, 0, 0
						for l in lines.iterate do -- SSSLLLOOOWWW look for a method to only get lines from the active sector
							if l.frontsector == l.backsector then continue end -- Just a decoration linedef, ignore...
							if l.frontsector ~= mo.subsector.sector and l.backsector ~= mo.subsector.sector then continue end -- Line isn't in our sector!
							local xtest, ytest = P_ClosestPointOnLine(mo.x, mo.y, l)
							if (xtest < l.v1.x-20 and xtest < l.v2.x-20)
							or (xtest > l.v1.x+20 and xtest > l.v2.x+20)
							or (ytest < l.v1.y-20 and ytest < l.v2.y-20)
							or (ytest > l.v1.y+20 and ytest > l.v2.y+20) then
								continue -- Closest point is outside of the line!
							end
							local dangle = R_PointToAngle2(mo.x, mo.y, xtest, ytest)-mo.angle
							if dangle > ANGLE_90 or dangle < ANGLE_270 then
								continue -- Closest point is not in front of us!
							end
							local newdist = P_AproxDistance(abs(mo.x-xtest), abs(mo.y-ytest))
							if newdist > 12*FRACUNIT and newdist < dist then
								dist = newdist
								x = xtest
								y = ytest
								line = l
							end
						end
						--print(("#%s %su away at %s,%s (angle: %s)"):format(#line, dist/FRACUNIT, x/FRACUNIT, y/FRACUNIT, AngleFixed(abs(R_PointToAngle2(mo.x, mo.y, x, y)-mo.angle))/FRACUNIT))
						if line and not (line.flags & ML_NOCLIMB) then
							S_StartSound(player.mo, sfx_s3k4a)
							P_ResetPlayer(player)
							player.lastlinehit = #line
							player.climbing = 5
							mo.momx, mo.momy, mo.momz = 0, 0, 0
						else
							player.climbing = 0
							mo.momx, mo.momy = 0, 0
						end
					end
				end
			else
				P_InstaThrust(mo, mo.angle, FixedMul(FixedMul(player.actionspd - player.glidetime*FRACUNIT, mo.scale)/waterfactor, abs(sin(mo.angle-angle))))
			end
		elseif mo.state == S_PLAY_SPRING and springspin.value then
			if mo.isfacingleft then
				mo.angle = angle-ANG20*leveltime
			else
				mo.angle = angle+ANG20*leveltime
			end
		else
			mo.glidediff = 0
			if player.climbing then -- Actually, set isfacingleft based on the climbing angle!
				if mo.currentaxis.flipped then
					mo.isfacingleft = (angle-mo.angle) < 0
				else
					mo.isfacingleft = (angle-mo.angle) > 0
				end
			end
			if mo.isfacingleft then
				mo.angle = angle-ANGLE_90
			else
				mo.angle = angle+ANGLE_90
			end
			if mo.currentaxis.flipped then
				mo.angle = $1+ANGLE_180
			end
		end
		
		-- Rip out normal movement and do it ourselves! Muahaha!
		player.normalspeed = 0
		player.thrustfactor = 0
		player.accelstart = 0
		player.acceleration = 0
		player.runspeed = 2*skins[mo.skin].runspeed/3
		player.jumpfactor = 11*skins[mo.skin].jumpfactor/10
		if player.charability == CA_THOK then
			player.actionspd = 2*skins[mo.skin].actionspd/3
		end
		
		-- Normalize momentum to angle
		local newmag = R_PointToDist2(0, 0, mo.momx, mo.momy)
		local oldmag = R_PointToAngle2(0, 0, mo.momx, mo.momy)-angle
		if oldmag > 0 then
			oldmag = ANGLE_90
		else
			oldmag = -ANGLE_90
		end
		P_InstaThrust(mo, angle+oldmag, newmag)
		
		-- Referencing player movement code and kinda recreating it here
		if not player.climbing and not (player.pflags & PF_GLIDING)
				and not player.exiting and not (player.pflags & PF_STASIS)
				and not P_PlayerInPain(player) and player.health then
			local m = skins[mo.skin]
			local topspeed = (2*m.normalspeed)/3
			local thrustfactor = m.thrustfactor
			local acceleration = m.accelstart + (FixedDiv(player.speed, mo.scale)/FRACUNIT) * m.acceleration
			if player.powers[pw_tailsfly] then
				topspeed = $1/2
				thrustfactor = $1*2
			elseif mo.eflags & (MFE_UNDERWATER|MFE_GOOWATER) then
				topspeed = $1/2
				acceleration = 2*$1/3
			end
			if player.powers[pw_super] or player.powers[pw_sneakers] then
				thrustfactor = $1*2
				acceleration = $1/2
				topspeed = $1*2
			end
			
			local movepushside = sidemove*thrustfactor*acceleration
			if not P_IsObjectOnGround(mo) then
				movepushside = $1/2
				if player.powers[pw_tailsfly] and player.speed > topspeed then
					player.speed = topspeed-1
					movepushside = $1/4
				end
			end
			if player.pflags & PF_SPINNING then
				if not (player.pflags & PF_STARTDASH) then
					movepushside = $1/48
				else
					movepushside = 0
				end
			end
			movepushside = FixedMul(movepushside, mo.scale)
			
			local oldmag = R_PointToDist2(0, 0, mo.momx, mo.momy)
			if mo.currentaxis.flipped then
				P_Thrust(mo, angle-ANGLE_90, movepushside)
			else
				P_Thrust(mo, angle+ANGLE_90, movepushside)
			end
			local newmag = R_PointToDist2(0, 0, mo.momx, mo.momy)
			if newmag > topspeed then
				if oldmag > topspeed then
					if newmag > oldmag then
						mo.momx = FixedMul(FixedDiv($1, newmag), oldmag)
						mo.momy = FixedMul(FixedDiv($1, newmag), oldmag)
					end
				else
					mo.momx = FixedMul(FixedDiv($1, newmag), topspeed)
					mo.momy = FixedMul(FixedDiv($1, newmag), topspeed)
				end
			end
		end
		
	elseif player.movevars then
		player.normalspeed = skins[mo.skin].normalspeed
		player.thrustfactor = skins[mo.skin].thrustfactor
		player.accelstart = skins[mo.skin].accelstart
		player.acceleration = skins[mo.skin].acceleration
		player.movevars = nil
		if player.charability == CA_THOK then
			player.actionspd = skins[mo.skin].actionspd
		end
		player.runspeed = skins[mo.skin].runspeed
		player.jumpfactor = skins[mo.skin].jumpfactor
		player.pflags = $1&~PF_FORCESTRAFE
	end
end, MT_PLAYER)

-- Get linedef executors that trigger axis changers
-- Table of sector numbers
local axisChangeExecs = {}

-- Function to reset
function axis2d.ResetAxisChangeExecTable()
	-- Get all of LD443 that change axes, and all of LD300
	local ld443 = {}
	local ld300 = {}
	for line in lines.iterate do
		if line.special == 300 then
			table.insert(ld300, line)
		elseif line.special == 443 and line.frontside.text == "P_DOANGLESPIN" then
			table.insert(ld443, line)
		end
	end
	
	-- Reset axis changer directory
	axisChangeExecs = {}
	
	-- Compare frontsectors of linedefs to find matches
	for _,trigger in pairs(ld300) do
		for _,func in pairs(ld443) do
			if trigger.frontsector == func.frontsector then
				table.insert(axisChangeExecs, trigger.tag) -- We only need the tag
				--print("!")
				break
			end
		end
	end
	
	-- Done!
end

-- Hooks
addHook("MapLoad", axis2d.ResetAxisChangeExecTable)

local function IterateMobjSectors(mo, func)
	local sec = mo.subsector.sector
	func(mo, sec)
	local tag = sec.tag
	local foftypes = {223} -- Referenced from the SRB2DB 2.1 config
	for i = 1, #foftypes do
		local foftype = foftypes[i]
		local linedefnum = P_FindSpecialLineFromTag(foftype, tag, -1)
		local last = -1
		while linedefnum ~= last do
			local fof = lines[linedefnum]
			if not fof then continue end
			fof = fof.frontsector
			if mo.z <= fof.ceilingheight and mo.z+mo.height >= fof.floorheight then
				func(mo, fof)
			end
			--last = linedefnum
			linedefnum = P_FindSpecialLineFromTag(foftype, tag, linedefnum)
		end
	end
end

-- Function to place an object along axes
function axis2d.HandleSwitches(mo, legacy)
	if legacy == nil then
		legacy = axis2d.legacymode
	end
	
	if legacy then
		IterateMobjSectors(mo, function(mo, sector)
			if ((sector.special >> 4) & 15) == 4 then -- Trigger Linedef Executor (Anywhere in Sector)
				for _,i in ipairs(axisChangeExecs) do
					if sector.tag == i then
						P_LinedefExecute(i, mo, sector) -- Trigger linedef exec
						return
					end
				end
			end
		end)
	end
	
	axis2d.ScanForAxes(mo)
end

function axis2d.ScanForAxes(mo) -- Look for axis switch "FOF"s (LD9001) to switch to, but only if already in Axis2D mode!
	-- Tag is already taken by tagging it to the sector, so use X offset as axis number
	local sec = mo.subsector.sector
	
	local line = P_FindSpecialLineFromTag(9001, sec.tag, -1)
	
	while line ~= -1 do
		local fofsec = lines[line].frontsector
		if fofsec.floorheight <= mo.z and fofsec.ceilingheight >= mo.z then
			axis2d.SwitchAxis(mo, lines[line].frontside.textureoffset/FRACUNIT)
			return
		end
	
		line = P_FindSpecialLineFromTag(9001, sec.tag, line)
	end
end

addHook("MobjThinker", function(mo)
	-- Set lost rings to the player's axis on spawn
	-- (Do this in MobjThinker instead of MobjSpawn because object mom hasn't initialized by the
	-- time MobjSpawn hook is called!)
	if not mo.spawnchecked then
		mo.spawnchecked = true
		if mo.target and mo.target.currentaxis then
			mo.currentaxis = mo.target.currentaxis
			
			-- Set horizontal momentum based on player's angle
			P_InstaThrust(mo, mo.target.angle, mo.momx)
		end
	end
	
	-- Snap rings to axes
	if not (mo.fuse & 3) then -- Make it not run every frame for performance's sake
		axis2d.SnapMobj(mo)
	end
	if not (mo.fuse & 7) then
		axis2d.HandleSwitches(mo)
	end
end, MT_FLINGRING)
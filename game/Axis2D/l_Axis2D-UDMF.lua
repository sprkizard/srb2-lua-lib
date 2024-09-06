--[[

* l_Axis2D-UDMF.lua
* (sprkizard varren, fickleheart, sphere)
* (September 6, 2024)

* Version: 1.0

* Desc: Public release version 1.0 
		Feel free to use it for your own purposes! In exchange, if you make a change that
		improves it, please share it with us!
		1.0: Proper UDMF support, remove legacy system

* Quick guide:
	1. Add "Lua.Axis2DUDMF = true" to your level header.
	2. Add an axis to your map with a unique Order value above 0. Make sure its Direction setting is set correctly!
	3. Add a trigger sector (or intangible FOF) somewhere on the axis' path, triggering a linedef executor with action 443 (Call Lua Function), with P_AXIS2D as the function name. The linedef's parameters are as follows:
		- Linedef tag = The Order value of the axis to snap to
		- Linedef angle = Camera angle, relative to the player's movement direction, should usually be 90
		- Argument 1 = Camera distance, in fracunits (defaults to 448)
		- Argument 2 = Camera height, in fracunits (defaults to 0)
		- Argument 3 = Camera aiming, in degrees. Positive values point up, negative values point down. (defaults to 0)
		- Argument 4 = Camera angle (defaults to 0, relative to a side view of the player)
		- Argument 5 = Flags:
			1 - If enabled, the camera angle becomes absolute and won't rotate with the player
			2 - If enabled, use linedef angle to set the camera angle instead
	4. It is also possible to place an Axis Transfer Line, to make the player go in a straight line. This only requires one Axis Transfer Line object, with its angle set in the direction the player should move in.
	5. To exit Axis2D and go back into 3D, set up a linedef executor with tag 0.

]]



-- Killswitch to avoid the script loading multiple times
if axis2dudmf then
	print ("Axis2D for UDMF already loaded. Aborting...")
	return
end

rawset(_G, "axis2dudmf", {legacymode = false}) 

-- Toggle for spinning spring animation (for giggles)
--local springspin = CV_RegisterVar({"springspin", 1, 0, CV_OnOff})
local springspin = CV_RegisterVar({"springspin", 0, 0, CV_OnOff})

-- Axes found, so we don't have to look them up later
local axes = {lastmap = 0}





-- Checks what control style is currently active
function axis2dudmf.IsControlStyle(player)
	
	-- STRAFE   [0,0]
	-- STANDARD [0,4]
	-- SIMPLE   [2,4] sessionanalog/directionchar

	if (player.pflags & PF_ANALOGMODE and PF_DIRECTIONCHAR) then 
		return "simple"
	elseif (player.pflags &~ PF_ANALOGMODE and player.pflags & PF_DIRECTIONCHAR) then 
		return "standard"
	elseif (player.pflags &~ (PF_ANALOGMODE and PF_DIRECTIONCHAR)) then 
		return "strafe"
	end

end

-- Wrapper for checking if player is on an axis
function axis2dudmf.PlayerOnAxis(player)
	if not player and player.mo.valid then return end
	return (player.mo.currentaxis) and true or false
end

-- Refreshes the axis cache if needed
function axis2dudmf.CheckAxes()

	-- 6-30-2022: Only check if used through map headers
	if not mapheaderinfo[gamemap].axis2dudmf then return end

	if axes.lastmap ~= gamemap then
		axes = {lastmap = gamemap}
		print("Preparing Axis2D cache...")
		for mo in mobjs.iterate() do
			if mo.type == MT_AXIS then
				--print("Axis found!")
				local axisinfo = {}
				axisinfo.x = mo.x
				axisinfo.y = mo.y
				axisinfo.radius = mo.spawnpoint.args[2]
				axisinfo.flipped = mo.spawnpoint.args[3]
				axes[mo.spawnpoint.args[1]] = axisinfo
				--print("Storing axis #" .. mo.spawnpoint.args[1] .. " in table...")
				--print(axisinfo.x .. " " .. axisinfo.y .. " " .. axisinfo.radius)
			elseif mo.type == MT_AXISTRANSFERLINE then
				--print("Line axis found!")
				local axisinfo = {}
				axisinfo.basex = mo.x
				axisinfo.basey = mo.y
				axisinfo.angle = mo.angle
				axes[mo.spawnpoint.args[1]] = axisinfo
				--print("Storing axis #" .. mo.spawnpoint.args[1] .. " in table...")
				--print(axisinfo.basex .. " " .. axisinfo.basey .. " " .. axisinfo.angle)
			elseif mo.type == MT_AXISTRANSFER then
				continue -- Ignore these, but keep going in the list
			else
				--print("End of list.")
				break -- Axis objects always start off the list, so now we know there are no more to parse
			end
			axes[mo.spawnpoint.args[1]].number = mo.spawnpoint.args[1]
		end
	end
end

addHook("MapLoad", axis2dudmf.CheckAxes) -- Refresh axes on new map

-- Function to get the vector of a given object's axis
function axis2dudmf.GetVector(mo)

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
function axis2dudmf.SwitchAxis(mo, axisnum)

	axis2dudmf.CheckAxes() -- For starters, make the axis table if it's not already done
	
	local player = mo.player -- Special handling for players
	local oldangle
	
	if player then
		oldangle = axis2dudmf.GetVector(mo)
		if mo.currentaxis and mo.currentaxis.flipped then
			oldangle = $1+ANGLE_180
		end
		
		-- Lactozilla: fix backwards spindash, part 1
		if mo.ax2d_angle == nil
			mo.ax2d_angle = mo.angle
		end
		if mo.ax2d_dashflags == nil
			mo.ax2d_dashflags = 0
		end
		if mo.ax2d_dashspeed == nil
			mo.ax2d_dashspeed = 0
		end
	end
	
	--print("Changing to axis " .. l.tag)
	--if axis.angle then
	--	print("Axis is a straight line.")
	--end
	
	if player and (oldangle ~= nil) then

		local newangle = axis2dudmf.GetVector(mo)

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
	
	local axis = axes[l.tag]
	local axisnum = l.tag
	local player = mo.player


	if axisnum == 0 then

		--print("Ejecting the player from the 2D track...")
		if player and mo.currentaxis then
			axis2dudmf.EjectPlayer(player)
		end

		mo.currentaxis = nil
		return
	end
	
	if mo.currentaxis and mo.currentaxis.number == axisnum then
		return -- We're already on this axis, so no need to reset everything
	end


	if not axis then
		print("ERROR: Axis " .. l.tag .. " does not exist! Please create it!")
		return
	end

	-- Set Camera distance
	if (l.args[0] > 0)
		axis.camdist = l.args[0]*FRACUNIT
	else
		axis.camdist = false
	end
	
	-- Set Camera height
	if (l.args[1] > 0) then
		axis.camheight = l.args[1]*FRACUNIT
	else
		axis.camheight = false
	end
	
	-- Set Camera viewaiming
	if (l.args[2]) then
		axis.camaiming = FixedAngle(l.args[2]*FRACUNIT)
	else
		axis.camaiming = 0
	end

	-- Flags:
	
	-- 1 - Use absolute angle instead of relative, not rotating with the player
	if (l.args[4] & 1) then
		axis.camangleabs = true
	else
		axis.camangleabs = false
	end
	
	-- 2 - Set camera angle with linedef angle, instead of argument 4
	if (l.args[4] & 3) then
		axis.camangle = R_PointToAngle2(0, 0, l.dx, l.dy) - ANGLE_180
	elseif (l.args[4] & 2)
		axis.camangle = R_PointToAngle2(0, 0, l.dx, l.dy)
	else
		axis.camangle = FixedAngle(l.args[3]*FRACUNIT)
	end


	mo.currentaxis = axis
	axis2dudmf.SwitchAxis(mo, l.tag)
end, "P_Axis2D")


-- Snap mobj to axis
function axis2dudmf.SnapMobj(mo)

	-- Safety precaution!
	if not mo.currentaxis then return end

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

	angle = axis2dudmf.GetVector(mo)

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
		P_MoveOrigin(mo, mo.oldpos.x, mo.oldpos.y, mo.z)
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


-- Made to eject the player and reset any changes since these lines are used multiple times here
function axis2dudmf.EjectPlayer(player)

	player.mo.currentaxis = nil

	-- Reset status
	if not (player.mo.currentaxis) then
		player.normalspeed = skins[player.mo.skin].normalspeed
		player.thrustfactor = skins[player.mo.skin].thrustfactor
		player.accelstart = skins[player.mo.skin].accelstart
		player.acceleration = skins[player.mo.skin].acceleration
		if player.charability == CA_THOK then
			player.actionspd = skins[player.mo.skin].actionspd
		end
		player.runspeed = skins[player.mo.skin].runspeed
		player.jumpfactor = skins[player.mo.skin].jumpfactor
		player.pflags = $1&~PF_FORCESTRAFE
	end
end


local function SetCamera(player, x, y, z)

	local mo = player.mo

	if not (player.camera and player.camera.valid) then
		player.camera = P_SpawnMobj(mo.x, mo.y, mo.z, MT_GFZFLOWER1)
		player.camera.flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOTHINK
		player.camera.flags2 = MF2_DONTDRAW
		P_MoveOrigin(player.camera, x, y, z)
	end

	P_MoveOrigin(player.camera, player.camera.x+(x-player.camera.x)/4, player.camera.y+(y-player.camera.y)/4, player.camera.z+(z-player.camera.z)/4)
end

addHook("AbilitySpecial", function(player)
	-- Lactozilla: fix backwards thok, part 1
	if player.mo.currentaxis then
		player.mo.angle = player.mo.ax2d_angle
	end
end)


-- Player management!
addHook("PlayerThink", function(player)

	local mo = player.mo
	
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
		axis2dudmf.SnapMobj(mo)
		
		-- Handle camera
		if player.mo.health then -- Don't move the camera when the player's dead!
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
				mo.currentaxis.camheight = 32*FRACUNIT
			end
			if not mo.currentaxis.camaiming then
				mo.currentaxis.camaiming = 0
			end

			-- Attempt to track if your distance from the camera and act if far above tolerance value (eg. teleporting)
			if player.camera and player.camera.valid then

				local axiscamdist = FixedHypot(mo.currentaxis.x-player.camera.x, mo.currentaxis.y-player.camera.y)
				local playercamdist = FixedHypot(mo.currentaxis.x-mo.x, mo.currentaxis.y-mo.y)

				--print("camera dist from axis: "..axiscamdist/FRACUNIT)
				--print("p dist from axis: "..(playercamdist+ mo.currentaxis.camdist)/FRACUNIT)

				if axiscamdist > (playercamdist+mo.currentaxis.camdist)+128*FRACUNIT then
					P_MoveOrigin(player.camera,
						mo.currentaxis.x+(cos(angle)*mo.currentaxis.radius)+FixedMul(cos(camangle), mo.currentaxis.camdist),
						mo.currentaxis.y+(sin(angle)*mo.currentaxis.radius)+FixedMul(sin(camangle), mo.currentaxis.camdist),
						mo.z+20*FRACUNIT+(mo.currentaxis.camheight)
					)
				end
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
			player.awayviewaiming = mo.currentaxis.camaiming -- Awayviewaiming property
		end
		player.awayviewmobj.momz = 0
		
		-- Set player angle
		if (player.pflags & PF_GLIDING) then
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
					P_SetOrigin(mo, mo.x-mo.momx, mo.y-mo.momy, mo.z) -- Now put them back for reasons.
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

						-- TODO: replace with iterating lines from a table instead
						for l in lines.iterate do -- TODO: SSSLLLOOOWWW look for a method to only get lines from the active sector
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
				player.drawangle = angle-ANG20*leveltime
			else
				player.drawangle = angle+ANG20*leveltime
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

			-- Handle player angle direction when rotating around an axis + flipped
			if mo.isfacingleft then
				player.drawangle = angle-ANGLE_90
				mo.angle = angle-ANGLE_90
			else
				player.drawangle = angle+ANGLE_90
				mo.angle = angle+ANGLE_90
			end
			-- Flipped axis
			if mo.currentaxis.flipped then
				player.drawangle = $1+ANGLE_180
				mo.angle = $1+ANGLE_180
			end
		end
		
		-- Lactozilla: fix backwards thok, part 2
		mo.ax2d_angle = mo.angle

		-- Lactozilla: fix backwards spindash, part 2
		if (P_IsObjectOnGround(mo)
		and not (mo.ax2d_dashflags & PF_SPINDOWN)
		and (mo.ax2d_dashflags & PF_STARTDASH)
		and (mo.ax2d_dashflags & PF_SPINNING))
			-- Correct spindash angle
			P_InstaThrust(mo, mo.ax2d_angle, FixedMul(mo.ax2d_dashspeed, player.mo.scale))
		end

		mo.ax2d_dashflags = player.pflags & (PF_SPINDOWN|PF_STARTDASH|PF_SPINNING)
		mo.ax2d_dashspeed = player.dashspeed
		
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
				and not P_PlayerInPain(player) and player.mo.health then
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
		
	end
end)

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
		axis2dudmf.SnapMobj(mo)
	end
	
end, MT_FLINGRING)

-- SeventhSentinel: Fail-safe to eject and reset players when they respawn
-- TODO: I don't know what I'm doing, there is probably a better way to do this
addHook("PlayerSpawn", axis2dudmf.EjectPlayer)
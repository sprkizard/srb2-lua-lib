
rawset(_G, "EvAction", {})

-- ------------------------------------------------------
-- @region SYSTEM - System functions
-- ------------------------------------------------------

-- Allows zero values or an alternative if value is nil (prev: notnil)
function EvAction.defvalue(value, altvalue)
	return (value and not nil) and value or altvalue
end

function EvAction.IsValidMobj(mo)
	return (mo and mo.valid)
end

function EvAction.CheckValidMobj(mo)
	if not (mo and mo.valid) then return end
end

-- Determines whether or not to use the given player (userdata), or all players (string)
function EvAction.CheckPlayerTypeValid(player)
	-- no player exists
	if not (type(player) == "string") and not (player and player.mo.valid) then return true end
end

-- A wrapper for players.iterate
function EvAction.doforall(func)
	for player in players.iterate do
		-- if not (player.mo and player.mo.valid) then continue end
		do func(player) end
	end
end

-- Wrapper for checking if a player is valid
function EvAction.isplayervalid(checkedplayer)
	if (checkedplayer and checkedplayer.valid) then
		return true
	else
		return false
	end
end

-- Validates if a player exists if used in an EV, and shuts it down if they don't exist
function EvAction.EVS_validateplayer(ev, checkedplayer)
	if not (checkedplayer and checkedplayer.valid) then
		Event.destroyself(ev)
	end
end

-- Iterates players and adds them to a list that is returned
function EvAction.createplayerlist()
	local t = {}

	for player in players.iterate do
		if not (player and player.valid) then continue end
		table.insert(t, player)
	end
	return t -- return table
end

-- Iterates players and adds them to a list that is returned (on conditional)
function EvAction.createplayerlistfromcond(fn)
	local t = {}

	for player in players.iterate do
		if not (player and player.valid) then continue end

		-- do thing because of cond fn
		if fn(player) then
			table.insert(t, player)
		end
	end
	return t -- return table
end

-- Selectively assigns players to an EV State Sequence
-- Includes only specified players and filters out the rest
function EvAction.filterforplayers(container, playerlist)
	-- Create assigned players list
	if not container["assignedplayers"] then container["assignedplayers"] = {} end

	-- Check for valid players before assigning (because otherwise the game might throw yet another fit!)
	for _, play in ipairs(playerlist) do
		(function()-- not valid, skip
			if not (play and play.mo.valid) then return end
			-- Insert player
			table.insert(container["assignedplayers"], play)
		end)()
	end
end

function EvAction.timedexec(fn, tstart, tend, timer)
	if timer >= tstart and timer <= tend then
		fn()
	end
end

-- Converts a fixed distance (factored with speed and a scale) to tics.
function EvAction.DistToTics(distance, speed, scale)
	return FixedCeil(FixedDiv(FixedDiv(distance, speed), scale)) / FRACUNIT
end

-- Gets distance of two objects in 3D space
function EvAction.GetDist3D(p1, p2)
    return FixedHypot(FixedHypot(p1.x-p2.x, p1.y-p2.y), p1.z-p2.z)
end

-- Gets distance of two objects in 2D space
function EvAction.GetDist2D(p1, p2)
    return FixedHypot(p1.x-p2.x, p1.y-p2.y)
end

-- Custom Random function that uses leveltime in case the random seed desynched
local function RandomRange_P(min, max)
	if min == max then return min end -- What's the point if there's no range?

	-- Well this won't work if min isn't actually min!
	if min > max then
		local oldmax = max
		max = min
		min = oldmax
	end

	-- Get a mapthing's positioning based off of the leveltime
	local position = 0
	local thing = mapthings[leveltime % (#mapthings + 1)]
	if thing then
		if check == 0 then
			position = thing.x
		elseif check == 1 then
			position = thing.y
		else
			position = thing.z
		end

		--Add each player's lives and skin
		for player in players.iterate do
			position = $1 * player.skin * player.lives
		end

		if position < 0 then
			position = abs($1 + INT32_MAX)
		end
	end

	-- Get our value
	local factor = position or leveltime
	local value = (factor % (max - min))
	return value + min
end

-- Random Choice port
function EvAction.RandomChoice(choices, vanillarandom)
	local RandomKey = 0
	if vanillarandom then
		RandomKey = P_RandomRange(1, #choices)
	else
		RandomKey = RandomRange_P(1, #choices)
	end
    if type(choices[RandomKey]) == "function" then
        choices[RandomKey]()
    else
        return choices[RandomKey]
    end
end

function EvAction.PickRandomXYZ(choices)
	local rx = choices[P_RandomRange(1, #choices)]*FRACUNIT
	local ry = choices[P_RandomRange(1, #choices)]*FRACUNIT
	local rz = choices[P_RandomRange(1, #choices)]*FRACUNIT

	return {x=rx,y=ry,z=rz}
end

-- Creates a value in the container
function EvAction.Sq_CreateValue(container, valuename, value)
	container[valuename] = value
end

-- ------------------------------------------------------
-- @region INPUT - Effect functions
-- ------------------------------------------------------

-- Waits for an input by a selected player. Returns true if the decline button is pressed
function EvAction.waitForInput(ev, selectplayer, button, fn)
	if not selectplayer and selectplayer.valid then return end

	Event.waitUntil(ev, selectplayer.cmd.buttons & button)
end

-- Sets a timer to pass for automatically advancing.
function EvAction.Sq_SetQTimer(container, time)
	container["qt_autoadvancetime"] = 0
	container["qt_autoadvancetime_max"] = time
end

-- Waits for a timer to pass before automatically advancing. Not the same as waiting.
function EvAction.Sq_AdvanceQTimer(ev, container, triggerpause)
	-- if not e then return end

	if (container["qt_autoadvancetime_max"]) then

		container["qt_autoadvancetime"] = $1+1

		if (container["qt_autoadvancetime"] >= container["qt_autoadvancetime_max"]) then
			container["qt_autoadvancetime"] = 0
			container["qt_autoadvancetime_max"] = 0
			Event.resume(ev)
			return
		else
			if triggerpause then Event.pause(ev) end
		end
	end
end

-- ------------------------------------------------------
-- @region GAME - Gameplay functions
-- ------------------------------------------------------

-- Sets the checkpoint number manually for all players
function EvAction.setcheckpoint(num, position, chkangle)
    for player in players.iterate do
        player.starpostnum = num
        player.starposttime = player.realtime
        player.starpostx = position.x or 0*FRACUNIT
        player.starposty = position.y or 0*FRACUNIT
        player.starpostz = position.z or 0*FRACUNIT
        player.starpostangle = chkangle
    end
end

-- Forces a player to be re-born if they are dead in a netgame
function EvAction.forceplayerreborn(player)
	if not (player and player.valid) then return end -- no player exists

	if (netgame and (player.playerstate == PST_DEAD and player.lives > 0)) then
		player.playerstate = PST_REBORN
	end
end

-- Teleports all players to a location
function EvAction.relocateplayers(position, angle, interpolate)
	local warporigin = interpolate and P_MoveOrigin or P_SetOrigin -- or P_TeleportMove

	for player in players.iterate do
		warporigin(player.mo, position.x, position.y, position.z) -- (2.2.11 interpolation patch)
		-- P_MoveOrigin(player.mo, position.x, position.y, position.z)
		player.mo.angle = angle or 0
	end
end

Event.new("a_relocate_players", {
function(c,e)
	-- Capture players that should be re-located
end,
function(c,e)
	EvAction.relocateplayers(c.position, c.angle, c.interpolate)
	Event.wait(e, c.timing or 5*TICRATE)
end})

-- Teleports all players to a location constantly
function EvAction.relocateplayers_start(timing, position, angle, interpolate)
	Event.start("a_relocate_players", {timing = timing, position = position, angle = angle, interpolate = interpolate})
end


-- Stops teleporting all players to a location constantly
function EvAction.relocateplayers_end()
	Event.destroy("a_relocate_players")
end

-- @notice (8-31-2023): Was prone to a random error before
-- Creates a suspended position for suspending a player in place
local function Evie_CreateSuspendedPosition(player)
	player.mo._evie_suspendedxyz = {}
	player.mo._evie_suspendedxyz.x = player.mo.x
	player.mo._evie_suspendedxyz.y = player.mo.y
	player.mo._evie_suspendedxyz.z = player.mo.z
	player.mo._evie_suspendedxyz.drawangle = player.drawangle
	player.mo._evie_suspendedxyz.angle = player.mo.angle
end

-- Creates a sequence to suspend a player in place
Event.new("a_freeze_player", {
function(c,e)
	-- Get player original position
	for _, player in ipairs(c.playerlist) do

		if (player and player.valid) then
			Evie_CreateSuspendedPosition(player)
		end
	end
end,
function(c,e)
	-- Freeze player in place
	for _, player in ipairs(c.playerlist) do
		if (player and player.valid) then

			if not player.mo._evie_suspendedxyz then Evie_CreateSuspendedPosition(player) end

			-- Warp in place
			local mo = player.mo
			P_SetOrigin(mo, mo._evie_suspendedxyz.x, mo._evie_suspendedxyz.y, mo._evie_suspendedxyz.z) -- (2.2.11 interpolation patch)
			-- P_MoveOrigin(mo, mo._evie_suspendedxyz.x, mo._evie_suspendedxyz.y, mo._evie_suspendedxyz.z)

			-- Set angle
			mo.angle = mo._evie_suspendedxyz.angle
			player.drawangle = mo._evie_suspendedxyz.drawangle

			-- TODO: pw_nocontrol option for players to be allowed to jump
			-- Disable controls if enabled
			if (c.nocontrol) then
				player.powers[pw_nocontrol] = 1
			end
		end
	end
	Event.waitUntil(e, false)
end})

-- Freezes players in place, and also allows control restricting
function EvAction.FreezePlayers(frozenplayerlist, restrictcontrols)
	Event.start("a_freeze_player", {playerlist = frozenplayerlist, nocontrol = restrictcontrols})
end

-- Unfreezes players
function EvAction.UnfreezePlayers()
	Event.destroy("a_freeze_player")
end

-- Set a players textbox to another player
function EvAction.synchronizetextboxes(player, targetplayer)
	if not (player and player.mo.valid) then return end -- no player exists
	if not (player.textbox) then return end

	targetplayer.textbox = player.textbox

end

-- TODO: re-write for the new hud display
function EvAction.StartAnimationTimerDisplay(start_time)
	
	-- THE LIBRARY IS NOT ADDED
	if not (_G["R_AddHud"]) then return end

	-- local Time = start_time or 0

	-- R_AddHud("_fsm-animationtimer", 30, nil, function(a, v, stplyr, cam)
	-- 	Time = $1+1
	-- 	local Hours = string.format("%02d", G_TicsToHours(Time))
	-- 	local Minutes = string.format("%02d", G_TicsToMinutes(Time))
	-- 	local Seconds = string.format("%02d", G_TicsToSeconds(Time))
	-- 	local Centiseconds = string.format("%02d", G_TicsToCentiseconds(Time))
	-- 	local Milliseconds = string.format("%02d", G_TicsToMilliseconds(Time))
	-- 	v.drawString(320/2,5, Hours..":"..Minutes..":"..Seconds..":"..Centiseconds, V_ALLOWLOWERCASE|V_MONOSPACE, "center")
	-- end)
end

function EvAction.EndAnimationTimerDisplay(start_time)

	-- THE LIBRARY IS NOT ADDED
	-- if not (_G["R_DeleteHud"]) then return end
	
	R_DeleteHud("_fsm-animationtimer")
end

-- ------------------------------------------------------
-- @region CAMERA - Camera functions
-- ------------------------------------------------------

-- Creates an object to act as a camera inside of the container
function EvAction.Sq_MakeCamera(container, ox, oy, oz, custommobjtype)
	local x = (ox and not nil) and ox or 0
	local y = (oy and not nil) and oy or 0
	local z = (oz and not nil) and oz or 0

	container["camera"] = P_SpawnMobj(x, y, z, custommobjtype or MT_PUSH)
	container["camera"].isevcamera = true -- To let iterators know it's a camera, it will apply this variable to itself
end


-- Resets the awayviewmobj
local function P_ResetAwayviewCamera(play, viewmobj)
	play.awayviewmobj = nil
	play.awayviewmobj = viewmobj
end

-- Sets an awayviewmobj to act as a camera indefinitely
function EvAction.setactivecamera(player, awaycam, awayaiming)

	-- player is userdata but not valid
	if (type(player) == "userdata" and not player.valid) or (type(player) == "nil") then return end

	if not (awaycam and awaycam.valid) then print("Camera does not exist.") return end

	-- Triggers for all players, or only the one specified
	if (type(player) == "boolean" and player == true) then
		EvAction.doforall(function(play)
			P_ResetAwayviewCamera(play, awaycam)
			play.awayviewmobj = awaycam
			play.awayviewtics = INT32_MAX
			play.awayviewaiming = (awayaiming and not nil) and awayaiming or 0
		end)
	elseif (type(player) == "userdata") then
		P_ResetAwayviewCamera(player, awaycam)
		player.awayviewmobj = awaycam
		player.awayviewtics = INT32_MAX
		player.awayviewaiming = (awayaiming and not nil) and awayaiming or 0
	end

end

-- Moves the camera to a position, and updates player viewpoints unless specified
function EvAction.setcamera(player, awaycam, position, angle, aiming, useang, interpolate)

	-- player is userdata but not valid
	if (type(player) == "userdata" and not player.valid) or (type(player) == "nil") then return end

	if not (awaycam and awaycam.valid) then print("Camera does not exist.") return end

	-- Unused: position angle for backwards compat
	-- local pangle = EvAction.defvalue(position and position.angle, 0)
	local fangle = EvAction.defvalue(angle, 0)
	local faiming = EvAction.defvalue(aiming, 0)

	-- Determine whether to target all players, or just the one given
	EvAction.setactivecamera(player, awaycam, useang and faiming or FixedAngle(faiming))
	-- EvAction.setactivecamera(player, awaycam, FixedAngle(aiming))

	awaycam.angle = ( useang and fangle or FixedAngle(fangle) )
	-- awaycam.angle = FixedAngle(angle or position.angle)

	local warporigin = interpolate and P_MoveOrigin or P_SetOrigin -- or P_TeleportMove

	warporigin(awaycam, position.x, position.y, position.z) -- (2.2.11 interpolation patch)
	-- P_ResetAwayviewCamera(player, awaycam)
	-- P_MoveOrigin(awaycam, position.x, position.y, position.z)
end

-- Moves the camera relative to where it was last
-- TODO: replace with camera orientation
function EvAction.setcamera_relative(player, awaycam, rx, ry, rz, angle, aiming)

	local ax = (awaycam.x and not nil) and awaycam.x or 0
	local ay = (awaycam.y and not nil) and awaycam.y or 0
	local az = (awaycam.z and not nil) and awaycam.z or 0
	local aim = (aiming and not nil) and aiming or 0

	local position = {x=ax + rx, y=ay + ry, z=az + rz}

	EvAction.setcamera(player, awaycam, position, angle or awaycam.angle, aim)
end

-- Make the camera track a point in space (prev: lookAtZ)
function EvAction.cameratrack(player, awaycam, destination)

	-- player is userdata but not valid
	if (type(player) == "userdata" and not player.valid) or (type(player) == "nil") then return end

	if not (awaycam and awaycam.valid) then print("Camera does not exist.") return end

	local x1, y1, z1 = awaycam.x, awaycam.y, awaycam.z
	local x2, y2, z2 = destination.x, destination.y, destination.z

	-- Point to track destination, and z height of the destination
	awaycam.angle = R_PointToAngle2(x1, y1, x2, y2)
	-- player.awayviewaiming = R_PointToAngle2(0, 0, FixedHypot(x2 - x1, y2 - y1), z2 - z1)
	local aimdirection = R_PointToAngle2(0, 0, FixedHypot(x2 - x1, y2 - y1), z2 - z1)

	-- Determine whether to target all players, or just the one given
	EvAction.setactivecamera(player, awaycam, aimdirection)
end

-- Changes the viewroll for the specified player
function EvAction.setplayerviewroll(player, rollangle, addangle)

	-- player is userdata but not valid
	if (type(player) == "userdata" and not player.valid) or (type(player) == "nil") then return end

	-- Triggers for all players, or only the one specified
	if (type(player) == "boolean") then
		EvAction.doforall(function(play)
			play.viewrollangle = (addangle==true and $1+rollangle or rollangle)
		end)
	else
		player.viewrollangle = (addangle==true and $1+rollangle or rollangle)
	end
end

-- TODO: may disrupt anything else that uses awayviewmobj
-- Ceases all awayviewmobj activity
function EvAction.stopcameraview(player)

	-- player is userdata but not valid
	if (type(player) == "userdata" and not player.valid) or (type(player) == "nil") then return end

	-- Triggers for all players, or only the one specified
	if (type(player) == "boolean") then
		EvAction.doforall(function(play)
			play.awayviewmobj = nil
			play.awayviewtics = 0
			play.awayviewaiming = 0
		end)
	else
		player.awayviewmobj = nil
		player.awayviewtics = 0
		player.awayviewaiming = 0
	end
end

-- ------------------------------------------------------
-- @region SOUND - Sound functions
-- ------------------------------------------------------

-- local MUSIC_RELOADRESET = MUSIC_RELOADRESET or 0x8000

-- Plays a musicname with S_ChangeMusic, with the ability to set it as the main map playback track
function EvAction.SetCurrentMusic(mainmus, musname, loop, player, flags, position, prefade, fadein)
	S_ChangeMusic(musname, loop, player, flags, position, prefade, fadein)

	-- Sets main playback track
	if mainmus then	mapmusname = musname end

	if multiplayer then
		mapmusflags = 0 -- Don't reload music on death
	else
		mapmusflags = 32768 -- 0x8000 Reload music on death
	end
end

-- TODO: More study on how this works is needed
-- Sets music flags to mapmusflags
-- Flag Types: (reload [MUSIC_RELOADRESET] (Reload on death) | force [MUSIC_FORCERESET] (???))
function EvAction.SetMapMusicFlags(flagtype)
	local flag = 0

	if flagtype == "reload" then
		flag = 32768 --0x8000
	elseif (flagtype == "force") then
		flag = 16384 --0x4000
	end

	mapmusflags = flag
end

-- Event Action wrapper to play a sound
function EvAction.startsound(mobj, soundnum, volume, player)
	if (volume) then
		S_StartSoundAtVolume(mobj, soundnum, volume, player)
	else
		S_StartSound(mobj, soundnum, player)
	end
end

-- Plays a sound at a timed rate
function EvAction.PlaySoundRate(source, soundnum, time, volume, player)
	if (leveltime % time == 0) then
		local sound = (volume) and S_StartSoundAtVolume(source, soundnum, volume or 255, player) or S_StartSound(source, soundnum, player)
	end
end

-- ------------------------------------------------------
-- @region ACTOR - Actor functions
-- ------------------------------------------------------

-- Creates a character that can be modified by the sequence (prefixed under ac_)
function EvAction.Sq_CreateActor(container, charname, skin, sprite, radius, shadow, color, attr)

	container["ac_" .. charname] = P_SpawnMobj(0, 0, 0, MT_PUSH) -- (Change when needed)
	container["ac_" .. charname].sprite = sprite or SPR_PLAY
	if skin then container["ac_" .. charname].skin = skin or "Sonic" end
	container["ac_" .. charname].radius = radius
	container["ac_" .. charname].shadowscale = shadow
	container["ac_" .. charname].color = color or SKINCOLOR_BLUE

	-- Sets custom attributes in function format if wanted
	if attr then
		do attr(container["ac_" .. charname]) end
	end
end

-- Creates an object that can be modified by the sequence (prefixed under m_)
function EvAction.Sq_CreateMobjActor(container, mobjname, mobjtype, position, attr)

	local x = (position.x and not nil) and position.x or 0
	local y = (position.y and not nil) and position.y or 0
	local z = (position.z and not nil) and position.z or 0

	container["m_" .. mobjname] = P_SpawnMobj(x, y, z, mobjtype)

	-- Sets custom attributes in function format if wanted
	if attr then
		do attr(container["m_" .. mobjname]) end
	end
end

-- ========
-- Camera Actions
-- ========

-- Local shortcut to set awayviewmobj
local function setawayview(player, awayviewmobj, awayviewaiming, enabled)
	-- Sets the camera and viewtics to an absurdly high amount
	if (enabled) then
		player.awayviewmobj = awayviewmobj
		player.awayviewtics = INT16_MAX --65535*TICRATE
		player.awayviewaiming = awayviewaiming or 0
	else
		player.awayviewmobj = nil
		player.awayviewtics = 1
		player.awayviewaiming = 0 -- awayviewaiming or 0
	end
end

-- Sets or disables the active camera for the player (prev: netgameOverride)
function EvAction.setactivecamera(player, targetawaycamera, enabled)
	if EvAction.CheckPlayerTypeValid(player) then return end
	-- if not (type(player) == "string") and not (player and player.mo.valid) then return end -- no player exists
	if not (targetawaycamera and targetawaycamera.valid) then return end

	-- Determine whether to target all players, or just the one given
	if (type(player) == "string") then
		EvAction.doforall(function(play)
			setawayview(play, targetawaycamera, 0, enabled)
		end)
	else
		setawayview(player, targetawaycamera, 0, enabled)
	end

end

-- Sets the camera as 'inactive'
function EvAction.cameraoverride(player, awaycamera, enabled)
	-- TODO: pointless player check?
	-- if not (player and player.mo.valid) then return end -- no player exists
	if not (awaycamera and awaycamera.valid) then return end

	if (enabled and not awaycamera.inactive) then
		awaycamera.momz = 0
	end
	awaycamera.inactive = enabled
end

-- Sets the camera position (prev: SetEye)
function EvAction.setcamera(player, awaycamera, position)
	if EvAction.CheckPlayerTypeValid(player) then return end
	-- if not (type(player) == "string") and not (player and player.mo.valid) then return end -- no player exists
	if not (awaycamera and awaycamera.valid) then return end

	-- Determine whether to target all players, or just the one given
	if (type(player) == "string") then
		EvAction.doforall(function(play)
			setawayview(play, awaycamera, (position and position.aiming) or 0, true)
		end)
	else
		setawayview(player, awaycamera, (position and position.aiming) or 0, true)
	end
	awaycamera.angle = (position and position.angle) or awaycamera.angle

	-- Use relative position setting, or absolute
	if (position and position.rel) then
		P_TeleportMove(awaycamera, awaycamera.x+position.x, awaycamera.y+position.y, awaycamera.z+position.z)
	else
		P_TeleportMove(awaycamera, position.x, position.y, position.z)
	end

	-- TODO: explore if we still need an event to freeze the camera in place
	-- P_TeleportMove(camera, position.x, position.y, position.z)
	-- P_TeleportMove(camera, position.x or camera.x, position.y or camera.y, position.z or camera.z)
end

-- Make the camera track a point in space (prev: lookAtZ) (added offsets for better composition)
function EvAction.cameratrack(player, awaycamera, destination, offseth, offsetv)
	if EvAction.CheckPlayerTypeValid(player) then return end

	-- point in the direction the camera is already looking if destination's type changes
	if (type(destination) == "boolean") then
		destination = {
			x=awaycamera.x+P_ReturnThrustX(awaycamera, awaycamera.angle, awaycamera.radius + 64*FRACUNIT),
			y=awaycamera.y+P_ReturnThrustY(awaycamera, awaycamera.angle, awaycamera.radius + 64*FRACUNIT),
			z=awaycamera.z
		}
	end

	local x1, y1, z1 = awaycamera.x, awaycamera.y, awaycamera.z
	local x2, y2, z2 = destination.x, destination.y, destination.z

	-- Point to track destination, and z height of the destination
	local hangle = R_PointToAngle2(x1, y1, x2, y2)

	local aimdirection = R_PointToAngle2(0, 0, FixedHypot(x2 - x1, y2 - y1), z2 - z1)
	
	if (type(player) == "string") then
		EvAction.doforall(function(play)
			setawayview(play, awaycamera, aimdirection + FixedAngle(offsetv or 0), true)
		end)
	else
		setawayview(player, awaycamera, aimdirection + FixedAngle(offsetv or 0), true)
	end
	-- Angle
	awaycamera.angle = hangle + (FixedAngle(offseth or 0))
end

--[[function EvAction.camerashake(player, awaycamera, hangle, hspeed, vangle, vspeed)
	awaycamera.angle = $1 + FixedAngle(hangle*cos(leveltime*FixedAngle(hspeed)))

	if (type(player) == "string") then
		EvAction.doforall(function(play)	
			play.awayviewaiming = $1 + FixedAngle(vangle*sin(leveltime*FixedAngle(vspeed)))
		end)
	else	
		player.awayviewaiming = $1 + FixedAngle(vangle*sin(leveltime*FixedAngle(vspeed)))
	end
end--]]

function EvAction.setplayerviewroll(player, rollangle, addangle)
	if EvAction.CheckPlayerTypeValid(player) then return end

	if (type(player) == "string") then
		EvAction.doforall(function(play)
			play.viewrollangle = (addangle==true and $1+rollangle or rollangle)
		end)
	else
		player.viewrollangle = (addangle==true and $1+rollangle or rollangle)
	end
end

function EvAction.setcamerapos(mobj, point, prefs)

	if not (mobj and mobj.valid) then return end -- no mobj

	P_TeleportMove(mobj, point.x, point.y, point.z)
end

-- ------------------------------------------------------
-- @region OBJECT - Object/Mobj functions
-- ------------------------------------------------------

-- Gets distance between two mobj/point
function EvAction.getmobjdistance(mobja, mobjb)

	if not ((mobja and mobja.valid) or (mobjb and mobjb.valid)) then return end -- no mobj

	return FixedHypot(FixedHypot(mobja.x-mobjb.x, mobja.y-mobjb.y), mobja.z-mobjb.z)
end

-- A wrapper for P_TeleportMove in the eventaction table with extras
function EvAction.movemobjto(mobj, position, interpolate)

	position = EvAction.defvalue($1, {x=0,y=0,z=0})

	if not (mobj and mobj.valid) then return end -- no mobj

	local px = EvAction.defvalue(position.x, 0)
	local py = EvAction.defvalue(position.y, 0)
	local pz = EvAction.defvalue(position.z, 0)
	-- local px = (position.x and not nil) and position.x or 0
	-- local py = (position.y and not nil) and position.y or 0
	-- local pz = (position.z and not nil) and position.z or 0

	local warporigin = interpolate and P_MoveOrigin or P_SetOrigin -- or P_TeleportMove
	warporigin(mobj, px, py, pz) -- (2.2.11 interpolation patch)
	-- P_MoveOrigin(mobj, px, py, pz)
end

-- Moves a mobj relatively from its current position
function EvAction.movemobjrelative(mobj, rx, ry, rz, interpolate)

	if not (mobj and mobj.valid) then return end -- no mobj

	local ax = (mobj.x and not nil) and mobj.x or 0
	local ay = (mobj.y and not nil) and mobj.y or 0
	local az = (mobj.z and not nil) and mobj.z or 0
	-- local position = {x=ax + rx, y=ay + ry, z=az + rz}

	local warporigin = interpolate and P_MoveOrigin or P_SetOrigin -- or P_TeleportMove
	warporigin(mobj, ax + rx, ay + ry, az + rz) -- (2.2.11 interpolation patch)
	-- P_MoveOrigin(mobj, ax + rx, ay + ry, az + rz)
end

-- Event action wrapper for changing the mobj sprite (+frame)
function EvAction.setmobjsprite(mobj, newsprite, newframe)

	if not (mobj and mobj.valid) then return end -- no mobj

	mobj.sprite = newsprite or SPR_UNKN -- fallback to error sprite
	if (newframe) then mobj.frame = newframe end
end

-- Event action wrapper for changing the mobj frame
function EvAction.setmobjframe(mobj, newframe)

	if not (mobj and mobj.valid) then return end -- no mobj

	mobj.frame = newframe or 0
end

-- Event action to set a mobj color, and colorize it
function EvAction.setmobjcolor(mobj, color, colorize)
	if (colorize) then
		mobj.color = color
		mobj.colorized = true
	else
		mobj.color = color
		mobj.colorized = false
	end
end

-- Event action to set a mobj shadow scale (warning, edits its radius. useful for NPC)
function EvAction.setshadowscale(mobj, scale, radius)
	mobj.shadowscale = scale
	mobj.radius = radius
end

-- Sets a mobj scale (or destscale)
function EvAction.setmobjscale(mobj, scale, speed)

	if not (mobj and mobj.valid) then return end -- no mobj

	if (speed) then
		mobj.destscale = scale
		mobj.scalespeed = speed
	else
		mobj.scale = scale
	end
end

-- Sets multiple mobj scale (wrapper)
function EvAction.setmultiscale(mobjlist, scale, speed)
	for i=1,#mobjlist do
		-- if not (mobjlist[i] and mobjlist[i].valid) then return end -- no mobj
		EvAction.setmobjscale(mobjlist[i], scale, speed)
	end
end

-- Wrapper for setting the dontdraw flag
function EvAction.setmobjvisible(mobj, isvisible)
	if not (mobj and mobj.valid) then return end -- no mobj

	if (isvisible) then
		mobj.flags2 = $1 &~ MF2_DONTDRAW
	else
		mobj.flags2 = $1|MF2_DONTDRAW
	end
end

-- Make the mobj look at a direction (in angles) (prev: mobjchangeangle)
function EvAction.setmobjeangle(mobj, directionangle, addangle)
	if not (mobj and mobj.valid) then return end -- no mobj
	mobj.angle = (addangle == true) and $1+directionangle or directionangle
end

-- Make the mobj look at another mobj or point (prev: mobjlookat)
function EvAction.setmobjlookat(mobj, point)
	if not (mobj and mobj.valid) then return end -- no mobj
	mobj.angle = R_PointToAngle2(mobj.x, mobj.y, point.x, point.y)
end

-- Get the direction of where to look at a mobj or point
function EvAction.getlookangle(mobj, point)
	if not (mobj and mobj.valid) then return end -- no mobj
	return R_PointToAngle2(mobj.x, mobj.y, point.x, point.y)
end

-- Set the mobj roll/rotation angle (or continuously add)
function EvAction.setspriteroll(mobj, angle, addangle)
	if not (mobj and mobj.valid) then return end -- no mobj

	if (addangle) then
		mobj.rollangle = $1+angle
	else
		mobj.rollangle = angle
	end
end

-- Stops the mobj's momentum
function EvAction.stopmobjmomentum(mobj)
	if not (mobj and mobj.valid) then return end -- no mobj

	mobj.momx = 0
	mobj.momy = 0
	mobj.momz = 0
end

-- A wrapper for P_TeleportMove in the eventaction table with extras
function EvAction.setmobjpos(mobj, point, prefs)

	if not (mobj and mobj.valid) then return end -- no mobj
	-- if (type(point) == "userdata" and not (point and point.valid)) then return end -- no mobj
	
	-- Use relative position setting, or absolute
	if (prefs and prefs.rel) then
		P_TeleportMove(mobj, mobj.x+point.x, mobj.y+point.y, mobj.z+point.z)
	else
		P_TeleportMove(mobj, point.x, point.y, point.z)
	end

	-- P_TeleportMove(mobj, point.x, point.y, point.z)
end

-- TODO: slight rework?
function EvAction.setmobjorbit(mobj, point, prefs, lookat)

	if not (mobj and mobj.valid) then return end -- no mobj

	local xd = prefs.x*cos(prefs.dir+FixedAngle(prefs.rot*FRACUNIT))
	local yd = prefs.y*sin(prefs.dir+FixedAngle(prefs.rot*FRACUNIT))
	local zd = prefs.z


	-- Use relative position setting, or absolute
	if (prefs and prefs.rel) then
		P_TeleportMove(mobj, mobj.x+point.x+xd, mobj.y+point.y+yd, mobj.z+point.z+zd)
	else
		P_TeleportMove(mobj, point.x+xd, point.y+yd, point.z+zd)
	end

	-- if lookat then mobj.angle = R_PointToAngle2(mobj.x, mobj.y, point.x, point.y)+($-R_PointToAngle2(mobj.x, mobj.y, point.x, point.y))/4 end
	if lookat then mobj.angle = R_PointToAngle2(mobj.x, mobj.y, point.x, point.y) end
end

-- Linear interpolation (might avoid a function conflict)
function EvAction.lerp(a, b, t)
	return a + FixedMul(b - a, t)
end

function EvAction.Distance3D(p1, p2)
    return FixedHypot(FixedHypot(p1.x-p2.x, p1.y-p2.y), p1.z-p2.z)
end

function EvAction.Distance2D(p1, p2)
    return FixedHypot(p1.x-p2.x, p1.y-p2.y)
end

local function bezier(delta, p1, p2)
	-- first iteration
	local p0 = FixedMul(p1, delta)
	p1 = $ + FixedMul(p2-p1, delta)
	p2 = $ + FixedMul(FRACUNIT-p2, delta)
	
	-- second iteration
	p0 = $+FixedMul(p1-p0, delta)
	p1 = $+FixedMul(p2-p1, delta)
	
	-- final pointp
	return p0 + FixedMul(p1-p0, delta)
end

-- TODO: deleteme
function EvAction.mobjmoveto(event, mobj, point, speed, prefs)

	if not (mobj and mobj.valid) then return end -- no mobj

	-- TODO?: division by zero error fixed with +1 on dist below..but 
	-- check and return if we reached point anyways?

	local dist = FixedHypot(point.z-mobj.z, FixedHypot(point.x-mobj.x, point.y-mobj.y))+1
	-- local dist = FixedHypot(FixedHypot(mobj.x-point.x, mobj.y-point.y), mobj.z-point.z)+1
	local t_ang = R_PointToAngle2(mobj.x, mobj.y, point.x, point.y) -- The travel angle

	local pct = FixedDiv(speed, dist)+1 -- percent to move per frame
	-- pct = bezier(pct, 0, FRACUNIT)

	-- Interpolate the constant movement on all axis based on the distance
	local movex = EvAction.lerp(mobj.x, point.x, pct)
	local movey = EvAction.lerp(mobj.y, point.y, pct)
	local movez = EvAction.lerp(mobj.z, point.z, pct)

	-- Move the object in an arc over its distance to the destination
	-- TODO: why does this make the arc higher the further the distance?
	if (prefs and prefs.arc) then
		local ang = FixedMul(FixedMul(ANGLE_180, dist/speed), 26*FRACUNIT) -- dist/speed
		-- print(string.format("distance: %d | pct: %d | ang: %f", dist/FRACUNIT, pct/FRACUNIT, ang))
		-- movex = $-FixedMul(prefs.arc.x or 0, sin(ang))
		-- movey = $-FixedMul(prefs.arc.y or 0, sin(ang))
		movex = $+P_ReturnThrustX(nil, t_ang+ANGLE_90, FixedMul((prefs.arc.horz or 0), sin(ang)))
		movey = $+P_ReturnThrustY(nil, t_ang+ANGLE_90, FixedMul((prefs.arc.horz or 0), sin(ang)))
		movez = $-FixedMul((prefs.arc.vert or 0), sin(ang)) -- the same as d*sin(a)
	end

	-- Set mobj angle
	mobj.angle = (prefs and prefs.angle) or mobj.angle

	-- Apply the movement
	P_TeleportMove(mobj, 
		movex,
		movey,
		movez
	)

	-- Lock final position when done
	-- TODO: jitters when 8 and hi-speed, is the distance to end dependent on speed too?
	waitUntil(event, dist < speed/2 --[[8*FRACUNIT jitters]], function()
		if not (prefs and prefs.nolock) then 
			P_TeleportMove(mobj, point.x, point.y, point.z)
		end

		if (prefs and prefs.callback) then
			prefs.callback(mobj)
		end
	end)
	-- if dist < speed/2 then
	-- 	return true
	-- else
	-- 	return false
	-- end
end

-- TODO: deleteme
function EvAction.simplemove(event, mobj, point, speed, prefs)

	local dist2d = P_AproxDistance(point.x - mobj.x, point.y - mobj.y)
	-- print(dist2d)
	P_InstaThrust(mobj, R_PointToAngle2(mobj.x, mobj.y, point.x, point.y), speed)

	waitUntil(event, dist2d < speed/2 --[[8*FRACUNIT jitters]], function()
		if not (prefs and prefs.nolock) then
			mobj.momx = 0
			mobj.momy = 0
			P_TeleportMove(mobj, point.x, point.y, point.z)
		end

		if (prefs and prefs.callback) then
			prefs.callback(mobj)
		end
	end)
end

-- TODO: deleteme
function EvAction.mobjmove2(event, mobj, point, speed, prefs)
	

	--[[local start = mobj
	local finish = point
	local arc = (prefs and prefs.arc)

	--Get full distance from start to finish
	local fulldist =
		FixedHypot(start.z-finish.z,
			FixedHypot(start.x-finish.x,start.y-finish.y)
		)+1

	--Get interpolation speed and distance %
	if mobj.lerpspeed == nil or mobj.lerpdist == nil then
		--Current Movespeed
		local speed = FixedHypot(mobj.momz,FixedHypot(mobj.momx,mobj.momy))
		mobj.lerpspeed = FixedDiv(speed,fulldist)
		mobj.lerpdist = mobj.lerpspeed
	end
	local lerpspeed = mobj.lerpspeed
	--Get distance from start
	local traveldist = 
		FixedHypot(start.z-mobj.z, 
			FixedHypot(start.x-mobj.x, start.y-mobj.y)
		)+1
	
	--Get new lerpdist based on interpolation amount increment
	mobj.lerpdist = $+lerpspeed
	
	--Get lerped coordinate positions between start and finish
	local x = EvAction.lerp(start.x,finish.x,mobj.lerpdist)
	local y = EvAction.lerp(start.y,finish.y,mobj.lerpdist)
	local z = EvAction.lerp(start.z,finish.z,mobj.lerpdist)
	--Apply offset from arc
	if prefs and prefs.arc then
		local ang = FixedMul(ANGLE_180, mobj.lerpdist)
		x = $+P_ReturnThrustX(nil,mobj.angle+ANGLE_90,FixedMul(arc.horz or 0,sin(ang)))
		y = $+P_ReturnThrustY(nil,mobj.angle+ANGLE_90,FixedMul(arc.horz or 0,sin(ang)))
		z = $-FixedMul(arc.vert or 0,sin(ang))
	end
	--Move to new position
	P_TeleportMove(mobj,x,y,z)--]]

	waitUntil(event, fulldist < mobj.lerpspeed/2 --[[8*FRACUNIT jitters]], function()
		if not (prefs and prefs.nolock) then 
			P_TeleportMove(mobj, point.x, point.y, point.z)
		end

		if (prefs and prefs.callback) then
			prefs.callback(mobj)
		end
	end)
end

-- Make the mobj look at a direction (in angles)
function EvAction.mobjchangeangle(mobj, directionangle)
	if not (mobj and mobj.valid) then return end -- no mobj
	mobj.angle = directionangle
end

-- Make the mobj look at another mobj or point
function EvAction.mobjlookat(mobj, point)
	if not (mobj and mobj.valid) then return end -- no mobj
	mobj.angle = R_PointToAngle2(mobj.x, mobj.y, point.x, point.y)
end

-- Get the direction of where to look at a mobj or point
function EvAction.getlookangle(mobj, point)
	if not (mobj and mobj.valid) then return end -- no mobj
	return R_PointToAngle2(mobj.x, mobj.y, point.x, point.y)
end

-- Set the mobj roll/rotation angle (or continuously add)
function EvAction.setspriteroll(mobj, angle, addangle)
	if not (mobj and mobj.valid) then return end -- no mobj
	
	if (addangle) then
		mobj.rollangle = $1+angle
	else
		mobj.rollangle = angle
	end
end


-- Find a mobj in the gamemap (may be extremely slow) (missing redundant args)
function EvAction.findmobj(mobjtype, prefs)
	for mobj in mobjs.iterate() do
		if (prefs) then
			if (mobj.type == mobjtype
				and (mobj.extrainfo == prefs.id
				or mobj.angle == prefs.angle
				or (mobj.spawnpoint and mobj.spawnpoint.extrainfo == prefs.param)
				or mobj.spawnpoint and mobj.spawnpoint.options == prefs.sflags
				or mobj.flags == prefs.flags)) then
				return mobj
			end
		elseif (mobj.type == mobjtype) then
			return mobj
		end
	end
end

-- A wrapper for creating a mobj with extra settings
function EvAction.createmobj(mobjtype, point, prefs, callback)
	local newmobj = P_SpawnMobj(point.x, point.y, point.z, mobjtype)

	newmobj.extrainfo =   (prefs and prefs.id) or 0
	newmobj.extravalue1 = (prefs and prefs.id2) or 0
	newmobj.extravalue2 = (prefs and prefs.id3) or 0
	newmobj.color =       (prefs and prefs.color) or $1
	newmobj.colorized =   (prefs and prefs.colorized) or $1
	newmobj.mirrored =    (prefs and prefs.mirrored) or $1
	newmobj.shadowscale = (prefs and prefs.shadowscale) or $1

	-- Run a callback after creation for one frame
	if (callback) then
		callback(newmobj)
	end

	return newmobj
end

-- A wrapper for creating multiple mobjs in one go
function EvAction.createmultimobjs(...)
	local list = {}
	for _,entry in ipairs({...}) do
		table.insert(list, EvAction.createmobj(entry.mtype, entry.pos, entry.prefs or nil))
	end
	return unpack(list)
end

-- Remove a mobj (using lists by default since its more efficient)
function EvAction.removemobj2(mobjlist, fuse)
	for i=1,#mobjlist do

		if not (mobjlist[i] and mobjlist[i].valid) then return end -- no mobj

		if (fuse) then
			mobjlist[i].fuse = 35
		else
			P_RemoveMobj(mobjlist[i])
		end
	end
	-- for _,entry in pairs(mobjlist) do
		
	-- 	if (fuse) then
	-- 		entry.fuse = 35
	-- 	else
	-- 		P_RemoveMobj(entry)
	-- 	end
	-- end
end

-- ------------------------------------------------------
-- @region EFFECT - Effect functions
-- ------------------------------------------------------

-- ------------------------------------------------------
-- @region GAMEMAP - Game Map functions
-- ------------------------------------------------------

-- For coordinate placement (binary/non-udmf), set an origin to reference positions from (prefixed with mo_ 'map origin')
function EvAction.coordinateanchor(container, placement_name, mapx, mapy, mapz, mangle)
	container["mo_" .. placement_name] = {x=mapx, y=mapy, z=mapz}
end

-- Uses the coordinate anchor given to add positions to a made-up grid
function EvAction.coordinategetoffset(container, placement_name, offsetx, offsety, offsetz)
	if not container["mo_" .. placement_name] then
		print(string.format("Coordinate anchor %s does not exist!", placement_name))
		return
	end

	local anchor = container["mo_" .. placement_name]

	return {x=anchor.x + offsetx, y=anchor.y + offsety, z=anchor.z + offsetz}
end

-- ------------------------------------------------------
-- @region VIDEO - Video functions
-- ------------------------------------------------------

EvAction.vidwidth = 0
EvAction.vidheight = 0
EvAction.viddup = 0

-- Toggles default hud visibility
function EvAction.SetInternalHudStatus(namelist, huditemvisible)
	for i=1,#namelist do
		if (huditemvisible) then
			hud.enable(namelist[i])
		else
			hud.disable(namelist[i])
		end
	end
end

-- Sets the container of the sequence to use HUD drawing
function EvAction.togglerender(container, setting)
	container.sendtohud = (setting == nil or setting == true) and true or false
	if not container["huditems"] then container["huditems"] = {} end
end

-- TODO: Edit another render from another event
-- function EvAction.updaterenderfrom(evname, itemname)
-- end

-- Edits a hud item in the container
function EvAction.editrender(container, name)
	return container["huditems"][name]
end

function EvAction.renderitemvisibility(container, name, visible)
	container["huditems"][name].order = (visible and not nil) and visible or -1
end

-- Adds drawfill to the hud item list
function EvAction.renderfill(container, order, name, x, y, width, height, color)
	-- TODO: priority sort
	-- local tempname = string.format("%s_%s", order, name)
	if not container["huditems"] then print("Please use togglerender() first to enable the screen renderer!") return end
	container["huditems"][name] = {}
	container["huditems"][name].huditem = true
	container["huditems"][name].order = order
	container["huditems"][name].type = "fill"
	container["huditems"][name].x = x or (x and not nil) and x or 0
	container["huditems"][name].y = y or (y and not nil) and y or 0
	container["huditems"][name].width = width or 0
	container["huditems"][name].height = height or 0
	container["huditems"][name].color = color or 0
end

-- Adds drawstretched to the hud item list
function EvAction.renderstretchedpatch(container, order, name, x, y, hscale, vscale, patch, flags, colormap)
	-- TODO: priority sort
	-- local tempname = string.format("%s_%s", order, name)
	if not container["huditems"] then print("Please use togglerender() first to enable the screen renderer!") return end
	container["huditems"][name] = {}
	container["huditems"][name].huditem = true
	container["huditems"][name].order = order
	container["huditems"][name].type = "stretchedgraphic"
	container["huditems"][name].x = x or (x and not nil) and x or 0
	container["huditems"][name].y = y or (y and not nil) and y or 0
	container["huditems"][name].hscale = hscale or FU
	container["huditems"][name].vscale = vscale or FU
	container["huditems"][name].patch = patch or "UNKNOWN"
	container["huditems"][name].flags = flags or (flags and not nil) and flags or 0
	container["huditems"][name].colormap = colormap or 0
end

-- Adds drawscaled to the hud item list
function EvAction.renderscaledpatch(container, order, name, x, y, scale, patch, flags, colormap)
	-- TODO: priority sort
	-- local tempname = string.format("%s_%s", order, name)
	if not container["huditems"] then print("Please use togglerender() first to enable the screen renderer!") return end
	container["huditems"][name] = {}
	container["huditems"][name].huditem = true
	container["huditems"][name].order = order
	container["huditems"][name].type = "scaledgraphic"
	container["huditems"][name].x = x or (x and not nil) and x or 0
	container["huditems"][name].y = y or (y and not nil) and y or 0
	container["huditems"][name].scale = scale or FU
	-- Assign sprite patch or a normal patch
	if (type(patch) == "table") then
		container["huditems"][name].type = "scaledsprite" -- change the name
		container["huditems"][name].patch = patch[1] or SPR_PLAY
		container["huditems"][name].spr_frame = patch[2] or 0
		container["huditems"][name].spr_rotate = patch[3] or 0
		container["huditems"][name].spr_roll = patch[4] or 0
	else
		container["huditems"][name].patch = patch or "UNKNOWN"
	end
	container["huditems"][name].flags = flags or (flags and not nil) and flags or 0
	container["huditems"][name].colormap = colormap or 0
end

-- Adds drawstring to the hud item list
function EvAction.rendertext(container, order, name, x, y, text, flags, alignment)
	-- local tempname = string.format("%s_%s", order, name)
	if not container["huditems"] then print("Please use togglerender() first to enable the screen renderer!") return end
	container["huditems"][name] = {}
	container["huditems"][name].huditem = true
	container["huditems"][name].order = order
	container["huditems"][name].type = "string"
	container["huditems"][name].x = x or (x and not nil) and x or 0
	container["huditems"][name].y = y or (y and not nil) and y or 0
	container["huditems"][name].text = text or ""
	container["huditems"][name].textflags = flags or 0
	container["huditems"][name].textalign = alignment or "left"
end


-- Sequence version of fadescreen
Event.new("h_fadescreen", {
function(c,e)
	 -- frame 1 of the initialization
	Event.wait(e, c.waitingtime or 0, true)
end,
function(c,e)
	-- c.showfade = true

    -- Options (full, in, out)
	if (c.fadetype == "full") then
		c.time = c.maxstrength
	else
		if (leveltime % c.delay == 0) and not paused then
			if c.fadetype == "out" then
				c.time = min(c.maxstrength, $+1 * 1)
			elseif c.fadetype == "in" then
				c.time = max(0, $-1 * 1)
			end
		end
	end
	Event.waitUntil(e, e.status == "dead")
end,
function(c,e)
end})

-- The return of fadescreen()!
function EvAction.fadescreen(fadetype, color, delay, waitingtime, fadedplayers, fadetag)
	local t = {}

	t.fadetype = fadetype or "clear"
	-- t.fadetype = (fadetype == "in" or fadetype == "out" or fadetype=="clear") and fadetype or "clear"

	-- t.color = color
	-- Control colortypes
	local colortypes = {
		level = 0xFF00,
		title = 0xFA00,
		special = 0xFB00,
    }
    for k,v in pairs(colortypes) do
        if (color and color == k) then
            t.color = v
            break
        else
            t.color = color or 0 -- color
        end
    end
    -- Max strength is different for those other fade colors
	t.maxstrength = ((t.color == 0xFF00 or t.color == 0xFA00 or t.color == 0xFB00) and 31 or 10)
	-- t.maxstrength = 10
	t.time = 0
	t.delay = delay or 1

	if t.fadetype == "in" then t.time = t.maxstrength end
	if t.fadetype == "full" then t.time = t.maxstrength end

	-- Fade Tag ID stores what used the function to avoid overwrite conflicts.
	if (fadetag) then
		-- print("Set TID:" .. fadetag)
		t.fadetag = fadetag
	end

	if t.fadetype == "clear" then
		-- print("Removing TID:" .. fadetag)
		Event.destroy("h_fadescreen", fadetag and {haskey={"fadetag", fadetag}} or nil)
	else
		-- Filter players from the passed table to only show fading for included players only, otherwise show for everyone
		if (fadedplayers and #fadedplayers > 0) then
			EvAction.filterforplayers(t, fadedplayers)
			-- t.fadedplayers = fadedplayers -- (currently unused)
		end
		-- Set up graphics toggle and others, then start
		t.waitingtime = waitingtime or 0
		t.showfade = true
		Event.destroy("h_fadescreen", fadetag and {haskey={"fadetag", fadetag}} or nil)
		Event.start("h_fadescreen", t)
	end
end

function EvAction.fadescreenopt(prefs)
	local fadetype = EvAction.defvalue(prefs.fade, "clear")
	local color = EvAction.defvalue(prefs.color, nil)
	local delay = EvAction.defvalue(prefs.delay, nil)
	local waitingtime = EvAction.defvalue(prefs.waiting, nil)
	local fadedplayers = EvAction.defvalue(prefs.playerfilter, nil)
	local fadetag = EvAction.defvalue(prefs.fadetag, nil)
	EvAction.fadescreen(fadetype, color, delay, waitingtime, fadedplayers, fadetag)
end

-- Sequence version of drawborder
Event.new("a_cineborder", {
function(c,e)
	EvAction.togglerender(c)
end,
function(c,e)
	EvAction.renderstretchedpatch(c, c.order, "cineborder_top", 0, 0, EvAction.vidwidth*FU,c.width*FU, "~031G", V_SNAPTOTOP, 0)
	EvAction.renderstretchedpatch(c, c.order, "cineborder_bottom", 0, (200-c.width)*FU, EvAction.vidwidth*FU, c.width*FU, "~031G", V_SNAPTOBOTTOM, 0)
	Event.waitUntil(e, false)
end,
function(c,e)
end})

function EvAction.drawcineborders(c, order, borderwidth)
	local t = {}

	t.order = order or 50 -- drawing order
	t.width = borderwidth or 8 -- border width

	-- Event.destroy("a_cineborder")
	-- Event.start("a_cineborder", t)

	-- temporary until sequence can appear under other graphics drawn (+animations)
	EvAction.renderstretchedpatch(c, t.order, "cineborder_top", 0, 0, EvAction.vidwidth*FU, t.width*FU, "PAL_31G", V_SNAPTOTOP|V_SNAPTOLEFT, 0)
	EvAction.renderstretchedpatch(c, t.order, "cineborder_bottom", 0, (200-t.width)*FU, EvAction.vidwidth*FU, t.width*FU, "PAL_31G", V_SNAPTOBOTTOM|V_SNAPTOLEFT, 0)
end

function EvAction.removecineborders(container)
	container["huditems"]["cineborder_top"] = nil
	container["huditems"]["cineborder_bottom"] = nil
end

-- Checks if the graphics EVS hud control has any assigned players
-- to it if the table exists, then returns true if there is a display mismatch.
-- Used to stop showing graphics to all players, and only each hudplayer individually
function EvAction.EVassignedplayer_isnt_hudplayer(rc, hudplayer)

	if rc.assignedplayers then
		for i, pl in ipairs(rc.assignedplayers) do
			if (EvAction.isplayervalid(consoleplayer) and hudplayer ~= pl) then return true else return false end
		end
	end
end

-- Reads sequence data for hud drawing content
function EvAction.hudcontrol(v, stplyr, cam)

	-- Hacks to get vid information that should be non-exclusive to hud :|
	EvAction.vidwidth = v.width()
	EvAction.vidheight = v.height()
	EvAction.viddup = v.dupx()

	Event.read("any", function(rc)

		-- Graphics should only show to the players assigned to this unless specified (ie. dont assign players)
		if EvAction.EVassignedplayer_isnt_hudplayer(rc, stplyr) then return end

		-- replacement for render() and renderplayer()
		if not (rc.sendtohud == true) then return end -- is not drawing to the HUD

		for keyname, rend in Event.spairs(rc.huditems, function(t,a,b) return t[b].order > t[a].order end) do

			if (type(rend) == "table" and rend.huditem) then

				if (rend.order == -1) then continue end -- skip negative ordered

				if (rend.type == "fill") then
					v.drawFill(rend.x, rend.y, rend.width, rend.height, rend.color)
				elseif (rend.type == "stretchedgraphic") then
					v.drawStretched(rend.x, rend.y, rend.hscale, rend.vscale, v.cachePatch(rend.patch), rend.flags or 0, v.getColormap(1, rend.colormap))
				elseif (rend.type == "scaledgraphic") then
					v.drawScaled(rend.x, rend.y, rend.scale, v.cachePatch(rend.patch), rend.flags or 0, v.getColormap(1, rend.colormap))
				elseif (rend.type == "scaledsprite") then
					local spr = v.getSpritePatch(rend.patch, rend.spr_frame, rend.spr_rotate, rend.spr_roll)
					v.drawScaled(rend.x, rend.y, rend.scale, spr, rend.flags or 0, v.getColormap(1, rend.colormap))
				elseif (rend.type == "string") then
					v.drawString(rend.x, rend.y, rend.text, rend.textflags, rend.textalign)
				end
			end
		end
	end)
	Event.read("h_fadescreen", function(rc)

		-- Graphics should only show to the players assigned to this unless specified (ie. dont assign players)
		if EvAction.EVassignedplayer_isnt_hudplayer(rc, stplyr) then return end

		-- Handle the hud entry options (full, clear, or default)
		if rc.showfade then
			v.fadeScreen(rc.color, rc.time)
		end
	end)
end

-- Detect if the player is viewing through a custom EV-made camera (allows seenames through any EV that doesn't use a camera)
function EvAction.seenamesoff(player, seenplayer)
	-- :|
	if not (player and player.mo and player.mo.valid) then return end

	if (((player.awayviewmobj and player.awayviewmobj.valid) and player.awayviewmobj.isevcamera))
	or (((seenplayer.awayviewmobj and seenplayer.awayviewmobj.valid) and seenplayer.awayviewmobj.isevcamera)) then
		return false
	end
end


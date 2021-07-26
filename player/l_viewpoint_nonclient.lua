--[[
* l_viewpoint_nonclient.lua
* (Author: sprkizard) (Nev3r)
* (July 12, 2021 18:04)
* Desc: A hack that exposes viewpointswitch spectating information to all players
*
* Notes: 
]]

rawset(_G, "spectating", setmetatable({}, {
   __index = function(t, k)
		return #consoleplayer -- returns yourself when empty
   end
}))

rawset(_G, "spectators", {})

-- Gets how many players are watching the specified player
spectators.watching = function(p)
	local count = 0

	for i=0,#spectating do
		(function()
			if (#p == i) then return end
			if (spectating[i] == #p) then count = $1+1 end
		end)()
	end

	return count
end

-- Add a command to update the spectators list
COM_AddCommand("__update_spectating", function(player, arg1)
	spectating[#player] = tonumber(arg1)
end)

local function think_updatespectating()
	for player in players.iterate do
		(function()
			if not player and player.__spectating then return end
			COM_BufInsertText(player, "__update_spectating " .. tostring(player.__spectating.nextviewedplayer))
		end)()
	end
end

-- Setup the nextviewedplayer variable
addHook("PlayerSpawn", function(player)
	player.__spectating = {nextviewedplayer = #player}
end)

-- When the player spectates another player, reference them privately
addHook("ViewpointSwitch", function(switcher, nextviewed)
	if not switcher and switcher.__spectating then return end
	switcher.__spectating.nextviewedplayer = #nextviewed
end)

-- Remove player from the spectating list if they leave
addHook("PlayerQuit", function(player)
	spectating[#player] = nil
end)

-- Update spectators list
addHook("ThinkFrame", function()
	think_updatespectating()
end)

--[[
* l_hudzordering.lua
* (sprkizard)
* (November 28, 2018 1:04)
* Desc: A tiny HUD library made to allow multiple HUD elements with
	layer priority. Inspired by a script made by fickleheart

* Usage: hudlayer["layer"] = {}
        ------
        Table arguments:
        ({layernum = 1}) - The 'priority' or layer the HUD element sits on.
        A value of -1 Removes it from view

        ({func = function(v, stplyr, cam)}) - The HUD function to run
        which can contain HUD elements, strings, etc

        Can also be called with hudlayer["layer"].layernum and hudlayer["layer"].func()

* Depends on:
	spairs
]]

-- spairs attribution by:
-- https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
-------------------
-- Do not add this twice if it is in another file, please
if _G["hudLayer"] then return end


-- Attempts to sort pairs
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end


-- The container table that holds all user created HUD elements
rawset(_G, "hudLayer", {items={}})


-- Iterates and sorts through hudLayer with spairs
local function sortHudItems(v, stplyr, cam)

	--for k,huditem in spairs(hudLayer.items, function(t,a,b) return t[b].layernum < t[a].layernum end) do -- desc
	for _,huditem in spairs(hudLayer.items, function(t,a,b) return t[a].layernum > t[b].layernum end) do -- asc
		
		-- Delete the item (Stop it from running at all and skip it)
		if (huditem.layernum == -99) then
			-- huditem = nil
			return
		end

		(function()
			-- Do not run on items with -1 at all.
			if (huditem.layernum == -1) then return end
			
			-- Run hud functions
			huditem.func(huditem.args, v, stplyr, cam)
		end)()
	end
end
hud.add(sortHudItems, "game")

-- Adds a new hud to the layer table
local function R_AddHud(layername, ordernum, args, hudfunc, forcereset)
	hudLayer.items[layername] = {
		args = args or {},
		-- reset = setreset or true, (Unused)
		layernum = ordernum or -1,
		func = hudfunc,
	}
end

-- Sets layer order
local function R_SetHud(layername, ordernum, args)
	if not (hudLayer and hudLayer.items[layername]) then return end

	-- TODO: find another way to keep the default value
	hudLayer.items[layername].layernum = (ordernum and type(ordernum) == "string" and $ or ordernum or -1) 
	-- hudLayer.items[layername].layernum = ordernum or -1
	
	-- Add or update variables to the Hud if specified
	if (args) then
		for k,v in pairs(args) do
			(function()
				hudLayer.items[layername].args[k] = v
			end)()
		end
	end
end

-- Disables a layer
local function R_DisableHud(layername)
	if not (hudLayer and hudLayer.items[layername]) then return end
	hudLayer.items[layername].layernum = -1
end

-- Sets the layer to be deleted
local function R_DeleteHud(layername)
	if not (hudLayer and hudLayer.items[layername]) then return end
	hudLayer.items[layername].layernum = -99
end

-- Sets internal game huds to be hidden/unhidden
local function R_SetInternalHudStatus(namelist, huditemvisible)
	for i=1,#namelist do
		if (huditemvisible) then
			hud.enable(namelist[i])
		else
			hud.disable(namelist[i])
		end
	end
end

-- Netvars hook / function
function hudLayer.netvars(n)
	for _,entry in pairs(hudLayer.items) do
		entry.args = n($)
		entry.layernum = n($)
		-- entry.func = n($)
	end
end

--[[addHook("NetVars", function(network)
	hudLayer.netvars(network)
end)--]]

rawset(_G, "R_AddHud", R_AddHud)
rawset(_G, "R_SetHud", R_SetHud)
rawset(_G, "R_DisableHud", R_DisableHud)
rawset(_G, "R_DeleteHud", R_DeleteHud)
rawset(_G, "R_SetInternalHudStatus", R_SetInternalHudStatus)


-- Some examples
-- (Uncomment to test)
-- Test the script addon by removing the removable layer, and replacing the text on 'test1'
--[[R_AddHud("test1", 5, {text=nil}, -- Custom text variable
function(args, v, stplyr)
	v.drawString(64, 64, args.text or "Jump to replace my text!", V_ALLOWLOWERCASE, "left")
end)

R_AddHud("test2", 4, {},
function(args, v, stplyr)
	local x = 6*cos(leveltime*ANG10)/FU
	v.drawString(64+x, 68, "Moving text!", V_ALLOWLOWERCASE, "left")
end)

R_AddHud("removable", 3, {},
function(args, v, stplyr)
	v.drawString(64, 76, "Remove me on Jump", V_ALLOWLOWERCASE, "left")
end)

addHook("ThinkFrame", function()

	for player in players.iterate do
		if (player.cmd.buttons & BT_JUMP) then
			R_DeleteHud("removable")
			R_SetHud("test1", "", {text="Replaced Text!"})
		end
	end
end)--]]


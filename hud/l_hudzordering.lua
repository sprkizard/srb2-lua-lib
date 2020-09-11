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
rawset(_G, "hudLayer", {})

-- Some examples
--[[
hudLayer["test1"] = {
	layernum = 5,
	func = (function(v, stplyr, cam)
		v.drawString(120, 64, "Layer 5", V_ALLOWLOWERCASE, "left")
	end)
}

hudLayer["test2"] = {
	layernum = 4,
	func = (function(v, stplyr, cam) 
		v.drawString(126, 66, "Layer 4", V_ALLOWLOWERCASE, "left")
	end)
}

hudLayer["test3"] = {
	layernum = 9,
	func = (function(v, stplyr, cam) 
		v.drawString(129, 67, "Layer 9", V_ALLOWLOWERCASE, "left")
	end)
}

hudLayer["removable"] = {
	layernum = 3,
	func = (function(v, stplyr, cam) 
		v.drawString(129, 67, "Remove me on Jump", V_ALLOWLOWERCASE, "left")
	end)
}
--]]



-- Iterates and sorts through hudLayer with spairs
local function sortHudItems(v, stplyr, cam)

	--for k,huditem in spairs(hudLayer, function(t,a,b) return t[b].layernum < t[a].layernum end) do -- desc
	for _,huditem in spairs(hudLayer, function(t,a,b) return t[a].layernum > t[b].layernum end) do -- asc
		
		-- Delete the item
		if (huditem.layernum == -99) then
			huditem = nil
			return
		end

		(function()
			-- Do not run on indexes with -1 at all.
			if (huditem.layernum == -1) then return end
			
			-- Run hud functions
			huditem.func(v, stplyr, cam)
		end)()
	end
end
hud.add(sortHudItems, "game")

-- Adds a new layer
local function R_AddHud(layername, ordernum, hudfunc)
	hudLayer[layername] = {
		layernum = ordernum,
		func = (function(v, stplyr, cam) hudfunc(v, stplyr, cam) end)
	}
end

-- Sets layer order
local function R_SetHudOrder(layername, ordernum)
	if not (hudLayer and hudLayer[layername]) then return end
	hudLayer[layername].layernum = ordernum
end

-- Disables a layer
local function R_DisableHud(layername)
	if not (hudLayer and hudLayer[layername]) then return end
	hudLayer[layername].layernum = -1
end

-- Sets the layer to be deleted
local function R_DeleteHud(layername)
	if not (hudLayer and hudLayer[layername]) then return end
	hudLayer[layername].layernum = -99
end


rawset(_G, "R_AddHud", R_AddHud)
rawset(_G, "R_SetHudOrder", R_SetHudOrder)
rawset(_G, "R_DisableHud", R_DisableHud)
rawset(_G, "R_DeleteHud", R_DeleteHud)


-- (Uncomment to test)
-- Test the addon by removing removable layer, and replacing the text on 'test1'
--[[
addHook("ThinkFrame", function()

	for player in players.iterate do
		if (player.cmd.buttons & BT_USE) then
		
			hudLayer["removable"].layernum = -1
			hudLayer["test1"].func = (function(v, stplyr, cam)
				v.drawString(120, 64, "Replaced Text!", V_ALLOWLOWERCASE, "left")
			end)
		end
	end
end)
--]]

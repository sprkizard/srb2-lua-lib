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


rawset(_G, "z_HUD", {})

-- Table indexes
z_HUD["test1"] = {
					z_index = 5,
					dontdraw = false,
					func = (function(v, stplyr, cam)
						v.drawString(120, 64, "Layer 5", V_ALLOWLOWERCASE, "left")
					end)
				}

z_HUD["test2"] = {
					z_index = 4, 
					func = (function(v, stplyr, cam) 
						v.drawString(126, 66, "Layer 4", V_ALLOWLOWERCASE, "left")
					end)
				}

z_HUD["test3"] = {
					z_index = 9, 
					func = (function(v, stplyr, cam) 
						v.drawString(129, 67, "Layer 9", V_ALLOWLOWERCASE, "left")
					end)
				}
z_HUD["testOrder"] = {
					z_index = 3, 
					func = (function(v, stplyr, cam) 
						v.drawString(129, 67, "Layer 999", V_ALLOWLOWERCASE, "left")
					end)
			}		


local function hudorder(v, stplyr, cam)
	-- Iterates and sorts through z_HUD with spairs
	
	--for k,huditem in spairs(z_HUD, function(t,a,b) return t[b].z_index < t[a].z_index end) do -- desc
	for k,huditem in spairs(z_HUD, function(t,a,b) return t[a].z_index > t[b].z_index end) do -- asc
		-- Do not run on indexes with -1 at all.
		if (huditem.z_index == -1) then return end
		-- Run hud functions
		huditem.func(v, stplyr, cam)
	end
end
hud.add(hudorder, "game")

addHook("ThinkFrame", do

	for player in players.iterate
		if player.cmd.buttons & BT_USE then
		
			z_HUD["testOrder"].z_index = -1
			print(z_HUD["testOrder"].z_index)
		end
	end
end)

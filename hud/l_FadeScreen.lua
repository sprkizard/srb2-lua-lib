-- Requires: l_hudzordering.lua

local function fadescreen(direction, color, speed, timescale, dontdraw)

    local dt = 0 -- time
    local dts = timescale or 1 -- timescale
    local spd = speed or 1 --speed
    local visible_layer = (dontdraw == false) and -1 or 99 -- toggle for visibility

    -- If it is a fade_in, then start from max value instead of 0
    if (direction == "in") then dt = 32 end

    -- Send new overwritable hudlayer entry
    R_AddHud("fadescreen", visible_layer, function(v, stplyr, cam)
        -- simple time math for out and in fading
        -- through min and max values of 0 and 32
        if (leveltime % dts == 0) then
            if (direction == "out") then
                dt = min(32, $+1 * spd)
            elseif (direction == "in") then
                dt = max(0, $-1 * spd)
            else
                return
            end
        end
        -- Only one fadescreen needed outside the if here
        v.fadeScreen(color, dt%33)
    end)

end

rawset(_G, "fadescreen", fadescreen)

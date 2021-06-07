-- Do not add this twice if it is in another file, please
if _G["R_ScreenFade"] then return end

-- Legacy Version
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


-- New Version (tables are a little safer in the event we change entire arguments...)
local function R_ScreenFade(ftype, args)

    -- Requires: l_hudzordering.lua
    if not _G["R_AddHud"] then print("This R_ScreenFade requires l_hudzordering.lua to work!") return end

    local time = 0 -- elapsed time value
    local timescale = args and args.timescale or 1 -- TODO: merge speed and timescale?
    local speed = args and args.speed or 1 -- speed
    local color = args and args.color or 0 -- color
    
    -- Allow the user to access the built in fadetypes with a phrase
    if (color == "type1") then
        color = 0xFF00
    elseif (color == "type2") then
        color = 0xFA00
    elseif (color == "type3") then
        color = 0xFB00
    end

    -- Maxstrength between palette and special values
    local maxstrength = ((args and (color == 0xFF00 or color == 0xFA00 or color == 0xFB00)) and 32 or 10)

    -- Inverse the time if a fade-in
    if (ftype == "in") then time = maxstrength end

    -- Send new overwritable hudlayer entry (full, clear, or default)
    if (ftype == "full") then
         R_AddHud("_screenfade", 99, function(v, stplyr)
            v.fadeScreen(color, maxstrength)
        end)
        return
    elseif (ftype == "clear")
        R_DeleteHud("_screenfade")
        return
    else
        R_AddHud("_screenfade", 99, function(v, stplyr)

            if (leveltime % timescale == 0) then
                if (ftype == "out") then
                    time = min(maxstrength, $+1 * 1)
                elseif (ftype == "in") then
                    time = max(0, $-1 * 1)
                else
                    return
                end
            end
            -- Only one fadescreen needed outside the if here
            v.fadeScreen(color, time)
        end)
    end
end

rawset(_G, "fadescreen", fadescreen)
rawset(_G, "R_ScreenFade", R_ScreenFade)

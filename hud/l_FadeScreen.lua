-- Do not add this twice if it is in another file, please
if _G["R_ScreenFade"] then return end

-- Legacy Version
--[[local function fadescreen(direction, color, speed, timescale, dontdraw)

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

end--]]


-- New Version
local function R_ScreenFade(ftype, args)

    -- Requires: l_hudzordering.lua
    if not _G["R_AddHud"] then print("(!)\x82 R_ScreenFade requires l_hudzordering.lua to work!") return end
    
    -- Allow the user to relocate the layer the fade is on
    local layer = (args and args.layer or 256)

    local a = {}
    a.fadetype = ftype -- The fading type (in, out, full, clear)
    a.time = 0 -- Elapsed Time
    a.delay = (args and args.delay or 1) -- Delay of the fade TODO: merge speed and delay?
    -- a.speed = (args and args.speed or 1) -- Speed of the fade (Unused)

    -- Allow the user to access the built in fadetypes with an alias
    local colortypes = {
        type1 = 0xFF00,
        -- value1 = 0xFF00,
        type2 = 0xFA00,
        -- value2 = 0xFA00,
        type3 = 0xFB00,
        -- value3 = 0xFB00,
    }
    for k,v in pairs(colortypes) do
        if (args and args.color == k) then
            a.color = v
            break
        else
            a.color = (args and args.color or 0) -- color
        end
    end

    -- Determine the max strength between palette and special values
    a.maxstrength = ((args and (a.color == 0xFF00 or a.color == 0xFA00 or a.color == 0xFB00)) and 32 or 10)

    -- Inverse the time if a fade-in
    if (ftype == "in") then a.time = a.maxstrength end

    -- Set the Hud attributes 
    R_SetHud("__vfadeScreen", layer, a)
    -- print(string.format("time:%d | type: %s | strn: %s", a.time, a.fadetype, a.maxstrength))
end

-- Custom Hud Entry
R_AddHud("__vfadeScreen", nil, 
{
    fadetype = "in",
    time = 0,
    delay = 1,
    -- speed = 1,
    color = 0,
    maxstrength = 10,
},
function(args, v, stplyr)

    -- Handle the hud entry options (full, clear, or default)
    if (args.fadetype == "full") then
        v.fadeScreen(args.color, args.maxstrength)
    elseif (args.fadetype == "clear")
        R_DeleteHud("__vfadeScreen")
    else
        if (leveltime % args.delay == 0) and not paused then
            if (args.fadetype == "out") then
                args.time = min(args.maxstrength, $+1 * 1)
            elseif (args.fadetype == "in") then
                args.time = max(0, $-1 * 1)
            else
                return
            end
        end
        -- Only one fadescreen needed here
        v.fadeScreen(args.color, args.time)
    end
end)

rawset(_G, "fadescreen", fadescreen)
rawset(_G, "R_ScreenFade", R_ScreenFade)

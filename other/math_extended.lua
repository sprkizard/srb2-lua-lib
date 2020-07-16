--[[

* math_extended.lua
* (sprkizard)
* (none)

* Desc: More functions for math related things

* Usage: 

]]


local function map(x, in_min, in_max, out_min, out_max)
	return out_min + (x - in_min)*(out_max - out_min)/(in_max - in_min)
end

local function FixedLerp(a, b, t)
    if (a == b) then
        return a
    else
        -- 0.005 equiv to 65535/(65535*200), but better would be 0.5 (65535/2)
        if abs(a-b) < FRACUNIT/FRACUNIT*200 or abs(b-a) < FRACUNIT/FRACUNIT*200 then return b else return a + FixedMul(b - a, t) end
    end
end

-- A function created by SwitchKaze in #scripting
local function floatToFixed(str)
    if not (str and str:len()) then return 0 end
    local decpos = str:find('%.')        -- decposito
    if decpos == nil then
        return tonumber(str)*FRACUNIT
    end
    local num = tonumber(str:sub(0,decpos-1))*FRACUNIT
    local frac = 0
    local i = 1
    for c in str:sub(decpos+1,str:len()):gmatch("%d+") do
        frac = frac + tonumber(c)*FRACUNIT/(10^i)
        i = i+1
        -- no digit n*65536 will ever be > 10^7
        if i==7 then break end
    end
    
    return num+frac
end

local function P_RandomChoice(choices)
    local RandomKey = P_RandomRange(1, #choices)
    if type(choices[RandomKey]) == "function" then
        choices[RandomKey]()
    else
        return choices[RandomKey]
    end
end

-- Lazy cos variable moving
local function P_CosWave(speedangle, timer, numrange)
    return cos(FixedAngle(speedangle*FRACUNIT)*timer)*numrange
end

local function P_SinWave(speedangle, timer, numrange)
    return sin(FixedAngle(speedangle*FRACUNIT)*timer)*numrange
end

-- Triangular Wave
local function tri(m, tm, period)
	return abs((tm % (period or (m*2)) ) - m)
end

-- x position cosine math for angle rotation around a point in space
local function P_XAngle(distance, direction_angle, rotation)
    return distance*cos(direction_angle+FixedAngle(rotation*FRACUNIT))
end
-- y position cosine math for angle rotation around a point in space
local function P_YAngle(distance, direction_angle, rotation)
    return distance*sin(direction_angle+FixedAngle(rotation*FRACUNIT))
end
-- z position cosine math for angle rotation around a point in space
local function P_ZAngle(distance, direction_angle, rotation, dist2, dir_angle2, rot2)
    return FixedMul(P_XAngle(distance, direction_angle, rotation),
                    P_YAngle(dist2 or distance, dir_angle2 or direction_angle, rot2 or rotation))
end

rawset(_G, "map", map)
rawset(_G, "FixedLerp", FixedLerp)
rawset(_G, "floatToFixed", floatToFixed)
rawset(_G, "P_RandomChoice", P_RandomChoice)
rawset(_G, "P_CosWave", P_CosWave)
rawset(_G, "P_SinWave", P_SinWave)
rawset(_G, "tri", tri)
rawset(_G, "P_XAngle", P_XAngle)
rawset(_G, "P_YAngle", P_YAngle)
rawset(_G, "P_ZAngle", P_ZAngle)



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

-- x position cosine math for angle rotation around a point in space
local function P_XAngle(distance, direction_angle, rotation)
    return distance*cos(direction_angle+FixedAngle(rotation*FRACUNIT))
end
-- y position cosine math for angle rotation around a point in space
local function P_YAngle(distance, direction_angle, rotation)
    return distance*sin(direction_angle+FixedAngle(rotation*FRACUNIT))
end
-- z position cosine math for angle rotation around a point in space
local function P_ZAngle(distance, direction_angle, rotation)
    return FixedMul(P_XAngle(distance, direction_angle, rotation),
                    P_YAngle(distance, direction_angle, rotation))
end

rawset(_G, "map", map)
rawset(_G, "FixedLerp", FixedLerp)
rawset(_G, "P_XAngle", P_XAngle)
rawset(_G, "P_YAngle", P_YAngle)
rawset(_G, "P_ZAngle", P_ZAngle)



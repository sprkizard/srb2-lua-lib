--[[
* l_radiusexplode.lua
* (sprkizard)
* (Feburary 3, 2020 23:59)
* Desc: A function that applies an exploding particle force on
    the center of an object

* Usage: P_RadiusExplode(source, speed, particleType, params)
        ------
        source will also accept table values of {x, y, z} as long as valid = true
        is an entry inside the table (an example is in this file)

        Table arguments:
        ({skip = 32}) - the amount of angles in the radius to skip past, defaulting to 32

]]

local function P_RadiusExplode(position, wavespeed, args)

    -- Load extra parameters for further customization if needed
    local angleskip = (args and args.angleskip) or 32
    local mobjtype = (args and args.mobjtype or MT_EXPLODE)

    -- if position is a mobj and is not valid, do nothing
    if type(position) == "userdata" and not (position and position.valid) then return end

    for angle=1, 360, angleskip do

        local explode = P_SpawnMobj(position.x, position.y, position.z, mobjtype)

        explode.scale = (args and args.scale) or FU

        -- Set a fuse for long lasting objects
        if (args and args.fuse) then
            explode.fuse = args.fuse
        end

        -- Call a callback function
        if (args and args.callback) then
            do args.callback(explode, angle, angleskip) end
        end

        -- Force the objects outward
        P_InstaThrust(explode, FixedAngle(angle*FU), wavespeed)
    end
end



rawset(_G, "P_RadiusExplode", P_RadiusExplode)

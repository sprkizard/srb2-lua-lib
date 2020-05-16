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

local function P_RadiusExplode(source, speed, particleType, params)

    -- Load extra parameters for further customization if needed
    source.skipParam = (params and params.skip) or 32
    source.scaleParam = (params and params.scale) or FRACUNIT
    --source.destscaleParam = (params and params.destscale) or FRACUNIT
    source.fuseParam = (params and params.fuse) or nil
    source.funcParam = (params and params.func) or nil

    if (source.valid) then

        -- Form a circle using angles
        for newAngle=1*FRACUNIT,360*FRACUNIT, source.skipParam*FRACUNIT do

            source.explodeForceFx = P_SpawnMobj(source.x, source.y, source.z, particleType or MT_EXPLODE)
            source.explodeForceFx.scale = source.scaleParam

            -- Set an object fuse if you use something that does not disappear easily
            if (source.fuseParam) then
                source.explodeForceFx.fuse = source.fuseParam
            end

            -- Call a callback function
            if (source.funcParam) then
                do source.funcParam(source.explodeForceFx) end
            end

            -- Force the objects outward
            P_InstaThrust(source.explodeForceFx, FixedAngle(newAngle), speed*FRACUNIT)
        end
    end
end



rawset(_G, "P_RadiusExplode", P_RadiusExplode)

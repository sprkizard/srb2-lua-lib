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


    if (source.valid) then

        -- Form a circle using angles
        for newAngle=1*FRACUNIT,360*FRACUNIT, source.skipParam*FRACUNIT do

            source.explodeForceFx = P_SpawnMobj(source.x, source.y, source.z, particleType or MT_EXPLODE)
            source.explodeForceFx.scale = source.scaleParam

            -- Force the objects outward
            P_InstaThrust(source.explodeForceFx, FixedAngle(newAngle), speed*FRACUNIT)
        end
    end
end






-- Example: will spawn a radius of particles above the player every 90 tics
addHook("ThinkFrame", function()
    
    for player in players.iterate do

        if (leveltime % 90 == 0) then

            local position = {valid = true, x = player.mo.x, y = player.mo.y, z = player.mo.z + 64*FRACUNIT}
            P_RadiusExplode(position, 8, MT_EXPLODE, {scale = FRACUNIT/2})
        end
    end
end)



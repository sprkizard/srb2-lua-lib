--[[

* mobj_extended.lua
* (sprkizard)
* (May 16, 2020 00:23)

* Desc: More functions for mobj related things

* Usage: 

]]

-- Simple function to shoot a line of objects in the direction the mobj is facing for scripting reference purposes
local function P_DrawFacingLine(source, color)

    local facingangle = P_SpawnMobj(source.x, source.y, source.z, MT_THOK)
    facingangle.tics = 6
    facingangle.scale = FRACUNIT/3
    facingangle.color = color
    facingangle.momz = source.momz
    P_InstaThrust(facingangle, source.angle, 32*FRACUNIT)
end

rawset(_G, "P_DrawFacingLine", P_DrawFacingLine)
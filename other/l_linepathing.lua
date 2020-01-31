
local FF_FLAT = FF_PAPERSPRITE
local FF_FLATCOLLIDER = FF_PAPERCOLLISION

-- Minimum freeslot items
freeslot("MT_LINEPATH", "S_LINEPATH", "SPR_SPLN")

-- Railing Example
freeslot("MT_FLAT", "S_FLAT", "SPR_RAIL")


mobjinfo[MT_LINEPATH] = {
    --$Name Spline Path
    --$Sprite SPLN
    doomednum = 840,
    spawnhealth = 1000,
    spawnstate = S_LINEPATH,
    speed = 8,
    radius = 16*FRACUNIT,
    height = 16*FRACUNIT,
    damage = 0,
    mass = 10,
    flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT,
}
states[S_LINEPATH] = {SPR_CEMG,0,-1,A_None,0,0,S_NULL}

-- (Add a flat object for demonstration purposes)
mobjinfo[MT_FLAT] = {
    --$Name Flat Railing Object
    --$Sprite SPHR
    doomednum = -1,
    spawnhealth = 1000,
    spawnstate = S_FLAT,
    radius = 16*FRACUNIT,
    height = 16*FRACUNIT,
    flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT,
}
states[S_FLAT] = {SPR_RAIL,0|FF_FLAT,2,A_None,0,0,S_NULL}

rawset(_G, "List_LinePaths", {})

addHook("MapThingSpawn", function(mo, mthing)

    -- Set up path options
    mo.paths = {}
    --mo.pathcolor = 0
    --mo.pathradius = nil

    -- Set the start point id (moved to here from thinker instead)
    mo.startid = mo.spawnpoint.angle

    -- Add the mapthing object into a table to iterate over rather than the entire map
    table.insert(List_LinePaths, mthing)

    -- Sort values
    table.sort(List_LinePaths, function(a,b) return a.angle < b.angle end)

    --print("added object type: "..tostring(mo.type).." of "..tostring(mo))
end, MT_LINEPATH)


-- Reset tables on map change
addHook("MapChange", do
    List_LinePaths = {}
end)



local function map(x, in_min, in_max, out_min, out_max)
  return out_min + (x - in_min)*(out_max - out_min)/(in_max - in_min)
end


-- Calculate 3D distance (x,y + z height)
local function R_Distance(p1, p2)

    --local distance_x = to_dest.x - from.x
    --local distance_y = to_dest.y - from.y
    --local distance_z = to_dest.z - from.z

    --return FixedSqrt(FixedMul(distance_x, 2) + FixedMul(distance_y, 2) + FixedMul(distance_z, 2))
    return FixedHypot(FixedHypot(p1.x-p2.x, p1.y-p2.y), p1.z-p2.z)
end

-- Calculate 2D distance (x,y only)
local function R_Distance2D(p1, p2)
    return FixedHypot(p1.x-p2.x, p1.y-p2.y)
end

-- Calculate and draw a line ray to the coordinates specified
local function R_DrawMobjLine(from, to, params)

    -- We want the line casting to be customizable, so we sort out this stuff in a table
    local width = params.width or 64
    local dots = (params and params.dots == false) and MF2_DONTDRAW or 0
    local lines = (params and params.lines == false) and MF2_DONTDRAW or 0
    local lineMobj = params.linemobj or MT_THOK
    local scale = params.scale or FRACUNIT


    -- The lower the width, the more depth the line has (eg, more objects)
    local pointDistance = R_Distance(from, to)
    local linkcount = pointDistance/(width<<FRACBITS)

    -- The vertical angle from point a to b
    local vertangle = R_PointToAngle2(0, from.z, pointDistance, to.z)
    --local vertangle = R_PointToAngle2(0, 0, FixedHypot(to.y - from.x, to.y - from.y), to.z - from.z)

    from.links = {}

    -- Set parameters for dot customizability
    from.flags2 = dots
    to.flags2 = dots

    -- math borrowed from fickleheart to form a line properly (thanks a bunch!)
    for i=1, linkcount do

        -- Draw/Spawn lines
        from.links[i] = P_SpawnMobj(from.x+(to.x-from.x)/linkcount/2*(2*i-1),
                                    from.y+(to.y-from.y)/linkcount/2*(2*i-1),
                                    from.z+(to.z-from.z)/linkcount/1*(1*i-1), lineMobj)
        
        -- Make all line objects face toward their destination point
        from.links[i].angle = R_PointToAngle2(from.links[i].x, from.links[i].y, to.x, to.y)
        
        -- Set parameters for line customizability
        from.links[i].scale = scale
        from.links[i].flags2 = lines

        -- 'Attempt' to invert the sprite roll based on view
        local invert = -1
        if (R_PointToAngle(from.links[i].x, from.links[i].y) > from.links[i].angle)  then
            invert = 1
        end

        from.links[i].rollangle = vertangle*invert
        
    end
end


addHook("MobjThinker", function(mo)

    -- TODO: get options such as width, lines and dots from a line effect or elsewhere for this

    if (mo.valid) then

        -- Gather mobj properties
        local mobjflags = mo.spawnpoint.options

        -- Gather the objects path set once
        if (mo.spawnpoint.options & MTF_OBJECTSPECIAL and #mo.paths <= 0) then

            -- Search the global path list for the mobj
            for amnt=1,#List_LinePaths do

                -- Gather path list mobj properties
                local pl_mthing = List_LinePaths[amnt] -- current mapthing mobj in list
                local pl_mthing_angle = pl_mthing.angle -- mobj spawnpoint angle
                local pl_mthing_flags = pl_mthing.options -- mobj spawnpoint flags

                if (pl_mthing.valid) then

                    -- Find angle ids that follow after the start point angle and insert into the path list
                    -- as long as it is not another starting point not identical to this set
                    --print("List_LinePaths Index: " .. amnt .. " - has angle of " .. pl_mthing_angle)

                    for i=mo.startid,512 do
                        if ( (pl_mthing_angle == mo.startid+#mo.paths) ) then
                            
                            --print("Path start id [" .. mo.startid .. "] found next path id - ".. amnt)
                            table.insert(mo.paths, pl_mthing.mobj)
                            
                        end
                    end
                end
            end
            --print("Done gathering paths!")
            --print("Path start id [" .. mo.startid .. "] has " .. #mo.paths .. " paths")
        end

        -- Draw lines from the path list (continuous)
        for i=1,#mo.paths-1 do
            R_DrawMobjLine(mo.paths[i], mo.paths[i+1], {width = 45, lines = true, dots = false})
            --mo.rollangle = $1 + ANG1
        end
    end
end, MT_LINEPATH)



-- Unused Test Code
--addHook("ThinkFrame", function()
--
--    for i=1,#List_LinePaths do
--        
--        --local mobj = List_LinePaths[i]
--        for player in players.iterate() do
--            -- TODO: map a maximum distance that sprites will continue to be drawn
--            --R_DrawMobjLine(player.mo, List_LinePaths[2], 64)
--        end
--        --print(R_Distance(List_LinePaths[1], List_LinePaths[2])/FRACUNIT)
--        --print(R_Distance2D(List_LinePaths[1], List_LinePaths[2])/FRACUNIT)
--    end
--
--end)

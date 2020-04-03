-- Forces a sign post goal clear almost anywhere the function is called where spawnpoint is valid

local function P_SetGoalClear(source, spawnorigin, playerMobj)

    local special = source
    local toucher = playerMobj
    --P_RadiusExplode(source, 32, MT_EXPLODE)
--[[
    source.DummyGoal = P_SpawnMobj(source.x, source.y, source.z, MT_SIGN)
    source.DummyGoal.spawnpoint = spawnorigin.spawnpoint
    source.DummyGoal.spawnpoint.angle = $1-90

    --source.DummyGoal.tracer.flags2 = $1|MF2_DONTDRAW
    --source.DummyGoal.tracer.target.flags2 = $1|MF2_DONTDRAW
    --source.DummyGoal.flags2 = $1|MF2_DONTDRAW

    -- Do the magic clearing stuff here now
    playerMobj.target = source.DummyGoal
    P_DoPlayerExit(playerMobj.player)
]]

    if not (special.DummyGoal and special.DummyGoal.valid) then
        special.DummyGoal = P_SpawnMobj(special.x, special.y, special.z, MT_SIGN)
        special.DummyGoal.spawnpoint = spawnorigin.spawnpoint

        P_RemoveMobj(special.DummyGoal.tracer)
        special.DummyGoal.tracer = nil
        special.DummyGoal.flags2 = $1|MF2_DONTDRAW
    end

    -- Do the magic clearing stuff here now
    toucher.target = special.DummyGoal
    P_DoPlayerExit(toucher.player)

end



addHook("ThinkFrame", function()
    -- A Custom leveltimer test

    for player in players.iterate do
        if (leveltime == 3*TICRATE) then
            P_SetGoalClear({valid = true, x = 1024*FRACUNIT, y = 1024*FRACUNIT, z = 1024*FRACUNIT, spawnpoint = nil}, mapthings[0], player.mo)
        end
    end
end)

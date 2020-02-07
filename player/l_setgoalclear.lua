-- Forces a sign post goal clear almost anywhere the function is called where spawnpoint is valid

local function P_SetGoalClear(source, spawnorigin, playerMobj)

    --P_RadiusExplode(source, 32, MT_EXPLODE)

    source.DummyGoal = P_SpawnMobj(source.x, source.y, source.z, MT_SIGN)
    source.DummyGoal.spawnpoint = spawnorigin.spawnpoint
    source.DummyGoal.spawnpoint.angle = $1-90

    --source.DummyGoal.tracer.flags2 = $1|MF2_DONTDRAW
    --source.DummyGoal.tracer.target.flags2 = $1|MF2_DONTDRAW
    --source.DummyGoal.flags2 = $1|MF2_DONTDRAW

    -- Do the magic clearing stuff here now
    playerMobj.target = source.DummyGoal
    P_DoPlayerExit(playerMobj.player)

end

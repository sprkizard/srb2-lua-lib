-- Forces a sign post goal clear almost anywhere the function is called where spawnpoint is valid
rawset(_G, "P_SetGoalClear", function (source, spawnorigin, playerMobj)

    local special = source
    local toucher = playerMobj
    --P_RadiusExplode(source, 32, MT_EXPLODE)

    if not (special.DummyGoal and special.DummyGoal.valid) then
        special.DummyGoal = P_SpawnMobj(special.x, special.y, special.z, MT_SIGN)
        special.DummyGoal.spawnpoint = spawnorigin
		special.DummyGoal.state = S_SIGNSPIN1
		special.DummyGoal.momz = 8*FRACUNIT
		
		S_StartSound(thing, special.DummyGoal.info.seesound)
		
		special.DummyGoal.flags2 = $1|MF2_DONTDRAW
        special.DummyGoal.tracer.flags2 = $1|MF2_DONTDRAW
		special.DummyGoal.tracer.tracer.flags2 = $1|MF2_DONTDRAW
    end

    -- Do the magic clearing stuff here now
    toucher.target = special.DummyGoal
    P_DoPlayerExit(toucher.player)
end)

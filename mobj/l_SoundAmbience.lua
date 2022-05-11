
-- create mobj sound source

freeslot("MT_SOUNDPLAYER", "S_SOUNDPLAYER_SPAWN", "S_SOUNDPLAYER_SET", "S_SOUNDPLAYER_PLAY", "S_SOUNDPLAYER_END")

mobjinfo[MT_SOUNDPLAYER] = {
    doomednum = -1,
    spawnstate = S_SOUNDPLAYER_SPAWN,
    -- seesound = sfx_laser,
    -- speed = 8*FRACUNIT,
    -- radius = 41*FRACUNIT,
    -- height = 41*FRACUNIT,
    -- damage = 2,
    -- mass = 100,
    flags = MF_NOGRAVITY
}
states[S_SOUNDPLAYER_SPAWN] = {SPR_THOK,0|FF_TRANS40,1,nil,0,0,S_SOUNDPLAYER_SET}
states[S_SOUNDPLAYER_SET] = {SPR_THOK,0|FF_TRANS40,1,function(mo)
    mo.audiosrc.loop = mo.audiosrc.sfxlist[mo.audiosrc.num][2]
    -- print("test")
end,0,0,S_SOUNDPLAYER_PLAY}
states[S_SOUNDPLAYER_PLAY] = {SPR_THOK,0|FF_TRANS40,1,function(mo)

    local soundid = mo.audiosrc.sfxlist[mo.audiosrc.num]

    -- if (mo.audiosrc.num > #mo.audiosrc.sfxlist) then
    --     mo.state = S_SOUNDPLAYER_END
    --     print("ended")
    --     return
    -- else
    -- if (mo.audiosrc.num < #mo.audiosrc.sfxlist) then
        
        if S_SoundPlaying(mo, soundid[1]) then

            -- stop loop while playing    
            if mo.audiosrc.loop and mo.audiosrc.loop == 1 then
                print("stopped")
                S_StopSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
                mo.audiosrc.loop = $1 - 1
                return
            end
        else
            
            if (mo.audiosrc.loop > 0) then
                S_StartSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
                -- mo.state = S_SOUNDPLAYER_PLAY
                return
            end
            -- -- repeat starts over, once ends after last sound,
            -- -- none or any string repeats last sound endlessly
            -- if isLoop == "repeat" then
            --     mo.i = 1
            -- elseif isLoop == "once" then 
            --     return 
            -- else
            --     mo.i = #mo.audiosrc.sfxlist 
            -- end
            -- print(debugmsg)

            --[[if not mo.audiosrc.playing then
                mo.audiosrc.playing = true
            else
                mo.audiosrc.num = $1 + 1
            end--]]
            -- and mo.audiosrc.sfxlist[mo.audiosrc.num][2]
            if (mo.audiosrc.num < #mo.audiosrc.sfxlist) then
                mo.audiosrc.num = (mo.audiosrc.playing) and $1+1 or $1+0
                mo.audiosrc.playing = true

                 -- play sound
                print(string.format("soundid %s", tostring(mo.audiosrc.num)))
                S_StartSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
                mo.state = S_SOUNDPLAYER_SET
            else
                
        mo.state = S_SOUNDPLAYER_END
            end
        end
    -- else
    --     mo.state = S_SOUNDPLAYER_END
    --     print("ended")
    --     -- mo.audiosrc.playing = true
    -- end
    print(string.format("loop - %d", tostring(mo.audiosrc.loop)))
    mo.audiosrc.loop = max(0, $1-1)
    -- print(string.format("loop - %d", tostring(soundid[2])))
    -- soundid[2] = max(0, $1-1)

   --[[ if not S_SoundPlaying(mo, soundid[1]) then
        
        if mo.audiosrc.num <= #mo.audiosrc.sfxlist then
            -- if not mo.audiosrc.playing then
            --     mo.audiosrc.playing = true
            -- else
            --     mo.audiosrc.num = $1 + 1
            -- end
            mo.audiosrc.num = (mo.audiosrc.playing) and $1+1 or $1+0
            mo.audiosrc.playing = true
        else
            -- works but repeats final sound twice
            if (soundid[2]) then
                -- mo.state = S_SOUNDPLAYER_SET
            else
                mo.state = S_SOUNDPLAYER_END
                print("ended")
            end
           
            -- -- repeat starts over, once ends after last sound,
            -- -- none or any string repeats last sound endlessly
            -- if isLoop == "repeat" then
            --     mo.i = 1
            -- elseif isLoop == "once" then 
            --     return 
            -- else
            --     mo.i = #mo.audiosrc.sfxlist 
            -- end
            -- print(debugmsg)
        end
         -- play sound
        print(mo.audiosrc.num)
        S_StartSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
    else
        -- mo.audiosrc.playing = true
    end
    soundid[2] = max(0, $1-1)--]]
   
end,0,0,S_SOUNDPLAYER_PLAY}
states[S_SOUNDPLAYER_END] = {SPR_THOK,0|FF_TRANS40,5*TICRATE,nil,0,0,S_NULL}


local soundsourcelist = {}

local function P_CreateSoundSource(sounds, soundorigin, args)

    local src = P_SpawnMobj(soundorigin.x, soundorigin.y, soundorigin.z, MT_SOUNDPLAYER)
    -- src.tics = INT8_MAX
    -- src.color = SKINCOLOR_WHITE

    src.audiosrc = {soundmobj=src, sfxlist=sounds, playing=false, num=1, loop=0, origin=soundorigin, static=true, length=1*TICRATE}
    -- table.insert(soundsourcelist, {soundmobj=src, sfxlist=sounds, listnum=1, origin=soundorigin, static=true, length=1*TICRATE})
end

-- local function S_PlayAmbience(isAMobjSource, source, soundnum, player)
--     if (isAMobjSource) then

--         if not S_SoundPlaying(source, soundnum) then
--             S_StartSound(source, soundnum, player)
--         end
--     else
--         if not S_IdPlaying(soundnum) then
--             S_StartSound(source, soundnum, player)
--         end
--     end
-- end
-- rawset(_G, "S_PlayAmbience", S_PlayAmbience)

addHook("MobjSpawn", function(mo)
    mo.audiosrc = {}

end)



addHook("ThinkFrame", function()
    if leveltime == 2*TICRATE then
        -- P_CreateSoundSource({sfx_eleva2}, server.mo, {static=true})
        P_CreateSoundSource({{sfx_jump,0}, {sfx_eleva1,0}, {sfx_eleva2, 8*TICRATE}, {sfx_eleva3,0}}, server.mo, {static=true})
        -- P_CreateSoundSource({{sfx_jump,0}, {sfx_eleva1,0}, {sfx_eleva2, 5*TICRATE}}, server.mo, {static=true})
    end
end)

--[[addHook("ThinkFrame", function()
    for i=1,#soundsourcelist do
        local source = soundsourcelist[i]
        if not source.soundmobj.valid then continue end

        
        if not S_SoundPlaying(source.soundmobj, source.sfxlist[source.listnum]) then
            S_StartSound(source.soundmobj, source.sfxlist[source.listnum])
        else
            source.listnum = $1+1
        end

        P_TeleportMove(source.soundmobj, source.origin.x, source.origin.y, source.origin.z)
    end
end)--]]
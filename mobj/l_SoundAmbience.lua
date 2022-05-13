
-- reimplementation of soundtable.lua (2020)
-- TODO: format file


-- note: only for loops, use S_StartSound for one entry that has no looptime

freeslot("MT_SOUNDPLAYER", "S_SOUNDPLAYER_SET", "S_SOUNDPLAYER_PLAY", "S_SOUNDPLAYER_END")

mobjinfo[MT_SOUNDPLAYER] = {
    doomednum = -1,
    spawnstate = S_SOUNDPLAYER_SET,
    flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP,
}
states[S_SOUNDPLAYER_SET] = {SPR_NULL,0|FF_TRANS40,1,function(mo)
    -- set loop
    mo.audiosrc.loop = mo.audiosrc.sfxlist[mo.audiosrc.num][2]
end,0,0,S_SOUNDPLAYER_PLAY}
states[S_SOUNDPLAYER_PLAY] = {SPR_NULL,0|FF_TRANS40,1,function(mo)

    local soundid = mo.audiosrc.sfxlist[mo.audiosrc.num]
    local loopnum = mo.audiosrc.sfxlist[mo.audiosrc.num][2]

    if S_SoundPlaying(mo, soundid[1]) then

        -- stop loop while playing    
        if mo.audiosrc.loop and mo.audiosrc.loop == 1 then
            S_StopSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
            mo.audiosrc.loop = $1 - 1
            -- print("stopped loop")
            return
        end
    else
        -- TODO: looppoint with third argument
        -- TODO: re-add repeat mode
        -- TODO: infinite loop
        --[[ if (mo.audiosrc.loop == -1) then
            S_StartSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
            return
        end--]]
        -- reset sound in loop
        if (mo.audiosrc.loop > 0) then
            S_StartSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
            return
        end
        
        if (mo.audiosrc.num < #mo.audiosrc.sfxlist) then
            mo.audiosrc.num = (mo.audiosrc.playing) and $1+1 or $1+0
            mo.audiosrc.playing = true

            -- play next sound and reset state
            -- print(string.format("soundid %s", tostring(mo.audiosrc.num)))
            S_StartSound(mo, mo.audiosrc.sfxlist[mo.audiosrc.num][1])
            mo.state = S_SOUNDPLAYER_SET
        else
            -- hit end of list
            mo.state = S_SOUNDPLAYER_END
            -- print("Ended")
            return
        end
    end

    -- print(string.format("loop - %d", tostring(mo.audiosrc.loop)))
    mo.audiosrc.loop = max(0, $1-1)

end,0,0,S_SOUNDPLAYER_PLAY}
states[S_SOUNDPLAYER_END] = {SPR_THOK,0|FF_TRANS40,1,nil,0,0,S_NULL}




-- Creates a mobj sound source
local function S_StartSoundEnviro(sounds, soundorigin, args)

    local src = P_SpawnMobj(soundorigin.x, soundorigin.y, soundorigin.z, MT_SOUNDPLAYER)

    src.audiosrc = {soundmobj=src, sfxlist=sounds, playing=false, num=1, loop=0, origin=soundorigin, static=(args and args.static)}

    -- TODO: reference created object properly
    return src
end
rawset(_G, "S_StartSoundEnviro", S_StartSoundEnviro)


addHook("MobjSpawn", function(mo)
    mo.audiosrc = {}
end)

addHook("MobjThinker", function(mo)

    if not mo and mo.audiosrc then return end

    if (mo.audiosrc.origin and mo.audiosrc.origin.valid) and not mo.audiosrc.static then
        P_TeleportMove(mo, mo.audiosrc.origin.x, mo.audiosrc.origin.y, mo.audiosrc.origin.z)
    end
end)


addHook("ThinkFrame", function()
    if leveltime == 2*TICRATE then
        S_StartSoundEnviro({{sfx_jump,0}, {sfx_eleva1,0}, {sfx_eleva2, 8*TICRATE}, {sfx_eleva3,0}}, server.mo, {static=false})
    end
end)

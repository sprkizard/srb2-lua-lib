
local function S_PlayAmbience(isAMobjSource, source, soundnum, player)
    if (isAMobjSource) then

        if not S_SoundPlaying(source, soundnum) then
            S_StartSound(source, soundnum, player)
        end
    else
        if not S_IdPlaying(soundnum) then
            S_StartSound(source, soundnum, player)
        end
    end
end

rawset(_G, "S_PlayAmbience", S_PlayAmbience)

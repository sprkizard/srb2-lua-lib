-- TODO: turn accidental Timescale into a working functional thing to use

rawset(_G, "motimescale", 1)

COM_AddCommand("timescale", function(t)
    motimescale = t
end)


-- Someone will find this useful some day
addHook("MobjThinker", function(mo)
    if (leveltime % motimescale) then
        return true
    else
        return false
    end
end)
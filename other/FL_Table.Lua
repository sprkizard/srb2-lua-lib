-- 
-- FL_Table.Lua
-- Resource file for Table functions
-- 
-- Flame
-- Date 3-27-21
--

--
-- Function;
--    createFlags(name, t)
--
-- Arguments;
--    name   - Existing blank table.
--    t      - Table with a list of strings.
--
-- Description:
--    Creates flags similar to MF_*, MF2_*, MFE_*, constraints
--    Gets length of 't' table, assigns each value of 't' in the Global Table and assigns it a flag value
--    Also places in the tname table for other accessibility such as verifying the tname.string or tname.value
--
-- Example:
--    createFlags(tname, {"FL_FLAG", "FL_FLAG2", "FL_FLAG3"})
--
--    Creates FL_FLAG with value 1
--    Creates FL_FLAG2 with value 2
--    Creates FL_FLAG3 with value 4
--
--    Creates tname[1].string = "FL_FLAG", tname[1].value = 1
--    Creates tname[2].string = "FL_FLAG2", tname[2].value = 2
--    Creates tname[2].string = "FL_FLAG3", tname[2].value = 4
--
-- Usage:
--    mobj.customflags = $ | FL_FLAG
--
rawset(_G, "createFlags", function(tname, t)
    for i = 1,#t do
		rawset(_G, t[i], 2^(i-1))
		table.insert(tname, {string = t[i], value = 2^(i-1)} )
    end
end)

-- Function;
--    createEnum(name, t)
--
-- Arguments;
--    name   - Existing blank table.
--    t      - Table with a list of strings.
--
-- Description:
--    Gets length of 't' table, assigns each value of 't' in the Global Table and assigns it a enum value - 1
--    Different from createFlags in that it allows familar table access. Think player.powers[pw_shield] for example
--    Also places in the tname table for other accessibility such as verifying the tname.string or tname.value
--
-- Example:
--    createEnum(tname, {"FL_Enum", "FL_Enum2", "FL_Enum3"})
--
--    Creates Global FL_Enum with value 0
--    Creates Global FL_Enum2 with value 1
--    Creates Global FL_Enum3 with value 2
--
--    Creates tname[1].string = "FL_Enum", tname[1].value = 0
--    Creates tname[2].string = "FL_Enum2", tname[2].value = 1
--    Creates tname[2].string = "FL_Enum3", tname[2].value = 2
--
-- Usage:
--    mobj.exampletable[FL_Enum] -- Notice the lack of need for quotation marks (" ")
--
rawset(_G, "createEnum", function(tname, t, from)
    if from == nil then from = 0 end
    for i = 1,#t do
		rawset(_G, t[i], from+(i-1))
		table.insert(tname, {string = t[i], value = from+(i-1)} )
    end
end)


-- Function;
--    spairs(t, order)
--
-- Arguments;
--    t       - Table.
--    order   - .
--
-- Description:
--    Sorts t pairs with a f
--
-- Example usage:
--    local Scores = { Sonic = 8, Tails = 10, Knuckles = 11 }
--    for k,v in spairs(Scores, function(t,a,b) return t[b] < t[a] end) do
--      print(k,v)
--    end
--
-- Output:
--    --> Knuckles     11
--    --> Tails     10
--    --> Sonic   8
--
rawset(_G, "spairs", function(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end)

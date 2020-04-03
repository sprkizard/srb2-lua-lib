
--local soft = {}

local RUNNING_VALUES = {}

--local soft = {
--    speed = 1,
--    vars = {}
--}

function table.size(table_name)
    local n = 0
    for k,v in pairs(table_name) do
        n = n + 1
    end
    return n
end

local function FixedLerp(a, b, t)
    if (a == b) then
        return a
    else
        -- 0.005 equiv to 65535/(65535*200), but better would be 0.5 (65535/2)
        if abs(a-b) < FRACUNIT/FRACUNIT*200 or abs(b-a) < FRACUNIT/FRACUNIT*200 then return b else return a + FixedMul(b - a, t) end
    end
end

--function soft:to(val, targetval)
--    table.insert(RUNNING_VALUES, object)
--end

--local function scrollvar(name, val, targetvalue, speed)
local function scrollvar(name, parms)

    -- insert a new scroll object into the global table
    if not (RUNNING_VALUES[name] and RUNNING_VALUES[name].active) then
        RUNNING_VALUES[name] = {value = parms.val, target = parms.targetvalue, active = true, speed = parms.speed or 128, ref = parms.ref}
        --table.insert(RUNNING_VALUES, {value = val, target = targetvalue, active = true, speed = speed or 1})
    end
    return RUNNING_VALUES[name].value
end

rawset(_G, "clearScroll", function(name)
    RUNNING_VALUES[name].active = false
end)
-- Reset table on change
addHook("MapChange", function()

    -- Pick which to clone over into a new table if it is meant to be persistent
    for k,v in pairs(RUNNING_VALUES) do
        --print(k,v)
    end

    -- Wipe the table
    RUNNING_VALUES = {}
end)

addHook("ThinkFrame", function()

    -- Iterate the container and update and lerp all values
    for k,v in pairs(RUNNING_VALUES) do

        -- Remove when finished
        --if (v.value == v.target) then RUNNING_VALUES[v] = nil end--print("Remove this") end
        v.value = FixedLerp(v.value, v.target, leveltime * v.speed)
        --v.ref.scale = FixedLerp(v.value, v.target, leveltime * v.speed)
        --if (v.value == v.target) then RUNNING_VALUES[k] = nil end--print("Remove this") end
        --print(k,v.value)
    end

end)

rawset(_G, "scrollvar", scrollvar)









local function LerpTest(v, stplyr, ticker, endtime)

    --local w = scrollvar("wfill", 0*FRACUNIT, 330*FRACUNIT, 256)
    --v.drawFill(0, 0, w/FRACUNIT, 200, 30)
    --v.drawFill(0, 0,   scrollvar("wfill1", 0*FRACUNIT, v.width()*FRACUNIT, 256)/FRACUNIT, 42, 30)
    --v.drawFill(0, 42,  scrollvar("wfill2", 0*FRACUNIT, v.width()*FRACUNIT, 64)/FRACUNIT, 32, 28)
    --v.drawFill(0, 74,  scrollvar("wfill3", 0*FRACUNIT, v.width()*FRACUNIT, 32)/FRACUNIT, 64, 26)
    --v.drawFill(0, 138, scrollvar("wfill4", 0*FRACUNIT, v.width()*FRACUNIT, 16)/FRACUNIT, 200, 24)

    --local x = scrollvar("x", 0*FRACUNIT, 256*FRACUNIT)
--
    --v.drawString(16, 64, "x ["..x.."]", V_ORANGEMAP)
    --v.drawString(16, 84, "x Int ["..x/FRACUNIT.."]", V_ORANGEMAP)
--
    --if (leveltime >= 5*TICRATE) then
    --    local z = scrollvar("z", 32*FRACUNIT, 0*FRACUNIT)
    --    v.drawString(16, 74, "z ["..z.."]", V_ORANGEMAP)
    --    v.drawString(16, 94, "z Int ["..z/FRACUNIT.."]", V_ORANGEMAP)
    --end
--
--
    local x = scrollvar("x_hud", {val = 20*FRACUNIT, targetvalue = 70*FRACUNIT, speed = 128})
    v.drawString(x/FRACUNIT, 171, "Scroll String", V_ORANGEMAP)
    v.drawString(x/FRACUNIT, 181, "Above x position ["..x/FRACUNIT.."]", V_ORANGEMAP)
    
    v.drawString(310, 190, "Tables ["..table.size(RUNNING_VALUES).."]", V_ORANGEMAP, "right")

end

hud.add(LerpTest, "titlecard")


addHook("ThinkFrame", function()

    for player in players.iterate do
        --player.mo.momx = 0
        --player.mo.momy = 0
        --player.mo.momz = 0
        --P_TeleportMove(player.mo, scrollvar("x", -32*FRACUNIT, 1524*FRACUNIT ), scrollvar("y", -64*FRACUNIT, 1524*FRACUNIT), scrollvar("z", 32*FRACUNIT, 1024*FRACUNIT))
        
    end

end)

-- Selects a player at random, and returns the said player
local function P_PickRandomPlayer(playertable)
    
    local playerlist = playertable or {}

    -- TODO: see if using a for statement with MAXPLAYERS as a limit is better than players.iterate
    if not playertable then
        for player in players.iterate do
            table.insert(playerlist, player)
        end
    end

    local randomTarget = P_RandomChoice(playerlist)

    if (randomTarget.mo.valid) then
        return randomTarget.mo
    else
        -- Rerun this exact function
        --PickRandomTargetPlayer()
    end

end

-- Selects a mobj at random, and returns the said mobj
local function P_PickRandomMobj(sourcemo, mobjtable)

    local mobjlist = mobjtable or {}

        for mobj in mobjs.iterate() do
            -- TODO: exclude mt push and pull
            if (mobj == sourcemo) then continue end
            table.insert(mobjlist, mobj)
        end

    local randomTarget = P_RandomChoice(mobjlist)

    if (randomTarget and randomTarget.valid) then
        return randomTarget
    else
        -- Rerun this exact function
        --P_PickRandomTargetPlayer()
    end

end



rawset(_G, "P_PickRandomPlayer", P_PickRandomPlayer)
rawset(_G, "P_PickRandomMobj", P_PickRandomMobj)

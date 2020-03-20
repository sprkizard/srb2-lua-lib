

//--============================================================================
//-- Button state management - Ever want an easy way to
//-- know whether a button's been tapped, held, released, 
//-- for how long? Well, here you go. player.buttonstate[blah] 
//-- returns x frames being held, or -x frames being released
local dupeprevent = false
 
addHook("MobjThinker", function(mo)
		local player = mo.player
		if player.buttonstate and not dupeprevent then return end -- Avoid processing buttonstate multiple times per frame if multiple loaded addons have this code snippet in them!
		dupeprevent = true
	   
		if not player.buttonstate then player.buttonstate = {} end
		local bs = player.buttonstate
	   
		local function state(cond, key)
				if cond then
						bs[key] = max(($1 or 0)+1, 1)
				else
						bs[key] = min(($1 or 0)-1, -1)
				end
		end
	   
		-- Handle normal buttons - get these with player.buttonstate[BT_WHATEVER]
		for _,v in ipairs({
				BT_JUMP, BT_USE, BT_ATTACK, BT_FIRENORMAL,
				BT_CAMLEFT, BT_CAMRIGHT,
				BT_WEAPONNEXT, BT_WEAPONPREV, BT_TOSSFLAG,
				BT_CUSTOM1, BT_CUSTOM2, BT_CUSTOM3
		}) do
				state(player.cmd.buttons & v, v)
		end
	   
		-- Handle weapon quick select buttons - get these with player.buttonstate[weaponnum] (can probably use WEP_WHATEVER+1?)
		for i = 1,BT_WEAPONMASK-1 do
				state(player.cmd.buttons & BT_WEAPONMASK == i, i)
		end
	   
		-- Finally, handle directional taps (no analog support, soz) - get these with player.buttonstate["direction"] (up, down, left, right)
		for k,v in pairs({
				up = function(p) return p.cmd.forwardmove > 0 end,
				down = function(p) return p.cmd.forwardmove < 0 end,
				left = function(p) return p.cmd.sidemove < 0 end,
				right = function(p) return p.cmd.sidemove > 0 end
		}) do
				state(v(player), k)
		end
		
		if player.camdist == nil
			player.camdist = 240*FRACUNIT
		end
end, MT_PLAYER)
//--============================================================================



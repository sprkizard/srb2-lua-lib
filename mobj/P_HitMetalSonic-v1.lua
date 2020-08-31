--[[ 
*
*	L_HitMetalSonic-v1.lua
*
*
*
*	LUA adaptation of vectorise from the source code file p_mobj.c
*
*   Adapted from the source code into LUA by Stonecutter.
*
*   Credits for the original code go to:
*		toasterone
*		MonsterIestyn
*		MascaraSnakeSRB2
*		marcolovescode
*		alama
*		lachwright
*		KScl
*		Jimita
*		Yukitty
*		LJSonik
*		Nevur
*		Ikkarin
*		jameds
*		spherallic
*		SwitchKaze
*		wolfy852
*		SteelTitanium
*		TehRealSalt
*		sprkizard
*		RedEnchilada
*		HybridEidolon
*		SeventhSentinel
*		ilag11111
*
*	Distributed under the GNU GPL v2.0
*
*
*	(August 30, 2020 5:02)
*
*	Desc: Knocks MT_METALSONIC_BATTLE out of S_STATE_FLOAT
*			(It lets you hit Metal into his vulnerable phase out of the phase where he flies around the player)
*
]]


--[[
*
* Preconditions: 
*				1.	thing exists and is valid.
*				2.	mo exists and is valid.
*
* Postconditions:
*				1.	If thing was Metal Sonic, and he was in his float state,
*					he behaves as if he were hit by a vanilla attack.
*
* Variables:
*				1.	thing, mobj, thing is the mobj that will be hit if it is Metal Sonic in his float state.
*				
]]
local function P_HitMetalSonic(thing)
    
						
	if
	(
		metal.state == S_METALSONIC_FLOAT	-- Only Metal Sonic uses this state (as far as I know)
											-- and this is the only state in which special code is necessary.
	)
							
										
			-- Here's where the source code adaptation begins.
								
			-- vectorise from p_mobj.c
			thing.movedir = ANGLE_11hh - FixedAngle(FixedMul(AngleFixed(ANGLE_11hh), FixedDiv((thing.info.spawnhealth - thing.health)<<FRACBITS, (thing.info.spawnhealth-1)<<FRACBITS)))
								
			if (P_RandomChance(FRACUNIT/2))
				thing.movedir = InvAngle(thing.movedir)
			end
			thing.threshold = 6 + (FixedMul(24<<FRACBITS, FixedDiv((thing.info.spawnhealth - thing.health)<<FRACBITS, (thing.info.spawnhealth-1)<<FRACBITS))>>FRACBITS)
			if (thing.info.activesound)
				S_StartSound(thing, thing.info.activesound)
			end
			if (thing.info.painchance)
				thing.state = thing.info.painchance
			end
			thing.flags2 = $ & ~MF2_INVERTAIMABLE
								
			-- end source code adaptation
	end
						
									
end)

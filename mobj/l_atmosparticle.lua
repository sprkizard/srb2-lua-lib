
freeslot(
"MT_ATMOSPARTICLE",
"S_ATMOSPARTICLE"
)

freeslot("SPR_BPRT")


mobjinfo[MT_ATMOSPARTICLE] = {
	doomednum = -1,
	spawnhealth = 8*TICRATE,
	spawnstate = S_ATMOSPARTICLE,
	speed = 8, 
	radius = 32*FRACUNIT,
	height = 32*FRACUNIT,
	mass = 100,
	reactiontime = 10*TICRATE,
	flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT
}
states[S_ATMOSPARTICLE] = {SPR_THOK,A,-1,nil,0,0,S_NULL}
-- states[S_ATMOSPARTICLE] = {SPR_BPRT,A|FF_FULLBRIGHT|FF_ANIMATE|FF_TRANS30,-1,A_None,5,2,S_NULL}

addHook("MobjSpawn", function(mo)
	mo._dist = 512
	mo._roll = 0
end, MT_ATMOSPARTICLE)

addHook("MobjThinker", function(mo)
	if mo.valid then
		mo.health = max($1-1, 0)
		-- TODO: mobj._roll, scale, and splat/papersprite
		mo.destscale = FRACUNIT/8
		mo.scalespeed = FRACUNIT/64
		--print(mo.health)
		if mo._roll then mo.rollangle = $1+mo._roll end

		if not mo.health then
			P_RemoveMobj(mo)
			--mo.state = S_NULL
		-- Destroy any past distance threshold
		elseif R_PointToDist(mo.x, mo.y) > mo._dist*FRACUNIT then
			P_RemoveMobj(mo)
		end
	end
end, MT_ATMOSPARTICLE)



local function P_CreateEmitter(spawner, settings)

	local x,y,z = spawner.x, spawner.y, spawner.z

	-- The maximium amount of distance the spawner stays is in
	local distance_threshold = (settings and settings.maxdist) or 512
	
	-- The range of where objects spawn from the spawner
	local maxrad = (settings and settings.maxrad) or 256

	-- The height range of both the top and bottom of the spawner
	local maxceil = (settings and settings.ceil) or 128
	local maxfloor = (settings and settings.floor) or -32

	-- If specified, replace the default particle mobj with your own
	local particlemo = (settings and settings.mobj)

	-- The amount of time each particle lasts
	local decay = (settings and settings.decay) or 8*TICRATE

	-- Set emitter coords relative to in front of spawner (default distance was -32..)
	local spawnx = x + 0*cos(spawner.angle+FixedAngle(ANGLE_90))
	local spawny = y + 0*sin(spawner.angle+FixedAngle(ANGLE_90))

	-- Set up particle spawn below view distance threshold
	-- if R_PointToDist(spawnx, spawny) < distance_threshold*FRACUNIT then
	-- 	local particle = P_SpawnMobj(
	-- 		x + cos(spawner.angle) + P_RandomRange(-maxrad, maxrad)*FRACUNIT,
	-- 		y + sin(spawner.angle) + P_RandomRange(-maxrad, maxrad)*FRACUNIT,
	-- 		z + P_RandomRange(maxfloor, maxceil)*FRACUNIT, MT_ATMOSPARTICLE)
	-- P_SpawnMobj(spawnx, spawny, spawner.z, MT_THOK)
	if R_PointToDist(spawnx, spawny) < distance_threshold*FRACUNIT then

		local rx = P_RandomRange(-maxrad, maxrad)*FRACUNIT
		local ry = P_RandomRange(-maxrad, maxrad)*FRACUNIT
		local rz = P_RandomRange(maxfloor, maxceil)*FRACUNIT

		local particle = P_SpawnMobj(
			-- x + cos(spawner.angle) + P_RandomRange(-maxrad, maxrad)*FRACUNIT,
			-- y + sin(spawner.angle) + P_RandomRange(-maxrad, maxrad)*FRACUNIT,
			-- spawnx + P_RandomRange(-maxrad, maxrad)*FRACUNIT,
			-- spawny + P_RandomRange(-maxrad, maxrad)*FRACUNIT,
			-- z + P_RandomRange(maxfloor, maxceil)*FRACUNIT, MT_ATMOSPARTICLE)
			spawnx + rx,
			spawny + ry,
			z + rz, particlemo or MT_ATMOSPARTICLE)
		
		-- Sync object settings
		particle._dist = distance_threshold
		particle._roll = (settings and settings.roll) or 0
		particle.health = decay
		--[[local particle = P_SpawnMobj(player.mo.x + P_RandomRange(-256, 256)*cos(player.mo.angle+FixedAngle(P_RandomRange(-32, 32)*FRACUNIT)),
									player.mo.y + P_RandomRange(-256, 256)*sin(player.mo.angle+FixedAngle(P_RandomRange(-32, 32)*FRACUNIT)),
									player.mo.z + P_RandomRange(-32, 128)*FRACUNIT, MT_ATMOSPARTICLE)]]
		
		-- Be able to customize what your particles can do
		if (settings and settings.func) then
			settings.func(particle)
			-- Ex: Keep momentum with movement using momx and momy
		end

		-- Destroy any past distance threshold
		--[[if R_PointToDist(particle.x, particle.y) > distance_threshold*FRACUNIT then
			P_RemoveMobj(particle)
		end]]
	end

end

rawset(_G, "P_CreateEmitter", P_CreateEmitter)


-- local particle_viewplayer = nil











--[[local function viewPlayerCheck(v, stplyr, cam)
	particle_viewplayer = stplyr
end
hud.add(viewPlayerCheck, "game")--]]

-- addHook("ThinkFrame", do

-- 	for player in players.iterate
	
-- 		local x,y,z = player.mo.x, player.mo.y, player.mo.z
-- 		local distance_threshold = 512
-- 		if (particle_viewplayer == player) then

-- 			local spawnx = player.mo.x + 32*cos(player.mo.angle+FixedAngle(ANGLE_90))
-- 			local spawny = player.mo.y + 32*sin(player.mo.angle+FixedAngle(ANGLE_90))

-- 			-- Set up particle spawn below distance threshold
-- 			if R_PointToDist(spawnx, spawny) < distance_threshold*FRACUNIT then
-- 				local particle = P_SpawnMobj(player.mo.x + cos(player.mo.angle) + P_RandomRange(-256, 256)*FRACUNIT,
-- 											player.mo.y + sin(player.mo.angle) + P_RandomRange(-256, 256)*FRACUNIT,
-- 											player.mo.z + P_RandomRange(-32, 128)*FRACUNIT, MT_ATMOSPARTICLE)
-- 				--[[local particle = P_SpawnMobj(player.mo.x + P_RandomRange(-256, 256)*cos(player.mo.angle+FixedAngle(P_RandomRange(-32, 32)*FRACUNIT)),
-- 											player.mo.y + P_RandomRange(-256, 256)*sin(player.mo.angle+FixedAngle(P_RandomRange(-32, 32)*FRACUNIT)),
-- 											player.mo.z + P_RandomRange(-32, 128)*FRACUNIT, MT_ATMOSPARTICLE)]]
-- 				particle.momz = $1+2*FRACUNIT
				
-- 				-- Keep momentum with movement
-- 				particle.momx = player.mo.momx
-- 				particle.momy = player.mo.momy

-- 				-- Destroy any past distance threshold
-- 				--[[if R_PointToDist(particle.x, particle.y) > distance_threshold*FRACUNIT then
-- 					P_RemoveMobj(particle)
-- 				end]]
-- 			end
			
-- 		end
-- 	end
-- end)

--[[ -- Particle Reference Code
	local spawnx = player.mo.x + 32*cos(player.mo.angle+FixedAngle(ANGLE_90))
	local spawny = player.mo.y + 32*sin(player.mo.angle+FixedAngle(ANGLE_90))
	if R_PointToDist(spawnx, spawny) < distance_threshold*FRACUNIT then
		local particle = P_SpawnMobj(player.mo.x + P_RandomRange(-256, 256)*cos(player.mo.angle+FixedAngle(0)),
								player.mo.y + P_RandomRange(-256, 256)*sin(player.mo.angle+FixedAngle(0)),
								player.mo.z + P_RandomRange(-32, 32)*FRACUNIT, MT_THOK)
		particle.momz = $1+2*FRACUNIT
	end
]]
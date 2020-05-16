--[[
* l_sprite3dgroup.lua
* (sprkizard)
* (May 16, 2020 00:28)
* Desc: Small script that allows the simple creation of
		grouped sprites on objects in the form of a 3D object ala
		ACZ2 minecart (v2.2)

* Usage:
        
        
        

]]



local function P_BuildSpriteGroup(source, grouplist)
	
	if not source.valid then return end

	source.group_items = grouplist
end

local function P_UpdateSpriteGroup(source, func)

	if not source.valid then return end

	for i=1,#source.group_items do

		local groupmobj = source.group_items[i].mobj
		local offset = source.group_items[i].offset
		local direction = source.group_items[i].angle
		local rotation = source.group_items[i].rotation

		groupmobj.angle = source.angle+FixedAngle(direction*FRACUNIT)
		groupmobj.scale = source.scale

		if (func) then
			do func(source.group_items[i])

			end
		end
		-- if not relative then
		P_TeleportMove(
			groupmobj,
			source.x+FixedMul(offset.x*cos(source.angle+FixedAngle(rotation*FRACUNIT)), groupmobj.scale),
			source.y+FixedMul(offset.y*sin(source.angle+FixedAngle(rotation*FRACUNIT)), groupmobj.scale),
			source.z+offset.z*FRACUNIT)
	end

end

addHook("MobjSpawn", function(mo)
	P_BuildSpriteGroup(mo, {
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), offset = {x = 32, y = 32, z = 0}, angle = 90, rotation = 0},
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), id = "sides", offset = {x = 16, y = 16, z = 0}, angle = 0, rotation = 90},
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), id = "sides", offset = {x = 16, y = 16, z = 0}, angle = 180, rotation = -90},
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), offset = {x = 32, y = 32, z = 0}, angle = 270, rotation = 180},
	})
end, MT_GR)

addHook("MobjThinker", function(mo)

	P_UpdateSpriteGroup(mo, function(item)
		if item.id then
			item.mobj.frame = 1
		end
		item.mobj.sprite = SPR_BOXS
		item.mobj.frame = $1|FF_PAPERSPRITE
		item.mobj.scale = max(FRACUNIT/4, cos(ANG1*leveltime)*4)
	end)

	mo.angle = $1+ANG1
	if (leveltime % 90 == 0) then 
		mo.momz = 8*FRACUNIT
	end
	--P_DrawFacingMarker(mo, SKINCOLOR_RED)

end, MT_GR)


addHook("MobjSpawn", function(mo)
	P_BuildSpriteGroup(mo, {
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), offset = {x = 0, y = 0, z = 0}, angle = 0, rotation = 0},
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), offset = {x = 0, y = 0, z = 0}, angle = 110, rotation = 0},
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), offset = {x = 0, y = 0, z = 0}, angle = 230, rotation = 0},
		{mobj = P_SpawnMobj(mo.x, mo.y, mo.z, MT_PULL), id = "top", offset = {x = 0, y = 0, z = 64}, angle = 0, rotation = 0},
	})
end, MT_GOLDENPEDESTAL)

addHook("MobjThinker", function(mo)

	P_UpdateSpriteGroup(mo, function(item)
		if item.id == "top" then
			item.mobj.sprite = SPR_RING
		else
			item.mobj.sprite = SPR_PEDG
			item.mobj.frame = $1|FF_PAPERSPRITE
		end
	end)

	--P_DrawFacingMarker(mo, SKINCOLOR_RED)

end, MT_GOLDENPEDESTAL)



addHook("ThinkFrame", function()

	for player in players.iterate do
		if leveltime == 1*TICRATE then
			-- local group = P_SpawnMobj(player.mo.x+64*FRACUNIT, player.mo.y, player.mo.floorz, MT_GR)
			local group = P_SpawnMobj(player.mo.x+64*FRACUNIT, player.mo.y, player.mo.floorz, MT_GOLDENPEDESTAL)
			--group.angle = ANGLE_90
		end
	end
end)

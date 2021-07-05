--[[
* l_spritemdl.lua
* (sprkizard)
* (May 16, 2020 00:28)
* Desc: Small script that allows the simple creation of
		grouped sprites on objects in the form of a 3D object ala
		ACZ2 minecart (v2.2)

* Usage:
]]


-- Builds up a mobj sprite group from a list of mobjs
local function P_BuildSpriteModel(source, itemlist)

	-- source mobj is not valid
	if not source.valid then return end

	source.sprmdl = {}
	
	for i=1,#itemlist do
		local mo = P_SpawnMobjFromMobj(source, 0, 0, 0, itemlist[i].mobjtype or MT_THOK)

		if (itemlist[i].spritetype == "splat") then
       		mo.renderflags = $1|RF_FLOORSPRITE|RF_SLOPESPLAT|RF_NOSPLATBILLBOARD
		elseif (itemlist[i].spritetype == "paper") then
			mo.renderflags = $1|RF_PAPERSPRITE
		end

		-- References the parent in every object created by the parent builder, including the object itself
		table.insert(source.sprmdl, {
			mobj = mo,
			parent = source,
			offset = itemlist[i].offset, -- the object's offset position
			angleoffset = (not (itemlist[i].angleoffset == nil) and itemlist[i].angleoffset or 0), -- the object's angle
			scaleoffset = (not (itemlist[i].scaleoffset == nil) and itemlist[i].scaleoffset or 0),
			rotation = (not (itemlist[i].rotation == nil) and itemlist[i].rotation or 0), -- the objects rotation around the source's radius
			spritetype = itemlist[i].spritetype,
			zangle = itemlist[i].zangle,
			id = itemlist[i].id,
		})
	end
end

local function P_UpdateSpriteModel(source, callback)

	-- source mobj is not valid
	if not source.valid then return end

	-- Run through the entire source spritegroup
	for i=1,#source.sprmdl do

		local modelpart = source.sprmdl[i]

		if not modelpart.mobj.valid then return end

		-- Follow the source angle + offset
		modelpart.mobj.angle = R_PointToAngle2(modelpart.mobj.x, modelpart.mobj.y, source.x, source.y) + FixedAngle(modelpart.angleoffset*FU)

		-- Set scale to source scale
		modelpart.mobj.scale = source.scale + modelpart.scaleoffset

		if (modelpart.spritetype == "splat" and modelpart.zangle) then
			P_CreateFloorSpriteSlope(modelpart.mobj)
			modelpart.mobj.floorspriteslope.zangle = FixedAngle(modelpart.zangle*FU)
            modelpart.mobj.floorspriteslope.xydirection = modelpart.mobj.angle
			modelpart.mobj.floorspriteslope.o = {
                x = source.x+FixedMul(modelpart.offset.x*cos(source.angle+FixedAngle(modelpart.rotation*FU)), source.scale),
                y = source.y+FixedMul(modelpart.offset.y*sin(source.angle+FixedAngle(modelpart.rotation*FU)), source.scale),
                z = source.z+FixedMul(modelpart.offset.z*FU, source.scale)
            }
		end

		-- Run a callback function to edit one or all items
		if (callback) then
			do
				callback(modelpart)
			end
		end

		-- Update the position of all parts to be relative to the mobj + offsets (+ scaling)
		P_TeleportMove(modelpart.mobj,
			source.x+FixedMul(modelpart.offset.x*cos(source.angle+FixedAngle(modelpart.rotation*FU)), source.scale),
			source.y+FixedMul(modelpart.offset.y*sin(source.angle+FixedAngle(modelpart.rotation*FU)), source.scale),
			source.z+FixedMul(modelpart.offset.z*FU, source.scale))

	end

end



local function P_BuildSpriteMdl(source, grouplist)

	-- source mobj is not valid
	if not source.valid then return end

	source.sprmdl = grouplist
	for i=1,#source.sprmdl do

		-- References the parent in every object created by the parent builder, including the object itself
		if (source.sprmdl[i].mobj.valid) then
			source.sprmdl[i].mobj.sprmdl_parent = source
			source.sprmdl[i].mobj.sprmdl_self = source.sprmdl[i]
		end
	end
end

-- Updates the position and callback functions of the sprite group
local function P_UpdateSpriteMdl(source, func)

	-- source mobj is not valid
	if not source.valid then return end

	-- Run through the entire source spritegroup
	for i=1,#source.sprmdl do

		-- sprmdl mobj is not valid
		if not source.sprmdl[i].mobj.valid then return end

		local groupmobj = source.sprmdl[i].mobj
		local offset = source.sprmdl[i].offset or {x = 0, y = 0, z = 0} -- TODO: be able to exclude each axis; default to 0
		local direction = source.sprmdl[i].angle or 0
		local rotation = source.sprmdl[i].rotation or 0

		-- Follow the source angle + independent angle
		groupmobj.angle = source.angle+FixedAngle(direction*FRACUNIT)

		-- Set scale to source scale
		groupmobj.scale = source.scale

		-- Run a callback function to edit one or all items
		if (func) then
			do
				func(source.sprmdl[i])
			end
		end

		-- Update the position of all group items to be relative to the mobj angle + offsets (and scaling!)
		P_TeleportMove(
			groupmobj,
			source.x+FixedMul(offset.x*cos(source.angle+FixedAngle(rotation*FRACUNIT)), groupmobj.scale),
			source.y+FixedMul(offset.y*sin(source.angle+FixedAngle(rotation*FRACUNIT)), groupmobj.scale),
			source.z+FixedMul(offset.z*FRACUNIT, groupmobj.scale))
	end

end

-- Expose globals
rawset(_G, "P_BuildSpriteMdl", P_BuildSpriteMdl)
rawset(_G, "P_UpdateSpriteMdl", P_UpdateSpriteMdl)

rawset(_G, "P_BuildSpriteModel", P_BuildSpriteModel)
rawset(_G, "P_UpdateSpriteModel", P_UpdateSpriteModel)
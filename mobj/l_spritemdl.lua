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
local function P_BuildSpriteMdl(source, grouplist)

	-- source mobj is not valid
	if not source.valid then return end

	source.sprmdl = grouplist
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
			source.z+offset.z*FRACUNIT)
	end

end

-- Expose globals
rawset(_G, "P_BuildSpriteMdl", P_BuildSpriteMdl)
rawset(_G, "P_UpdateSpriteMdl", P_UpdateSpriteMdl)

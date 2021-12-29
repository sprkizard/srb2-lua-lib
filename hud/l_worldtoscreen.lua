--[[
* l_worldtoscreen.lua
* (sprkizard)
* (‎Aug 19, ‎2021, ‏‎22:51:56)
* Desc: WIP

* Usage: TODO
]]


local maplines = {}


local function R_WorldToScreen2(p, cam, target)

	-- local sx = cam.angle - R_PointToAngle2(p.mo.x, p.mo.y, target.x, target.y)
	local sx = cam.angle - R_PointToAngle(target.x, target.y)
	local visible = false

	-- Get the h distance from the target
	local hdist = R_PointToDist(target.x, target.y)
	-- print(AngleFixed(sx)/FU )
	if sx > ANGLE_90 or sx < ANGLE_270 then
		-- sx = 0 -- return {x=0, y=0, scale=0}
		visible = false
	else
		sx = FixedMul(160*FU, tan($1)) + 160*FU
		visible = true
	end

	-- local sx = 160*FU + (160 * tan(cam.angle - R_PointToAngle(target.x, target.y)))
	-- local sy = 100*FU + (100 * (tan(cam.aiming) - FixedDiv(target.z, hdist)))
	local sy = 100*FU + 160 * (tan(cam.aiming) - FixedDiv(target.z-cam.z, 1 + FixedMul(hdist, cos(cam.angle - R_PointToAngle(target.x, target.y))) ))
	
	-- local c = cos(p.viewrollangle)
	-- local s = sin(p.viewrollangle)
	-- sx = $1+FixedMul(c, target.x) + FixedMul(s, target.y)
	-- sy = $1+FixedMul(c, target.y) - FixedMul(s, target.x)

	local ss = FixedDiv(160*FU, hdist)

	return {x=sx, y=sy, scale=ss, inview=visible}
end


hud.add(function(v, stplyr, cam)


	for mobj in mobjs.iterate() do
		if mobj.type == MT_BLUECRAWLA then
		-- if mobj.type == MT_TOKEN then
			local screencoords = R_WorldToScreen2(stplyr, cam, mobj)
			if screencoords.inview then
				v.drawString(screencoords.x/FU, screencoords.y/FU, "Text", V_ALLOWLOWERCASE, "thin-center")
				-- v.drawScaled(screencoords.x, screencoords.y, screencoords.scale+FU*2/3, v.cachePatch("CROSHAI1"), 0)
			end
		end
	end

	-- for i=1,#maplines do
	-- 	local ln = maplines[i]
	-- 	local screencoords = R_WorldToScreen2(stplyr, cam, {x=ln.v1.x,y=ln.v1.y,z=ln.frontsector.floorheight})
	-- 	local screencoords_b = R_WorldToScreen2(stplyr, cam, {x=ln.v1.x,y=ln.v1.y,z=(ln and ln.backsector) and ln.backsector.floorheight or 0})

	-- 	v.drawScaled(screencoords.x, screencoords.y, screencoords.scale+FU*2/3, v.cachePatch("CROSHAI1"), 0)
	-- 	v.drawScaled(screencoords_b.x, screencoords_b.y, screencoords_b.scale+FU*2/3, v.cachePatch("CROSHAI1"), 0)
	-- end
end, "game")


addHook("MapLoad", function(g)
	for line in lines.iterate do
		table.insert(maplines, line)
	end
end)

addHook("ThinkFrame", function()

	for player in players.iterate do
		-- player.viewrollangle = $1+ANG1
	end
end)
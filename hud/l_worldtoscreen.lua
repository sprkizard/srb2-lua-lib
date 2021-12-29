--[[
* l_worldtoscreen.lua
* (sprkizard)
* (‎Aug 19, ‎2021, ‏‎22:51:56)
* Desc: WIP

* Usage: TODO
]]

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

	return {x=sx, y=sy, scale=ss, onscreen=visible}
end

rawset(_G, "R_WorldToScreen2", R_WorldToScreen2)



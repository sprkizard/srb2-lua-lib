--[[
* l_parabola.lua
* (sprkizard, fickleheart, Nev3r)
* (May 11, 2020 15:13)
* Desc: Parabolic trajectory drawing, and launching

* Usage:
        
        
        

]]




local function P_DrawArc(source, distance, thrust)
	--(a/2) * (x^2) + b*x + c
	for i=1,64 do
		local zt = (thrust + gravity/4) * i - (gravity/2)*i^2
		local arc = P_SpawnMobj(
				source.x+cos(source.angle)*i*distance, 
				source.y+sin(source.angle)*i*distance,
				source.z+(source.height+8*FRACUNIT)+zt,
				MT_THOK)

		arc.scale = FRACUNIT/6
		arc.color = SKINCOLOR_RED
		arc.tics = 2
		--arc.flags = $1&~MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
	end
end

local function P_ArcThrow(source, distance, thrust, mobjtype)

	local arc = P_SpawnMobj(source.x, source.y, source.z+(source.height+8*FRACUNIT), mobjtype)

	arc.momz = thrust
	P_InstaThrust(arc, source.angle, distance*FRACUNIT)
	--arc.tics = 444 arc.fuse = 353
	arc.flags = $1&~MF_NOGRAVITY

end


rawset(_G, "P_DrawArc", P_DrawArc)
rawset(_G, "P_ArcThrow", P_ArcThrow)


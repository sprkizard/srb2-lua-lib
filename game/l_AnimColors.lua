--[[
* l_AnimColors.lua
* (sprkizard)
* (July 10, 2020 14:35)
* Desc: -- Takes a list of ramps, and mashes them together into
		an animtable for skincolor ramps (unsafe?)
		https://wiki.srb2.org/wiki/List_of_skin_colors

* Usage: (See example skin Dreamy or Blackwave)
]]




freeslot("SKINCOLOR_BLACKWAVE") 
skincolors[SKINCOLOR_BLACKWAVE] = {
	name = "Animated",
	-- ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	ramp = {0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30},
	chatcolor = V_GRAYMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_BLACKWAVE, SKINCOLOR_BLUE)

rawset(_G, "AnimColors", {})

AnimColors.chromeloop = {
	startpos = 1,
	type = "test",
	ramp = {
		0,0,0,0,0,0,0,0,0,0,
		31,31,31,31,31,31,31,31,31,31
	},
}

--[[
32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,
		46,45,44,43,42,41,40,39,38,37,36,35,34,33

local blackramp = {
	0,0,0,0,0,0,0,0,0,0,
	31,31,31,31,31,31,31,31,31,31
}

local abm = {10,20,30,40,50,60,70,80,90,100,110,120,130,140,150}
--]]


local function P_AnimateSkinColor(skincolornum, animdef)

	local max = #skincolors[skincolornum].ramp
	local skinramp = skincolors[skincolornum].ramp

	-- local animpos = animdef.startpos

	if (animdef.type == "test") then

		animdef.startpos = $ < #animdef.ramp and $1+1 or 1

		for i=0,15 do
			skincolors[skincolornum].ramp[i] = animdef.ramp[((animdef.startpos+i) % #animdef.ramp)+1]
		end
	elseif (animdef.type == "idk")
	--[[elseif (antype == "flatscroll") then
		skincolors[skincolornum].ramp[(leveltime % max)] = ramp[(leveltime/max % #ramp)+1]
	elseif(antype == "flatflash") then
		for i=0,max do
			skincolors[skincolornum].ramp[i] = ramp[leveltime % #ramp]
		end
	elseif (antype == "flatbounce") then
		for i=0,max-1 do
			local b = abs(cos(ANG1*leveltime)*#ramp)/FRACUNIT
			skincolors[skincolornum].ramp[i] = ramp[b]
		end--]]
	end
end

addHook("ThinkFrame", function()

	print(string.format("{%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d}", 
		skincolors[SKINCOLOR_BLACKWAVE].ramp[0],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[1],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[2],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[3],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[4],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[5],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[6],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[7],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[8],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[9],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[10],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[11],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[12],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[13],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[14],
		skincolors[SKINCOLOR_BLACKWAVE].ramp[15]
	))

	P_AnimateSkinColor(SKINCOLOR_BLACKWAVE, AnimColors.chromeloop)
	-- P_AnimateSkinColor(SKINCOLOR_BLACKWAVE, blackramp, "test")

	if (server) then server.mo.color = SKINCOLOR_BLACKWAVE end

end)


-- REFERENCE CODE FROM SWITCHKAZE
--[[freeslot("SKINCOLOR_ANIMATED")
skincolors[SKINCOLOR_ANIMATED] = {
    name = "Animated",
    accessible = true
}

local test = {
    0,0,0,0,0,0,0,0,0,0,
    31,31,31,31,31,31,31,31,31,31
}

local pos = 1
addHook("ThinkFrame", do
    pos = $<#test and $1+1 or 1
    for i=0,15
        skincolors[SKINCOLOR_ANIMATED].ramp[i] = test[((pos+i)%#test)+1]
    end
end)--]]

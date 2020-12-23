--[[
* l_AnimColors.lua
* (sprkizard)
* (July 10, 2020 14:35)
* Desc: -- Takes a list of ramps, and mashes them together into
		an animtable for skincolor ramps (unsafe?)
		https://wiki.srb2.org/wiki/List_of_skin_colors

* Usage: (See example skin Dreamy or Blackwave)
]]

-- The animcolors global
rawset(_G, "AnimColors", {})

-- Concat. a list of ramps
function AnimColors.merge(...)

	local list = {...}
	local merged = {}

	for _,entry in pairs(list) do

		-- print(string.format("Table: %s", tostring(entry) ))
		local offset = (type(entry) == "userdata") and 1 or 0

		for i=(1-offset), (#entry-offset) do
			-- print(string.format("---Color: %s inserted!", entry[i]))
			table.insert(merged, entry[i])
		end
	end
	-- print("MERGED:")
	-- for k,v in pairs(merged) do
	-- 	print(v)
	-- end
	return merged
end

function AnimColors.reverse(ramp)
	local rev = {}

	local offset = (type(ramp) == "userdata") and 1 or 0

	for i=(#ramp-offset), (1-offset), -1 do
		table.insert(rev, ramp[i])
	end
	return rev
end







-- Example colors

freeslot("SKINCOLOR_GOLDRAMPWAVE") 
skincolors[SKINCOLOR_GOLDRAMPWAVE] = {
	name = "Gold Ramp Wave",
	ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	chatcolor = V_GRAYMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_GOLDRAMPWAVE, SKINCOLOR_BLUE)

AnimColors.r_goldwave = {
	startpos = 1,
	type = "ramp",
	style = "wave",
	delay = 4,
	ramp = {
		skincolors[SKINCOLOR_SUPERGOLD1].ramp,
		skincolors[SKINCOLOR_SUPERGOLD2].ramp,
		skincolors[SKINCOLOR_SUPERGOLD3].ramp,
		skincolors[SKINCOLOR_SUPERGOLD4].ramp,
		skincolors[SKINCOLOR_SUPERGOLD5].ramp,
	},
}

freeslot("SKINCOLOR_GOLDWAVE") 
skincolors[SKINCOLOR_GOLDWAVE] = {
	name = "Gold Color Wave",
	ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	chatcolor = V_GRAYMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_GOLDWAVE, SKINCOLOR_GOLDRAMPWAVE)

AnimColors.goldwave = {
	startpos = 1,
	type = "palette",
	style = "wave",
	delay = 1,
	ramp = AnimColors.merge(
		skincolors[SKINCOLOR_SUPERGOLD1].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD1].ramp),
		skincolors[SKINCOLOR_SUPERGOLD2].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD2].ramp),
		skincolors[SKINCOLOR_SUPERGOLD3].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD3].ramp),
		skincolors[SKINCOLOR_SUPERGOLD4].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD4].ramp),
		skincolors[SKINCOLOR_SUPERGOLD5].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD5].ramp),
		skincolors[SKINCOLOR_SUPERGOLD4].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD4].ramp),
		skincolors[SKINCOLOR_SUPERGOLD3].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD3].ramp),
		skincolors[SKINCOLOR_SUPERGOLD2].ramp,
		AnimColors.reverse(skincolors[SKINCOLOR_SUPERGOLD2].ramp)
	),
}


freeslot("SKINCOLOR_GOLDBOUNCE") 
skincolors[SKINCOLOR_GOLDBOUNCE] = {
	name = "Gold (Bounce)",
	ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	chatcolor = V_GRAYMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_GOLDBOUNCE, SKINCOLOR_GOLDWAVE)

AnimColors.superbounce = {
	startpos = 1,
	type = "ramp",
	style = "bounce",
	delay = 2,
	ramp = {
		skincolors[SKINCOLOR_SUPERGOLD1].ramp,
		skincolors[SKINCOLOR_SUPERGOLD2].ramp,
		skincolors[SKINCOLOR_SUPERGOLD3].ramp,
		skincolors[SKINCOLOR_SUPERGOLD4].ramp,
		skincolors[SKINCOLOR_SUPERGOLD5].ramp
	},
}


freeslot("SKINCOLOR_REDWAVE") 
skincolors[SKINCOLOR_REDWAVE] = {
	name = "Red Wave",
	ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	chatcolor = V_GRAYMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_REDWAVE, SKINCOLOR_GOLDBOUNCE)

AnimColors.redwave = {
	startpos = 1,
	type = "palette",
	style = "wave",
	delay = 3,
	ramp = {
		32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,
		47,46,45,44,43,42,41,40,39,38,37,36,35,34,33
	},
}

freeslot("SKINCOLOR_CRAINBOW") 
skincolors[SKINCOLOR_CRAINBOW] = {
	name = "Rainbow Wave",
	ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	chatcolor = V_GRAYMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_CRAINBOW, SKINCOLOR_REDWAVE)

AnimColors.rainbowwave = {
	startpos = 1,
	type = "palette",
	style = "wave",
	delay = 2,
	ramp = {
		47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,
		176,177,178,179,180,181,182,183,184,185,186,187,
		199,198,197,196,195,194,193,192,
		160,161,162,163,164,165,166,167,168,169,
		159,158,157,156,155,154,153,152,151,150,149,148,147,146,145,144,
		128,129,130,131,132,133,134,135,136,137,138,139,
		111,110,109,108,107,106,105,104,103,102,101,100,99,98,97,96,
		88,89,90,91,92,93,94,95,
		79,78,77,76,75,74,73,72,
		48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,
	},
}

--[[

local blackramp = {
	0,0,0,0,0,0,0,0,0,0,
	31,31,31,31,31,31,31,31,31,31
}

local abm = {10,20,30,40,50,60,70,80,90,100,110,120,130,140,150}
--]]


local function P_AnimateSkinColor(skincolornum, animdef)

	if (animdef.style == "wave") then

		if (leveltime % animdef.delay) then return end -- set delay speed

		-- This is the range that normally appears (max -> 1)
		animdef.startpos = ($ > 1) and $1-1 or #animdef.ramp

		-- Decide on if the ramp table is only colors, or using a full ramp
		if (animdef.type == "palette") then
			for i=15,0,-1 do
				skincolors[skincolornum].ramp[i] = animdef.ramp[((animdef.startpos+i) % #animdef.ramp)+1]
			end
		else
			skincolors[skincolornum].ramp = animdef.ramp[((animdef.startpos) % #animdef.ramp)+1]
		end

	elseif (animdef.style == "wavereverse") then

		if (leveltime % animdef.delay) then return end -- set delay speed

		-- 1 -> max (appears as reversed)
		animdef.startpos = ($ < #animdef.ramp) and $1+1 or 1

		-- Decide on if the ramp table is only colors, or using a full ramp
		if (animdef.type == "palette") then
			for i=0,15 do
				skincolors[skincolornum].ramp[i] = animdef.ramp[((animdef.startpos+i) % #animdef.ramp)+1]
			end
		else
			skincolors[skincolornum].ramp = animdef.ramp[((animdef.startpos) % #animdef.ramp)+1]
		end

	elseif (animdef.style == "bounce") then

		if (leveltime % animdef.delay) then return end -- set delay speed

		-- Get the bounce speed
		if not animdef.dir then animdef.dir = 1 end

		-- Swap directions on ramp edges
		if (animdef.startpos <= 1) then animdef.dir = 1
		elseif (animdef.startpos >= #animdef.ramp) then animdef.dir = -1 end

		animdef.startpos = $1+1*animdef.dir

		-- Decide on if the ramp table is only colors, or using a full ramp
		if (animdef.type == "palette") then
			-- Cycle colors through ramp
			for i=0,15 do
				skincolors[skincolornum].ramp[i] = animdef.ramp[((animdef.startpos+i) % #animdef.ramp)+1]
			end
		else
			-- Cycle ramps
			skincolors[skincolornum].ramp = animdef.ramp[animdef.startpos]
		end

	elseif (animdef.style == "shift") then

		-- The original scroll error is so silly that it should be kept as a type
		animdef.startpos = ($ < #animdef.ramp) and $1+1 or 1

		skincolors[skincolornum].ramp[(leveltime % 16)] = animdef.ramp[(animdef.startpos % #animdef.ramp)+1]
	
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

	--[[print(string.format("{%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d}", 
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
	))--]]

	P_AnimateSkinColor(SKINCOLOR_GOLDRAMPWAVE, AnimColors.r_goldwave)
	P_AnimateSkinColor(SKINCOLOR_GOLDWAVE, AnimColors.goldwave)
	P_AnimateSkinColor(SKINCOLOR_GOLDBOUNCE, AnimColors.superbounce)
	P_AnimateSkinColor(SKINCOLOR_REDWAVE, AnimColors.redwave)
	P_AnimateSkinColor(SKINCOLOR_CRAINBOW, AnimColors.rainbowwave)
	-- P_AnimateSkinColor(SKINCOLOR_BLACKWAVE, blackramp, "test")

	-- if (server) then server.mo.color = SKINCOLOR_BLACKWAVE end

end)

rawset(_G, "P_AnimateSkinColor", P_AnimateSkinColor)


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

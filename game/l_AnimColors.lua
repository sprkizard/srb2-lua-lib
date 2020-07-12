--[[
* l_AnimColors.lua
* (sprkizard)
* (July 10, 2020 14:35)
* Desc: -- Takes a list of ramps, and mashes them together into
		an animtable for skincolor ramps (unsafe?)
		https://wiki.srb2.org/wiki/List_of_skin_colors

* Usage: (See example skin Dreamy or Blackwave)
]]



local function M_BuildRampAnim(an_skcolors, newRamp)

	an_skcolors.colors = {}

	-- Iterate through skcolors
	--print("Anim Size: " .. #an_skcolors)
	for i=1,#an_skcolors do

		---- Color ramp table of this specific skincolor
		local sk_color = an_skcolors[i] -- skincolor
		local skc_name = an_skcolors[i].name or "none" -- skincolor name
		local skc_ramp = an_skcolors[i].ramp -- skincolor ramp

		--print("Ramp Size of ["..skc_name.."]: " .. #skc_ramp)

		-- Iterate through ramp entries
		for e=1, #skc_ramp do
			-- Vanilla colors are indexed diffrently by 1 (?)
			if (type(skc_ramp) == "userdata") then e = $1-1 else end
			--print("Entry ("..tostring(e)..") - "..tostring(skc_ramp[e]))
			table.insert(an_skcolors.colors, skc_ramp[e])
		end

		-- Now go reversed!
		if (sk_color.reverse and sk_color.reverse == true) then
			for e=#skc_ramp, 1, -1 do
				-- Vanilla colors are indexed diffrently by 1 (?)
			if (type(skc_ramp) == "userdata") then e = $1-1 else end
				--print("Entry ("..tostring(e)..") - "..tostring(skc_ramp[e]))
				table.insert(an_skcolors.colors, skc_ramp[e])
			end
		end
	end
	-- Remove leftovers except for the actual color ramp
	for i=1,#an_skcolors do
		table.remove(an_skcolors, i)
	end
end

--M_BuildRampAnim(anim_dreamy, animatedrampfull, false)

-- -- iterate  skincolors
-- for i=1,#skincolors-1 do

-- 	-- ramp table
-- 	local skincolor_ramp = skincolors[i].ramp

-- 	print ("Ramp numbers " .. #skincolor_ramp)
-- 	-- go over ramp colors
-- 	for j=0,#skincolor_ramp-1 do
-- 		print(skincolors[i].name .. "|" .. skincolor_ramp[j])
-- 		table.insert(all, skincolor_ramp[j])
-- 	end
-- 	--now go reverse!
-- 	for j=#skincolor_ramp-1, 0, -1 do
-- 		print(skincolors[i].name .. "|" .. skincolor_ramp[j])
-- 		table.insert(all, skincolor_ramp[j])
-- 	end
-- end

-- Rotates a table by inserting the last entry to the start and removing it afterwards
local function rotatetable(tbl, step)
    for i = 1, step do
        table.insert(tbl, 1, tbl[#tbl])
        table.remove(tbl, #tbl)
    end
end


addHook("ThinkFrame", function()

	--local colRamp = skincolors[SKINCOLOR_RADIANTPURPLE].ramp
	-- for i = 0, 15 do
		-- colRamp[i] = ($1+1) % 256
		--colRamp[i] = skincolors[count+i].ramp
	-- end
	-- wrap(ramp,1)
	-- skincolors[SKINCOLOR_RADIANTPURPLE].ramp = ramp
	-- count = (($1 + 1 ) % 56)
	-- skincolors[SKINCOLOR_RADIANTPURPLE].ramp = skincolors[count+i].ramp


	--wrap(anim_dreamy.colors, 1)
	wrap(anim_supergolden.colors, 1)
	--skincolors[SKINCOLOR_DREAMY].ramp = anim_dreamy.colors
	skincolors[SKINCOLOR_SUPERGOLDEN].ramp = anim_supergolden.colors
end)

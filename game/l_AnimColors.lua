--[[
* l_AnimColors.lua
* (sprkizard)
* (July 10, 2020 14:35)
* Desc: -- Takes a list of ramps, and mashes them together into
		an animtable for skincolor ramps (unsafe?)
		https://wiki.srb2.org/wiki/List_of_skin_colors

* Usage: (See example skin Dreamy or Blackwave)
]]



local function M_ConvertRampAnim(an_skcolors)

	local outputRamp = {}

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
			table.insert(outputRamp, skc_ramp[e])
		end

		-- Now go reversed!
		if (sk_color.reverse and sk_color.reverse == true) then
			for e=#skc_ramp, 1, -1 do
				-- Vanilla colors are indexed diffrently by 1 (?)
			if (type(skc_ramp) == "userdata") then e = $1-1 else end
				--print("Entry ("..tostring(e)..") - "..tostring(skc_ramp[e]))
				table.insert(outputRamp, skc_ramp[e])
			end
		end
	end
	-- Wipes the original table and converts it to a usable ramp
	-- (if all else fails, revert to newOutputRamp)
	an_skcolors = {}
	return outputRamp
end



-- Rotates a table by inserting the last entry to the start and removing it afterwards
local function rotatetable(tbl, step)
    for i = 1, step do
        table.insert(tbl, 1, tbl[#tbl])
        table.remove(tbl, #tbl)
    end
end



local function M_AnimColorThink(skinColor, animRamp, step)
	rotatetable(animRamp, step)
	skincolors[skinColor].ramp = animRamp
end

rawset(_G, "M_BuildRampAnim", M_BuildRampAnim)
rawset(_G, "M_AnimColorThink", M_AnimColorThink)

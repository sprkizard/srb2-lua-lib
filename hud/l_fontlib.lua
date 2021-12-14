
rawset(_G, "Fontlib", {})

Fontlib.fontinfo = {
	["STCFN"] = {width=8},
	["TNYFN"] = {width=5},
	["LTFNT"] = {width=20},
	["TTL"] = {width=29},
	["CRFNT"] = {width=16},
	["NTFNT"] = {width=16},
	["NTFNO"] = {width=20},
}

-- Returns the width what the string as patches would be,
-- and returns all cached patches in a table
-- function Fontlib.GetInternalFontWidth(str, font)
function Fontlib.cachePatchWidth(v, str, font)

	-- No string
	if not (str) then return 0 end

	local patches = {}
	local width = 0

	for i=1,#str do

		local char = str:sub(i)
		-- Spaces before fonts
		if char:byte() == 32 then
			width = $1+4
			continue
		end
		-- Ignore skincolors completely
		if char:byte() >= 131 and char:byte() <= 198 then
			continue
		end
		-- TODO: count special characters?
		if char:byte() >= 200 then
			width = $1+8
			continue
		end

		-- Cache patches assigned by byte number
		-- TODO: some fonts have different byte offsets and digit amounts in names
		-- if not (patches[char:byte()]) then
			-- Avoid caching the same character twice
			patches[char:byte()] = v.cachePatch( string.format("%s%03d", font, char:byte()) )
		-- end
		width = $1 + patches[char:byte()].width

		-- (Get font width info)
		-- for fontname, attr in pairs(Fontlib.fontinfo) do
		-- 	if (font == fontname) then
		-- 		width = $1 + attr.width
		-- 		break
		-- 	end
		-- end

		--[[for i=1,#Fontlib.fontinfo do
			if (font == Fontlib.fontinfo[i].font) then
				width = $1 + Fontlib.fontinfo[i].width
				break
			end
		end--]]

		-- if (font == "STCFN") then -- default font
		-- 	width = $1+8
		-- elseif (font == "TNYFN") then
		-- 	width = $1+7
		-- elseif (font == "LTFNT") then
		-- 	width = $1+20
		-- elseif (font == "TTL") then
		-- 	width = $1+29
		-- elseif (font == "CRFNT" or font == "NTFNT") then -- TODO: Credit font centers wrongly
		-- 	width = $1+16
		-- elseif (font == "NTFNO") then
		-- 	width = $1+20
		-- else
		-- 	width = $1+8
		-- end
	end
	return {patches=patches, width=width}
end

function Fontlib.drawString(v, sx, sy, text, flags, align)

	-- Scale adjustments
	local scale = (flags and flags.scale) or FRACUNIT

	-- Text Font
	local font = (flags and flags.font) or "STCFN"



	-- Split our string into new lines from line-breaks
	local lines = {}

	for breaks in text:gmatch("[^\r\n]+") do
		table.insert(lines, breaks)
	end

	-- Interate through the text blocks
	for seg=1,#lines do

		local line = lines[seg]

		-- Screen x and y positions
		local x = sx
		local y = sy
		local width = 0

		-- Current character & font patch (hopeful optimization)
		local char
		local charpatch

		-- Fixed is no longer an alignment option, and is now a flag
		if not (flags and flags.fixed) then
			x = $1 << FRACBITS
			y = $1 << FRACBITS
		end

		-- local patches = {}
		-- for pos=1,#line do
		-- 	char = line:sub(pos, pos)
		-- 	if not char:byte() or char:byte() == 32 then
		-- 		return
		-- 	end
		-- 	patches[string.byte(char)] = v.cachePatch( string.format("%s%03d", font, string.byte(char)) )
		-- 	width = $1 + patches[char:byte()].width
		-- end
		-- print(Fontlib.cachePatchWidth(v, line, font).width)
		-- break
		-- print
		local patches = Fontlib.cachePatchWidth(v, line, font).patches
		local width = Fontlib.cachePatchWidth(v, line, font).width
		-- TODO: not working correctly for CRFNT
		-- Text block alignment settings
		if (align == "center") then
			x = $1-FixedMul( width/2, scale) << FRACBITS
			-- x = $1-FixedMul( (Fontlib.GetInternalFontWidth(line, font)/2), scale) << FRACBITS
		elseif (align == "right") then
			x = $1-FixedMul( width, scale) << FRACBITS
			-- x = $1-FixedMul( (Fontlib.GetInternalFontWidth(line, font)), scale) << FRACBITS
		end

		v.drawString(320/2, 150+seg*8, "Line Length: "+#line, 0, "thin")

		-- 
		for pos=1,#line do
			(function()

				-- String sub each character
				char = line:sub(pos, pos)
				
				-- Skip and replace spaces
				if not char:byte() or char:byte() == 32 then
					x = $1+4*scale
					return
				end

				-- Transform the char to a font patch
				-- charpatch = v.cachePatch( string.format("%s%03d", font, string.byte(char)) )

				-- Draw the current character given
				v.drawStretched(x, y, 1*FU, 1*FU, patches[char:byte()], 0, color)

				-- Sets the space between each character using the font's width
				x = $1 + (0+patches[char:byte()].width)*scale

			end)()
		end

		-- Break new lines by spacing and patch width for semi-accurate spacing
		local linespacing = FixedMul((4+patches[char:byte()].height)*FU, scale)
		sy = $1 + ((flags and flags.fixed) and linespacing or linespacing >> FRACBITS)

	end
end






hud.add(function(v, stplyr, cam)
	v.drawFill(320/2, 0, 1, v.height(), 35)

	-- Vanilla
	-- v.drawString(320/2, 64, "Fontlib\n-Version 2-\nCustom Text Drawer", 0, "left")

	-- Fontlib
	Fontlib.drawString(v, 320/2, 4, "ABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n`1234567890-=\n~!@#$%^&*()_+\n[]\\;',./\n{}|:\"<>?", {font="TNYFN"}, "center")
	-- Fontlib.drawString(v, 320/2, 4, "0123456789", {font="TNYFN"}, "center")
	-- Fontlib.drawString(v, 320/2, 64, string.upper("Fontlib\n-Version 2-\nCustom Text Drawer"), {}, "left")
	-- Fontlib.drawString(v, 320/2, 4, "Fontlib\nwith\nnewlines\n1000000\n2000000\n3000000", {font="TNYFN"}, "center")
	-- Fontlib.drawString(v, 320/2, 130, "Fontlib", {}, "center")
	-- Fontlib.drawString(v, 320/2*FU, 140*FU, "Fontlib", {fixed=true}, "center")
	-- Fontlib.drawString(v, 320/2*FU, 150*FU, "Fontlib fixed with\nspaces+newline", {fixed=true}, "center")
	-- Fontlib.drawString(v, 320/2, 170, "Fontlib\nwith\nnewlines", {}, "center")
	-- Fontlib.drawString(v, 320/2*FU, 150*FU, "Fontlib\n-Version 2-\nCustom Text Drawer", {fixed=true}, "center")
					  --(v, x, y, str, flags, align)

end, "game")


hud.add(function(v, stplyr, cam)
	-- v.drawFill(320/2, 0, 1, v.height(), 35)

	-- Vanilla
	-- v.drawString(320/2, 64, "Fontlib\n-Version 2-\nCustom Text Drawer", 0, "left")

	-- Fontlib
	-- drawSuperText(v, 320/2, 80, "0123456789", {})

end, "game")
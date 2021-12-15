
rawset(_G, "Fontlib", {})

Fontlib.fontinfo = {
	["STCFN"] = {},
	["TNYFN"] = {},
	["LTFNT"] = {},
	["TTL"] = {},
	["CRFNT"] = {upperonly=true},
	["NTFNT"] = {upperonly=true},
	["NTFNO"] = {},
}

-- Returns the width what the string as patches would be,
-- and returns all cached patches in a table
-- function Fontlib.GetInternalFontWidth(str, font)
function Fontlib.cachePatchWidth(v, str, font, space)

	-- No string
	if not (str) then return 0 end

	local patches = {}
	local width = 0

	for i=1,#str do

		local char = str:sub(i,i)

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

		-- TODO: some patches do not exist, and the fix below may not be enough
		if not (v.patchExists(string.format("%s%03d", font, char:byte()))) then patches[char:byte()] = nil continue end
		
		-- Cache patches assigned by byte number
		-- TODO: some fonts have different byte offsets and digit amounts in names
		if not (patches[char:byte()]) then
			-- Avoid caching the same character twice
			patches[char:byte()] = v.cachePatch( string.format("%s%03d", font, char:byte()) )
		end
		width = $1 + (patches[char:byte()].width or 8) + space

	end
	return {patches=patches, linewidth=width}
end

function Fontlib.invalidCharPatch(patchlist, char)
	return patchlist[char:byte()] == nil and true or false
end

function Fontlib.drawString(v, sx, sy, text, flags, align)

	-- Constants
	local spacewidth = 4

	-- Scale adjustments
	local scale = (flags and flags.scale) or FRACUNIT
	local hscale = (flags and flags.hscale) or 0
	local vscale = (flags and flags.vscale) or 0
	
	-- Spacing
	local xspace = (flags and flags.xspace) or 0 -- TODO: inconsistent width problem again
	local yspace = (flags and flags.yspace) or spacewidth
	
	-- Font Options
	local font = (flags and flags.font) or "STCFN"
	-- local uppercs = (flags and flags.upper) or false -- TODO: broken


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

		-- Current character & font patch (hopeful optimization)
		local char
		local charpatch

		-- Fixed is no longer an alignment option, and is now a flag
		if not (flags and flags.fixed) then
			x = $1 << FRACBITS
			y = $1 << FRACBITS
		end

		-- Get used character patches and the width of the line
		local cache = Fontlib.cachePatchWidth(v, line, font, xspace)
		-- local cache = Fontlib.cachePatchWidth(v, line, font).patches
		-- local width = Fontlib.cachePatchWidth(v, line, font).width

		-- Modify widths for spacing adjustments before setting alignment
		-- if xspace then width = $1+xspace*spacewidth end

		-- Text block alignment settings
		if (align == "center") then
			x = $1-FixedMul( cache.linewidth/2, scale) << FRACBITS
		elseif (align == "right") then
			x = $1-FixedMul( cache.linewidth, scale) << FRACBITS
		end


		-- v.drawString(320/2, 150+seg*8, "Line Length: "+#line, 0, "thin")
		for pos=1,#line do
			(function()

				-- String sub each character
				char = line:sub(pos, pos)
				
				-- DOES NOTHING FURTHER IF CHARACTER HAS NO PATCH
				if (Fontlib.invalidCharPatch(cache.patches, char)) then return end
				-- if (patches[char:byte()]) == nil then return end

				-- Skip and replace spaces
				if not char:byte() or char:byte() == 32 then
					x = $1+spacewidth*scale
					return
				end

				-- TODO: broken, should be probably be done in caching
				-- Unavoidable non V_ALLOWLOWERCASE flag toggle (exclude specials above 210)
				if (Fontlib.fontinfo[font].upperonly) --(font == "CRFNT" or font == "NTFNT"))
				and not (char:byte() >= 210) then
					char = tostring(char):upper()
				end

				-- Draw the current character given
				v.drawStretched(x, y, scale+hscale, scale+vscale, cache.patches[char:byte()], 0, color)

				-- Sets the space between each character using the font's width
				x = $1 + (xspace+cache.patches[char:byte()].width)*scale

			end)()
		end
		
		if (Fontlib.invalidCharPatch(cache.patches, char)) then continue end
		-- if (patches[char:byte()]) == nil then continue end

		-- Break new lines by spacing and patch height for source-accurate spacing
		local linespacing = FixedMul( (yspace+cache.patches[char:byte()].height)*FU, scale )
		sy = $1 + ((flags and flags.fixed) and linespacing or linespacing >> FRACBITS)

	end
end






hud.add(function(v, stplyr, cam)
	v.drawFill(320/2, 0, 1, v.height(), 35)

	-- Vanilla
	-- v.drawString(320/2, 64, "Fontlib\n-Version 2-\nCustom Text Drawer", 0, "left")

	-- Fontlib
	Fontlib.drawString(v, 320/2, 4, "Fontlib\nv2\ncentered\nLines", {font="STCFN", scale=FU}, "center")
	-- Fontlib.drawString(v, 320/2, 4, "aBABcdFefG", {font="NTFNT"}, "center")
	-- Fontlib.drawString(v, 320/2, 14, "AAAAAAA", {font="NTFNT"}, "center")
	-- Fontlib.drawString(v, 320/2, 4, "ABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n`1234567890-=\n~!@#$%^&*()_+\n[]\\;',./\n{}|:\"<>?", {font="NTFNT"}, "center")
	
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



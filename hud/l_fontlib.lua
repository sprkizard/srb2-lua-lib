--[[
* l_fontlib.lua
* (sprkizard)
* (Dec 6, 2021 16:51)
* Desc: A custom drawstring function that can 
		use custom font sets

* Usage: TODO
]]

rawset(_G, "Fontlib", {})

Fontlib.defaultspace = 4
Fontlib.defaultreturn = 4

Fontlib.fontinfo = {
	["CRFNT"] = {upperonly=true},
	["LTFNT"] = {},
	["NTFNO"] = {},
	["NTFNT"] = {upperonly=true},
	["STCFN"] = {spacewidth=4, returnheight=4},
	["TNYFN"] = {spacewidth=2, returnheight=5},
}

-- Creates an entry for custom font info (width between letters, return spacing, etc)
function Fontlib.setFontAttr(font, t)
	
	Fontlib.fontinfo[font] = {}
	for k,v in pairs(t) do
		Fontlib.fontinfo[font][k] = v
	end
end

-- Checks if the fontinfo entry exists, and gets the supplied attribute of it
function Fontlib.getFontAttr(font, attr)
	return (Fontlib.fontinfo[font] and Fontlib.fontinfo[font][attr])
end

-- Wrapper for validating table contents used here, and using them
function Fontlib.getAttr(t, key, attr)
	return (t[key] and t[key][attr])
end

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

		-- Spaces before fonts. Use accurate font space widths or revert to defaults
		if char:byte() == 32 then
			width = $1 + (Fontlib.getFontAttr(font, "spacewidth") or 4)
			continue
		end
		-- Ignore skincolors completely
		if char:byte() >= 131 and char:byte() <= 199 then
			continue
		end
		-- TODO: count special characters?
		if char:byte() >= 200 and char:byte() <= 203 then
			-- width = $1+8
			continue
		end

		-- Create patch name format
		local patchname = string.format("%s%03d", font, char:byte())

		-- TODO: some patches do not exist, and the fix below may not be enough
		if not (v.patchExists(patchname)) then patches[char:byte()] = nil continue end
		
		-- Cache patches assigned by byte number
		if not (patches[char:byte()]) then
			-- Avoid caching the same character twice
			patches[char:byte()] = v.cachePatch( patchname )
		end
		width = $1 + (patches[char:byte()].width or 8) + space

	end
	return {patches=patches, linewidth=width}
end

function Fontlib.invalidCharPatch(patchlist, char)
	return patchlist[char:byte()] == nil and true or false
end

-- TODO: separate text effects
-- function Fontlib.stringEffects(x, y, char, time)
-- end

-- TODO: Find a way to capture embedded flags
-- (eg. Font swapping with format: t[font..char:byte()] to cache multiple characters))
--[[function Fontlib.gettextflag()
	local keypos = 0
	local ahead = 0

	if keypos and (pos >= keypos and pos <= ahead) then return end
	if line:sub(pos, pos+5) == "<test:" then
		
		keypos = pos
		ahead = pos+6

		local capture = ""

		for j=ahead, #line do
			if (line:sub(j, j) == ">") ahead = $1+#capture break end
			capture = $1 .. line:sub(j, j)
			-- print(keypos.."|"..str:sub(j, j))
		end
		x = capture
		return
	end
end--]]


function Fontlib.drawString(v, sx, sy, text, flags, align)

	-- Font Options
	local font = (flags and flags.font) or "STCFN"
	local uppercs = (flags and flags.upper) or false
	local ramp = (flags and flags.ramp) or nil -- Custom rainbow color
	local marspeed = (flags and flags.marspeed) or 4 -- Rainbow marquee speed
	local color = nil

	-- Constants
	local spacewidth = (Fontlib.getFontAttr(font, "spacewidth") or 4)

	-- Scale adjustments
	local scale = (flags and flags.scale) or FRACUNIT
	local hscale = (flags and flags.hscale) or 0
	local vscale = (flags and flags.vscale) or 0
	
	-- Spacing
	local xspace = (flags and flags.xspace) or 0
	local yspace = (flags and flags.yspace) or (Fontlib.getFontAttr(font, "returnheight") or 4)
	


	-- Split our string into new lines from line-breaks
	local lines = {}

	for breaks in text:gmatch("[^\r\n]+") do
		table.insert(lines, breaks)
	end

	-- Interate through the text blocks (alignment should always go last before char drawing)
	for seg=1,#lines do

		local line = lines[seg]

		-- Screen x and y positions
		local x = sx
		local y = sy

		-- Text effects
		local off_x = 0
		local off_y = 0
		local swirl = 0
		local shake = 0
		local rainbow = 0
		local rcolors = ramp or {SKINCOLOR_SALMON,SKINCOLOR_ORANGE,SKINCOLOR_YELLOW,SKINCOLOR_MINT,SKINCOLOR_SKY,SKINCOLOR_PASTEL,SKINCOLOR_BUBBLEGUM}

		-- Current (+backwards) character & font patch (hopeful optimization)
		local bchar
		local char
		local charpatch

		-- Fixed is no longer an alignment option, and is now a flag
		if not (flags and flags.fixed) then
			x = $1 << FRACBITS
			y = $1 << FRACBITS
		end

		-- V_ALLOWLOWERCASE flag replacement
		if (uppercs or Fontlib.getFontAttr(font, "upperonly")) then
			line = tostring(line):upper()
		end

		-- Get used character patches and the width of the line
		-- TODO: character spacing does not work correctly
		local cache = Fontlib.cachePatchWidth(v, line, font, xspace)

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

				-- Text Effects
				-- TODO: separate text effects
				-- ========
				-- Text Effect: Rainbow color
				if (char:byte() == 199) then
					color = nil
					rainbow = leveltime/marspeed + #line
					return
				end

				-- Text Effect: Text color (Custom skincolors unsupported, only MAXSKINCOLORS allowed.)
				if (char:byte() == 130) then
					color = nil
					return
				elseif (char:byte() >= 131 and char:byte() <= 198) then
					color = v.getColormap(TC_DEFAULT, char:byte() - 130)
					rainbow = 0
					return
				end
				-- Stop effects
				if (char:byte() == 200) then
					swirl = 0
					shake = 0
					return
				end

				-- Text Effect: That one undertale groove effect
				if (char:byte() == 201) then
					swirl = leveltime*2
					shake = 0
					return
				end

				-- Text Effect: That one deltarune shake effect
				if (char:byte() == 202) then
					shake = (leveltime/1)*(leveltime/1)*3
					swirl = 0
					return
				end

				if (rainbow) then
					color = v.getColormap(TC_DEFAULT, rcolors[((rainbow-pos) % #rcolors)+1])
				end
				
				if (swirl) then
					swirl = $1+2
					off_x = (cos(ANG10*(swirl)))
					off_y = (sin(ANG10*(swirl)))
				end

				if (shake) then
					shake = ($1+1)*($1+FU)
					off_x = (cos(ANG10*shake))
					shake = ($1+1)*($1+FU)
					off_y = (sin(ANG10*shake))
				end
				-- ========

				-- Prevent spaces and non-existent characters from drawing altogether
				if not char:byte() or char:byte() == 32 then
					x = $1+spacewidth*scale
					return
				end

				-- Weird return spacing fix by getting the previous character
				bchar = line:sub(pos-1, pos)

				-- If a character has no patch: prevent from drawing
				if (Fontlib.invalidCharPatch(cache.patches, char)) then return end

				-- Draw the current character given
				v.drawStretched(x+off_x, y+off_y, scale+hscale, scale+vscale, cache.patches[char:byte()], 0, color or v.getColormap(TC_DEFAULT, 1))

				-- Sets the space between each character using the font's width
				x = $1 + (xspace+cache.patches[char:byte()].width)*scale

			end)()
		end
		-- For control code effects, try to get the last character height
		local cheight = Fontlib.getAttr(cache.patches, char:byte(), "height")
		local bcheight = Fontlib.getAttr(cache.patches, bchar:byte(), "height")
		-- Break new lines by spacing and patch height for source-accurate spacing
		local linespacing = FixedMul( (yspace + (cheight or bcheight or 4) )*FU, scale )
		sy = $1 + ((flags and flags.fixed) and linespacing or linespacing >> FRACBITS)

	end
end





-- Example
--[[hud.add(function(v, stplyr, cam)

	-- v.drawFill(320/2, 0, 1, v.height(), 35)

	-- Vanilla
	v.drawString(320/2, 0, "Fontlib\n-Version 2-\nCustom Text Drawer", 0, "left")

	-- Fontlib
	local text = "\201Fontlib\200\n-Version 2-\n\202Custom Text Drawer\200"
	Fontlib.drawString(v, 320/2, 32, text, {font="STCFN"}, "center")
	Fontlib.drawString(v, 320/2, 64, text, {font="CRFNT"}, "center")
	Fontlib.drawString(v, 320/2, 128, text, {font="LTFNT"}, "center")

end, "game")
--]]


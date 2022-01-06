--[[
* l_textboxes.lua
* (sprkizard)
* (October ‎26, ‎2020, 0:00)
* Desc: A rewrite of textboxes used in sugoi2, with
	a more minimalistic graphical style

* Usage: TODO: check wiki???

* Depends on:
	hudlayers
	EventStepThinker
]]

rawset(_G, "TextBox", {debug=true})
local textboxes = {
	-- {id=1, name="Amy Rose", text="Demo 1\nDemo 1\nDemo 1", icon=true, strcnt=0, showbg=1},
	-- {id=2, name=nil, text="Demo 2", icon=false, ax=320/2,ay=200/2, strcnt=0, showbg=1}
}

-- Show information when enabled
function TextBox.debug(v,x,y,textbox)
	if not TextBox.debug then return end
	local str = textbox.text:gsub("\n", " ")
	local info_output = string.format("ID: %d | Name: %s | Text: %s | Icon: %s | Printed: %d/%d | Auto: [%d/%d]| rel: (%d,%d) | abs: (%d,%d)", 
		textbox.id, tostring(textbox.name),str,tostring(textbox.icon),textbox.strcnt,#textbox.text,textbox.linetime,textbox.auto,textbox.rx or 0,textbox.ry or 0,textbox.ax or 0,textbox.ay or 0)
	v.drawString(x, y, info_output, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin")
end

-- Creates a new textbox 
function TextBox.new(id, name, text, args)
	if type(id) == "string" then print("Textbox ID must be a number!") return end

	-- Wipe the last id and overwrites it with a new under the same id
	if textboxes[id] then textboxes[id] = nil end

	local new_tb = {
		id = id,
		name = name,
		text = text,
		icon = (args and args.icon),
		linetime = 0,
		showbg = 1,
		strcnt = 0,-- + startpos,
		-- textsfx = (settings and settings.sfx) or sfx_none,
		auto = (args and args.auto) or 3*TICRATE,
		-- startpos = (settings and settings.startpos) or 0,
		-- speed = (settings and settings.speed) or 1,
		-- delay = (settings and settings.delay) or 1,
	}
	table.insert(textboxes, id or 1, new_tb)
end
function TextBox.Setconfig(id, settings)
	textboxes[id].textsfx = (settings and settings.sfx) or sfx_none
	textboxes[id].auto = (settings and settings.auto) or 3*TICRATE
	textboxes[id].startpos = (settings and settings.startpos) or 0
	textboxes[id].speed = (settings and settings.speed) or 1
	textboxes[id].delay = (settings and settings.delay) or 1
	textboxes[id].rx = (settings and settings.rx)
	textboxes[id].ry = (settings and settings.ry)
	textboxes[id].ax = (settings and settings.ax)
	textboxes[id].ay = (settings and settings.ay)
end

function TextBox.textbox_update()

	for id,textbox in pairs(textboxes) do
		
		-- Play a sound on each letter, skipping spaces and nl
		--[[if (textbox.textsfx) then
			if (textbox.strcnt < textbox.text:len())
			and not (textbox.text:sub(textbox.strcnt):byte() == 0 or textbox.text:sub(textbox.strcnt):byte() == 32)
			and (textbox.strcnt % textbox.speed == 0) then
				S_StartSound(nil, textbox.textsfx)
			end
		end--]]

		-- Check if we reached the end of the string, and clear textbox if we did
		if (textbox.strcnt >= textbox.text:len()) then

			-- We finish automatically on a set time, or end on button press
			if (textbox.auto and textbox.linetime < textbox.auto) then
				textbox.linetime = $1+1
			else
				TextBox.new(textbox.id, textbox.name, "Next")
				-- textboxes[id] = nil
			end
			-- if (textbox.auto and textbox.linetime < textbox.auto) then
			-- 	player.textbox.linetime = $1+1
			-- 	-- print(string.format("[text auto: %d/%d]", textbox.linetime, textbox.auto))
			-- elseif not (textbox.auto) and (player.cmd.buttons & BT_JUMP) then
			-- 	textbox.text = nil
			-- else
			-- 	textbox.text = nil -- set to automatically end for auto if neither
			-- end
		else
			-- Increment string.sub
			-- if (leveltime % textbox.delay == 0) then
				textbox.strcnt = min($1 + 1, textbox.text:len())
			-- end
			-- print(string.format("[text subcnt: %d/%d]", textbox.strcnt, textbox.text:len()))
		end
	end
end


function TextBox.textbox_drawer(a, v, stplyr, cam)

	-- TODO: center/right aligned math
	-- Screen settings
	local scrwidth = v.width() / v.dupx() -- screen width
	local scrheight = v.height() / v.dupy() -- screen height

	local boxheight = 52 -- textbox height (52:78)
	
	-- v.drawFill(320/2, 0, 1, 200, 35)
	-- v.drawFill(320/2, 200/2, 320, 1, 160)

	-- Prepare a textbox (snap to bottom)
	for _,textbox in pairs(textboxes) do
	
		local prompt_x = ((320-scrwidth)/2) -- origin x
		local prompt_y = (200-boxheight) -- origin y
		local textoffset = 4 -- icon offset

		-- Set custom coordinates of the textbox (relative/absolute)
		if (textbox.rx and textbox.ry) then
			prompt_x = $1 + (textbox.rx or 0)
			prompt_y = $1 - (textbox.ry or 0)
		elseif (type(textbox.ax) == "number" and type(textbox.ay) == "number") then
			prompt_x = (textbox.ax)
			prompt_y = (textbox.ay)-17
			textoffset = 0
		end

		TextBox.debug(v, prompt_x, prompt_y-4, textbox)

		-- Draw the background to stretch to the screen edges
		if (textbox.showbg) then
			v.drawStretched(prompt_x*FU, prompt_y*FU, scrwidth*FU, boxheight*FU, v.cachePatch("~031G"), V_30TRANS|V_SNAPTOBOTTOM)
		end

		-- Draw the icon (4:152) (+ text offset) 
		if (textbox.icon) then
			v.drawScaled((prompt_x+4)*FU, (prompt_y+4)*FU, FRACUNIT/6+FU/160, v.cachePatch("AMYRTALK"), V_SNAPTOBOTTOM)
			textoffset = 52
		end

		-- Show name (52:153)
		if (textbox.name) then
			v.drawString(prompt_x+textoffset, prompt_y+4, "\x82"..textbox.name, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")
		end

		-- Draw the text (52:165)
		v.drawString(prompt_x+textoffset, prompt_y+17, textbox.text:sub(0, textbox.strcnt), V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")
	end
end

addHook("ThinkFrame", TextBox.textbox_update)
hud.add(function(v, stplyr, cam) TextBox.textbox_drawer(nil, v, stplyr, cam) end, "game")

if true then return end

function TextBox.new(event, player, name, text)

	if not ( (player and player.mo.valid)
	and (player and player.textbox) ) then return end -- both player nor textbox table exists
	
	-- Initialize text settings, and run the textbox
	if not player.textbox.text then
		-- local _tb = {}
		player.textbox.strcnt = 0 + player.textbox.startpos
		player.textbox.linetime = 0
		player.textbox.speaker = name
		player.textbox.text = text
		-- player.textbox = _tb
	end
	TextBox.textbox_update(event, player)
end

-- Sets textbox configuration settings in advance to keep the .new function cleaner
-- (want to reset all? leave settings empty)
function TextBox.Setconfig(player, settings)

	if not ( (player and player.mo.valid)
	and (player and player.textbox) ) then return end -- both player nor textbox table exists
	
	-- This should initialize once before the textbox contains text
	if not player.textbox.text then
		player.textbox.icon = (settings and settings.icon) or "NONEICO"
		player.textbox.textsfx = (settings and settings.sfx) or sfx_none
		player.textbox.auto = (settings and settings.auto) or 3*TICRATE
		player.textbox.startpos = (settings and settings.startpos) or 0
		player.textbox.speed = (settings and settings.speed) or 1
		player.textbox.delay = (settings and settings.delay) or 1
		-- player.textbox.offset = {}
	end
end

local function P_SetupTextboxes(player)

		-- Set textbox information
		player.textbox = {
			speaker = nil, -- the name inserted into speaker field (can be anything)
			text = nil, -- the current text
			icon = "NONEICO", -- icon to use to besides the text\
			textsfx = sfx_none, -- text printing sound
			strcnt = 0, -- the amount of the string that is shown
			linetime = 0, -- the time spent on current block of text
			-- offset = {x = 0, y = 0}, -- the offset of the textbox
			-- textoffset = {x = 0, y = 0}, -- the offset of the text
			-- iconoffset = {x = 0, y = 0}, -- the offset of the icon
			auto = 2*TICRATE, -- set a timer to advance to the next block
			startpos = 0, -- modify the starting position
			speed = 1, -- text printing speed
			-- selection = nil,
		}
		-- TODO: in the future maybe we can put multiple text boxes on screen?
		-- or instead, works like movienight emoji (anything non-player floats above mobj)
		-- player.textboxes = {}
		-- player.renders = {} -- TODO: do we need renders if hudlayers can do casebycase?
end

-- TODO: this used to be a mapload hook, is playerspawn better? find out (probably is)
addHook("PlayerSpawn", function(player)
	-- for player in players.iterate do
		P_SetupTextboxes(player)
	-- end
end)

-- Textbox controller
function TextBox.textbox_update(event, player)

	if not ( (player and player.mo.valid)
	and (player and player.textbox) ) then return end -- both player nor textbox table exists
	
	local textbox = player.textbox

	-- TODO: how to use an event wait, and reset the textblock at the same time?
	-- Run when string exists in text
	if (textbox.text) then
		
		-- Play a sound on each letter, skipping spaces and nl
		if (textbox.textsfx) then
			if (textbox.strcnt < textbox.text:len())
			and not (textbox.text:sub(textbox.strcnt):byte() == 0 or textbox.text:sub(textbox.strcnt):byte() == 32)
			and (textbox.strcnt % textbox.speed == 0) then
				S_StartSound(nil, textbox.textsfx)
			end
		end

		-- Check if we reached the end of the string, and clear textbox if we did
		if (textbox.strcnt >= textbox.text:len()) then

			-- We finish automatically on a set time, or end on button press
			if (textbox.auto and textbox.linetime < textbox.auto) then
				player.textbox.linetime = $1+1
				-- print(string.format("[text auto: %d/%d]", textbox.linetime, textbox.auto))
			elseif not (textbox.auto) and (player.cmd.buttons & BT_JUMP) then
				textbox.text = nil
			else
				textbox.text = nil -- set to automatically end for auto if neither
			end
		else
			-- Increment string.sub
			if (leveltime % textbox.delay == 0) then
				player.textbox.strcnt = min($1 + 1*textbox.speed, textbox.text:len())
			end
			-- print(string.format("[text subcnt: %d/%d]", textbox.strcnt, textbox.text:len()))
		end
	end
	waitUntil(event, textbox.text == nil) -- pause the event until text is nil, not empty
end

-- Text Box drawer
function TextBox.textbox_drawer(a, v, stplyr, cam)

	if not stplyr and stplyr.textbox then return end -- both player nor textbox table exists

	-- Screen settings
	local scrwidth = v.width() / v.dupx() -- screen width
	local scrheight = v.height() / v.dupy() -- screen height

	local boxheight = 52 -- textbox height (52:78)

	-- Prepare a textbox (snap to bottom)
	if (stplyr.textbox and stplyr.textbox.text) then

		-- Draw the background to scale to the screen edges
		-- TODO: until drawfill gets alpha values, use a graphic...
		-- v.drawFill((320-scrwidth)/2, 200-boxheight, scrwidth,boxheight, 31|V_SNAPTOBOTTOM|V_40TRANS)
		v.drawScaled(((320-scrwidth)/2)*FRACUNIT, (200-boxheight)*FRACUNIT, FRACUNIT*v.dupx(), v.cachePatch("PRMPTBG"), V_30TRANS|V_SNAPTOBOTTOM)

		-- The text box has a speaker
		if (stplyr.textbox.speaker) then
			v.drawString(52, 153, "\x82"..stplyr.textbox.speaker, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")
		end

		-- Draw the icon
		v.drawScaled(4*FRACUNIT, 152*FRACUNIT, FRACUNIT/6, v.cachePatch(stplyr.textbox.icon), V_SNAPTOBOTTOM)

		-- Draw the text
		v.drawString(52, 165, stplyr.textbox.text:sub(0, stplyr.textbox.strcnt), V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")
	end
end


R_AddHud("Player_TextBoxes", 1, nil, TextBox.textbox_drawer)
--addHook("PlayerThink", TextBox.textbox_update)

rawset(_G, "SetTextConfig", SetTextConfig)
rawset(_G, "Speak", Speak)




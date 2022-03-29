--[[
* l_textboxesv2.lua
* (sprkizard)
* (March 29, 2022, 0:00)
* Desc: A re-rewrite of textboxes used in sugoi2, with
	a more minimalistic graphical style and more features

* Usage: TODO: check wiki???

* Depends on:
	TODO: (none atm)
]]

rawset(_G, "TextBox", {dialogs={}, debug=true})

local textboxes = {}

-- mockcode: 
-- if leveltime 4 seconds then Textbox.add(id for identifier, name for talker, text for text, arguments for settings)

-- textbox add (settings: text sound, autoprogress timer, start position, subtitle, speed, delay, relative x,y position, absolute x,y position, cecho)
	-- has unique identifier to allow for multiple boxes on screen
	-- also has unique identifier to allow a text change on the same box
		-- (nextid=2 \\ textid[number] equals {name is 'Amy', text is 'Hello World!', autotime is 4s, skin is skin for this text, etc})

function TextBox.debug(v,x,y,textbox)
	if not TextBox.debug then return end
	local str = textbox.text:gsub("\n", " ")
	local info_output = string.format("ID: %d | Name: %s | Text: %s | Icon: %s | Printed: %d/%d | Auto: [%d/%d]| rel: (%d,%d) | abs: (%d,%d)", 
		textbox.id or 0, tostring(textbox.name),str,tostring(textbox.icon),textbox.strpos,#textbox.text,textbox.linetime,textbox.auto,textbox.rx or 0,textbox.ry or 0,textbox.ax or 0,textbox.ay or 0)
	v.drawString(x, y, info_output, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin")
end

-- TODO: can i stop pasting this in multiple scripts every time i need it? :D
function TextBox.randomchoice(choices)
    local RandomKey = P_RandomRange(1, #choices)
    if type(choices[RandomKey]) == "function" then
        choices[RandomKey]()
    else
        return choices[RandomKey]
    end
end

function TextBox.add(boxid, args)
	if type(boxid) == "string" then print("Box ID must be a number!") return end

	-- Wipe the last id and overwrites it with a new under the same id
	if textboxes[boxid] then textboxes[boxid] = nil end

	local new_tb = {
		id = boxid,
		name = (args and args.name) or "",
		text = (args and args.text) or " ",
		icon = (args and args.icon),
		showbg = 1,
		auto = (args and args.auto) or 3*TICRATE,
		nextid = (args and args.nextid),
		speed = (settings and settings.speed) or 1,
		-- delay = (settings and settings.delay) or 1,
		soundbank = (args and args.soundbank) or {opensfx=nil,printsfx=nil,compsfx=nil,nextsfx=nil,endsfx=nil},
		sb_atend=false,
		-- startpos = (settings and settings.startpos) or 0,
		rx = (args and args.rx),
		ry = (args and args.ry),
		ax = (args and args.ax),
		ay = (args and args.ay),
		strpos = 0,-- + startpos,
		linetime = 0,
		closing=false,
	}
	textboxes[boxid] = new_tb
end

-- textbox update
-- 	play ticker sound
-- 	check if printed string is above the text length
-- 		has autoprogress timer
-- 			count up line timer to reach automatic timelimit
-- 		or
-- 		wait for button press (default jump or change in textbox settings) if has no autoprogress timer
-- 			close the textbox or turn to (nextid=) textbox text page
-- 		or else (autotimer ran out)
-- 			close the textbox or turn to (nextid=) textbox text page
-- 	increment text printing position; by speed or delay

-- New text id for chaining dialogue together
function TextBox.next_text(id, box)

	-- nextid is a number, find a new defined id in the dialogue table
	if (type(box.nextid) == "number") then
		-- TODO: nextid for secondary ids?
		TextBox.add(id, TextBox.dialogs[box.nextid])

	-- nextid is a table, allows for searching a user-defined table that has stored dialogue
	elseif (type(box.nextid) == "table") then
		local userdef = box.nextid[1] -- id user-named
		local nextid = box.nextid[2] -- id
		TextBox.add(id, TextBox.dialogs[userdef][nextid])
	end

end

-- Plays sound in the update function by type
function TextBox.playdialogsound(txtbox, soundtype)
	if (soundtype == "start") then
		-- TODO: (Unsure when this is played, check reference)
	elseif (soundtype == "open") then

		-- Plays when the dialog is opened
		if (txtbox.soundbank and txtbox.soundbank.opensfx) then
			S_StartSound(nil, txtbox.soundbank.opensfx)
		end
	elseif (soundtype == "print") then

		-- Plays on each letter printed
		if (txtbox.soundbank and txtbox.soundbank.printsfx) then
			if (txtbox.strpos < txtbox.text:len())
			and not (txtbox.text:sub(txtbox.strpos):byte() == 0 or txtbox.text:sub(txtbox.strpos):byte() == 32)
			and (txtbox.strpos % txtbox.speed == 0) then

				-- Take a table if given, and mix the sounds around!
				if (type(txtbox.soundbank.printsfx) == "table") then
					S_StartSound(nil, TextBox.randomchoice(txtbox.soundbank.printsfx))
				else
					S_StartSound(nil, txtbox.soundbank.printsfx)
				end
			end
		end
	elseif (soundtype == "complete") then

		-- Plays at completion
		if (txtbox.soundbank and txtbox.soundbank.compsfx and not txtbox.sb_atend) then
			S_StartSound(nil, txtbox.soundbank.compsfx)
			txtbox.sb_atend = true
		end
	elseif (soundtype == "next") then

		-- Plays on the trigger to progress to a next set
		if (txtbox.soundbank and txtbox.soundbank.nextsfx) then
			S_StartSound(nil, txtbox.soundbank.nextsfx)
		end
	elseif (soundtype == "end") then

		-- Plays at the event which removes the dialog
		if (txtbox.soundbank and txtbox.soundbank.endsfx) then
			S_StartSound(nil, txtbox.soundbank.endsfx)
		end
	end
end

function TextBox.textbox_update()

	for id,txtbox in pairs(textboxes) do

		if (txtbox.closing) then
			textboxes[id] = nil
			break
		end

		-- Plays printing sounds (while ignoring spaces and nothing)
		TextBox.playdialogsound(txtbox, "print")

		-- (The text string position has reached the end of the string length)
		if (txtbox.strpos >= txtbox.text:len()) then

			-- Automatic progression is enabled so use the user-defined or default value
			if (txtbox.auto and txtbox.linetime < txtbox.auto) then
				txtbox.linetime = $1+1

				-- Play a sound at the completion of dialog (triggers only once)
				TextBox.playdialogsound(txtbox, "complete")

			-- Wait for button press if no automatic, and a button is specified instead
			elseif not (txtbox.auto) and (txtbox.button and player.cmd.buttons & txtbox.button) then
				-- close the textbox or turn to (nextid=) textbox text id
				if (txtbox.nextid) then
					TextBox.next_text(id, txtbox)
					TextBox.playdialogsound(txtbox, "next")
				else
					txtbox.closing = true
					TextBox.playdialogsound(txtbox, "end")
				end
			else
				-- close the textbox or turn to (nextid=) textbox text id
				if (txtbox.nextid) then
					TextBox.next_text(id, txtbox)
					TextBox.playdialogsound(txtbox, "next")
				else
					txtbox.closing = true
					TextBox.playdialogsound(txtbox, "end")
				end
			end

		else
			txtbox.strpos = min($1 + 1, txtbox.text:len())
		end
	end
end

-- textbox drawer:
-- 	(predefined screen width/height)
-- 	(predefined boxheight)
-- 	(set origin point for textbox)
-- 	(set icon offset - 4)
-- 	textbox relative x,y setting exists:
-- 		add coordinates to origin position
-- 	or
-- 	textbox absolute x,y setting exists:
-- 		replace origin position coordinates
-- 	draw pixel stretched background
-- 	draw icon:
-- 		add to text offset if icon is drawn - 52
-- 	draw name
-- 	draw text

function TextBox.textbox_drawer(v, stplyr, cam)

	-- TODO: center/right aligned math
	-- Screen settings
	local scrwidth = v.width() / v.dupx() -- screen width
	local scrheight = v.height() / v.dupy() -- screen height

	local boxheight = 52 -- textbox height (52:78)
	
	-- v.drawFill(320/2, 0, 1, 200, 35)
	-- v.drawFill(320/2, 200/2, 320, 1, 160)

	-- Prepare a textbox (snap to bottom)
	for _,textbox in pairs(textboxes) do

		-- Textbox origin point (x,y) (top-left)
		local prompt_x = ((320-scrwidth)/2)
		local prompt_y = (200-boxheight)
		local textoffset = 4 -- icon offset

		-- Set custom coordinates of the textbox (relative/absolute)
		if (textbox.rx ~= nil or textbox.ry ~= nil) then
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
			v.drawScaled((prompt_x+4)*FU, (prompt_y+4)*FU, FRACUNIT/6+FU/160, v.cachePatch(textbox.icon), V_SNAPTOBOTTOM)
			textoffset = 52
		end

		-- Show name (52:153)
		if (textbox.name) then
			v.drawString(prompt_x+textoffset, prompt_y+4, "\x82"..textbox.name, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")
		end

		-- Draw the text (52:165)
		v.drawString(prompt_x+textoffset, prompt_y+17, textbox.text:sub(0, textbox.strpos), V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")
	end
end

hud.add(TextBox.textbox_drawer, "game")

-- local textboxes = {
-- 	-- {id=1, name="Amy Rose", text="Demo 1\nDemo 1\nDemo 1", icon=true, strcnt=0, showbg=1},
-- 	-- {id=2, name=nil, text="Demo 2", icon=false, ax=320/2,ay=200/2, strcnt=0, showbg=1}
-- }

function TextBox.addDialog(category, textid, icon, name, text, args, soundbank)

	local newargs = args or {}

	newargs.boxid = id
	newargs.name = name
	newargs.text = text
	newargs.icon = icon
	newargs.soundbank = soundbank

	if (category) then
		if not TextBox.dialogs[category] then TextBox.dialogs[category] = {} end
		TextBox.dialogs[category][textid] = newargs
	else
		TextBox.dialogs[textid] = newargs
	end

end

function TextBox.getDialog(category, textid)
	if (category) then
		if not (TextBox.dialogs[category]) then print("\x82WARNING:\x80 User-defined dialog does not exist!") end
		return TextBox.dialogs[category][textid]
	else
		return TextBox.dialogs[textid]
	end
end

local testsndbank = {opensfx=sfx_wwopen,printsfx={sfx_bubbl1,sfx_bubbl2,sfx_bubbl3,sfx_bubbl4,sfx_bubbl5,},compsfx=sfx_wwcomp,nextsfx=sfx_wwnext,endsfx=sfx_wwclos}

-- Examples:
TextBox.addDialog(nil, 1, "AMYRTALK", "Amy", "This is a test dialog that\nwill print sound effects on\ndifferent textbox events.", {nextid=9}, testsndbank)
TextBox.addDialog(nil, 9, "AMYRTALK", "Amy", "This is the next set of\ndialog.", nil, testsndbank)
-- TextBox.dialogs = {
TextBox.dialogs[2] = {icon="AMYRTALK", name="Amy", text="This is a new text page.", nextid=3}
TextBox.dialogs[3] = {icon="AMYRTALK", name="Amy", text="This is page three,\nwhich is also the end."}


TextBox.dialogs["Custom"] = {}
TextBox.dialogs["Custom"][6] = {icon="AMYRTALK", name="Amy", text="This is a custom categorized\ndialoge! This is to prevent\noverwrites and conflicts!"}

-- Creates a new textbox 
addHook("ThinkFrame", function()
	TextBox.textbox_update()
	
	if leveltime == 3*TICRATE then
		TextBox.add(1, TextBox.getDialog(nil, 1))
		-- TextBox.add(1, {icon="AMYRTALK", name="Amy", text="Hello world!", nextid={"Custom", 6}})
		-- TextBox.add(12, {icon="AMYRTALK", name="Amy", text="Hello world!", rx=0, ry=100, nextid=2})
	end

end)
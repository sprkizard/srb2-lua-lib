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

-- textbox update/display table
local textboxes = {}

-- mockcode: 
-- if leveltime 4 seconds then Textbox.add(id for identifier, name for talker, text for text, arguments for settings)

-- textbox add (settings: text sound, autoprogress timer, start position, subtitle, speed, delay, relative x,y position, absolute x,y position, cecho)
	-- has unique identifier to allow for multiple boxes on screen
	-- also has unique identifier to allow a text change on the same box
		-- (nextid=2 \\ textid[number] equals {name is 'Amy', text is 'Hello World!', autotime is 4s, skin is skin for this text, etc})
	-- only the player that initiated add can press buttons to proceed
	-- boxes are not shown to players if they cannot see them or did not open them

-- Prints information on top of the dialog box
function TextBox.debug(v,x,y,textbox)
	if not TextBox.debug then return end
	local str = textbox.text:gsub("\n", " ")
	local info_output = string.format("ID: %d | Name: %s | Text: %s | Icon: %s | Printed: %d/%d | Auto: [%d/%d]| rel: (%d,%d) | abs: (%d,%d)", 
		textbox.id or 0, tostring(textbox.name),str,tostring(textbox.icon),textbox.strpos,#textbox.text,textbox.linetime,textbox.auto,textbox.rx or 0,textbox.ry or 0,textbox.ax or 0,textbox.ay or 0)
	v.drawString(x, y, info_output, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin")
end

function TextBox.isvalid(player)
	return (player and player.valid)
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

-- Adds a new dialog to the screen with a box identifier (TODO: ranges 10k-32k reserved for players with multiple ids?)
function TextBox.add(boxid, args, player, soundbank)
	if type(boxid) == "string" then print("Box ID must be a number!") return end

	local new_tb = {
		id = boxid,
		name = (args and args.name) or "",
		text = (args and args.text) or " ",
		icon = (args and args.icon),
		button = (args and args.button),
		auto = (args and args.auto) or 3*TICRATE,
		nextid = (args and args.nextid),
		speed = (args and args.speed) or 1,
		delay = (args and args.delay) or 1,
		soundbank = (args and args.soundbank) or nil, -- Ex: {opensfx=_,printsfx=_,compsfx=_,nextsfx=_,endsfx=_}
		sb_atend = false, -- for compsfx
		rx = (args and args.rx),
		ry = (args and args.ry),
		ax = (args and args.ax),
		ay = (args and args.ay),
		showbg = 1,
		startpos = (args and args.startpos) or 0,
		strpos = 0,-- + startpos,
		linetime = 0,
		closing = false,
		persist = false, -- TODO: finish kept dialogs later
		player = player,
	}

	-- Wipe the last id and overwrites it with a new one under the same id (moved below def to prevent sound from playing each overwrite)
	-- perform a few tasks on overwrite:
	if textboxes[boxid] then

		-- Keeps the players used in the last dialog block if they exist
		if textboxes[boxid].player then	new_tb.player = textboxes[boxid].player end
		
		-- TOOO: Keeps the button prompt if given until it's set to zero
		-- if textboxes[boxid].button and new_tb.button ~= 0 then new_tb.button = textboxes[boxid].button end
		
		-- Keeps the soundbank if one was added
		if textboxes[boxid].soundbank and new_tb.soundbank == -1 then new_tb.soundbank = textboxes[boxid].soundbank end

		textboxes[boxid] = nil

	else
		-- Plays when opened for the very first time
		TextBox.playdialogsound(new_tb, "start")
	end

	textboxes[boxid] = new_tb

end

-- Adds a new dialog
function TextBox.newDialog(category, textid, icon, name, text, args, soundbank)

	local newargs = args or {}

	newargs.boxid = id
	newargs.name = name
	newargs.text = text
	newargs.icon = icon
	newargs.soundbank = soundbank

	-- TODO: ? print soundbank errors as dialog instead
	--[[if soundbank == -1 or type(soundbank) == "table" or not soundbank then
		newargs.soundbank = soundbank
	else
		newargs.soundbank = {}
		newargs.text = string.format("\x82WARNING IN DIALOG ID [%s]:\x80 \n-1 or table expected, got %s", tostring(textid), tostring(soundbank))
	end--]]

	if (category) then
		if not TextBox.dialogs[category] then TextBox.dialogs[category] = {} end
		TextBox.dialogs[category][textid] = newargs
	else
		TextBox.dialogs[textid] = newargs
	end

end

-- Gets a dialog by id
function TextBox.getDialog(category, textid)
	if (category) then
		if not (TextBox.dialogs[category]) then print("\x82WARNING:\x80 User-defined dialog does not exist!") end
		return TextBox.dialogs[category][textid]
	else
		return TextBox.dialogs[textid]
	end
end

-- Closes a dialog box
function TextBox.close(boxid)
	if textboxes[boxid] then
		textboxes[boxid].closing = true
	end
end

function TextBox.refreshlist(removespecial)
	for _,t in pairs(textboxes) do
		if t and t.persist then return end
		t.closing = true
	end
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

-- Uses new text id for chaining dialogue together
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

	local plyr = nil -- TODO: unsure if needed with below line TextBox.isvalid(txtbox.player) or nil

	-- Ensures that sounds only play for the displayed player (incl. spectating) and not everybody at once
	-- also for players that do not have a dialog open by exclusion
	if (TextBox.isvalid(consoleplayer) and not consoleplayer.indialog and displayplayer == consoleplayer) then return end

	if (soundtype == "start") then
		-- Plays when the dialog is opened
		if (txtbox.soundbank and txtbox.soundbank.startsfx) then
			S_StartSound(nil, txtbox.soundbank.startsfx, plyr)
		end
	elseif (soundtype == "open") then
		-- TODO: (played on a prompt)
	elseif (soundtype == "print") then

		-- Plays on each letter printed
		if (txtbox.soundbank and txtbox.soundbank.printsfx) then
			if (txtbox.strpos < txtbox.text:len())
			and not (txtbox.text:sub(txtbox.strpos):byte() == 0 or txtbox.text:sub(txtbox.strpos):byte() == 32)
			and (txtbox.strpos % txtbox.speed == 0) then

				-- Take a table if given, and mix the sounds around!
				if (type(txtbox.soundbank.printsfx) == "table") then
					S_StartSound(nil, TextBox.randomchoice(txtbox.soundbank.printsfx), plyr)
				else
					S_StartSound(nil, txtbox.soundbank.printsfx, plyr)
				end
			end
		end
	elseif (soundtype == "complete") then

		-- Plays at completion
		if (txtbox.soundbank and txtbox.soundbank.compsfx) then
			S_StartSound(nil, txtbox.soundbank.compsfx, plyr)
		end
	elseif (soundtype == "next") then

		-- Plays on the trigger to progress to a next set
		if (txtbox.soundbank and txtbox.soundbank.nextsfx) then
			S_StartSound(nil, txtbox.soundbank.nextsfx, plyr)
		end
	elseif (soundtype == "end") then

		-- Plays at the event which removes the dialog
		if (txtbox.soundbank and txtbox.soundbank.endsfx) then
			S_StartSound(nil, txtbox.soundbank.endsfx, plyr)
		end
	end
end

-- Updater
function TextBox.textbox_update()

	for id,txtbox in pairs(textboxes) do

		-- Remove dialog from table if ended
		if (txtbox.closing) then
			textboxes[id] = nil
			break
		end
		-- print(txtbox.player[1].mo.momx)
		-- Plays printing sounds (while ignoring spaces and nothing)
		TextBox.playdialogsound(txtbox, "print")

		-- (The text string position has reached the end of the string length)
		if (txtbox.strpos >= txtbox.text:len()) then

			-- Wait for button press if no automatic, and a button is specified
			if (txtbox.button) then

				txtbox.linetime = 0 --txtbox.button*-1

				-- Play a sound at the completion of dialog (triggers only once)
				if not txtbox.sb_atend then
					TextBox.playdialogsound(txtbox, "complete")
					txtbox.sb_atend = true
				end

				-- close the textbox or turn to (nextid=) textbox text id
				if  (txtbox.player[1].cmd.buttons & txtbox.button) then
					if (txtbox.nextid) then
						TextBox.next_text(id, txtbox)
						TextBox.playdialogsound(txtbox, "next")
					else
						txtbox.closing = true
						TextBox.playdialogsound(txtbox, "start")
						TextBox.playdialogsound(txtbox, "end")
					end
				end
			-- Automatic progression is enabled so use the user-defined or default value instead
			elseif (txtbox.auto and txtbox.linetime < txtbox.auto) then
				txtbox.linetime = $1+1

				-- Play a sound at the completion of dialog (triggers only once)
				if not txtbox.sb_atend then
					TextBox.playdialogsound(txtbox, "complete")
					txtbox.sb_atend = true
				end
			else
				-- close the textbox or turn to (nextid=) textbox text id
				if (txtbox.nextid) then
					TextBox.next_text(id, txtbox)
					TextBox.playdialogsound(txtbox, "next")
				else
					txtbox.closing = true
					TextBox.playdialogsound(txtbox, "start")
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

	-- (Not much can be done about splitscreen except prevent it from drawing twice)
	if splitscreen and stplyr == displayplayer then return end

	-- Prevent players from seeing dialogs if they are not included
	if not stplyr.indialog then return end
	-- if textbox.player == displayplayer then return end

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

		-- Draw a graphic to show a button press (bottom-right)
		if (textbox.sb_atend and not textbox.linetime) then
			local blink = (leveltime % 10 >= 6) and 134 or 30
			v.drawFill(prompt_x+scrwidth-8, prompt_y+(boxheight-8), 6, 6, blink)
		end

		-- Draw the text (52:165)
		v.drawString(prompt_x+textoffset, prompt_y+17, textbox.text:sub(0, textbox.strpos), V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "left")

	end
end

hud.add(TextBox.textbox_drawer, "game")




addHook("PlayerSpawn", function(player)
	player.indialog = true
end)

addHook("MapLoad", function()
	TextBox.refreshlist()
end)

addHook("MapChange", function()
	TextBox.refreshlist()
end)










-- Examples:
TextBox.newDialog(nil, 2, "AMYRTALK", "Amy", "Apples\noranges\nbananas", {nextid=3}, {printsfx=sfx_oratxt})
TextBox.newDialog(nil, 3, "AMYRTALK", "Amy", "(A soundbank is being\nused for printing)", {nextid=4}, {printsfx=sfx_oratxt})
TextBox.newDialog(nil, 4, "AMYRTALK", "Amy", "This is the third dialog\nchain which is also the end.\nGood-bye!", nil, {printsfx=sfx_oratxt})
TextBox.newDialog("Custom", 6, "AMYRTALK", "Amy", "This is a custom categorized\ndialoge! This is to prevent\noverwrites and conflicts!", nil, {printsfx=sfx_bttx5})

local testsndbank = {startsfx=sfx_strpst,printsfx=sfx_radio,compsfx=sfx_menu1,nextsfx=sfx_appear,endsfx=sfx_addfil}

TextBox.newDialog(nil, 1, "AMYRTALK", "Amy", "This is a test dialog that\nwill print sound effects on\ndifferent textbox events.", {nextid=9}, testsndbank)
TextBox.newDialog(nil, 9, "AMYRTALK", "Amy", "This is the next set of\ndialog.", nil, testsndbank)

-- Button and sound trigger stuff
TextBox.newDialog(nil, 10, "AMYRTALK", "Amy", "Press [jump] to continue.", {nextid=11, button=BT_JUMP}, {printsfx=sfx_oratxt,nextsfx=sfx_appear})
TextBox.newDialog(nil, 11, "AMYRTALK", "Amy", VERSIONSTRING.." is the latest SRB2 version.\n[jump]", {nextid=12, button=BT_JUMP}, -1)
TextBox.newDialog(nil, 12, "AMYRTALK", "Amy", "Text 1 [jump]", {nextid=13, button=BT_JUMP})
TextBox.newDialog(nil, 13, "AMYRTALK", "Amy", "Text 2", {nextid=14})
TextBox.newDialog(nil, 14, "AMYRTALK", "Amy", "Text 3", {nextid=15})
TextBox.newDialog(nil, 15, "AMYRTALK", "Amy", "Text 4 [jump]", {nextid=16, button=BT_JUMP})
TextBox.newDialog(nil, 16, "AMYRTALK", "Amy", "Press [spin] to end.", {button=BT_SPIN}, {printsfx=sfx_oratxt,endsfx=sfx_appear})
TextBox.newDialog(nil, 17, "AMYRTALK", "Amy", "New dialog 1", {button=BT_SPIN})

-- TODO: store playerlists in text boxes and add a method to exclude players in a function primarily towards individual player boxes
-- Creates a new textbox 
addHook("ThinkFrame", function()

	TextBox.textbox_update()
	
	if (leveltime == 3*TICRATE) then
		
		local table_player = {}
		
		for player in players.iterate do
			if TextBox.isvalid(player) then table.insert(table_player, player) end
		end

		TextBox.add(12, TextBox.getDialog(nil, 10), table_player)

end)
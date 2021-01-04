--[[
* l_EventStepThinker.lua
* (sprkizard)
* (September ‎18, ‎2020, 3:39)
* Desc: A set of functions to run map events in the same style of
	Pokémon Mystery Dungeon: Gates to Infinity.
	(Inspired by a script made by fickleheart and D00D64)

* Usage: TODO: check wiki???

* Depends on:

]]

rawset(_G, "Event", {})

-- rawset(_G, "FESM", Event)

-- Variable to print certain debug stuff related to the event
Event.printlog = false

-- The events created on initialization or anonymously
local EventList = {}

-- global table for running events
local Running_Events = {}

-- Creaets a new event
function Event.new(eventname, ...)
	-- Create an event class for each new event
	local _event = {events = {}}

	_event.name = eventname
	_event.status = "normal" -- mimic coroutine statuses (dead|suspended|running|normal)
	_event.step = 1 -- the current step in the event (might be easier than for-do?)
	_event.signal = "" -- signal to wait on if given one
	 -- where all of our class variables can be traded inside the event
	_event.index = {
		_self = _event, -- a reference to the event itself
		_user = nil, -- the user of the event (eg. player, mobj, variable)
		_idletime = 0, -- the event wait timer
		_looptrack = 0, -- the event looptracker (can be used for anything eg. doOnce)
	}
	
	-- Reference our event list into the event class
	-- All event functions will reference its own index for using variables
	-- TODO: while this works, find another way to keep this the same, but store functions elsewhere
	local funclist = {unpack(...)}
	for i=1,#funclist do
		_event.events[i] = do funclist[i](_event.index) end
		--table.insert(_event.events, (do funclist[i](_event.index) end))
	end
	
	-- Store event class and return to objects
	EventList[eventname] = _event
	return _event
end

-- Creates a userdata block'name' (usually when printed from tostring)
local function randomUserBlockName()
	local str = "0"
	for i=1,7 do
		-- Randomize
		local bits = {P_RandomRange(65,70), P_RandomRange(48,57)}
		local RandomKey = P_RandomRange(1, #bits)
		str = str .. string.char(bits[RandomKey])
	end
	return str
end

-- Runs an event (better used on a wide scope) 
function Event.start(eventname, args)
	assert(EventList[eventname], "Event '" .. eventname .. "' does not exist!")

	local ev = EventList[eventname]

	-- TODO: this needs to be deepcopied to have all fields be copied here and matched correctly
	--[[local ev = {}
	for k,v in pairs(EventList[eventname]) do
		ev[k] = v
	end--]]

	ev.status = "running" -- Set the status to running
	ev.signal = "" -- reset the signal, will re-activate when given another
	ev.step = args and args.order or 1 -- Advance to a future step on start? (use with caution)
	ev.index._user = args and args.user or nil -- set the thing 'using' the event
	ev.index._copy = args and args.copy or nil -- set the copy field (for variable transfers)
	ev.index._idletime = 0 -- TODO: timer problem on reload during wait????
	ev.index._looptrack = 0 -- TODO: above

	-- Clone the table to prevent editing the direct reference
	table.insert(Running_Events, ev)
end

-- Runs a sub event (better used on an individual scope)
function Event.newsub(subeventname, args, funcs)
	-- TODO: accept nil string name
	-- Create a random name and start it instantly
	local subname = subeventname.."_"..randomUserBlockName()
	Event.new(subname, funcs)
	Event.start(subname, args or nil)
end

-- TODO: rework to find complete name or event
-- Destroys an event (searching for part of the name is _maybe_ more effective)
function Event.destroy(eventname, seekall)
	if not (seekall) then
		-- Seek the first most named event to delete
		for _,evclass in pairs(Running_Events) do
			if (string.match(evclass.name, eventname)) then
				evclass._idletime = 0
				evclass.status = "dead"
				Running_Events[evclass] = nil
				if (Event.printlog) then
					print(string.format("Event (%s) deleted by event.destroy /!\\", evclass.name))
				end
			end
		end
	else
		-- Seek all events named similarly
		for _,evclass in pairs(Running_Events) do
			(function()
				if (string.match(evclass.name, eventname)) then
					evclass._idletime = 0 -- TODO: should be .index?
					evclass.status = "dead"
					Running_Events[evclass] = nil
					if (Event.printlog) then
						print(string.format("Event (%s) deleted by event.destroy /!\\", evclass.name))
					end
					return
				end

			end)()
		end
	end
end

-- Transfers all of the variables from the source event
-- will work with other objects, but best used to reference another event
function Event.transfercontent(indexsource, indextdest)
	-- Surf through the source index table for content
	for k,v in pairs(indexsource._copy) do
		(function()
			if (k == "_idletime"
			or k == "_looptrack"
			or k == "_self"
			or k == "_copy") then
			--or k == "_user") then
				return 
			end
			indexsource[k] = v
			--print(k,v)
		end)()
	end
	-- erase the current event user after inserting
	indexsource._copy = nil
end

-- Returns the 'user' of the state
function Event.getuser(eventsource)
	return eventsource._user
end

-- Get the current tag/step of the scope this is called in
function Event.gettag(event, stepnum)
	return event._self.step
end

-- Go to the tag number given in the current state
function Event.gototag(event, stepnum)
	event._self.step = stepnum
end

-- TODO: seek and stop/resume all if needed
function Event.stop(event)
	event._self.status = "stopped"
end

function Event.pause(event)
	event._self.status = "suspended"
end

function Event.resume(event)
	event._self.status = "running"
end


-- Forces an event to wait until a set time
local function wait(event, time)

	-- sleep time is over
	if event._idletime <= 1 then event._self.status = "resumed" end

	if not (event._idletime) then
		-- Set time and suspended status
		event._self.status = "suspended"
		event._idletime = time+1
		
		if (Event.printlog) then
			print(event._self.name.." is now waiting")
		end
	else
		event._idletime = max(0, $1-1)
	end
end

-- Waits until the condition is true, then unsuspend the event (with callback at end)
local function waitUntil(event, cond, end_func)
	if not (cond) then
		event._self.status = "suspended"
	else
		event._self.status = "resumed"

		-- Run a callback function when the condition is reached if specified
		if (end_func) then
			end_func()
		end
	end
end

-- Pauses the entire state until its signal is responded to
-- (attempted rewrite without waiting_on_signal)
local function waitSignal(event, signalname)
	if (event._self.signal == "") then
		-- TODO: should this be a check in the thinker or is it fine here?, 
		-- it should achieve the same result
		event._self.status = "suspended"
		event._self.signal = signalname
	elseif (event._self.signal == "__" .. signalname .. "_gotsignal") then
		event._self.status = "resumed"
		event._self.signal = ""
	end
end

-- Activates a signal
local function signal(signalname)
	-- Seek all signals named similarly
	for _,evclass in pairs(Running_Events) do
		(function()
			-- Find a match, then clear + resume (warning: matches partial)
			if (string.match(tostring(evclass.signal), signalname)) then

				-- TODO: ..get a better response name
				evclass.signal = "__".. $1 .."_gotsignal"

				if (Event.printlog) then
					print(string.format("Signal match (%s) and response: FESM should progress. (*)", signalname))
				end
				return
			end
		end)()
	end
end

-- function Event.for(start, max, skip, func)
-- 	for start, max, skip do
		
-- 	end
-- end

-- Does a function once on an event during a wait()
-- (for multiple, use doOrder instead)
rawset(_G, "doOnce", function(event, func)
	-- Run once when looptracker is under 1 (thanks for this)
	if event._looptrack < 1 then
		
		func()

		if (Event.printlog) then
			print("doOnce has been launched.")
		end
	end
	event._looptrack = $1+1
end)

-- Waits until the condition is true, then unsuspend the event (wrapper ver.)
rawset(_G, "doUntil", function(event, cond, while_func, end_func)
	if not (cond) then
		while_func()
		event._self.status = "suspended"
	else
		event._self.status = "resumed"

		-- Run a callback function when the condition is reached if specified
		if (end_func) then
			end_func()
		end

		if (Event.printlog) then
			print("doUntil has ended.")
		end
	end
end)

-- Starts a list of functions per gameframe, and suspends itself on the last
rawset(_G, "doOrder", function(event, funclist)

	-- Increase loop tracker until the end of the list
	-- TODO: ordertype such as loop, anim(ation), or multi?
	if (event._looptrack < #funclist) then
		event._looptrack = $1+1	
		event._self.status = "suspended"
	end

	-- Run the function type in the list
	if type(funclist[event._looptrack]) == "function" then
		do funclist[event._looptrack]() end
	end

end)


-- Handles running events similar to coroutines
local function RunEvents(event)

	for key,evclass in pairs(Running_Events) do
		
		-- The status is dead, remove
		if (evclass.status == "dead") then
			Running_Events[key] = nil
		end

		-- Do not run if the status is normal or dead. Continue next iteration if so.
		(function()
			if not (evclass.status == "normal" or evclass.status == "dead") then

				-- Set events to dead once they reach the end of the list
				if (evclass.step > #evclass.events) then
					evclass.status = "dead"
					return
				end

				-- Print some useful info to the log when enabled
				if (Event.printlog) then
					print(string.format("%d/%d %s[%s%s] - [w%d] [lt%d] [Action]:", evclass.step, #evclass.events, evclass.name, evclass.status, "|"..evclass.signal, evclass.index._idletime, evclass.index._looptrack))
				end

				-- the _entire_ state is stopped, nothing runs
				if evclass.status == "stopped" then return end

				-- TODO: what if suspended, and we want the step function to run only once?
				do evclass.events[evclass.step]() end -- Run functions (:

				-- the event is waiting/yielded
				if evclass.status == "suspended" then return end

				-- Progress the step of the list
				evclass.step = $1+1
				evclass.index._looptrack = 0

			end
		end)()
	end
end


-- Hooks

-- The structure of each state machine should be:
-- Saved 1: 
-- {
-- 	name: {name, status, step, signal, index{}, funcs{...}},
-- ...
-- }

-- Running 2:
-- {
-- 	{name, status, step, signal, index{}, funcs{...}},
-- 	...
-- }

-- Index:
-- {_user, _copy, _idletime, _looptrack, _self, ...}

-- To Avoid errors, hooks should modify based on each table mapping

-- TODO: when netvars eventually works
addHook("NetVars", function(network)

	--[[for key,obj in pairs(Running_Events) do
		obj.name = net($)
		obj.status = net($)
		obj.step = net($)
		obj.signal = net($)
		obj.index = {
			_user = net($),
			_copy = net($),
			_idle = net($),
			_looptrack = net($),
			_self = {
			},
		}
	end--]]

	--[[for object,val in pairs(EventList) do
		if not (type(val) == "function") then
			object[val] = net($)
		end
	end--]]

	--[[Running_Events = net(Running_Events)
	EventList = net(EventList)--]]
end)


-- When specified, run an event by name on map load, and do other kinds of stuff
addHook("MapLoad", function(gamemap)
	
	-- Run an event on map load
	if (mapheaderinfo[gamemap].loadevent) then
		for player in players.iterate do
			-- Event.newsub(mapheaderinfo[gamemap].loadevent:gsub("%z", ""), player)
		end
	end

	-- Run a 'global' event
	-- TODO: stated far above, but thinking about it further- if globals are
	-- just started every time with the same exact content, does it matter
	-- if we don't deepcopy?
 	if (mapheaderinfo[gamemap].globalevent) then
		Event.start(mapheaderinfo[gamemap].globalevent:gsub("%z", ""), {user = server})
	end
end)

-- Destroy all events on map change (TODO: unless specified?)
addHook("MapChange", function()

	-- TODO: move to separate function (?)
	for key,evclass in pairs(Running_Events) do
		Running_Events[key] = nil
		-- evclass.status = "dead"
		-- evclass = nil
	end
	Running_Events = {}
end)

addHook("ThinkFrame", RunEvents)

-- Globals
rawset(_G, "wait", wait)
rawset(_G, "waitUntil", waitUntil)
rawset(_G, "signal", signal)
rawset(_G, "waitSignal", waitSignal)



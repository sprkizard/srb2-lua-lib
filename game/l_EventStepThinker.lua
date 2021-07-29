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

rawset(_G, "Event", {debug=true})
rawset(_G, "EVE", Event)


-- Prints a debug message
function Event.printdebug(msg)
	if (Event.debug) then print(msg) end
end

function Event.debugfunc(f)
	if (Event.debug) then f() end
end

-- The events created on initialization
rawset(_G, "EventList",{events={},subevents={}})

-- global table for running events (disable for now)
-- rawset(_G, "Running_Events",{})

-- Reduce redundancy when looking through the event tables
function Event.searchtable(f, issubevent)
	if not issubevent then
		for k,evclass in pairs(EventList.events) do
		(function()
			do f(k, evclass) end
		end)()
		end
	else
		for k,evclass in pairs(EventList.subevents) do
		(function()
			do f(k, evclass) end
		end)()
		end
	end
end

-- Creates a new event
function Event.new(eventname, ftable)

	-- Create an event object for each new event
	local _event = {}

	_event.name = eventname
	_event.status = "normal" -- mimic coroutine statuses (dead|suspended|running|normal)
	_event.step = 1 -- the current step position in the state list (might be easier than for-do?)
	_event.signal = "" -- signal to wait on if given one
	_event.tags = {} -- Tags for jumping around inside of a state (like goto)
	_event.sleeptime = 0 -- the event wait timer
	_event.looptrack = 0 -- the event looptracker (can be used for anything eg. doOnce)

	-- Create a container for variables
	_event.vars = {
		-- TODO: reference to only what we will allow in the event's 'self' property
		-- _self = _event,
		-- TODO: find another use for user since we no longer transfer variables using a function
		-- the user of the event (eg. player, mobj, variable)
		_user = nil,
	}
	_event.states = {}

	-- Reference our event list into the event object
	-- Assign arguments to the functions to access these fields (variable, event, [parentevent])
	for k,v in pairs(ftable) do

		if type(v) == "function" then
			-- add the functions to the state list with arguments (container, event)
			_event.states[tonumber(k)] = do ftable[tonumber(k)](_event.vars, _event) end
		elseif type(v) == "table" then
			
			-- Sub-Events in the ftable should be added into the subevents table separately
			-- (they will inherit the parent event's variables, etc but still act independently)
			local _subevent = {name=k,status="normal",step=1,signal="",tags={},sleeptime=0,states={}}

			-- add the functions to the state list with arguments (container, subevent, [parentevent])
			for i=1,#v do
				_subevent.states[i] = do v[i](_event.vars, _subevent, _event) end
			end

			-- Add subevents into the subevent table
			EventList.subevents[k] = _subevent
		end
	end

	-- Add events into the event table
	EventList.events[eventname] = _event
	return _event
end

-- private functions to reset event properties
function Event.__setupEvent(ev)
	ev.status = "running" -- Set the event status to running
	ev.signal = "" -- reset the event signal, will re-activate when given another
	ev.step = 1 -- Reset setp count
	ev.tags = {} -- tags
	ev.sleeptime = 0 -- Reset wait time
end

function Event.__endEvent(ev)
	ev.sleeptime = 0
	ev.looptrack = 0
	ev.status = "dead"
	-- Running_Events[re] = nil
end

function Event.__resetEvent(ev)
	ev.status = "normal"
	ev.step = 1
	ev.signal = ""
	ev.tags = {}
	ev.sleeptime = 0
	ev.looptrack = 0
end

-- TODO: find a new use for this since anonymous functions are dead
-- Creates a userdata block'name' (usually when printed from tostring)
--[[local function randomUserBlockName()
	local str = "0"
	for i=1,7 do
		-- Randomize
		local bits = {P_RandomRange(65,70), P_RandomRange(48,57)}
		local RandomKey = P_RandomRange(1, #bits)
		str = str .. string.char(bits[RandomKey])
	end
	return str
end--]]

-- Runs an event
function Event.start(eventname, args)

	-- Instead of breaking the entire script trying to warn, just don't play it
	if not EventList.events[eventname] then
		print(string.format("\x81 Event [%s] does not exist!", eventname))
		return
	end

	local ev = EventList.events[eventname]

	-- Setup the event from the beginning
	Event.__setupEvent(ev)
	
	-- Get everything in args to be added to vars, nullifying the _user variable
	if args then
		for k,v in pairs(args) do
			(function()
				ev.vars[k] = v
			end)()
		end
	end
end

-- Runs a sub event that is inside of another event
-- TODO: check for feature completion
function Event.startsub(subname, args)
	local ev = EventList.subevents[subname]

	Event.__setupEvent(ev)
end

-- TODO: seek and stop/resume all if needed
function Event.stop(event)
	event.status = "stopped"
end

function Event.pause(event)
	event.status = "suspended"
end

function Event.resume(event)
	event.status = "running"
end

-- TODO: rework to find complete name or event
-- Destroys an event (searching for part of the name is _maybe_ more effective)
function Event.destroy(eventname, seekall)

	-- TODO: reduce redundancy
	-- Seek the first most named event to force end
	if not (seekall) then
		for _,evclass in pairs(EventList.events) do
			if (evclass.name == eventname) then
				Event.__endEvent(evclass)
				Event.printdebug(string.format("\x81 Event [%s] declared dead by Event.destroy!", evclass.name))
				return
			end
		end
		for _,evclass in pairs(EventList.subevents) do
			if (evclass.name == eventname) then
				Event.__endEvent(evclass)
				Event.printdebug(string.format("\x81 Event [%s] declared dead by Event.destroy!", evclass.name))
				return
			end
		end
	else
		-- Seek all events named similarly
		--[[for _,evclass in pairs(EventList.events) do
			if (string.match(evclass.name, eventname)) then
				Event.__endEvent(evclass)
				Event.printdebug(string.format("Event [%s] declared dead by Event.destroy /!\\", evclass.name))
			end
		end
		for _,evclass in pairs(EventList.subevents) do
			if (string.match(evclass.name, eventname) then
				Event.__endEvent(evclass)
				Event.printdebug(string.format("Event [%s] declared dead by Event.destroy /!\\", evclass.name))
			end
		end--]]
	end	
end

-- Destroys a group of states all in one go
function Event.destroygroup(eventnamelist, seekall)
	for i=1,#eventnamelist do
		Event.destroy(eventnamelist[i], seekall)
	end
end

-- Get the current state number number of the scope this is called in
function Event.getcurrentstate(event, stepnum)
	return event.step
end

-- Sets a tag inside of the state
function Event.settag(event, tagname)
	event.tags[tagname] = event.step
	
	Event.printdebug(string.format("Set tag id %d on tag[%s]", event.step, tagname))
	
	return event.step
end

-- function Event.removetag(event, tagname)
-- 	event.tags[tagname] = nil
-- 	Event.printdebug(string.format("Removed tag[%s].", tagname))
-- end

-- Go to the tag number given in the current state
function Event.gototag(event, tagname)
	event.step = event.tags[tagname]-1

	Event.printdebug(string.format("Going to tag id %d on tag[%s]", event.step+1, tagname))
end

-- Go to a tag number if a condition is reached
function Event.gototaguntil(event, tagname, cond)
	if not (cond) then
		Event.gototag(event, tagname)
	else
		-- do nothing
	end
end

-- Aliases for these while keeping the old for backwards compatability
Event.setloop = Event.settag
Event.gotoloop = Event.gototag
Event.loopuntil = Event.gototaguntil


-- Forces an event to wait until a set time
local function wait(event, time)

	--[[-- sleep time is over
	if event.sleeptime <= 1 then event.status = "resumed" end

	if not (event.sleeptime) then
		-- Set time and suspended status
		event.status = "suspended"
		event.sleeptime = time+1
		
		Event.printdebug(string.format("[%s] is now waiting.", event.name))
	else
		event.sleeptime = max(0, $1-1)
	end--]]
	
	-- Set time and suspended status
	if (event.sleeptime == 0 and not (event.status == "suspended")) then
		event.sleeptime = time
		event.status = "suspended"
		Event.printdebug(string.format("[%s] is now waiting. (%d)", event.name, time))
	end

	-- Count down
	if (event.sleeptime > 0) then
		event.sleeptime = max(0, $1-1)
	else
		event.status = "resumed"
	end
end

-- Waits until the condition is true, then unsuspend the event (with callback at end)
local function waitUntil(event, cond, end_func)
	if not (cond) then
		event.status = "suspended"
	else
		event.status = "resumed"

		-- Run a callback function when the condition is reached if specified
		if (end_func) then
			end_func()
		end
	end
end

-- Pauses the entire state until its signal is responded to
-- (attempted rewrite without waiting_on_signal)
local function waitSignal(event, signalname)
	if (event.signal == "") then
		event.status = "suspended"
		event.signal = signalname
		Event.printdebug(string.format("[%s]: Seeking signal '%s'...", event.name, signalname))
	elseif (event.signal == signalname .. "_resp") then
		event.status = "resumed"
		event.signal = ""
	end
end

-- Activates a signal
local function signal(signalname, issubevent)
	
	-- Seek all signals named similarly
	Event.searchtable(function(i, evclass)
		if (string.match(evclass.signal, signalname)) then

			evclass.signal = $1 .."_resp"

			Event.printdebug(string.format("Signal '%s' found! Continuing...", signalname))
			return
		end
	end, issubevent)
end

-- function Event.for(start, max, skip, func)
-- 	for start, max, skip do
		
-- 	end
-- end

-- Does a function once on an event during a wait()
-- (for multiple, use doOrder instead)
rawset(_G, "doOnce", function(event, func)
	-- Run once when looptracker is under 1 (thanks for this)
	if event.looptrack < 1 then
		
		func()

		Event.printdebug("doOnce has been launched.")
	end
	event.looptrack = $1+1
end)

-- Waits until the condition is true, then unsuspend the event (wrapper ver.)
rawset(_G, "doUntil", function(event, cond, while_func, end_func)
	if not (cond) then
		while_func()
		event.status = "suspended"
	else
		event.status = "resumed"

		-- Run a callback function when the condition is reached if specified
		if (end_func) then
			end_func()
		end

		Event.printdebug("doUntil has ended.")
	end
end)

-- Starts a list of functions per gameframe, and suspends itself on the last
rawset(_G, "doOrder", function(event, funclist)

	-- Increase loop tracker until the end of the list
	-- TODO: ordertype such as loop, anim(ation), or multi?
	if (event.looptrack < #funclist) then
		event.looptrack = $1+1	
		event.status = "suspended"
	end

	-- Run the function type in the list
	if type(funclist[event.looptrack]) == "function" then
		do funclist[event.looptrack]() end
	end

end)

-- This function progresses the state inside the event forward
local function EventStateProgressor(e)

	-- Do not run if the status is normal or dead. Continue next iteration if so.
	if not (e.status == "normal" or e.status == "dead") then

		-- Set events to dead once they reach the end of the list
		if (e.step > #e.states) then
			e.status = "dead"
			return
		end

		-- Print some useful info to the log when enabled
		-- Event.printdebug(string.format("%d/%d %s[%s%s] - [w%d] [lt%d] [Action]:", e.step, #e.states, e.name, e.status, "|"..e.signal, e.sleeptime, e.looptrack))

		-- the _entire_ state is stopped, nothing runs
		if e.status == "stopped" then return end

		-- TODO: what if suspended, and we want the step function to run only once?
		do e.states[e.step]() end -- Run functions (:

		-- the event is waiting/yielded
		if e.status == "suspended" then return end

		-- Progress the step of the list
		e.step = $1+1
		e.looptrack = 0

	end
end

-- Handles running events similar to coroutines, but only when they are activated
function Event.RunEvents(event)

	for key,evclass in pairs(EventList.events) do
		
		-- TODO: what do we do now if we aren't actually deleting tables anymore?
		-- The status is dead, remove
		-- if (evclass.status == "dead") then
		-- 	-- EventList[key] = nil
		-- end

		EventStateProgressor(evclass)

		-- (function()
		-- end)()

	end
	for key,evclass in pairs(EventList.subevents) do
		EventStateProgressor(evclass)
	end
end






-- =====================
-- Hooks
-- =====================
--[[
This is the structure of each container with fields we allow to be accessed:
Events 1: 
{
	name: {name, status, step, signal, tags, sleeptime, looptrack, vars{}, states{...}},
	...
}

SubEvents 2:
{
	name: {name, status, step, signal, tags, sleeptime, looptrack, states{...}},
	...
}

Vars:
{_user, _copy, ...}
--]]

-- Syncs table data over netplay so players are not de-synced on join
addHook("NetVars", function(network)

	for key,obj in pairs(EventList.events) do
		obj.name = network($)
		obj.status = network($)
		obj.step = network($)
		obj.signal = network($)
		obj.tags = network($)
		obj.sleeptime = network($)
		obj.looptrack = network($)
		obj.vars = network($)
	end

	for key,obj in pairs(EventList.subevents) do
		obj.name = network($)
		obj.status = network($)
		obj.step = network($)
		obj.signal = network($)
		obj.tags = network($)
		obj.sleeptime = network($)
		obj.looptrack = network($)
		-- obj.vars = network($)
	end

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
 	if (mapheaderinfo[gamemap].globalevent) then
		Event.start(mapheaderinfo[gamemap].globalevent:gsub("%z", ""), {user = server})
	end
end)

-- Destroy all events on map change (TODO: unless specified?)
function Event.MapReloadResetEvents()
	-- TODO: if an event does not want to be reset, exclude it
	for k,object in pairs(EventList.events) do
		Event.__resetEvent(object)
	end
	for k,object in pairs(EventList.subevents) do
		Event.__resetEvent(object)
	end
end

addHook("MapChange", function()
	Event.MapReloadResetEvents()
end)
addHook("MapLoad", function()
	Event.MapReloadResetEvents()
end)

addHook("ThinkFrame", Event.RunEvents)

-- Globals
rawset(_G, "wait", wait)
rawset(_G, "waitUntil", waitUntil)
rawset(_G, "signal", signal)
rawset(_G, "waitSignal", waitSignal)


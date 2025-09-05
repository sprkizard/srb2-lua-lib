--[[
* l_EventStepThinker.lua
* (sprkizard)
* (September 18, 2020, 3:39)
* Desc: A set of functions to run map events in the same style of
	Pokémon Mystery Dungeon: Gates to Infinity.
	(Inspired by a script made by fickleheart and D00D64)

* Usage: TODO: check wiki???

* Depends on:

]]

-- TODO: Prevent duplicate loading
if _G["EventList"] then
	print("(!)\x81 ALERT: EventStepThinker is already loaded. The script will be skipped.")
	return
end

rawset(_G, "Event", {debug=false})

-- The events created on initialization
rawset(_G, "EventList", {})


-- global table for running events (disable for now)
local Running_Events = {}

-- Sets a metatable to get function data from
local eventMT = {
    __index = function(t, key)
        if key == "states" then
            return EventList[t.name].states
        end
    end,
    __len = function(t, key)
    	return #EventList[t.name].states
	end
}

registerMetatable(eventMT)


-- Defaults to zero value or an alternative if value is nil
function Event.default(value, altvalue)
	return (value and not nil) and value or altvalue
end

-- Attempts to sort pairs
function Event.spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Reduce redundancy when looking through the event tables. Used internally
function Event.searchtable(f, issubevent)

	for k,evclass in pairs(Running_Events) do

		-- Await status change
		if f(k, evclass) then
			break
		end
		-- TODO: return value
		-- Fallback
		-- (function()
			-- do f(k, evclass) end
		-- end)()
	end
end

-- Seeks an event if it exists, and allows reading its data (editing data: at your own risk)
function Event.read(name, fn)

	for _, e in pairs(Running_Events) do
		-- Run under any event name
		if (e and (name == "any" or name == "all")) then
			do fn(e.vars, e) end
		-- Run under a specific name
		elseif (e and e.name == name) then
			do fn(e.vars, e) end
		end
	end
end

-- Checks if an event exists
function Event.exists(name)
	for _, e in pairs(Running_Events) do
		if (e and e.name == name) then
			return true
		end
	end
end

-- Prints a debug message
function Event.printdebug(msg)
	if (Event.debug) then print(msg) end
end

-- Runs a function (only for debugging)
function Event.debugfunc(f)
	if (Event.debug) then f() end
end

-- Enable table contents preview for debugging
if (Event.debug) then
	hud.add(function(v,stplyr,cam)
		local x = 0
		local y = 0
		v.drawString(0,55, string.upper("\x81Running Events: ")..#Running_Events, 0, "small-thin")
		Event.searchtable(function(i, ev)
			v.drawString(0+x,64+y, string.format("Event: %s\nState: %d/%d\nStatus: %s\nSignal: %s\nIdle: %d", ev.name, ev.step, #ev.states, ev.status, ev.signal, ev.sleeptime), 0, "small-thin")
			x = $1+64
			if (i % 4 == 0) then
				x = 0
				y = $1+32
			end
		end)
	end, "game")
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
	_event.vars = {}

	_event.states = {}

	-- Reference our event list into the event object
	-- Assign arguments to the functions to access these fields (variable, event, [parentevent])
	for k,v in pairs(ftable) do

		if type(v) == "function" then
			-- add the functions to the state list with arguments (container, event)
			_event.states[tonumber(k)] = ftable[tonumber(k)]
		elseif type(v) == "table" then
			
			-- Sub-Events in the ftable should be added into the subevents table separately
			-- (they will inherit the parent event's variables, etc but still act independently)
			local _subevent = {name=k,status="normal",step=1,signal="",vars={},tags={},sleeptime=0,looptrack=0,states={}}

			-- add the functions to the state list with arguments (container, subevent, [parentevent])
			for i=1,#v do
				_subevent.states[i] = v[i]
			end

			-- Add subevents into the subevent table
			EventList[k] = _subevent
			-- EventList.subevents[k] = _subevent
		end
	end

	-- Add events into the event table
	EventList[eventname] = _event
	return _event
end

-- private functions to reset event properties
function Event.__setupEvent(ev, eventname)
	ev.name = EventList[eventname].name
	ev.status = "running"
	ev.step = EventList[eventname].step
	ev.signal = EventList[eventname].signal
	ev.tags = {}
	ev.sleeptime = EventList[eventname].sleeptime
	ev.looptrack = EventList[eventname].looptrack
	ev.vars = {}
end

function Event.__endEvent(ev)
	ev.sleeptime = 0
	ev.looptrack = 0
	ev.status = "dead"
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
function Event.start(eventname, args, caller)

	-- Instead of breaking the entire script with a Lua error, just don't play it and print a warning instead
	if not EventList[eventname] then
		print(string.format("(?)\x81 Event [%s] does not exist!", eventname))
		return
	end

	local ev = {}

	-- Setup the event from the beginning
	Event.__setupEvent(ev, eventname)
	
	-- (Get everything in args to be added to vars, killing the old _user variable)
	-- Reference a variable container if given any
	if (args) then
		for k,v in pairs(args) do
			(function()
				ev.vars[k] = v
			end)()
		end
	end

	-- Sets the caller of the event, which can be anything (except a function)
	if (caller) then
		ev.caller = caller
	end

	setmetatable(ev, eventMT)
	table.insert(Running_Events, ev)
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


-- Destroys any event by found name
-- (Deletion modes: [find] - Partial name matching / [hasvariable] - Match by variable name / [firstfound] - Only removes the first found event entry)
function Event.destroy(eventname, mode)

	-- function wrapper to clear the data
	local function __set_ended(eventdata)
		Event.__endEvent(eventdata)
		Running_Events[eventdata] = nil
		Event.printdebug(string.format("(!)\x81 ALERT: Event [%s] was ended early by Event.destroy!", eventdata.name))
	end

	mode = Event.default(mode, {})

	Event.searchtable(function(_, ev)

		-- Finds a partial event name match
		if (mode.find) then
			if (string.find(ev.name, eventname)) then
				__set_ended(ev)
				Event.printdebug(string.format("(!)\x82 (------Find mode: Complete------)", ev.name))
				return (mode.firstfound) and true or false
			end
		-- Finds a valid variable name inside of the event
		elseif (mode.var) then -- or mode.hasvar) then
			if (ev.vars[eventname]) then
				__set_ended(ev)
				return (mode.firstfound) and true or false
			end
		-- Finds a valid variable name inside of the named event
		-- ("ev_event1", {hasvar="varname",value=true})
		elseif (mode.haskey) then
			if (ev.name == eventname and ev.vars[mode.haskey[1]] == mode.haskey[2]) then
				__set_ended(ev)
				return (mode.firstfound) and true or false
			end
		-- Default behavior (by name)
		else
			if (ev.name == eventname) then
				__set_ended(ev)
				Event.printdebug(string.format("(!)\x82 (------Default mode: Complete------)", ev.name))
				return (mode.firstfound) and true or false
			end
		end
	end)
end

-- Destroys a group of states all in one go
-- (Deletion modes: [find] - Partial name matching / [hasvariable] - Match by variable name / [firstfound] - Only removes the first found event entry)
function Event.destroygroup(eventnamelist, mode)
	for i=1,#eventnamelist do
		Event.destroy(eventnamelist[i], mode)
	end
end

-- Ends the event that this is attached to without finding it
function Event.destroyself(event)
	event.status = "dead"
end

-- Sets an event to be persistent between map changes
function Event.persist(event, arg)
	event.persist = arg
end

-- Get the current state number number of the scope this is called in
function Event.getcurrentstate(event, stepnum)
	return event.step
end

-- Sets a tag inside of the state
function Event.settag(event, tagname)
	event.tags[tagname] = event.step
	
	Event.printdebug(string.format("\x82 -------[%s]: Set loop at Step %d-------", tagname, event.step))
	
	return event.step
end

-- Go to the tag number given in the current state
function Event.gototag(event, tagname)
	event.step = event.tags[tagname]
	event.status = "looped"

	Event.printdebug(string.format("\x82 -------[%s]: Returning to Step %d-------", tagname, event.tags[tagname] or -1))
end

-- Go to a tag number if a condition is reached
function Event.gototaguntil(event, tagname, cond)
	if not (cond) then
		Event.gototag(event, tagname)
	else
		-- do nothing
	end
end

-- Forces an event to wait until a set time
function Event.wait(event, time, singleuse)
	
	-- Set time and suspended status
	if (event.sleeptime == 0 and not (event.status == "suspended")) then
		event.sleeptime = time
		event.status = "suspended"
		Event.printdebug(string.format("[%s] is now waiting. (%d)", event.name, time))
	end

	-- Count down
	if (event.sleeptime > 0) then
		event.sleeptime = max(0, $1-1)
		event.looptrack = singleuse and $1+1 or 0
	else
		event.status = "resumed"
	end
end

local function waitcountdown(event)
	-- Count down
	if (event.sleeptime > 0) then
		event.sleeptime = max(0, $1-1)
	else
		event.status = "resumed"
	end
end

-- Waits until the condition is true, then unsuspend the event (with callback at end)
function Event.waitUntil(event, cond, end_func)
	if not (cond) then
		event.status = "suspended"
	else
		event.status = "resumed"

		-- Run a callback function when the condition is reached if specified
		if (end_func) then
			end_func()
		end
		return true
	end
end

-- Pauses the entire state until its signal is responded to
-- (attempted rewrite without waiting_on_signal)
function Event.waitSignal(event, signalname, identifier)
	if (event.signal == "") then
		event.status = "suspended"
		event.signal = signalname
		Event.printdebug(string.format("[%s]: Seeking signal '%s'...", event.name, signalname))
	elseif (event.signal == signalname .. "_resp" .. (identifier or "")) then
		event.status = "resumed"
		event.signal = ""
	end
end

-- Activates a signal
function Event.signal(signalname, identifier)
	
	-- Seek all signals named similarly
	Event.searchtable(function(i, evclass)
		if (string.match(evclass.signal, signalname)) then

			evclass.signal = $1 .."_resp" .. (identifier or "")

			Event.printdebug(string.format("Signal '%s' found! Continuing...", signalname))
			return
		end
	end)
end

-- Executes gallery image popup from a linedef
function Event.LinedefExecute(line, trigger, sector)

	-- @ Flag Effects:
	--  [1] Block Enemies:
	-- 	[6] Not Climbable:
	--  [10] Repeat Midtexture (E5):
	-- @ Default: runs EV 'ev_[name]' with the texture of the floor/ceiling being the name of the EV to run
	--
	-- if not (trigger and trigger.player and trigger.player.valid) then return end

	local player = trigger and trigger.player or nil

	if (player and player.bot > 0) then return end -- bots shouldn't be able to trigger this

	-- if (line.flags & ML_BLOCKMONSTERS) then
	-- elseif (line.flags & ML_NOCLIMB) then
	-- end
	-- if (line.flags & ML_EFFECT5) then
	-- end

	local evs_name = string.format("ev_%s", string.lower(line.frontsector.floorpic))

	-- Event.start(seqname:gsub("%z", ""))
	-- Event.start(string.lower(evs_name), {execplayer=player, execmobj=trigger})
	Event.start(evs_name, {execsector=sector, execlinedef=line, execmobj=trigger, execplayer=player})
end

--[[-- Does a function once on an event during a wait()
-- (for multiple, use doOrder instead)
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
	if (event.looptrack < #funclist) then
		event.looptrack = $1+1
		event.status = "suspended"
	end

	-- Run the function type in the list
	if type(funclist[event.looptrack]) == "function" then
		do funclist[event.looptrack]() end
	end

end)--]]

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
		if not e.looptrack then
			do e.states[e.step](e.vars, e, e.caller or nil) end -- Run functions (:
		else
			waitcountdown(e)
		end

		-- the event is waiting/yielded
		if e.status == "suspended" then return end

		-- the event has looped backwards, and replaying itself
		if e.status == "looped" then e.status = "running" return end

		-- Progress the step of the list
		e.step = $1+1
		e.looptrack = 0

	end
end

-- Handles running events similar to coroutines, but only when they are activated
function Event.RunEvents(event)

	for key,evclass in Event.spairs(Running_Events, function(t,a,b) return t[b].name < t[a].name end) do
	-- for key,evclass in pairs(Running_Events) do
		
		-- The status is dead, remove
		if (evclass.status == "dead") then
			Running_Events[key] = nil
		end

		EventStateProgressor(evclass)

	end
end

function Event.netvars(n)
	Running_Events = n($)
end




-- =====================
-- Hooks
-- =====================
--[[
This is the structure of each container with fields we allow to be accessed:
EventList: 
{
	name: {name, status, step, signal, tags, sleeptime, looptrack, vars{}, x--states{...}},
	...
}

Running:
{
	{name, status, step, signal, tags, sleeptime, looptrack, x--states{...}},
	...
}

Vars:
{...}
--]]

-- Syncs table data over netplay so players are not de-synced on join
addHook("NetVars", function(network)
	Event.netvars(network)
end)

-- Destroy all events on map change
function Event.MapReloadClearEvents()
	-- if an event does not want to be reset or ended, exclude it
	Event.searchtable(function(i, ev)
		if ev and ev.persist then return end
		Event.__endEvent(ev)
	end)
end

-- When specified, run an event by name on map load, and do other kinds of stuff
function Event.h_MapLoad(gamemap)
	
	Event.MapReloadClearEvents()

	-- Run an event on map load per player
	if (mapheaderinfo[gamemap].loadevent) then
		for player in players.iterate do
			Event.start(mapheaderinfo[gamemap].loadevent:gsub("%z", ""), player)
		end
	end

	-- Run a singular event
 	if (mapheaderinfo[gamemap].globalevent) then
		Event.start(mapheaderinfo[gamemap].globalevent:gsub("%z", ""))
	end

end

addHook("MapLoad", function(gamemap)
	Event.h_MapLoad(gamemap)
end)

addHook("MapChange", function()
	Event.MapReloadClearEvents()
end)

addHook("LinedefExecute", Event.LinedefExecute, "RUN_EVS")

-- addHook("ThinkFrame", Event.RunEvents)

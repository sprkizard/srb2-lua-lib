--[[
* l_EventStepThinker.lua
* (sprkizard)
* (September ‎18, ‎2020, 3:39)
* Desc: A set of functions to run map events in the same vein of
	Pokémon Mystery Dungeon: Gates to Infinity.
	(Inspired by a script made by fickleheart and D00D64)

* Usage: TODO: check wiki???

* Depends on:

]]

rawset(_G, "Event", {})

-- Variable to print certain debug stuff related to the event
Event.printlog = true

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
	 -- where all of our class variables can be traded inside the event
	_event.index = {
		_self = _event, -- a reference to the event itself
		_user = nil, -- the user of the event (eg. player, mobj, variable)
		_idletime = 0, -- the event wait timer
		_looptrack = 0, -- the event looptracker (can be used for anything eg. doOnce)
		-- _signal = nil -- signal to wait on if given one
	}
	
	-- Reference our event list into the event class
	-- All event functions will reference the index for using variables
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
	ev.step = args and args.order or 1 -- Advance to a future step on start? (use with caution)
	ev.index._user = args and args.user or nil -- set the user of the event
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
function Event.destroy(eventname)
	for _,evclass in pairs(Running_Events) do
		if (string.match(evclass.name, eventname)) then
			evclass._idletime = 0
			evclass.status = "dead"
			Running_Events[evclass] = nil
		end
	end
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

-- Waits until the condition is true, then unsuspend the event
local function waitUntil(event, cond)
	if not (cond) then
		event._self.status = "suspended"
	else
		event._self.status = "resumed"
	end
end

--[[local function waitSignal(event, signalname)
	if not (event._self.signal and event._self.signal == signalname) then
		event._self.status = "suspended"
	else
		event._self.status = "resumed"
	end
end

local function signal(event, signalname)
	-- Activates a signal
	Running_Events[event].signal = signalname
end--]]

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
	-- print(#Running_Events)
	for key,evclass in pairs(Running_Events) do
		-- The status is dead, remove
		if (evclass.status == "dead") then
			Running_Events[key] = nil
		end
		-- Do not run if the status is normal or dead
		(function()
			if not (evclass.status == "normal" or evclass.status == "dead") then
				-- TODO: solve for-end (?)
				-- for i=1,#evclass.events do
				-- Set events to dead once they reach the end of the list
				if (evclass.step > #evclass.events) then
					evclass.status = "dead"
					return
				-- elseif (evclass.status == "suspended") then
				-- 	break
				end

				-- Print some useful info to the log when enabled
				if (Event.printlog) then
					print(string.format("%d/%d %s[%s] - [w%d] [lt%d] [Action]:", evclass.step, #evclass.events, evclass.name, evclass.status, evclass.index._idletime, evclass.index._looptrack))
				end

				do evclass.events[evclass.step]() end -- Run functions (:

				-- the event is waiting
				if evclass.status == "suspended" then return end

				-- Progress the step of the list
				evclass.step = $1+1
				evclass.index._looptrack = 0
				-- end
			end
		end)()
	end
	--print(#Running_Events)
	-- for k,v in pairs(Running_Events) do
	-- 	for i=1,#v do
	-- 		do v[i]()5 end
	-- 	end
	-- end
end

--[[addHook("NetVars", function(network)
    local running_eventCount = #Running_Events -- This will get overridden shortly for the client, so it's ok
    running_eventCount = network(running_eventCount)
    for i = 1, running_eventCount do
        Running_Events[i] = network(Running_Events[i])
    end
end)--]]

--[[Mock code!

local eventlist = {} --global list
local eventids = 0
local running_events -- events in thinkframe

event.new(name, function)

	eventlist[name] = function
end

event.start(name or function)
	eventid = $+1
	???	
end
--]]

--[[
.start({
	function(event)
		event.p = 1
	end,
	function(event)
		event.p = $1+1
	end,
	function(event)
		print(event.p)
	end,
})
--]]

-- Hooks

-- TODO: when netvars eventually works
addHook("NetVars", function(net)
	Running_Events = net(Running_Events)
	EventList = net(EventList)
end)

-- When specified, run an event by name on map load, and do other kinds of stuff
addHook("MapLoad", function(gamemap)
	
	-- Run an event on map load
	if (mapheaderinfo[gamemap].loadevent) then
		for player in players.iterate do
			-- Event.newsub(mapheaderinfo[gamemap].loadevent:gsub("%z", ""), player)
		end
	end
	-- Run a global event
	-- TODO: stated far above, but thinking about it further- if globals are
	-- just started every time with the same exact content, does it matter
	-- if we don't deepcopy?
 	if (mapheaderinfo[gamemap].globalevent) then
		Event.start(mapheaderinfo[gamemap].globalevent:gsub("%z", ""), {user = server})
	end
end)

-- Destroy all members on map change (TODO: unless specified?)
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
--rawset(_G, "signal", signal)
--rawset(_G, "waitSignal", waitSignal)

--[[
function event.new(eventname, e)
	local r = {}

	r.e = e

	EventList[eventname] = r
	return r
end

function event.start(eventname, f)

	EventList[eventname].e()

end

local function wait(time)
	time = $1-1
	if time then 
		return
	end
end

event.new("test", function()
	print("1")
	wait(45*TICRATE)
	print("2")
end)
--]]


-- end result
--  be able to store variables in a state varaible to use across the same event or different
--  be able to start a new event from a table event.start(..., {function})
-- 9-6-2020: success

--[[
local stepbystep = {

	function() print("Test") end,
	function() print("Test") end,

}

addHook("ThinkFrame", function()

	for i=1,#stepbystep do
		do
			stepbystep[i]()
		end
	end

end)
--]]

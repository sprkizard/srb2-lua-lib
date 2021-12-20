
rawset(_G, "MapZone", {effects={}})

local mapzones = {}

-- Wrapper to search for an area by it's tag
function MapZone.searchZoneByID(tag)
	for i=1, #mapzones do
		if (mapzones[i].tag == tag) then
			return mapzones[i]
		end
	end
end

-- Wrapper to sloppily for-loop the effects table to run functions stored in it with stacked tags
function MapZone.runZoneFunction(mobj, zone)
	for i=1, #MapZone.effects do

		for j=1, #MapZone.effects[i].tags do 
			if (MapZone.effects[i].tags[j] == zone.tag) then
				MapZone.effects[i].func(mobj, zone)
			end
		end
	end
end

-- Adds a function on an area's tag, allows for tag-stacked effects
function MapZone.AddBoundEffect(name, tags, f)
	table.insert(MapZone.effects, {name=name, tags=tags, func=f})
	-- MapZone.effects[tag] = {func=f}
end

-- Function to create a rectangle using two coordinate points
function MapZone.makeRect(x1, y1, x2, y2)

	-- I don't remember if this is trig or not, but this gets the x and y distance of our 2 points
	local x = x2 - x1
	local y = y2 - y1

	return {
		ca = {x=x1, y=y1},
		cb = {x=x2, y=y2},
		cc = {x=x1 + x, y=y2 - y},
		cd = {x=x2 - x, y=y1 + y},
	}
end

-- Linedef Executor made to be run at level load, or triggered non-continously to set
-- rectangular boundaries in a map to run effects, play sounds, etc
-- This technically acts as an invisible rectangular FOF, but not defined by a sector
addHook("LinedefExecute", function(line, trigger, sector)

	-- @ Flag Effects:
	--  [1] Block Enemies: Enable or disable a zone
	-- 	[6] Not Climbable: Use axis mobjs
	--  [10] Repeat Midtexture: Disable on creation
	-- @ Default:
	--	search by front and back sector offsets + assign lua function by linedef tag

	local rect = {}
	-- local x1,y1,x2,ys2 = 0

	if (line.flags & ML_BLOCKMONSTERS) then
		-- enables / disables the area and exits the executor
		local znb = MapZone.searchZoneByID(line.tag)
		znb.enabled = (not $1)
		return
	elseif (line.flags & ML_NOCLIMB) then

		local mo1, mo2

		for mt in mobjs.iterate() do
			-- TODO: custom object or keep MT_AXIS?
			if ((mt.type == MT_AXIS or mt.type == MT_BLASTEXECUTOR) and mt.spawnpoint.angle == line.tag) then
				-- Find objects using parameter values
				if (mt.spawnpoint.extrainfo == 0) then
					mo1 = mt
					-- x1 = mt.x
					-- y1 = mt.y
				elseif (mt.spawnpoint.extrainfo == 1) then
					mo2 = mt
					-- x2 = mt.x
					-- y2 = mt.y
				end
			end
		end

		-- If no mobjs exist for the tag, this exits if any one of the numbers are nil as a result
		if (mo1 == nil or mo2 == nil) then
		-- if (x1 == nil or x2 == nil or y1 == nil or y2 == nil) then
			print(string.format("\x81LinedefExecute [MAPZONE]: Cannot find mobj boundaries with tag [%d]!", line.tag))
			return
		end
		
		-- Create rectangle from mobjs
		rect = MapZone.makeRect(mo1.x, mo1.y, mo2.x, mo2.y)
		-- rect = MapZone.makeRect(x1, y1, x2, y2)

	else
		-- Create rectangle from line offset coordinates
		rect = MapZone.makeRect(line.frontside.textureoffset, 
								line.frontside.rowoffset, 
								line.backside.textureoffset, 
								line.backside.rowoffset)
	end

	-- Use the line tag as the identifier for this boundary
	rect.tag = line.tag

	-- Apply floor and ceiling boundaries
	rect.floor = line.frontsector.floorheight
	rect.ceiling = line.frontsector.ceilingheight

	-- EFFECT5 determines if this area is off/on on trigger
	if (line.flags & ML_EFFECT5) then rect.enabled = false else rect.enabled = true end
	
	-- print(string.format("Point A: (%d, %d)", (rect.ca.x)/FU, (rect.ca.y)/FU))
	-- print(string.format("Point B: (%d, %d)", (rect.cb.x)/FU, (rect.cb.y)/FU))
	-- print(string.format("Point C: (%d, %d)", (rect.cc.x)/FU, (rect.cc.y)/FU))
	-- print(string.format("Point D: (%d, %d)", (rect.cd.x)/FU, (rect.cd.y)/FU))

	-- Insert rectangle
	table.insert(mapzones, rect)

end, "MapZone")


-- Allows functions and thinkers to be executed when inside a created boundary
function MapZone.isInZoneTrigger(mobj)

	for i=1, #mapzones do

		local zone = mapzones[i]

		if not zone.enabled then return end -- This area is disabled

		-- Check if the mobj is inside of the rectangle boundaries
		if ((mobj.x > zone.ca.x and mobj.x < zone.cb.x)
		and (mobj.y > zone.cd.y and mobj.y < zone.cc.y)
		or (mobj.x < zone.ca.x and mobj.x > zone.cb.x)
		and (mobj.y < zone.cd.y and mobj.y > zone.cc.y))
		and (mobj.z > zone.floor and mobj.z < zone.ceiling) then
			-- Run function
			MapZone.runZoneFunction(mobj, zone)
			-- MapZone.effects[zone.tag].func(mobj, zone)
		end
	end
end


--[[addHook("ThinkFrame", function()

	for player in players.iterate do
		MapZone.isInZoneTrigger(player.mo)
	end

end)--]]

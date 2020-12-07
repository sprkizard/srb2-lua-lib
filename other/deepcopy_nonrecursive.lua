--[[

-- deepcopy_nonrecursive.lua, version v1.0.0
	*	A non-recursive table deep copy implementation in Lua.
		(Tested working in SRB2 and vanilla Lua 5.1, 5.2, and 5.3)
 
	*	Authors: Golden
	*	Originally Released: December 5, 2020 06:03 CST

-- Load this Lua:
	--- local deepcopy_nonrecursive = dofile("deepcopy_nonrecursive.lua")
		*	(deepcopy_nonrecursive will also be automatically put in the global space if other methods of loading are desirable)

-- Usage:
	--- deepcopy_nonrecursive(table): table
		*	Returns a deep copy of the input table, respecting recursive table references, but without recursion.
		*   Takes ~0.095 seconds on my machine to traverse a table (let's call it `t'..) 1962 levels deep,
			and ~0.1 seconds when input this structure:
			{t, {t}, {{t}}, {{{t}}}, ... more ... , {{{{{{{{{t}}}}}}}}}}
]]

local function deepcopy_nonrecursive(t)
	-- Copying a non-table? Just return it to copy the value.
	if type(t) ~= "table" then
		return t
	end

	-- We're...
	local curtables = {t} -- ...copying this original table...
	local curcopies = {{}} -- ...to this new table...
	local curindex = 1 -- ...starting from the first index of curtables...

	local unprocessedtables = 1 -- ...with only the original table to process to start with.

	local copied = curcopies[1] -- Keep a reference to that table copy to return later.

	repeat -- Run at least once.
		local curtable, curcopy = curtables[curindex], curcopies[curindex] -- Some useful references.

		unprocessedtables = unprocessedtables - 1 -- Processed previous table.

		for k, v in pairs(curtable) do -- Iterate the current table
			if type(v) ~= "table" then -- Value not a table?
				curcopy[k] = v -- Automatically copied.
			else -- Is a table?
				local recursive_caught = false -- We haven't found a table in our collection yet

				for i, copy_v in ipairs(curtables) do -- Find out if we've seen this table before...
					if copy_v == v then -- These 2 original tables are the same table?
						curcopy[k] = curcopies[i] -- Then copy a reference to the previously copied version. This works even if it hasn't been processed yet.
						recursive_caught = true -- We've got ourselves a recursive table reference!
						break -- Don't waste time.
					end
				end

				if not recursive_caught then -- If this is actually a new table we haven't seen before...
					table.insert(curtables, v) -- Copy a reference to curtables
					table.insert(curcopies, {}) -- Create a new table to hold the copy
					curcopy[k] = curcopies[#curcopies] -- Create a reference to the pending copy

					unprocessedtables = unprocessedtables + 1 -- Another table to process...
				end
			end
		end

		curindex = curindex + 1 -- Advance to the next index
	until unprocessedtables == 0 -- Stop when there's no longer any tables to copy.

	return copied -- Give it back!
end

-- Haphazardly throw the deepcopy algorithm in the general direction of the global space.
rawset(_G, "deepcopy_nonrecursive", deepcopy_nonrecursive)

return deepcopy_nonrecursive -- Satisfy the 0 other people who use dofile to load libraries like these
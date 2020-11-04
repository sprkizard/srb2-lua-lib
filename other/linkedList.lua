--[[

-- linkedList.lua, version v1.0.0
	*	A doubly-linked list implementation in SRB2's Lua.
 
	*	Authors: Golden
	*	Originally Released: September 11, 2020 22:08 CST

-- Load this Lua:
	--- local linkedList = dofile("linkedList.lua")
		*	(linkedList will also be automatically put in the global space if other methods of loading are desirable)

-- Usage:
	--- linkedList.newList(): list
		*	Returns a new linked list.

	--- linkedList.newNode([data]): node
		*	Returns a new node with data.

	--- linkedList.forward(list): iterator
		*	Iterates a list forward.

	--- linkedList.backward(list): iterator
		*	Iterates a list backward.

	--- linkedList.insertBeginning(node, list): node
	--- node:insertBeginning(list): node
		*	Insert node at the beginning of a list. Removes from the previous list it was in.

	--- linkedList.insertEnd(node, list): node
	--- node:insertEnd(list): node
		*	Insert node at the end of a list. Removes from the previous list it was in.

	--- linkedList.insertBefore(node, list, [anchorNode]): node
	--- node:insertBefore(list, [anchorNode]): node
		*	Insert node before an optional `anchorNode'. Removes from the previous list it was in.
		*	If there is no `anchorNode' given then it will insert `node' at the beginning of the list.
			(Useful if you want to call `linkedList.insertBefore' with the beginning or end of a list as an `anchorNode'.)

	--- linkedList.insertAfter(node, list, [anchorNode]): node
	--- node:insertAfter(list, [anchorNode]): node
		*	Insert node after an optional `anchorNode'. Removes from the previous list it was in.
		*	If there is no `anchorNode' given then it will insert `node' at the beginning of the list.
			(Useful if you want to call `linkedList.insertAfter' with the beginning or end of a list as an `anchorNode'.)

	--- linkedList.removeFromList(node, [list]): node
	--- node:removeFromList([list]):
		*	Remove node from the specified list. If no list is specified it will use the last list it seen.

--]]

// Global table of linked list manipulation functions.
local linkedList = {}

// Functions that are also global, but also are part of nodes; node manipulation functions.
local nodeFuncs = {}

// Inserts a node to the beginning of a list.
nodeFuncs.insertBeginning = function(node, list)
	// Remove from previous list (if any).
	if node.list then
		node:removeFromList(node.list)
	end

	rawset(node, "locked", false) // Unlock free access to node variables.

	node.list = list // Update list pointer.

	if list.first == nil then // List is empty? Fill with new entries!
		list.first = node
		list.last = node
		node.prev = nil
		node.next = nil
	else // Otherwise just insert this before the first list entry.
		nodeFuncs.insertBefore(node, list, list.first)
	end

	rawset(node, "locked", true) // Relock access to node variables.

	return node // Return node.
end

// Inserts a node to the end of a list.
nodeFuncs.insertEnd = function(node, list)
	// Remove from previous list (if any).
	if node.list then
		node:removeFromList(node.list)
	end

	rawset(node, "locked", false) // Unlock free access to node variables.

	node.list = list // Update list pointer.

	if list.last == nil then // List is empty? Fill with new entries!
		list.first = node
		list.last = node
		node.prev = nil
		node.next = nil
	else // Otherwise just insert this after the last list entry.
		nodeFuncs.insertAfter(node, list, list.last)
	end

	rawset(node, "locked", true) // Relock access to node variables.

	return node // Return node.
end

// Inserts a node before another node (or the beginning in absentia)
nodeFuncs.insertBefore = function(node, list, anchorNode)
	// Remove from previous list (if any).
	if node.list then
		node:removeFromList(node.list)
	end

	// Figure out a valid anchorNode.
	anchorNode = anchorNode == nil and list.first or anchorNode

	// No valid anchorNode? Just insert into the beginning then.
	if not anchorNode then
		return nodeFuncs.insertBeginning(node, list)
	end

	// node's the anchorNode? Don't continue, we can't insert the same node before itself!
	if anchorNode == node then
		return node
	end

	rawset(node, "locked", false) // Unlock free access to node variables.
	rawset(anchorNode, "locked", false) // Unlock free access to anchorNode variables.

	node.list = list // Update list pointer.

	node.next = anchorNode // Place anchorNode after node.

	if anchorNode.prev == nil then // If anchorNode is the first entry...
		list.first = node // Update list's first entry.
	else // Otherwise...
		anchorNode.prev.next = node // Place node after what used to go behind anchorNode.
	end

	node.prev = anchorNode.prev // Place anchorNode's previous node before node.
	anchorNode.prev = node // Place node before anchorNode.

	rawset(node, "locked", true) // Relock access to node variables.
	rawset(anchorNode, "locked", true) // Relock access to anchorNode variables.

	return node // Return node.
end

// Inserts a node after another node (or the end in absentia)
nodeFuncs.insertAfter = function(node, list, anchorNode)
	// Remove from previous list (if any).
	if node.list then
		node:removeFromList(node.list)
	end

	// Figure out a valid anchorNode.
	anchorNode = anchorNode == nil and list.last or anchorNode

	// No valid anchorNode? Just insert into the end then.
	if not anchorNode then
		return nodeFuncs.insertEnd(node, list)
	end

	// node's the anchorNode? Don't continue, we can't insert the same node after itself!
	if anchorNode == node then
		return
	end

	rawset(node, "locked", false) // Unlock free access to node variables.
	rawset(anchorNode, "locked", false) // Unlock free access to anchorNode variables.

	node.list = list // Update list pointer.

	node.prev = anchorNode // Place anchorNode before node.

	if anchorNode.next == nil then // If anchorNode is the last entry...
		list.last = node // Update list's last entry.
	else // Otherwise...
		anchorNode.next.prev = node // Place node before what used to go ahead of anchorNode.
	end

	node.next = anchorNode.next // Place anchorNode's next node after node.
	anchorNode.next = node // Place node after anchorNode.

	rawset(node, "locked", true) // Relock access to node variables.
	rawset(anchorNode, "locked", true) // Relock access to anchorNode variables.

	return node // Return node.
end

// Removes a node from a list (using the node's last seen list in absentia)
nodeFuncs.removeFromList = function(node, list)
	list = list or node.list // Figure out a valid list

	if not list then // No valid list? Don't continue, we don't want to mess up references!
		return node
	end

	rawset(node, "locked", false) // Unlock free access to node variables.

	if node.prev then // There's a previous node?
		rawset(node.prev, "locked", false) // Unlock free access to previous node's variables.
		node.prev.next = node.next // Make the previous node reference the next node.
		rawset(node.prev, "locked", true) // Relock access to previous node's variables.
	end

	if node.next then // There's a next node?
		rawset(node.next, "locked", false) // Unlock free access to next node's variables.
		node.next.prev = node.prev // Make the next node reference the previous node.
		rawset(node.next, "locked", true) // Relock access to next node's variables.
	end

	if list.last == node then // If the last node is referencing us,
		list.last = node.prev // make it reference the previous node instead.
	end

	if list.first == node then // If the first node is referencing us,
		list.first = node.next // make it reference the next node instead.
	end

	// Remove our own references to other nodes and the list.
	node.list = nil
	node.prev = nil
	node.next = nil

	rawset(node, "locked", true) // Relock access to node variables.

	return node // Return node.
end

// Allow the node functions to be accessible from linkedList
setmetatable(linkedList, {__index = nodeFuncs})

// Creates a new list.
linkedList.newList = function()
	return {first = nil, last = nil} // Not even a metatable needed.
end

// Iterates a list forward.
linkedList.forward = function(list)
	local node = list.first // Start at the first node of the list.

	// Generate functions
	return function()
		local returnme = node // Get current node to return (or nil)

		if node then // If this is a node, then prepare the next node for usage on the next iteration
			node = node.next
		end

		return returnme // Return the current node.
	end
end

// Iterates a list backward.
linkedList.backward = function(list)
	local node = list.last // Start at the last node of the list.

	// Generate functions
	return function()
		local returnme = node // Get current node to return (or nil)

		if node then // If this is a node, then prepare the previous node for usage on the next iteration
			node = node.prev
		end

		return returnme // Return the current node.
	end
end

// Creates a new node.
linkedList.newNode = function(data)
	local keys = {prev = true, data = true, next = true, locked = true, list = true} // Usable keys
	local node = {prev = nil, data = data, next = nil, locked = true, list = nil}

	return setmetatable(node, {
		__index = nodeFuncs, // Allow the node functions to be accessible from a node
		__newindex = function(node, key, value)
			if (keys[key] and not node.locked) // Allow the creation of any usable key when unlocked
			or key == "data" then // but only "data" when locked.
				rawset(node, key, value)
			end
		end, // Don't allow new indices.
		__usedindex = function(node, key, value) // Only allow editing of data, unless unlocked.
			if key == "data" or not node.locked then
				rawset(node, key, value)
			end
		end,
		__shl = function(node, shift_amount) // Left shifting, quick way to move node left in list.
			// Keep shifting left until we either hit the beginning or don't need to continue shifting
			while shift_amount > 0 and node.prev != nil do
				node:insertBefore(node.list, node.prev)
				shift_amount = $ - 1
			end
		end,
		__shr = function(node, shift_amount) // Right shifting, quick way to move node right in list.
			// Keep shifting right until we either hit the end or don't need to continue shifting
			while shift_amount > 0 and node.next != nil do
				node:insertAfter(node.list, node.next)
				shift_amount = $ - 1
			end
		end,
		__metatable = true // Don't allow viewing or editing of metatable either...
	})
end

rawset(_G, "linkedList", linkedList) // Globalise.

return linkedList // Return.
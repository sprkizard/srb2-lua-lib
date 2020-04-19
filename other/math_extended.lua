--[[

* math_extended.lua
* (sprkizard)
* (none)

* Desc: More functions for math related things

* Usage: 

]]

rawset(_G, "math", {})

function math.map(x, in_min, in_max, out_min, out_max)
	return out_min + (x - in_min)*(out_max - out_min)/(in_max - in_min)
end

local function checkBounds(x1, y1, x2, y2)
end

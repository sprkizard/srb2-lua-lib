
-- A wrapper that automatically converts a lua mapheader string into an integer,
-- with a default value as a callback
rawset(_G, "M_GetMapLuaInt", function(luastr, defaultvalue)
	if not luastr then
		return defaultvalue
	else
		return tonumber(luastr)
	end
end)

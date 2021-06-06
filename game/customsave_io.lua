--[[
* customsave_io.lua
* (sprkizard)
* (June 11, 2020 16:08)
* Desc: Library for Saving/Loading data into a custom file in SRB2 I/O
		https://wiki.srb2.org/wiki/User:Rapidgame7/iodocs

* Usage: Refer to - https://github.com/sprkizard/srb2-lua-lib/wiki/I-O-Easy-Custom-Save-Files
]]

-- Create global name for save functions
rawset(_G, "SaveData_I", {})




-- Converts a Lua table to a text representation.
local function Serialize(input)
	if type(input) == "string" then
		return "[[" .. input:gsub("](%--)]", "]-%1]") .. "]]"
	elseif type(input) == "number" then
		return "[" .. input .. "]"
	elseif type(input) == "boolean" then
		if input then
			return "T"
		else
			return "F"
		end
	elseif type(input) == "nil" then
		return "N"
	elseif type(input) == "table" then

		local str = "{"
		
		local delimit = false
		for k,v in pairs(input) do
			if delimit then
				str = $ .. ";"
			end
			
			str = $ .. Serialize(k) .. ":" .. Serialize(v)
			
			delimit = true
		end
		
		str = $ .. "}"
		return str
		
	else
		error("table contains a non-serializable element!")
	end
end

-- Converts the text representation of a Lua table back to the original table.
local function Deserialize(input)
	local output

	if input:sub(1, 2) == "[[" then -- string
		local endpos = input:find("]]")
		output = input:sub(3, endpos-1):gsub("]%-(%--)]", "]%1]")
		input = $:sub(endpos+2)
	elseif input:sub(1, 1) == "[" then -- number
		local endpos = input:find("]")
		output = tonumber(input:sub(2, endpos-1))
		input = $:sub(endpos+1)
	elseif input:sub(1, 1) == "T" then -- true
		output = true
		input = $:sub(2)
	elseif input:sub(1, 1) == "F" then -- false
		output = false
		input = $:sub(2)
	elseif input:sub(1, 1) == "N" then -- nil
		output = nil
		input = $:sub(2)
	elseif input:sub(1, 2) == "{}" then -- empty table
		output = {}
		input = $:sub(3)
	elseif input:sub(1, 1) == "{" then -- table
		output = {}
		
		while input:sub(1, 1) ~= "}" do
			local key, value
			
			key, input = Deserialize(input:sub(2))
			if input:sub(1, 1) ~= ":" then
				error("string is badly formatted! "..input)
			end
			
			value, input = Deserialize(input:sub(2))
			
			output[key] = value
		end
		
		input = $:sub(2)
	else
		error("string is badly formatted! "..input)
	end
	
	if input:len() then
		return output, input
	else
		return output
	end
end




-- Simple encrtyps/decrypts a text string or file
local function convert(chars,dist,inv)
	local charInt = string.byte(chars);
	for i=1,dist do
		if(inv)then charInt = charInt - 1; else charInt = charInt + 1; end
		if(charInt<32)then
			if(inv)then charInt = 126; else charInt = 126; end
		elseif(charInt>126)then
			if(inv)then charInt = 32; else charInt = 32; end
		end
	end
	return string.char(charInt);
end

local function crypt(str,k,inv)
	local enc= "";
	for i=1,#str do
		if(#str-k[5] >= i or not inv)then
			for inc=0,3 do
				if(i%4 == inc)then
					enc = enc .. convert(string.sub(str,i,i),k[inc+1],inv);
					break;
				end
			end
		end
	end
	if(not inv)then
		for i=1,k[5] do
			enc = enc .. string.char(P_RandomRange(32,126));
		end
	end
	return enc;
end

local enc1 = {1,2,3,4,0};
local enc2 = {124,533,663,123,27};






-- Reading data

-- Checks if a local file exists
function SaveData_I.FileExists(fileStr)

	local f = io.openlocal(fileStr, "r")
	
	if f ~= nil then
		f:close()
		return true
	else
		return false
	end
end

-- Reads a saved table into a variable from a file path
function SaveData_I.ReadSaveFile(fileStr, decrypt)
	
	local file = io.openlocal(fileStr) -- TODO: try regular open()
	
	if (file == nil) then
		print("Save Data is either missing or corrupt.")
		-- file:close()
	else
		local loaded_file = file:read("*a")

		file:close()

		if (decrypt) then
			return Deserialize(crypt(loaded_file, enc2, true))
		else
			return Deserialize(loaded_file)
		end
	end
	
	return false
end



-- Writing data

-- Writes a save table to the specified file path
function SaveData_I.WriteSaveFile(fileStr, dataTable, encrypt)
	
	local file = io.openlocal(fileStr, "w+") -- TODO: try regular open()

	if (encrypt) then
		file:write(crypt(Serialize(data), enc2))
	else
		file:write(Serialize(dataTable))
	end

	file:flush()

	file:close()
end


-- Testing Commands
-- (Each command will write/write a test file with a sample table)

local devsave = {
	One = "One",
	Two = 2,
	Three = False,
	Four = {},
}

-- Reads the test file, and prints its data
COM_AddCommand("readfile", function()

	-- if titlemapinaction and not (netgame or multiplayer) then
	devsave = I_ReadSaveFile("iosave_test.txt")

	for k,v in pairs(devsave) do
		print(k,v)
	end
	-- end
end)

-- Writes a test file with a sample table
COM_AddCommand("writefile", function()

	-- if titlemapinaction and not (netgame or multiplayer) then
		I_WriteSaveFile("iosave_test.txt", devsave)
	-- end
end)




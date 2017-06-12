local MAJOR, MINOR = "Module:Serialization-1.0", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then
  return -- no upgrade needed
end
local Serialization = APkg and APkg.tPackage or {}
local _ENV = nil -- blocking globals in Lua 5.2
Serialization.null = setmetatable ({}, {
  __toinn = function () return "null" end
})

-- Compact number serialization
local kCharNum = { ["a"]=0, ["b"]=1, ["c"]=2, ["d"]=3, ["e"]=4, ["f"]=5, ["g"]=6, ["h"]=7, ["i"]=8, ["j"]=9, ["k"]=10, ["l"]=11, ["m"]=12, ["n"]=13, ["o"]=14, ["p"]=15, ["q"]=16, ["r"]=17, ["s"]=18, ["t"]=19, ["u"]=20, ["v"]=21, ["w"]=22, ["x"]=23, ["y"]=24, ["z"]=25, ["A"]=26, ["B"]=27, ["C"]=28, ["D"]=29, ["E"]=30, ["F"]=31, ["G"]=32, ["H"]=33, ["I"]=34, ["J"]=35, ["K"]=36, ["L"]=37, ["M"]=38, ["N"]=39, ["O"]=40, ["P"]=41, ["Q"]=42, ["R"]=43, ["S"]=44, ["T"]=45, ["U"]=46, ["V"]=47, ["W"]=48, ["X"]=49, ["Y"]=50, ["Z"]=51, ["1"]=52, ["2"]=53, ["3"]=54, ["4"]=55, ["5"]=56, ["6"]=57, ["7"]=58, ["8"]=59, ["9"]=60, ["0"]=61, ["!"]=62, ["@"]=63, ["#"]=64, ["$"]=65, ["%"]=66, ["^"]=67, ["&"]=68, ["*"]=69, ["("]=70, [")"]=71, ["`"]=72, ["-"]=73, ["="]=74, ["["]=75, ["]"]=76, ["\\"]=77, [";"]=78, ["'"]=79, [","]=80, ["."]=81, ["/"]=82, ["~"]=83, ["_"]=84, ["+"]=85, ["{"]=86, ["}"]=87, ["|"]=88, [":"]=89, ["\""]=90, ["<"]=91, [">"]=92, ["?"]=93
}

local kNumChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()`-=[]\\;',./~_+{}|:\"<>?"

function Serialization.SerializeNumber(number, digits)
	local result = ""
	for i=1,digits do
		local digitValue = number % 94
		result = result .. string.sub(kNumChars, digitValue+1, digitValue+1)
		number = math.floor(number / 94)
	end
	return result
end

function Serialization.DeserializeNumber(code)
	local result = 0
	for i=#code,1,-1 do
		result = result * 94 + kCharNum[string.sub(code,i,i)]
	end
	return result
end

--------------------
-- arg/return marshallers for rpcs
--------------------

function Serialization.NUMBER(length)
	return {
		chars = length,
		Encode = function(marshal, value, code, last)
			return code .. Serialization.SerializeNumber(value, marshal.chars)
		end,
		Decode = function(marshal, code, last)
			return Serialization.DeserializeNumber(string.sub(code, 1, marshal.chars)),
				string.sub(code, marshal.chars + 1)
		end
	}
end

function Serialization.STRING(length)
	return {
		chars = length,
		Encode = function(marshal, value, code, last)
			return code .. string.sub(value, 1, marshal.chars)
		end,
		Decode = function(marshal, code, last)
			return string.sub(code, 1, marshal.chars),
				string.sub(code, marshal.chars + 1)
		end
	}
end

Serialization.VARSTRING = {
	Encode = function(marshal, value, code, last)
		if last then
			return code .. value
		else
			local length = string.len(value)
			return code .. Serialization.SerializeNumber(length, 1) .. value
		end
	end,
	Decode = function(marshal, code, last)
		if last then
			return code, ""
		else
			local length = Serialization.DeserializeNumber(string.sub(code, 1, 1))
			return string.sub(code, 2, length + 1), string.sub(code, length+2)
		end
	end
}

Apollo.RegisterPackage(Serialization, MAJOR, MINOR, {})
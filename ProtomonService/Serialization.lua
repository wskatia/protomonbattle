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

function Serialization.SerializeNumber(number, digits)
	local result = ""
	for i=1,digits do
		local digitValue = number % 94
		result = result .. string.char(digitValue + 33)
		number = math.floor(number / 94)
	end
	return result
end

function Serialization.DeserializeNumber(code)
	local result = 0
	for i=#code,1,-1 do
		result = result * 94 + (string.byte(string.sub(code,i,i)) - 33)
	end
	return result
end

--------------------
-- arg/return marshallers for rpcs
--------------------

-- supports values up to 94^length - 1
function Serialization.NUMBER(length)
	return {
		chars = length,
		Encode = function(marshal, value, code, last)
			return code .. Serialization.SerializeNumber(value, marshal.chars)
		end,
		Decode = function(marshal, code, last)
			return Serialization.DeserializeNumber(string.sub(code, 1, marshal.chars)),
				string.sub(code, marshal.chars + 1)
		end,
		FixedLength = function(marshal)
			return true
		end,
	}
end

function Serialization.SIGNEDNUMBER(length)
	return {
		chars = length,
		Encode = function(marshal, value, code, last)
			return code .. Serialization.SerializeNumber(value + math.floor(94^length / 2), marshal.chars)
		end,
		Decode = function(marshal, code, last)
			return Serialization.DeserializeNumber(string.sub(code, 1, marshal.chars)) - math.floor(94^length / 2), string.sub(code, marshal.chars + 1)
		end,
		FixedLength = function(marshal)
			return true
		end,
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
		end,
		FixedLength = function(marshal)
			return true
		end,
	}
end

Serialization.VARNUM = {
	Encode = function(marshal, value, code, last)
		if last then
			return code .. Serialization.SerializeNumber(value, math.ceil(math.log(value + 1) / math.log(94)))
		else
			local result = Serialization.SerializeNumber(value % 47, 1)
			value = math.floor(value / 47)
			while value > 0 do
				local digit = value % 47 + 47
				result = Serialization.SerializeNumber(digit, 1) .. result
				value = math.floor(value / 47)
			end
			return code .. result
		end
	end,
	Decode = function(marshal, code, last)
		if last then
			return Serialization.DeserializeNumber(code), ""
		else
			local result = 0
			while true do
				local digit = Serialization.DeserializeNumber(string.sub(code, 1, 1))
				code = string.sub(code, 2)
				if digit > 47 then
					result = result * 47 + (digit - 47)
				else
					result = result * 47 + digit
					break
				end
			end
			return result, code
		end
	end,
	FixedLength = function(marshal)
		return false
	end,
}

Serialization.VARSIGNEDNUM = {
	Encode = function(marshal, value, code, last)
		local designedValue = math.abs(value * 2)
		if value < 0 then designedValue = designedValue + 1 end
		return Serialization.VARNUM.Encode(marshal, designedValue, code, last)
	end,
	Decode = function(marshal, code, last)
		local value, code = Serialization.VARNUM.Decode(marshal, code, last)
		local signedValue = math.floor(value / 2)
		if value % 2 == 1 then signedValue = signedValue * -1 end
		return signedValue, code
	end,
	FixedLength = function(marshal)
		return false
	end,
}

Serialization.VARSTRING = {
	Encode = function(marshal, value, code, last)
		if last then
			return code .. value
		else
			local length = string.len(value)
			return Serialization.VARNUM:Encode(length, code, false) .. value
		end
	end,
	Decode = function(marshal, code, last)
		if last then
			return code, ""
		else
			local length, code = Serialization.VARNUM:Decode(code, false)
			return string.sub(code, 1, length), string.sub(code, length+1)
		end
	end,
	FixedLength = function(marshal)
		return false
	end,
}

function Serialization.ARRAY(length, elementMarshal)
	return {
		elements = length,
		subMarshal = elementMarshal,
		Encode = function(marshal, value, code, last)
			for i = 1, marshal.elements do
				code = marshal.subMarshal:Encode(value[i], code, last and i == marshal.elements)
			end
			return code
		end,
		Decode = function(marshal, code, last)
			local result = {}
			for i = 1, marshal.elements do
				result[i], code = marshal.subMarshal:Decode(code, last and i == marshal.elements)
			end
			return result, code
		end,
		FixedLength = function(marshal)
			return elementMarshal:FixedLength()
		end,
	}
end

function Serialization.VARARRAY(elementMarshal)
	return {
		subMarshal = elementMarshal,
		Encode = function(marshal, value, code, last)
			if last and #value == 0 then return code end
			if not last or not marshal.subMarshal:FixedLength() then
				code = Serialization.VARNUM:Encode(#value, code, false)
			end
			for i = 1, #value do
				code = marshal.subMarshal:Encode(value[i], code, false)
			end
			return code
		end,
		Decode = function(marshal, code, last)
			local result = {}
			if not last or not marshal.subMarshal:FixedLength() then
				local length, code = Serialization.VARNUM:Decode(code, false)
				for i = 1, length do
					result[i] = marshal.subMarshal:Decode(code, false)
				end
			else
				while code ~= "" do
					element, code = marshal.subMarshal:Decode(code, false)
					table.insert(result, element)
				end
			end
			return result, code
		end,
		FixedLength = function(marshal)
			return false
		end,
	}
end

function Serialization.TUPLE(...)
	return {
		subMarshals = arg,
		Encode = function(marshal, value, code, last)
			for i = 1, #marshal.subMarshals do
				code = marshal.subMarshals[i]:Encode(value[i], code, last and i == #subMarshals)
			end
			return code
		end,
		Decode = function(marshal, code, last)
			local result = {}
			for i = 1, #marshal.subMarshals do
				result[i], code = marshal.subMarshals[i]:Decode(code, last and i == #subMarshals)
			end
			return result, code
		end,
		FixedLength = function(marshal)
			for i = 1, #marshal.subMarshals do
				if not marshal.subMarshals[i]:FixedLength() then
					return false
				end
			end
			return true
		end,
	}
end

Apollo.RegisterPackage(Serialization, MAJOR, MINOR, {})
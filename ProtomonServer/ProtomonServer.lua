-- piece of decor Protomon Server's housing plot
local kDecorLo = 23340907
local kDecorHi = 352321536

local ProtomonService
local S

local ProtomonServer = {}

function ProtomonServer:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ProtomonServer:Init()
	Apollo.RegisterAddon(self, false, "", {})
end

function ProtomonServer:OnLoad()
	Apollo.RegisterEventHandler("ChatMessage", "OnChat", self)

	self.playercodes = {}
	self.experience = {}
	self.skillups = {}
	self.prospects = {}

	self.protomonServiceConnectTimer = ApolloTimer.Create(1, true, "ConnectProtomonService", self)
	self.serializationConnectTimer = ApolloTimer.Create(1, true, "ConnectSerialization", self)
	self.afkTimer = ApolloTimer.Create(300, true, "StayAlive", self)  -- avoid afk timeout
	self.persistTimer = ApolloTimer.Create(3600, true, "Persist", self)  -- save data
end

--------------------
-- Service implementations
--------------------

function ProtomonServer:GetBattleCode(player)
	local code = self.playercodes[player]
	
	-- give unregistered players an introductory team
	if code == nil then code = "yyyyy" end

	return code
end

function ProtomonServer:NewPlayer(player)
	self.playercodes[player] = "a#aa#"
	self.experience[player] = {0,0,0,0,0}
	self.skillups[player] = {0,0,0,0,0}
end

function ProtomonServer:ChangeProtomon(player, protomon_id, newcode)
	local code = self.playercodes[player]
	self.playercodes[player] = string.sub(code, 1, protomon_id - 1) .. newcode .. string.sub(code, protomon_id + 1)
end

-- Protomon skill changes will favor minor adjustments of current loadout rather than complete randomization
local costs = {1,1,1,1,2,2}
function ProtomonServer:FindProtomon(player, protomon_id, level)
	-- register player if doesn't exist
	if not self.playercodes[player] then
		self:NewPlayer(player)
	end
	
	-- get info about current protomon
	local code = string.sub(self.playercodes[player], protomon_id, protomon_id)
	local bits = {}
	local cost = 0
	local one_sets = {}
	local one_unsets = {}
	local two_sets = {}
	local two_unsets = {}
	local value = S.DeserializeNumber(code)
	if value >= 64 then
		-- no protomon, make a new one
		self:ChangeProtomon(player, protomon_id, S.SerializeNumber(0,1))
		return 0
	end
	for i=1,6 do
		bits[i] = value % 2
		if bits[i] == 1 then
			if costs[i] == 1 then
				table.insert(one_sets, i)
			else
				table.insert(two_sets, i)
			end
			cost = cost + costs[i]
		else
			if costs[i] == 1 then
				table.insert(one_unsets, i)
			else
				table.insert(two_unsets, i)
			end
		end
		value = math.floor(value / 2)
	end

	local levelup = false
	if (self.skillups[player][protomon_id] < 10 or cost >= 3) and cost > 0 then
		-- handle skill swaps
		self.skillups[player][protomon_id] = self.skillups[player][protomon_id] + 1
		if cost == 1 then -- level 1, just swap one skill for another
			local togain = one_unsets[math.random(#one_unsets)]
			bits[one_sets[1]] = 0
			bits[togain] = 1
		else
			togain = math.random(#one_unsets + #two_unsets)
			if togain <= #one_unsets then -- gaining a 1 pt skill
				togain = table.remove(one_unsets, togain) -- remember which; we may want to gain another
				bits[togain] = 1
				local tolose = math.random(#one_sets + #two_sets)
				if tolose <= #one_sets then
					bits[one_sets[tolose]] = 0
				else -- we are losing a 2 pter, so gain another 1pter
					bits[two_sets[tolose - #one_sets]] = 0
					bits[one_unsets[math.random(#one_unsets)]] = 1
				end
			else -- gaining a 2 pt skill
				togain = two_unsets[togain - #one_unsets]
				bits[togain] = 1
				if #one_sets < 2 then -- not enough 1pters, have to sacrifice a 2pter
					bits[two_sets[math.random(#two_sets)]] = 0
				else
					local tolose = math.random(#one_sets + #two_sets)
					if tolose <= #one_sets then -- gonna have to lose another 1pter
						tolose = table.remove(one_sets, tolose)
						bits[tolose] = 0
						bits[one_sets[math.random(#one_sets)]] = 0
					else -- lost a 2pter, so we are covered
						bits[two_sets[tolose - #one_sets]] = 0
					end
				end
			end
		end
	else
		-- handle level ups
		levelup = true
		bits[one_unsets[math.random(#one_unsets)]] = 1
		self.skillups[player][protomon_id] = 0
	end
	
	local newcodenumber = 0
	for i=6,1,-1 do
		newcodenumber = newcodenumber * 2 + bits[i]
	end
	newcode = S.SerializeNumber(newcodenumber, 1)
	if levelup then
		self:ChangeProtomon(player, protomon_id, newcode)
	else
		self.prospects[player] = {protomon_id, newcodenumber}
	end
	return newcodenumber
end

function ProtomonServer:AcceptProtomon(player, protomon_id)
	if self.prospects[player] and self.prospects[player][1] == protomon_id then
		local codenumber = self.prospects[player][2]
		local code = S.SerializeNumber(codenumber, 1)
		self:ChangeProtomon(player, protomon_id, code)
		self.prospects[player] = nil
		return codenumber
	else
		return 64
	end
end

--------------------
-- Startup connections
--------------------

function ProtomonServer:ConnectSerialization()
	if not S then
		local pack = Apollo.GetPackage("Module:Serialization-1.0")
		if pack then
			S = pack.tPackage
		end
	else
		self.serializationConnectTimer:Stop()
	end
end

function ProtomonServer:ConnectProtomonService()
	if not ProtomonService then
		ProtomonService = Apollo.GetAddon("ProtomonService")
		if ProtomonService then
			ProtomonService:Implement("ProtomonServer", "GetBattleCodes",
			function(caller, player1, player2)
				return self:GetBattleCode(player1), self:GetBattleCode(player2)
			end)

			ProtomonService:Implement("ProtomonServer", "GetMyCode",
			function(caller)
				return self:GetBattleCode(caller)
			end)

			ProtomonService:Implement("ProtomonServer", "JoinProtomon",
			function(caller)
				self:NewPlayer(caller)
			end)
			
			ProtomonService:Implement("ProtomonServer", "FindProtomon",
			function(caller, protomon_id, level)
				return self:FindProtomon(caller, protomon_id, level)
			end)
			
			ProtomonService:Implement("ProtomonServer", "AcceptProtomon",
			function(caller, protomon_id)
				return self:AcceptProtomon(caller, protomon_id)
			end)

		end
	else
		self.protomonServiceConnectTimer:Stop()
	end
end

--------------------
-- Server health functions
--------------------

-- moving a decor staves off the afk logout
function ProtomonServer:StayAlive()
	local res = HousingLib.GetResidence()
	
	if res ~= nil then
		local dec = res:GetDecorById(kDecorLo, kDecorHi)
		if dec ~= nil then
			dec:Select()
			dec:SetPosition(math.random(10), math.random(10), math.random(10))
			dec:Place()
		end
	end
end

-- reloading ui saves all player data in case of crash
function ProtomonServer:Persist()
	ChatSystemLib.Command("/reloadui")
end

--------------------
-- Test stuff, get rid of this later
--------------------

local function Whisper(msg, to)
	if to == GameLib.GetPlayerUnit():GetName() then
		Print(msg)
	else
		local command = "/w " .. to .. " " .. msg
		ChatSystemLib.Command(command)
	end
end

function ProtomonServer:OnChat(chan, msg)
	if msg.bSelf or chan:GetName() ~= "Whisper" then return end
	if string.sub(msg.arMessageSegments[1].strText, 1, 8) == "setteam " then
		local code = string.sub(msg.arMessageSegments[1].strText, 9)
		if string.len(code) == 5 then
			self.playercodes[msg.strSender] = code
			self.experience[msg.strSender] = {0,0,0,0,0}
			self.skillups[msg.strSender] = {0,0,0,0,0}
			Whisper("Team set!", msg.strSender)
		else
			Whisper("Bad code!", msg.strSender)
		end
		return
	else
		local result = ""
		for charname in string.gmatch(msg.arMessageSegments[1].strText, "[^,]+") do
			local code = self.playercodes[charname]
			if code == nil then code = "hhhhh" end
			result = result .. code
		end
		Whisper(result, msg.strSender)
	end

end

--------------------
-- Persistence
--------------------

function ProtomonServer:OnSave(eLevel)
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		local tSave = {}
		tSave.playercodes = self.playercodes
		tSave.experience = self.experience
		tSave.skillups = self.skillups
		return tSave
	end
end

function ProtomonServer:OnRestore(eLevel, tData)
	if tData == nil then return end
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		self.playercodes = tData.playercodes or {}
		self.experience = tData.experience or {}
		self.skillups = tData.skillups or {}
	end
end


local ProtomonServerInst = ProtomonServer:new()
ProtomonServerInst:Init()
-- piece of decor Protomon Server's housing plot
local kDecorLo = 23340907
local kDecorHi = 352321536

local ProtomonService

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
	self.protomon = {} -- if game gets popular, we will need a kd-tree eventually

	self.protomonServiceConnectTimer = ApolloTimer.Create(1, true, "ConnectProtomonService", self)
	self.afkTimer = ApolloTimer.Create(60, true, "StayAlive", self)  -- avoid afk timeout
	self.persistTimer = ApolloTimer.Create(3600, true, "Persist", self)  -- save data
end

--------------------
-- Utility functions
--------------------

local function MarkForDeath(parent, label, delay)
	local child = parent[label]
	child.myParent = parent
	child.myLabel = label
	child.Die = function(dying)
		dying.myParent[dying.myLabel] = nil
	end
	ApolloTimer.Create(delay, false, "Die", child)
end

--------------------
-- Service implementations
--------------------

function ProtomonServer:GetBattleCode(player)
	local code = self.playercodes[player]
	
	-- register new players
	if code == nil then
		self:NewPlayer(player)
		code = self.playercodes[player]
	end

	return code
end

function ProtomonServer:NewPlayer(player)
	self.playercodes[player] = {0, 64, 0, 0, 64} -- starter team is charenok, stemasaur, squig
	self.experience[player] = {0,0,0,0,0}
	self.skillups[player] = {0,0,0,0,0}
end

-- Protomon skill changes will favor minor adjustments of current loadout rather than complete randomization
local costs = {1,1,1,1,2,2}
function ProtomonServer:FindProtomon(player, protomonId)
	-- register player if doesn't exist
	if not self.playercodes[player] then
		self:NewPlayer(player)
	end
	
	-- get info about current protomon
	local code = self.playercodes[player][protomonId]
	local bits = {}
	local cost = 0
	local one_sets = {}
	local one_unsets = {}
	local two_sets = {}
	local two_unsets = {}
	if code >= 64 then
		-- no protomon, make a new one
		self.playercodes[player][protomonId] = 0
		return 0
	end
	for i=1,6 do
		bits[i] = code % 2
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
		code = math.floor(code / 2)
	end

	local levelup = false
	if (self.skillups[player][protomonId] < 1 or cost >= 3) and cost > 0 then
		-- handle skill swaps
		self.skillups[player][protomonId] = self.skillups[player][protomonId] + 1
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
		self.skillups[player][protomonId] = 0
	end
	
	local newcode = 0
	for i=6,1,-1 do
		newcode = newcode * 2 + bits[i]
	end
	if levelup then
		self.playercodes[player][protomonId] = newcode
	else
		self.prospects[player] = {protomonId, newcode}
	end
	return newcode
end

function ProtomonServer:AcceptProtomon(player, protomonId)
	if self.prospects[player] and self.prospects[player][1] == protomonId then
		local code = self.prospects[player][2]
		self.playercodes[player][protomonId] = code
		self.prospects[player] = nil
		return code
	else
		return 64
	end
end

function ProtomonServer:AddSpawn(typeLevel, worldId, position)
	if self.protomon[worldId] == nil then self.protomon[worldId] = {} end
	local newProtomon = {}
	newProtomon.typeLevel = typeLevel
	newProtomon.location = position
	newProtomon.viewers = {}
	newProtomon.takers = {}
	table.insert(self.protomon[worldId], newProtomon)
end

function ProtomonServer:RadarPulse(playerName, worldId, position)
	local nearbyProtomon = {}
	local nearestHeading = 64  -- 64 is considered non-existent heading
	local nearestDist
	
	-- TODO: this loop strong candidate for optimization if we have timeouts later; most likely
	-- it won't be an issue before comm limits are though
	for zoneId, protomon in pairs(self.protomon[worldId]) do  -- not ipairs, we skip over the gaps
		local distance = math.sqrt((position[1] - protomon.location[1])^2 +
			(position[2] - protomon.location[2])^2 +
			(position[3] - protomon.location[3])^2)
		if nearestDist == nil or distance < nearestDist then
			nearestDist = distance
			local protomonType = math.floor(protomon.typeLevel / 4)
			local protomonLevel = protomon.typeLevel % 4 + 1
			local heading
			local xDiff = protomon.location[1] - position[1]
			local zDiff = protomon.location[3] - position[3]
			if math.abs(zDiff) > math.abs(xDiff) then
				if zDiff > 0 then heading = 2 else heading = 0 end
			else
				if xDiff > 0 then heading = 1 else heading = 3 end
			end
			local isClose
			if distance < 200 then isClose = 1 else isClose = 0 end
			nearestHeading = protomonType * 8 + heading * 2 + isClose
		end
		if distance < 30 and not protomon.viewers[playerName] then
			table.insert(nearbyProtomon, {
				protomon.typeLevel,
				zoneId,
				{
					protomon.location[1] - position[1],
					protomon.location[2] - position[2],
					protomon.location[3] - position[3],
				}
			})
			protomon.viewers[playerName] = {}
			MarkForDeath(protomon.viewers, playerName, 600)
		end
	end
	
	return nearestHeading, nearbyProtomon
end

--------------------
-- Startup connections
--------------------

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
				function(caller, protomonId)
					return self:FindProtomon(caller, protomonId)
				end)
			
			ProtomonService:Implement("ProtomonServer", "AcceptProtomon",
				function(caller, protomonId)
					return self:AcceptProtomon(caller, protomonId)
				end)

			ProtomonService:Implement("ProtomonServer", "RadarPulse",
				function(caller, worldId, position)
					return self:RadarPulse(caller, worldId, position)
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "AddSpawn",
				function(caller, typeLevel, worldId, position)
					return self:AddSpawn(typeLevel, worldId, position)
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
-- Persistence
--------------------

function ProtomonServer:OnSave(eLevel)
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		local tSave = {}
		tSave.playercodes = self.playercodes
		tSave.experience = self.experience
		tSave.skillups = self.skillups
		tSave.protomon = self.protomon
		for _, world in pairs(tSave.protomon) do
			for _, protomon in pairs(world) do
				protomon.viewers = {}  -- do not save these
			end
		end
		return tSave
	end
end

function ProtomonServer:OnRestore(eLevel, tData)
	if tData == nil then return end
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		self.playercodes = tData.playercodes or {}
		self.experience = tData.experience or {}
		self.skillups = tData.skillups or {}
		self.protomon = tData.protomon or {}
	end
end


local ProtomonServerInst = ProtomonServer:new()
ProtomonServerInst:Init()
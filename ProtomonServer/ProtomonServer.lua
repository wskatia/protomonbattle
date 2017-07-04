local kVersion = 1

-- piece of decor Protomon Server's housing plot
local kDecorLo = 23340907
local kDecorHi = 352321536
local kAfkPeriod = 60
local kPersistPeriod = 3600

local kViewRefresh = 60
local kSpawnDelay = 30
local kViewDistance = 60
local kVerticalDistance = 30
local kHuntDistance = 100

local kLevelMultiplier = 10

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
	self.skillswaps = {}
	self.prospects = {}
	self.protomon = {}
	self.spawns = {}

	self.protomonServiceConnectTimer = ApolloTimer.Create(1, true, "ConnectProtomonService", self)
	self.afkTimer = ApolloTimer.Create(kAfkPeriod, true, "StayAlive", self)  -- avoid afk timeout
	self.persistTimer = ApolloTimer.Create(kPersistPeriod, true, "Persist", self)  -- save data
	self.spawnTimer = ApolloTimer.Create(kSpawnDelay, false, "Respawn", self) -- defer spawn calculations so delay doesn't stack with load time
end

function ProtomonServer:Respawn()
	local currentDay = GameLib.GetServerTime().nDayOfWeek
	if self.lastDay == currentDay then return end
	self.lastDay = currentDay

	-- TODO: make this conditional per zone
	for worldId, spawnset in pairs(self.spawns) do
		self.protomon[worldId] = {}
		
		for level, spawns in pairs(spawnset) do
			-- TODO: pick a set number from each level defined in zone params
			for spawnId, spawn in pairs(spawns) do
				table.insert(self.protomon[worldId], {
					level = level,
					location = spawn.location,
					protomonId = spawn.id,
					spawnId = spawnId,
					takers = {},
					viewers = {}
				})
			end
		end
	end
end

--------------------
-- Utility functions
--------------------

local function MarkForDeath(parent, label, delay)
	local child = parent[label]
	child.myParent = parent
	child.myLabel = label
	child.Die = function(dying)
		child.deathTimer:Stop()
		dying.myParent[dying.myLabel] = nil
	end
	child.deathTimer = ApolloTimer.Create(delay, false, "Die", child)
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
	self.playercodes[player] = {0, 64, 0, 0, 64}
	self.experience[player] = {0,0,0,0,0}
	self.skillswaps[player] = {0,0,0,0,0}
end

-- Protomon skill changes will favor minor adjustments of current loadout rather than complete randomization
local costs = {1,1,1,1,2,2}
function ProtomonServer:FindProtomon(player, worldId, zoneId)
	-- register player if doesn't exist
	if not self.playercodes[player] then
		self:NewPlayer(player)
	end
	
	Print(player .. " " .. worldId .. " " .. zoneId)
	if not self.protomon[worldId] or -- in a valid area?
		not self.protomon[worldId][zoneId] or -- this protomon exists?
		not self.protomon[worldId][zoneId].viewers[player] or -- player has seen it before capping?
		self.protomon[worldId][zoneId].takers[player] then -- player hasn't capped it already?
		return 64
	end
	local protomonId = self.protomon[worldId][zoneId].protomonId
	local level = self.protomon[worldId][zoneId].level
	self.protomon[worldId][zoneId].takers[player] = true
	self.protomon[worldId][zoneId].viewers[player]:Die()
	
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
		self.experience[player][protomonId] = 0
		self.skillswaps[player][protomonId] = 0
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

	-- was this at least a skillswap?
	if level < cost then
		self.experience[player][protomonId] = self.experience[player][protomonId] + kLevelMultiplier^level
		if math.random(2 * kLevelMultiplier^cost) > self.experience[player][protomonId] then
			return 64
		end
	end
	
	-- reset experience for skillswap, check if it's actually a levelup
	local levelup = false
	self.experience[player][protomonId] = 0
	self.skillswaps[player][protomonId] = self.skillswaps[player][protomonId] + 1
	if level > cost then
		self.skillswaps[player][protomonId] = self.skillswaps[player][protomonId] + 1
	end
	levelup = (cost == 0) or (cost < 3 and
		kLevelMultiplier + math.random(kLevelMultiplier) < self.skillswaps[player][protomonId])

	if not levelup then
		-- handle skill swaps
		if cost == 1 then -- level 1, just swap one skill for another
			local togain = one_unsets[math.random(#one_unsets)]
			bits[one_sets[1]] = 0
			bits[togain] = 1
		else
			local togain = math.random(#one_unsets + #two_unsets)
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
		bits[one_unsets[math.random(#one_unsets)]] = 1
		self.skillswaps[player][protomonId] = 0
	end
	
	local newcode = 0
	for i=6,1,-1 do
		newcode = newcode * 2 + bits[i]
	end
	if levelup then
		self.playercodes[player][protomonId] = newcode
	else
		self.prospects[player] = {newcode, protomonId}
	end
	return newcode
end

function ProtomonServer:AcceptProtomon(player, zoneId)
	if self.prospects[player] and self.prospects[player][2] == zoneId then
		local code = self.prospects[player][1]
		self.playercodes[player][self.prospects[player][2]] = code
		self.prospects[player] = nil
		return code
	else
		return 64
	end
end

function ProtomonServer:AddSpawn(protomonId, level, worldId, position)
	if self.protomon[worldId] == nil then self.protomon[worldId] = {} end
	local newProtomon = {}
	newProtomon.protomonId = protomonId
	newProtomon.level = level
	if protomonbattle_zones[worldId] then
		newProtomon.location = {
			position[1] / 4 + protomonbattle_zones[worldId].center.x,
			position[2] / 4 + protomonbattle_zones[worldId].center.y,
			position[3] / 4 + protomonbattle_zones[worldId].center.z,
		}
	else
		newProtomon.location = {
			position[1] / 4 + protomonbattle_zones["housing"].center.x,
			position[2] / 4 + protomonbattle_zones["housing"].center.y,
			position[3] / 4 + protomonbattle_zones["housing"].center.z,
		}
	end
	newProtomon.viewers = {}
	newProtomon.takers = {}

	if not self.spawns[worldId] then self.spawns[worldId] = {} end
	if not self.spawns[worldId][level] then self.spawns[worldId][level] = {} end
	table.insert(self.spawns[worldId][level], {
		id = protomonId,
		location = newProtomon.location,
	})
	newProtomon.spawnId = #self.spawns[worldId][level]

	table.insert(self.protomon[worldId], newProtomon)
end

function ProtomonServer:RemoveSpawn(worldId, zoneId)
	if self.protomon[worldId] == nil then self.protomon[worldId] = {} end
	
	local protomon = self.protomon[worldId][zoneId]
	self.protomon[worldId][zoneId] = nil

	if protomon.spawnId ~= nil then
		table.remove(self.spawns[worldId][protomon.level], protomon.spawnId)
		for _, inspect in pairs(self.protomon[worldId]) do
			if inspect.spawnId ~= nil and inspect.spawnId > protomon.spawnId and inspect.level == protomon.level then
				inspect.spawnId = inspect.spawnId - 1
			end
		end
	end
end

function ProtomonServer:RadarPulse(playerName, worldId, relativePosition)
	-- register player if doesn't exist
	if not self.playercodes[playerName] then
		self:NewPlayer(playerName)
	end

	local nearbyProtomon = {}
	local nearestHeading = {0, 0, 0} -- 0 element means no heading
	local nearestDist
	
	local position
	if protomonbattle_zones[worldId] then
		position = {
			relativePosition[1] + protomonbattle_zones[worldId].center.x,
			relativePosition[2] + protomonbattle_zones[worldId].center.y,
			relativePosition[3] + protomonbattle_zones[worldId].center.z,
		}
	else
		position = {
			relativePosition[1] + protomonbattle_zones["housing"].center.x,
			relativePosition[2] + protomonbattle_zones["housing"].center.y,
			relativePosition[3] + protomonbattle_zones["housing"].center.z,
		}
	end

	-- TODO: this loop strong candidate for optimization if we have timeouts later; most likely
	-- it won't be an issue before comm limits are though
	if not self.protomon[worldId] then return {0,0,0}, {} end
	for zoneId, protomon in pairs(self.protomon[worldId]) do  -- not ipairs, we skip over the gaps
		local protomonId = protomon.protomonId
		local protomonLevel = protomon.level
		if not protomon.takers[playerName] then
			local distance = math.sqrt((position[1] - protomon.location[1])^2 +
				(position[2] - protomon.location[2])^2 +
				(position[3] - protomon.location[3])^2)
			if nearestDist == nil or distance < nearestDist then
				nearestDist = distance
				local heading
				local xDiff = protomon.location[1] - position[1]
				local zDiff = protomon.location[3] - position[3]
				if math.abs(zDiff) > math.abs(xDiff) then
					if zDiff > 0 then heading = 2 else heading = 0 end
				else
					if xDiff > 0 then heading = 1 else heading = 3 end
				end
				local isClose
				if distance < kHuntDistance then isClose = 1 else isClose = 0 end
				nearestHeading = {protomonId, heading, isClose}
			end
			if distance < kViewDistance and 
				math.abs(protomon.location[2] - position[2]) < kVerticalDistance and
				not protomon.viewers[playerName] then
				table.insert(nearbyProtomon, {
					{
						protomonId,
						protomonLevel,
						zoneId,
					},
					{
						math.floor(4*(protomon.location[1] - position[1]) + 256),
						math.floor(4*(protomon.location[2] - position[2]) + 128),
						math.floor(4*(protomon.location[3] - position[3]) + 256),
					}
				})
				protomon.viewers[playerName] = {}
				MarkForDeath(protomon.viewers, playerName, kViewRefresh)
			end
		end
	end
	
	return nearestHeading, nearbyProtomon
end

function ProtomonServer:GetZoneInfo(worldId)
	local stats = {{0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}}
	for _, spawn in pairs(self.protomon[worldId]) do
		stats[spawn.protomonId][spawn.level] = stats[spawn.protomonId][spawn.level] + 1
	end
	return stats
end

function ProtomonServer:GetZoneList(worldId)
	local result = {}
	for i, spawn in pairs(self.protomon[worldId]) do
		table.insert(result, {
			{((spawn.protomonId - 1) % 6) + 1, spawn.level},
			{
				math.floor((spawn.location[1] - protomonbattle_zones[worldId].center.x + 5) / 10),
				math.floor((spawn.location[2] - protomonbattle_zones[worldId].center.y + 5) / 10),
				math.floor((spawn.location[3] - protomonbattle_zones[worldId].center.z + 5) / 10),
			},
		})
	end
	return result
end

--------------------
-- Startup connections
--------------------

function ProtomonServer:ConnectProtomonService()
	if not ProtomonService then
		ProtomonService = Apollo.GetAddon("ProtomonService")
		if ProtomonService then
			ProtomonService:Implement("ProtomonServer", "GetVersion",
				function(caller)
					return kVersion
				end)

			ProtomonService:Implement("ProtomonServer", "GetBattleCodes",
				function(caller, player1, player2)
					return self:GetBattleCode(player1), self:GetBattleCode(player2)
				end)

			ProtomonService:Implement("ProtomonServer", "GetMyCode",
				function(caller)
					return self:GetBattleCode(caller)
				end)

			ProtomonService:Implement("ProtomonServer", "FindProtomon",
				function(caller, worldId, zoneId)
					return self:FindProtomon(caller, worldId, zoneId)
				end)
			
			ProtomonService:Implement("ProtomonServer", "AcceptProtomon",
				function(caller, zoneId)
					return self:AcceptProtomon(caller, zoneId)
				end)

			ProtomonService:Implement("ProtomonServer", "RadarPulse",
				function(caller, worldId, position)
					return self:RadarPulse(caller, worldId, position)
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "SetTeam",
				function(caller, player, code)
					if not self.playercodes[player] then
						self:NewPlayer(player)
					end
					self.playercodes[player] = code
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "SetProtomon",
				function(caller, player, protomonId, code)
					if not self.playercodes[player] then
						self:NewPlayer(player)
					end
					self.playercodes[player][protomonId] = code
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "AddSpawn",
				function(caller, protomonId, level, worldId, position)
					return self:AddSpawn(protomonId, level, worldId, position)
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "RemoveSpawn",
				function(caller, worldId, zoneId)
					return self:RemoveSpawn(worldId, zoneId)
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "GetZoneInfo",
				function(caller, worldId)
					return self:GetZoneInfo(worldId)
				end)

			ProtomonService:Implement("ProtomonServerAdmin", "GetZoneList",
				function(caller, worldId)
					return self:GetZoneList(worldId)
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
		tSave.skillswaps = self.skillswaps
		tSave.protomon = self.protomon
		tSave.spawns = self.spawns
		for _, world in pairs(tSave.protomon) do
			for _, protomon in pairs(world) do
				protomon.viewers = {}  -- do not save these
			end
		end
		tSave.lastDay = self.lastDay
		return tSave
	end
end

function ProtomonServer:OnRestore(eLevel, tData)
	if tData == nil then return end
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		self.playercodes = tData.playercodes or {}
		self.experience = tData.experience or {}
		self.skillswaps = tData.skillswaps or {}
		self.protomon = tData.protomon or {}
		self.spawns = tData.spawns
		self.lastDay = tData.lastDay
	end
end


local ProtomonServerInst = ProtomonServer:new()
ProtomonServerInst:Init()
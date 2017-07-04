require "ICCommLib"
require "ICComm"
require "GuildLib"
local S = Apollo.GetPackage("Module:Serialization-1.0").tPackage

local kTimeout = 5
local kReservedChar = string.char(31) -- used to demarcate empty messages

local ProtomonService = {}

function ProtomonService:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ProtomonService:Init()
	Apollo.RegisterAddon(self, false, "", {})
end

ProtomonService.services = {
	["ProtomonServer"] = {
		host = "Protomon Server",
		channelType = ICCommLib.CodeEnumICCommChannelType.Global,
		rpcs = {
			["GetVersion"] = {
				args = {},
				returns = {
					S.VARNUM,
				},
			},

			-- pass two character names, receive their protomon codes
			["GetBattleCodes"] = {
				args = {
					S.VARSTRING, -- name of player 1
					S.VARSTRING, -- name of player 2
				},
				returns = {
					S.ARRAY(5, S.NUMBER(1)), -- protomon codes for player 1
					S.ARRAY(5, S.NUMBER(1)), -- protomon codes for player 2
				},
			},

			-- retrieve code for the caller
			["GetMyCode"] = {
				args = {},
				returns = {
					S.ARRAY(5, S.NUMBER(1)), -- protomon codes for caller
				},
			},

			-- called when finding a protomon in open world
			["FindProtomon"] = {
				args = {
					-- for ~400 plots, this hash gives us a ~0.1% collision probability
					S.NUMBER(4), -- hash of zone/housing
					S.VARNUM, -- zone-id of protomon
				},
				returns = {
					S.NUMBER(1), -- 6-bit code number of prospective skill change, 64 if none
				},
			},
			
			-- called when player wishes to accept prospective skill change
			["AcceptProtomon"] = {
				args = {
					S.NUMBER(1, true), -- protomon id
				},
				returns = {
					S.NUMBER(1), -- code number of new protomon loadout
				},
			},

			-- poll for nearby protomon
			-- will only return a particular protomon to a given player once, unless they
			-- call EnterWorld again, which will refresh those which have not been captured
			["RadarPulse"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
					S.TUPLE(S.SIGNEDNUMBER(2),  -- current position (x,y,z)
						S.VARSIGNEDNUM,  -- y-coord stands a reasonable chance of being 1 byte often
						S.SIGNEDNUMBER(2)),
				},
				returns = {
					S.BITARRAY(3, 2, 1), -- element, heading, range
					S.VARARRAY(S.TUPLE( -- nearby protomon
						S.BITARRAY(5, true, 2, true, 12), -- protomon-id, level, zone-id
						S.BITARRAY(9,8,9))), -- loc, relative to current position (x,y,z)
				},
			},
		},
	},
	["ProtomonServerAdmin"] = {
		host = "Protomon Server",
		channelType = ICCommLib.CodeEnumICCommChannelType.Guild, -- make this guild later
		guildName = "Protomon Administrators",
		rpcs = {
			-- assign protomon team
			["SetTeam"] = {
				args = {
					S.VARSTRING, -- player name to modify
					S.ARRAY(5, S.NUMBER(1)), -- new team code
				},
				returns = {},
			},
			
			-- assign specific protomon
			["SetProtomon"] = {
				args = {
					S.VARSTRING, -- player name to modify
					S.NUMBER(1), -- protomon id
					S.NUMBER(1), -- new code
				},
				returns = {},
			},
			
			-- create a protomon spawn here
			["AddSpawn"] = {
				args = {
					S.NUMBER(1), -- protomon id
					S.NUMBER(1), -- level
					S.NUMBER(4), -- hash of zone/housing
					S.ARRAY(3, S.VARSIGNEDNUM), -- position (x,y,z)
				},
				returns = {},
			},
			
			-- create a protomon spawn here until the next zone reset
			["AddTemporarySpawn"] = {
				args = {
					S.NUMBER(1), -- protomon id
					S.NUMBER(1), -- level
					S.NUMBER(4), -- hash of zone/housing
					S.ARRAY(3, S.VARSIGNEDNUM), -- position (x,y,z)
				},
				returns = {},
			},
			
			-- called when finding a protomon in open world
			["RemoveSpawn"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
					S.VARNUM, -- zone-id of protomon
				},
				returns = {},
			},
			
			-- get protomon spawn stats for current zone
			["GetZoneInfo"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
				},
				returns = {
					S.ARRAY(5, S.ARRAY(3, S.VARNUM)) -- For each protomon id, spawn counts per level
				},
			},
			
			-- get all protomon for zone (don't use too often)
			["GetZoneList"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
				},
				returns = {
					S.VARARRAY(S.TUPLE(
						S.BITARRAY(3, true, 3, true), -- element, level
						S.ARRAY(3, S.VARSIGNEDNUM))) -- zone relative position(x,y,z)
				},
			},
		},
	},
}

local function pack(...)
	return arg
end

local function GetGuild(name)
	for _, guild in pairs(GuildLib.GetGuilds()) do
		if guild:GetName() == name then return guild end
	end

	return nil
end

function ProtomonService:OnLoad()
	for serviceName, service in pairs(self.services) do
		for rpcName, rpc in pairs(service.rpcs) do
			local requestChannelName = serviceName .. "_" .. rpcName .. "_Request"
			local responseChannelName = serviceName .. "_" .. rpcName .. "_Response"

			rpc.ConnectRequest = function(rpc)
				if not rpc.requestComm then
					rpc.requestComm = ICCommLib.JoinChannel(requestChannelName, service.channelType, GetGuild(service.guildName))
					if rpc.requestComm then
						rpc.requestComm:SetReceivedMessageFunction("HandleRequest", self)
					end
				else
					rpc.requestConnectTimer:Stop()
				end
			end

			rpc.ConnectResponse = function(rpc)
				if not rpc.responseComm then
					rpc.responseComm = ICCommLib.JoinChannel(responseChannelName, service.channelType, GetGuild(service.guildName))
					if rpc.responseComm then
						rpc.responseComm:SetReceivedMessageFunction("HandleResponse", self)
					end
				else
					rpc.responseConnectTimer:Stop()
				end
			end

			rpc.HandleTimeout = function(rpc)
				rpc.pendingCallFailer()
				rpc.pendingCallFailer = nil
				rpc.pendingCallHandler = nil
			end
			
			rpc.requestConnectTimer = ApolloTimer.Create(1, true, "ConnectRequest", rpc)
			rpc.responseConnectTimer = ApolloTimer.Create(1, true, "ConnectResponse", rpc)
		end
	end
end

function ProtomonService:HandleRequest(iccomm, strMessage, strSender)
	local channel = iccomm:GetName()
	local firstSeparator = string.find(channel, "_")
	local secondSeparator = string.find(channel, "_", firstSeparator + 1)
	local serviceName = string.sub(channel, 1, firstSeparator - 1)
	local rpcName = string.sub(channel, firstSeparator + 1, secondSeparator - 1)
	local rpc = self.services[serviceName].rpcs[rpcName]
	if rpc.requestHandler == nil then return end
	
	if strMessage == kReservedChar then strMessage = "" end
	local args = {}
	for i = 1, #rpc.args do
		args[i], strMessage = rpc.args[i]:Decode(strMessage, i == #rpc.args)
	end
	table.insert(args, 1, strSender)
	local results = pack(rpc.requestHandler(unpack(args)))

	local resultstring = ""
	for i = 1, #rpc.returns do
		resultstring = rpc.returns[i]:Encode(results[i], resultstring, i==#rpc.returns)
	end
	if resultstring == "" then resultstring = kReservedChar end -- must send at least one char
	--Print(serviceName .. ":" .. rpcName .. " sent " .. resultstring)
	rpc.responseComm:SendPrivateMessage(strSender, resultstring)
end

function ProtomonService:HandleResponse(iccomm, strMessage, strSender)
	local channel = iccomm:GetName()
	local firstSeparator = string.find(channel, "_")
	local secondSeparator = string.find(channel, "_", firstSeparator + 1)
	local serviceName = string.sub(channel, 1, firstSeparator - 1)
	local rpcName = string.sub(channel, firstSeparator + 1, secondSeparator - 1)
	local rpc = self.services[serviceName].rpcs[rpcName]
	if strSender ~= self.services[serviceName].host then return end

	if strMessage == kReservedChar then strMessage = "" end
	if rpc.pendingCallHandler == nil then return end
	local returns = {}
	for i = 1, #rpc.returns do
		returns[i], strMessage = rpc.returns[i]:Decode(strMessage, i == #rpc.returns)
	end
	rpc.pendingCallHandler(unpack(returns))
	rpc.pendingTimeoutTimer:Stop()
	rpc.pendingCallHandler = nil
	rpc.pendingCallFailer = nil
end

function ProtomonService:Implement(serviceName, rpcName, handler)
	local rpc = self.services[serviceName].rpcs[rpcName]
	rpc.requestHandler = handler
end

function ProtomonService:RemoteCall(serviceName, rpcName, responseHandler, responseFailer, ...)
	local service = self.services[serviceName]
	local rpc = service.rpcs[rpcName]
	if rpc.pendingCallHandler ~= nil then
		responseFailer()
		return
	end
	rpc.pendingCallHandler = responseHandler
	rpc.pendingCallFailer = responseFailer
	local argstring = ""
	for i = 1, #rpc.args do
		argstring = rpc.args[i]:Encode(arg[i], argstring, i==#rpc.args)
	end
	if argstring == "" then argstring = kReservedChar end -- must send at least 1 char
	rpc.requestComm:SendPrivateMessage(service.host, argstring)
	
	rpc.pendingTimeoutTimer = ApolloTimer.Create(kTimeout, false, "HandleTimeout", rpc)
end

local ProtomonServiceInst = ProtomonService:new()
ProtomonServiceInst:Init()
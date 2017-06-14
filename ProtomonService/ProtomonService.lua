require "ICCommLib"
require "ICComm"
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

-- REMEMBER: only handles varstrings up to length 93, no current varnum implementation
ProtomonService.services = {
	["ProtomonServer"] = {
		host = "Protomon Server",
		channelType = ICCommLib.CodeEnumICCommChannelType.Global,
		rpcs = {
			-- pass two character names, receive their protomon codes
			["GetBattleCodes"] = {
				args = {
					S.VARSTRING, -- name of player 1
					S.VARSTRING, -- name of player 2
				},
				returns = {
					S.STRING(5), -- code for player 1
					S.STRING(5), -- code for player 2
				},
			},

			-- retrieve code for the caller
			["GetMyCode"] = {
				args = {},
				returns = {
					S.STRING(5), -- code for caller
				},
			},

			-- register new player
			["JoinProtomon"] = {
				args = {},
				returns = {},
			},
			
			-- called when finding a protomon in open world
			["FindProtomon"] = {
				args = {
					S.NUMBER(1), -- id of protomon type
					S.NUMBER(1), -- level of protomon found
				},
				returns = {
					S.NUMBER(1), -- code number of prospective skill change, 'absent' if none
				},
			},
			
			-- called when player wishes to accept prospective skill change
			["AcceptProtomon"] = {
				args = {
					S.NUMBER(1), -- id of protomon type
				},
				returns = {
					S.NUMBER(1), -- code number of new protomon loadout
				},
			},
		},
	},
	["ProtomonGeoServer"] = {
		host = "Protomon Server",
		channelType = ICCommLib.CodeEnumICCommChannelType.Global,
		rpcs = {
			-- called when a player enters a new zone, instructs geo server to update his zone
			["EnterZone"] = {
				args = {},
				returns = {},
			},
			
			-- retry call after entering zone to get update tracker info
			["GetZoneInfo"] = {
				args = {},
				returns = {
					S.VARARRAY(S.NUMBER(1)), -- available protomon types
					S.VARARRAY(S.ARRAY(3, S.NUMBER(2))), -- points of interest to visit (x,y,z)
				},
			},
			
			-- poll for nearby protomon
			["RadarPulse"] = {
				args = {},
				returns = {
					S.VARARRAY(S.TUPLE(
						S.NUMBER(1), -- type, level of nearby protomon
						S.ARRAY(3, S.NUMBER(1)))), -- loc, relative to current position (x,y,z)
				},
			},
		},
	},
}

local function pack(...)
	return arg
end

function ProtomonService:OnLoad()
	for serviceName, service in pairs(self.services) do
		for rpcName, rpc in pairs(service.rpcs) do
			local request_channel_name = serviceName .. "_" .. rpcName .. "_Request"
			local response_channel_name = serviceName .. "_" .. rpcName .. "_Response"

			rpc.ConnectRequest = function(rpc)
				if not rpc.requestComm then
					rpc.requestComm = ICCommLib.JoinChannel(request_channel_name, service.channelType);
					if rpc.requestComm then
						rpc.requestComm:SetReceivedMessageFunction("HandleRequest", self)
					end
				else
					rpc.requestConnectTimer:Stop()
				end
			end

			rpc.ConnectResponse = function(rpc)
				if not rpc.responseComm then
					rpc.responseComm = ICCommLib.JoinChannel(response_channel_name, service.channelType);
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
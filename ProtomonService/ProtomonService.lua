require "ICCommLib"
require "ICComm"
require "GuildLib"
local S = Apollo.GetPackage("Module:Serialization-3.0").tPackage
local ServiceManager = Apollo.GetPackage("Module:ServiceManager-1.0").tPackage

local kTimeout = 5
local kReservedChar = string.char(31) -- used to demarcate empty messages
local kHost = "Protomon Server"

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
		channelType = ICCommLib.CodeEnumICCommChannelType.Global,
		rpcs = {
			["GetVersion"] = {
				args = {},
				returns = {
					S.VARNUMBER,
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
					S.SKIPZERO(S.VARNUMBER), -- zone-id of protomon
				},
				returns = {
					S.NUMBER(1), -- 6-bit code number of prospective skill change, 64 if none
				},
			},
			
			-- called when player wishes to accept prospective skill change
			["AcceptProtomon"] = {
				args = {
					S.SKIPZERO(S.NUMBER(1)), -- protomon id
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
					S.TUPLE(S.SIGNED(S.NUMBER(2)),  -- current position (x,y,z)
						S.SIGNED(S.VARNUMBER),  -- y-coord stands a reasonable chance of being 1 byte often
						S.SIGNED(S.NUMBER(2))),
				},
				returns = {
					S.TABULAR(S.BITARRAY(S.BITS(3), S.BITS(2), S.BITS(1)),
						"element", "heading", "range"), -- closest protomon
					S.VARARRAY(
						S.TABULAR( -- nearby protomon
							S.BITARRAY(S.SKIPZERO(S.BITS(5)),
								S.SKIPZERO(S.BITS(2)),
								S.BITS(12),
								S.FRACTION(4, S.SIGNED(S.BITS(9))),
								S.FRACTION(4, S.SIGNED(S.BITS(8))),
								S.FRACTION(4, S.SIGNED(S.BITS(9)))),
						"protomonId", "level", "zoneId", "x", "y", "z")),
				},
			},
		},
	},
	["ProtomonServerAdmin"] = {
		host = "Protomon ServerTwo",
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
					S.SKIPZERO(S.NUMBER(1)), -- protomon id
					S.NUMBER(1), -- new code
				},
				returns = {},
			},
			
			-- create a protomon spawn here
			["AddSpawn"] = {
				args = {
					S.SKIPZERO(S.NUMBER(1)), -- protomon id
					S.SKIPZERO(S.NUMBER(1)), -- level
					S.NUMBER(4), -- hash of zone/housing
					S.ARRAY(3, S.FRACTION(4, S.SIGNED(S.VARNUMBER))), -- position (x,y,z)
				},
				returns = {},
			},
			
			-- create a protomon spawn here until the next zone reset
			["AddTemporarySpawn"] = {
				args = {
					S.SKIPZERO(S.NUMBER(1)), -- protomon id
					S.SKIPZERO(S.NUMBER(1)), -- level
					S.NUMBER(4), -- hash of zone/housing
					S.ARRAY(3, S.FRACTION(S.SIGNED(S.VARNUMBER))), -- position (x,y,z)
				},
				returns = {},
			},
			
			-- called when finding a protomon in open world
			["RemoveSpawn"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
					S.SKIPZERO(S.VARNUMBER), -- zone-id of protomon
				},
				returns = {},
			},
			
			-- get protomon spawn stats for current zone
			["GetZoneInfo"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
				},
				returns = {
					S.ARRAY(5, S.ARRAY(3, S.VARNUMBER)) -- For each protomon id, spawn counts per level
				},
			},
			
			-- get all protomon for zone (don't use too often)
			["GetZoneList"] = {
				args = {
					S.NUMBER(4), -- hash of zone/housing
				},
				returns = {
					S.VARARRAY(S.TUPLE(
						S.BITARRAY(S.SKIPZERO(S.BITS(3)), S.SKIPZERO(S.BITS(3))), -- element, level
						S.ARRAY(3, S.SIGNED(S.VARNUMBER)))) -- zone relative position(x,y,z)
				},
			},
		},
	},
}


function ProtomonService:OnLoad()
	for serviceName, service in pairs(self.services) do
		ServiceManager:RegisterService(self, serviceName, service)
	end
end


function ProtomonService:Implement(serviceName, rpcName, handler)
	ServiceManager:Implement(serviceName, rpcName, handler)
end

function ProtomonService:RemoteCall(serviceName, rpcName, responseHandler, responseFailer, ...)
	ServiceManager:RemoteCall(kHost, serviceName, rpcName, responseHandler, responseFailer, unpack(arg))
end

local ProtomonServiceInst = ProtomonService:new()
ProtomonServiceInst:Init()
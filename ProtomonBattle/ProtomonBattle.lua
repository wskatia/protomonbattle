require "Window"
require "ICCommLib"
require "ICComm"

local ChatAddon
local ProtomonService
 
local ProtomonBattle = {} 

function ProtomonBattle:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	return o
end

function ProtomonBattle:Init()
    Apollo.RegisterAddon(self, false, "", {})
end

function ProtomonBattle:OnLoad()
	Apollo.RegisterSlashCommand("animate", "OnAnimate", self)
	Apollo.RegisterSlashCommand("ranimate", "OnAnimate", self)
	Apollo.RegisterSlashCommand("record", "OnRecord", self)
	Apollo.RegisterSlashCommand("set1", "OnSetPlayer", self)
	Apollo.RegisterSlashCommand("set2", "OnSetPlayer", self)
	Apollo.RegisterSlashCommand("start", "OnStart", self)
	Apollo.RegisterSlashCommand("test", "OnTest", self)
	Apollo.RegisterSlashCommand("test2", "OnTestTwo", self)
	Apollo.RegisterSlashCommand("stop", "OnStop", self)
	Apollo.RegisterSlashCommand("do", "OnCommand", self)
	Apollo.RegisterEventHandler("ChatMessage", "OnChat", self)

	self.actionQueue = {} -- add actions to this list to have them processed sequentially
	self.decorLabels = {} -- mapping of game-names to decor ids
	self.retiredLabels = {} -- labels awaiting destruction
	self.players = {} -- array of 2 (for the foreseeable future)
	self.gameState = "off" -- "waiting" when accepting commands, other labels are mechanically interchangeable for now
	
	self.animationTimer = ApolloTimer.Create(0.1, false, "ProcessQueue", self)
	self.chatConnectTimer = ApolloTimer.Create(1, false, "GetChatAddon", self)
	self.battleConnectTimer = ApolloTimer.Create(1, true, "ConnectBattle", self)
	self.protomonserviceConnectTimer = ApolloTimer.Create(1, true, "ConnectProtomonService", self)
end

--------------------
-- Startup connections
--------------------

function ProtomonBattle:ConnectBattle()
	if not self.battleComm then
		self.battleComm = ICCommLib.JoinChannel("ProtomonBattle", ICCommLib.CodeEnumICCommChannelType.Global);
		if self.battleComm then
			self.battleComm:SetReceivedMessageFunction("OnBattleChat", self)
		end
	else
		self.battleConnectTimer:Stop()
	end
end

function ProtomonBattle:ConnectProtomonService()
	if not ProtomonService then
		ProtomonService = Apollo.GetAddon("ProtomonService")
	else
		self.protomonserviceConnectTimer:Stop()
	end
end

function ProtomonBattle:GetChatAddon()
	if ChatAddon == nil then
		ChatAddon = Apollo.GetAddon("ChatLog")
		self.chatConnectTimer = ApolloTimer.Create(1, false, "GetChatAddon", self)
	end
end

--------------------
-- Utility stuff
--------------------

-- Fetch a decor from crate, match color iff provided
local function ClonePack(pack)
	local tDecorCrateList = HousingLib.GetResidence():GetDecorCrateList()
	if tDecorCrateList ~= nil then
		for idx = 1, #tDecorCrateList do
			local tCratedDecorData = tDecorCrateList[idx]
			if pack.N ~= nil and tCratedDecorData.strName == pack.N then
				for _, specific in pairs(tCratedDecorData.tDecorItems) do
					if pack.C == nil or specific.idColorShift == pack.C then
						local dec = HousingLib.PreviewCrateDecorAtLocation(
									tCratedDecorData.tDecorItems[1].nDecorId,
									tCratedDecorData.tDecorItems[1].nDecorIdHi,
									pack.X, pack.Y, pack.Z,
									pack.P, pack.R, pack.Yaw,
									pack.S)
						local tDecorInfo = dec:GetDecorIconInfo()
						local newX = tDecorInfo.fWorldPosX
						local newY = tDecorInfo.fWorldPosY
						local newZ = tDecorInfo.fWorldPosZ
						-- Deshift if necessary
						dec = HousingLib.PreviewCrateDecorAtLocation(
									tCratedDecorData.tDecorItems[1].nDecorId,
									tCratedDecorData.tDecorItems[1].nDecorIdHi,
									2*pack.X - newX, 2*pack.Y - newY, 2*pack.Z  - newZ,
									pack.P, pack.R, pack.Yaw,
									pack.S)
						return dec
					end
				end
			end
		end
	end

	return nil
end

-- take any existing children of src and overwrite the corresponding elements of dest
local function OverwriteTable(src, dest)
	for k, v in pairs(src) do
		if type(v) == 'table' then
			if dest[k] == nil then dest[k] = {} end
			OverwriteTable(v, dest[k])
		else
			dest[k] = v
		end
	end
end

-- copy table not by reference
local function CopyTable(orig)
	local result = {}
	OverwriteTable(orig, result)
	return result
end

local function Whisper(msg, to)
	if to == GameLib.GetPlayerUnit():GetName() then
		Print(msg)
	else
		local command = "/w " .. to .. " " .. msg
		ChatSystemLib.Command(command)
	end
end

local function DecorFromIdList(label, list)
	local decorid = list[label]
	if decorid == nil then return nil end
	local dec = HousingLib.GetResidence():GetDecorById(decorid.low, decorid.high)
	if dec == nil or dec:GetName() == "" then return nil end
	return dec
end

local function ApplyCode(protomon, code)
	local pointsSpent = 0
	if code == nil or code >= 64 then
		-- don't need further binary encoding because if you are missing the protomon, they have no attributes
		protomon.absent = true
	else
		-- parse out 6 bits for 6 available bonuses per protomon
		for i=1,6 do
			if code % 2 == 1 then
				OverwriteTable(protomon.bonuses[i].addons, protomon)
				pointsSpent = pointsSpent + protomon.bonuses[i].cost
			end
			code = math.floor(code / 2)
		end
	end
	return pointsSpent
end

function ProtomonBattle:InitializePlayer(slot, name, code)
	self.players[slot] = {
		fighters = {
			{
				hp = 60,
			},
			{
				hp = 60,
			},
			{
				hp = 60,
			},
		},
		player = name,
		-- make a copy of protomon before applying bonuses to the copy
		protomon = CopyTable(protomonbattle_protomon),
	}
	for i=1,5 do
		ApplyCode(self.players[slot].protomon[i], code[i])
	end
	-- update player UI
	local updateMsg = "setteam"
	for i = 1, 5 do updateMsg = updateMsg .. " " .. code[i] end
	table.insert(self.actionQueue, {
		action = "private",
		dest = slot,
		msg = updateMsg,
		delay = 0.1,
	})
end

--------------------
-- Slash commands
--------------------

-- queue up an animation sequence from animations.lua
function ProtomonBattle:OnAnimate(strCmd, strArg)
	self:Animate(strArg, strCmd == "ranimate")
end

-- write a pastable chunk from the selected decor for animations.lua into the chatbar for copy/pasting (yes, dirty:P)
function ProtomonBattle:OnRecord(strCmd, strArg)
	local dec = HousingLib.GetResidence():GetSelectedDecor()
	if dec ~= nil then
		local decinfo = dec:GetDecorIconInfo()
		local add = ChatAddon.tChatWindows[1]:FindChild("Input"):GetText() ..
			"\t\t{\n" ..
			"\t\t\taction = \"place\",\n" ..
			"\t\t\tlabel = \"blah\",\n" ..
			"\t\t\tplacement = {\n" ..
			"\t\t\t\tX = " .. decinfo.fWorldPosX .. ",\n" ..
			"\t\t\t\tY = " .. decinfo.fWorldPosY .. ",\n" ..
			"\t\t\t\tZ = " .. decinfo.fWorldPosZ .. ",\n" ..
			"\t\t\t\tP = " .. decinfo.fPitch .. ",\n" ..
			"\t\t\t\tR = " .. decinfo.fRoll .. ",\n" ..
			"\t\t\t\tYaw = " .. decinfo.fYaw .. ",\n" ..
			"\t\t\t\tS = " .. decinfo.fScaleCurrent .. ",\n" ..
			"\t\t\t\tN = \"" .. dec:GetName() .. "\"\n" ..
			"\t\t\t},\n" ..
			"\t\t\tdelay = 1\n" ..
			"\t\t},\n"
		ChatAddon.tChatWindows[1]:FindChild("Input"):SetText(add)
	end
end

function ProtomonBattle:OnSetPlayer(strCmd, strArg)
	local target = GameLib.GetTargetUnit()
	if target ~= nil and target:IsACharacter() then
		if strCmd == "set1" then
			self.player1 = target:GetName()
			Print("Player 1 set as " .. self.player1)
		else
			self.player2 = target:GetName()
			Print("Player 2 set as " .. self.player2)
		end
	else
		Print("Target a player")
	end		
end

function ProtomonBattle:OnStart()
	ProtomonService:RemoteCall("ProtomonServer", "GetBattleCodes",
		function(code1, code2)
			self:InitializePlayer(1, self.player1, code1)
			self:InitializePlayer(2, self.player2, code2)

			self.gameState = "waiting"
			table.insert(self.actionQueue, {
				action = "broadcast",
				msg = "start",
				delay = 0.1,
			})
			Print("Game start!")
		end,
		function()
			Print("Server not available, can't start game!")
		end,
		self.player1, self.player2)
end

function ProtomonBattle:OnStop()
	self.gameState = "stopped"
	for label, _ in pairs(self.decorLabels) do
		table.insert(self.retiredLabels, label)
	end
	table.insert(self.actionQueue, {
		action = "broadcast",
		msg = "endgame",
		delay = 0.1,
	})
end

--------------------
-- Action Queue
--------------------

local actionset = {
	["place"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decorLabels)
		if dec ~= nil then
			dec:Select()
			dec:SetPosition(currentaction.placement.X, currentaction.placement.Y, currentaction.placement.Z)
			dec:SetRotation(currentaction.placement.P, currentaction.placement.R, currentaction.placement.Yaw)
			dec:SetScale(currentaction.placement.S)
			dec:Place()
		else
			dec = ClonePack(currentaction.placement)
			if dec ~= nil then
				local decorid = {}
				decorid.low, decorid.high = dec:GetId()
				addon.decorLabels[currentaction.label] = decorid
				dec:Place()
			end
		end
	end,

-- moves are used for simulating npc movements without forcing unit reload, by not placing the decor
	["startmove"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decorLabels)
		if dec ~= nil then
			dec:Select()
		end
	end,
	
	["move"] = function (currentaction, addon)
		HousingLib.GetResidence():SetCustomizationMode(HousingLib.ResidenceCustomizationMode.Advanced)
		HousingLib.SetControlMode(HousingLib.DecorControlMode.Global)

		local dec = DecorFromIdList(currentaction.label, addon.decorLabels)
		if dec ~= nil then
			dec:Translate(currentaction.placement.X, currentaction.placement.Y, currentaction.placement.Z)
		end
	end,
	
	["finishmove"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decorLabels)
		if dec ~= nil then
			dec:Place()
		end
	end,
	
	["cancelmove"] = function (currentaction, addon)
	local dec = DecorFromIdList(currentaction.label, addon.decorLabels)
		if dec ~= nil then
			dec:CancelTransform()
		end
	end,

	["crate"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decorLabels)
		if dec ~= nil then
			dec:Crate()
		end
		-- we use a retirement queue because dec:Crate() doesn't always seem to succeed, so we need to reattempt until successful and then remove the label
		if not currentaction.noretire then
			table.insert(addon.retiredLabels, currentaction.label)
		end
	end,

	-- return control to players in game loop
	["awaitcommand"] = function (currentaction, addon)
		addon.players[1].command = nil
		addon.players[2].command = nil
		addon.gameState = "waiting"
		addon.battleComm:SendMessage("waiting")
	end,

	["link"] = function (currentaction, addon)
		local parent = DecorFromIdList(currentaction.parent, addon.decorLabels)
		local child = DecorFromIdList(currentaction.child, addon.decorLabels)
		if parent ~= nil and child ~= nil then
			child:Link(parent)
		end
	end,
	
	["yell"] = function (currentaction)
		for _,channel in pairs(ChatSystemLib.GetChannels()) do
			if channel:GetType() == ChatSystemLib.ChatChannel_Yell then
				channel:Send(currentaction.msg)
			end
		end
	end,
	
	["broadcast"] = function (currentaction, addon)
		addon.battleComm:SendMessage(currentaction.msg) 
	end,
	
	["private"] = function (currentaction, addon)
		if addon.players[currentaction.dest].player ~= GameLib.GetPlayerCharacterName() then
			addon.battleComm:SendPrivateMessage(addon.players[currentaction.dest].player, currentaction.msg)
		end
	end,
}

-- todo: function for translating a frame for differently positioned battle arenas

-- take an animation frame intended for player 1 and use it for player2
local function ReverseFrame(frame)
	local newframe = {
		action = frame.action,
		label = frame.label,
		parent = frame.parent,
		child = frame.child,
		delay = frame.delay
	}
	if frame.placement ~= nil then
		newframe.placement = {
			X = -1 * frame.placement.X,
			Y = frame.placement.Y,
			Z = -1 * frame.placement.Z,
			P = frame.placement.P,
			R = frame.placement.R,
			S = frame.placement.S,
			N = frame.placement.N,
		}
		if frame.placement.Yaw ~= nil then
			newframe.placement.Yaw = frame.placement.Yaw + 180
		end
	end
	if frame.label == "protomon1" then
		newframe.label = "protomon2"
	elseif frame.label == "protomon2" then
		newframe.label = "protomon1"
	end
	return newframe
end

function ProtomonBattle:Animate(index, swap)
	local animation = protomonbattle_animations[index]
	for _, frame in ipairs(animation) do
		if not swap then
			table.insert(self.actionQueue, frame)
		else
			table.insert(self.actionQueue, ReverseFrame(frame))
		end
	end
end

function ProtomonBattle:ProcessQueue()
	if #self.actionQueue == 0 then
		-- if no available actions, check if any old decor are waiting to be crated/cleaned
		if #self.retiredLabels == 0 then
			self.animationTimer = ApolloTimer.Create(0.1, false, "ProcessQueue", self)
		else
			if self.decorLabels[self.retiredLabels[1]] == nil or DecorFromIdList(self.retiredLabels[1], self.decorLabels) == nil then
				self.decorLabels[self.retiredLabels[1]] = nil
				table.remove(self.retiredLabels,1)
				self.animationTimer = ApolloTimer.Create(0.1, false, "ProcessQueue", self)
			else
				DecorFromIdList(self.retiredLabels[1], self.decorLabels):Crate()
				self.animationTimer = ApolloTimer.Create(0.3, false, "ProcessQueue", self)
			end
		end
	else
		local currentaction = table.remove(self.actionQueue, 1)
		actionset[currentaction.action](currentaction, self)
		self.animationTimer = ApolloTimer.Create(currentaction.delay, false, "ProcessQueue", self)
	end
end


--------------------
-- Command parser
--------------------

function ProtomonBattle:OnChat(chan, msg)
	if msg.bSelf then return end

	if chan == nil or msg == nil or self.gameState ~= "waiting" then return end
	self:HandleCommand(msg.arMessageSegments[1].strText, msg.strSender)
end

function ProtomonBattle:OnBattleChat(iccomm, strMessage, strSender)
	if self.gameState ~= "waiting" then return end
	self:HandleCommand(strMessage, strSender)
end

function ProtomonBattle:OnCommand(strCmd, strArg)
	if self.gameState ~= "waiting" then return end
	self:HandleCommand(strArg, GameLib.GetPlayerUnit():GetName())
end

function ProtomonBattle:HandleCommand(strMessage, strSender)
	local player = nil
	if strSender == self.players[1].player then player = 1 end
	if strSender == self.players[2].player then player = 2 end
	if player == nil then return end
	local message = string.lower(strMessage)

	-- don't accept commands if active fighter is awake and recovering
	local currentFighter = self.players[player].activeprotomon
	if currentFighter and self.players[player].fighters[currentFighter].hp > 0 and self.players[player].recovering then
		local id = self.players[player].fighters[currentFighter].id
		Whisper(string.upper(self.players[player].protomon[id].name) .. " is still recovering!", strSender)
		return
	end
	
	-- only available player commands are switch protomon and use attack
	if string.sub(message, 1, 7) == "switch " then
		local protomonId = protomonbattle_names[string.sub(message, 8)]
		if protomonId ~= nil and not self.players[player].protomon[protomonId].absent then
			local selection = nil
			-- switch to previously chosen protomon if available, create a new protomon if a slot remains, return error otherwise
			for i=1,3 do
				local potentialmatch = self.players[player].fighters[i].id
				if potentialmatch == nil then
					self.players[player].fighters[i].id = protomonId
					self.players[player].fighters[i].hp = self.players[player].protomon[protomonId].hp
					selection = i
					break
				elseif potentialmatch == protomonId then
					selection = i
					break
				end
			end
			if selection == nil then
				Whisper("You already have a team of three!", strSender)
			elseif self.players[player].fighters[selection].hp <= 0 then
				Whisper(string.upper(string.sub(message, 8)) .. " is KOed!", strSender)
			else
				self.players[player].command = {
					action = "switch",
					which = selection,
				}
				Whisper("Command ready!", strSender)
				table.insert(self.actionQueue, {
					action = "private",
					dest = player,
					msg = "commandready",
					delay = 0.1,
				})
			end
		else
			Whisper("There's no protomon named " .. string.upper(string.sub(message, 8)) .. "!", strSender)
		end
	elseif string.sub(message, 1, 4) == "use " then
	-- "use" is for attacks
		local activeprotomon = self.players[player].activeprotomon
		if activeprotomon ~= nil then
			local id = self.players[player].fighters[activeprotomon].id
			local attack = string.sub(message, 5)
			if self.players[player].protomon[id].attacks[attack] then
				self.players[player].command = {
					action = "attack",
					which = protomonbattle_attacks[attack],
				}
				Whisper("Command ready!", strSender)
				table.insert(self.actionQueue, {
					action = "private",
					dest = player,
					msg = "commandready",
					delay = 0.1,
				})
			else
				Whisper(string.upper(self.players[player].protomon[id].name) .. " doesn't know " .. string.upper(attack) .. "!", strSender)
			end
		else
			Whisper("You don't have any protomon out!", strSender)
		end
	end
	if (self.players[1].command ~= nil or self.players[1].recovering) and (self.players[2].command ~= nil or self.players[2].recovering) then
		self:HandleTurn()
	end
end

--------------------
-- Turn logic
--------------------

-- switches happen before attacks
function ProtomonBattle:HandleSwitch(player)
	-- assumes 2 players, which we'll probably never change
	local other = 3 - player
	local command = self.players[player].command
	if command == nil then
		table.insert(self.actionQueue, {
			action = "yell",
			msg = string.upper(self.players[player].protomon[self.players[player].fighters[self.players[player].activeprotomon].id].name) .. " is still recovering!",
			delay = 0.1,
		})
		self.players[player].recovering = nil
	elseif command.action == "switch" then
		-- actual game logic
		local selectedFighter = self.players[player].fighters[command.which]
		local selectedProtomon = self.players[player].protomon[selectedFighter.id]
		self.players[player].activeprotomon = command.which
		self:Animate("place protoball", player ~= 1)
		
		-- animations (protoball and protomon change)
		table.insert(self.actionQueue, {
			action = "crate",
			label = "protomon" .. player,
			noretire = true,
			delay = 0.5
		})
		local frame = {
			action = "place",
			label = "protomon1", -- this will get reversed where appropriate
			placement = selectedProtomon.placement,
			delay = 0.5,
		}
		if player == 1 then
			table.insert(self.actionQueue, frame)
		else
			table.insert(self.actionQueue, ReverseFrame(frame))
		end
		self:Animate("remove protoball", player ~= 1)
		local hp = selectedFighter.hp

		-- inform players (yell for non-addon users, update UI for addon users)
		table.insert(self.actionQueue, {
			action = "yell",
			msg = self.players[player].player .. " chose " .. string.upper(selectedProtomon.name) .. "! (" .. hp .. " hp left)"
		})
		table.insert(self.actionQueue, {
			action = "private",
			dest = player,
			msg = "switch " .. command.which .. " " .. string.lower(selectedProtomon.name) .. " " .. selectedFighter.hp,
			delay = 0.1,
		})

		-- if this is a new protomon, make a flag for it
		local flaglabel = "protomonflag" .. player .. "-" .. command.which
		if self.decorLabels[flaglabel] == nil then
			local flag = selectedProtomon.flag
			local xcoord = 0.3 + (1.5 * command.which)
			if player == 2 then
				xcoord = xcoord * -1
			end
			-- todo: better arbitrary flag creation
			local frame = {
				action = "place",
				label = flaglabel,
				placement = {
					X = xcoord,
					Y = 16,
					Z = -10.4,
					P = 19.8,
					R = 0,
					Yaw = 0,
					S = 0.8,
					N = flag.N,
					C = flag.C
				},
				delay = 0.4
			}
			table.insert(self.actionQueue, frame)
		end
		
		-- queue swap attack
		if self.players[other].command == nil or self.players[other].command.action ~= "attack" or not self.players[other].command.which.skipswapattack then
			self.players[player].command = {
				action = "attack",
				which = protomonbattle_attacks[selectedProtomon.switchattack],
			}
		end
	end
	
end

function ProtomonBattle:HandleAttack(player)
	local other = 3 - player
	local command = self.players[player].command
	if command ~= nil and command.action == "attack" and self.players[player].activeprotomon ~= nil then
		local selectedFighter = self.players[player].fighters[self.players[player].activeprotomon]
		local selectedProtomon = self.players[player].protomon[selectedFighter.id]
		local targetFighter = self.players[other].fighters[self.players[other].activeprotomon]
		local targetProtomon = self.players[other].protomon[targetFighter.id]

		-- damage is modified by elemental weaknesses
		local multiplier = protomonbattle_element_damage[command.which.element][targetProtomon.element]
		local damage = command.which.damage * multiplier
		targetFighter.hp = targetFighter.hp - damage
		if targetFighter.hp < 0 then targetFighter.hp = 0 end

		-- animation and reporting
		self:Animate(command.which.animation, player ~= 1)
		local shout = string.upper(selectedProtomon.name) .. " used " .. string.upper(command.which.name)
		if multiplier > 1 then
			shout = shout .. ", it's SUPER EFFECTIVE!"
		elseif multiplier < 1 then
			shout = shout .. ", it's not very effective..."
		else
			shout = shout .. "!"
		end
		shout = shout .. " (" .. targetFighter.hp .. " hp left)"
		table.insert(self.actionQueue, {
			action = "yell",
			msg = shout
		})
		table.insert(self.actionQueue, {
			action = "private",
			dest = other,
			msg = "hp " .. self.players[other].activeprotomon .. " " .. targetFighter.hp,
			delay = 0.1,
		})
		if self.players[other].command and self.players[other].command.action == "switch" then
			table.insert(self.actionQueue, {
				action = "yell",
				msg = string.upper(targetProtomon.name) .. " is too stunned to attack!"
			})
		end
		
		-- check for fainting
		if targetFighter.hp <= 0 then
			table.insert(self.actionQueue, {
				action = "crate",
				label = "protomon" .. other,
				delay = 0.3,
			})
			table.insert(self.actionQueue, {
				action = "yell",
				msg = string.upper(targetProtomon.name) .. " fainted!",
				delay = 0.3,
			})

			local flaglabel = "protomonflag" .. other .. "-" .. self.players[other].activeprotomon
			if self.decorLabels[flaglabel] ~= nil then
				local xcoord = 0.3 + (1.5 * self.players[other].activeprotomon)
				if other == 2 then
					xcoord = xcoord * -1
				end
				-- todo: better control for arbitrary flags
				local frame = {
					action = "place",
					label = flaglabel,
					placement = {
						X = xcoord,
						Y = 16,
						Z = -10.4,
						P = 75,
						R = 0,
						Yaw = 0,
						S = 0.65,
					},
					delay = 0.4
				}
				table.insert(self.actionQueue, frame)
			end

			self.players[other].activeprotomon = nil
			self.players[other].recovering = nil
		elseif command.which.recoverifnoko then
			self.players[player].recovering = true
		end
	end
end

function ProtomonBattle:CheckWin(player)
	local other = 3 - player
	if self.players[other].fighters[1].hp <= 0 and
		self.players[other].fighters[2].hp <= 0 and
		self.players[other].fighters[3].hp <= 0 then
		table.insert(self.actionQueue, {
			action = "broadcast",
			msg = "endgame",
			delay = 0.1,
		})
		table.insert(self.actionQueue, {
			action = "yell",
			msg = self.players[player].player .. " wins!",
			delay = 5,
		})
		-- queue up all decor for crating
		for label, _ in pairs(self.decorLabels) do
			table.insert(self.retiredLabels, label)
		end
		return true
	end
	return false
end

function ProtomonBattle:HandleTurn()
	-- stop command parser and update UIs
	self.gameState = "playing"
	table.insert(self.actionQueue, {
		action = "broadcast",
		msg = "playing",
		delay = 0.1,
	})

	-- do turn logic
	local first = math.random(2)
	local second = 3 - first
	self:HandleSwitch(first)
	self:HandleSwitch(second)
	self:HandleAttack(first)
	self:HandleAttack(second)

	-- is the game over?
	if not self:CheckWin(1) and not self:CheckWin(2) then
		-- assuming nobody won, return control to players, use the animation queue so they can't enter commands while we are still animating
		table.insert(self.actionQueue, {
			action = "awaitcommand",
			delay = 0.1,
		})
	end
end

local ProtomonBattleInst = ProtomonBattle:new()
ProtomonBattleInst:Init()

require "Window"
local ChatAddon
 
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
	Apollo.RegisterSlashCommand("stop", "OnStop", self)
	Apollo.RegisterEventHandler("ChatMessage", "OnChat", self)

	self.action_queue = {} -- add actions to this list to have them processed sequentially
	self.decor_labels = {} -- mapping of game-names to decor ids
	self.retired_labels = {} -- labels awaiting destruction
	self.players = {} -- array of 2 (for the foreseeable future)
	self.playercodes = {} -- todo: move this to central server
	self.gamestate = "off" -- "waiting" when accepting commands, other labels are mechanically interchangeable for now
	
	self.animation_timer = ApolloTimer.Create(0.1, false, "ProcessQueue", self)
	self.chat_connect_timer = ApolloTimer.Create(1, false, "GetChatAddon", self)
	self.battle_connect_timer = ApolloTimer.Create(1, true, "ConnectBattle", self)
	self.battle_connect_timer:Start()
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
		self.battle_connect_timer:Stop()
	end
end

function ProtomonBattle:GetChatAddon()
	if ChatAddon == nil then
		ChatAddon = Apollo.GetAddon("ChatLog")
		self.chat_connect_timer = ApolloTimer.Create(1, false, "GetChatAddon", self)
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

-- serialization of protomon codes
local kCharNum = { ["a"]=0, ["b"]=1, ["c"]=2, ["d"]=3, ["e"]=4, ["f"]=5, ["g"]=6, ["h"]=7, ["i"]=8, ["j"]=9, ["k"]=10, ["l"]=11, ["m"]=12, ["n"]=13, ["o"]=14, ["p"]=15, ["q"]=16, ["r"]=17, ["s"]=18, ["t"]=19, ["u"]=20, ["v"]=21, ["w"]=22, ["x"]=23, ["y"]=24, ["z"]=25, ["A"]=26, ["B"]=27, ["C"]=28, ["D"]=29, ["E"]=30, ["F"]=31, ["G"]=32, ["H"]=33, ["I"]=34, ["J"]=35, ["K"]=36, ["L"]=37, ["M"]=38, ["N"]=39, ["O"]=40, ["P"]=41, ["Q"]=42, ["R"]=43, ["S"]=44, ["T"]=45, ["U"]=46, ["V"]=47, ["W"]=48, ["X"]=49, ["Y"]=50, ["Z"]=51, ["1"]=52, ["2"]=53, ["3"]=54, ["4"]=55, ["5"]=56, ["6"]=57, ["7"]=58, ["8"]=59, ["9"]=60, ["0"]=61, ["!"]=62, ["@"]=63, ["#"]=64
}
local kNumChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#"

local function ApplyCode(protomon, code)
	local code_number = string.find(kNumChars, code)
	local points_remaining = 3
	if code_number == 65 then
		-- don't need further binary encoding because if you are missing the protomon, they have no attributes
		protomon.absent = true
	else
		-- parse out 6 bits for 6 available bonuses per protomon
		code_number = code_number - 1
		for i=1,6 do
			if code_number % 2 == 1 and points_remaining >= protomon.bonuses[i].cost then
				OverwriteTable(protomon.bonuses[i].addons, protomon)
				points_remaining = points_remaining - protomon.bonuses[i].cost
			end
			code_number = math.floor(code_number / 2)
		end
		local points_used = 3 - points_remaining
		protomon.hp = 84 - (2 * points_used^2) - (2 * points_used)
	end
end

function ProtomonBattle:InitializePlayer(slot, name)
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
	local code = self.playercodes[name]
	-- "H" is the simple starter protomon with heavy swap and hard tackle
	if code == nil then code = "HHHHH" end
	for i=1,5 do
		ApplyCode(self.players[slot].protomon[i], string.sub(code, i, i))
	end
	-- update player UI
	table.insert(self.action_queue, {
		action = "private",
		dest = slot,
		msg = "setteam " .. code,
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
	self:InitializePlayer(1, self.player1)
	self:InitializePlayer(2, self.player2)

	self.gamestate = "waiting"
	table.insert(self.action_queue, {
		action = "broadcast",
		msg = "start",
		delay = 0.1,
	})
	Print("Game start!")
end

function ProtomonBattle:OnStop()
	self.gamestate = "stopped"
	for label, _ in pairs(self.decor_labels) do
		table.insert(self.retired_labels, label)
	end
	table.insert(self.action_queue, {
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
		local dec = DecorFromIdList(currentaction.label, addon.decor_labels)
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
				addon.decor_labels[currentaction.label] = decorid
				dec:Place()
			end
		end
	end,

-- moves are used for simulating npc movements without forcing unit reload, by not placing the decor
	["startmove"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decor_labels)
		if dec ~= nil then
			dec:Select()
		end
	end,
	
	["move"] = function (currentaction, addon)
		HousingLib.GetResidence():SetCustomizationMode(HousingLib.ResidenceCustomizationMode.Advanced)
		HousingLib.SetControlMode(HousingLib.DecorControlMode.Global)

		local dec = DecorFromIdList(currentaction.label, addon.decor_labels)
		if dec ~= nil then
			dec:Translate(currentaction.placement.X, currentaction.placement.Y, currentaction.placement.Z)
		end
	end,
	
	["finishmove"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decor_labels)
		if dec ~= nil then
			dec:Place()
		end
	end,
	
	["cancelmove"] = function (currentaction, addon)
	local dec = DecorFromIdList(currentaction.label, addon.decor_labels)
		if dec ~= nil then
			dec:CancelTransform()
		end
	end,

	["crate"] = function (currentaction, addon)
		local dec = DecorFromIdList(currentaction.label, addon.decor_labels)
		if dec ~= nil then
			dec:Crate()
		end
		-- we use a retirement queue because dec:Crate() doesn't always seem to succeed, so we need to reattempt until successful and then remove the label
		if not currentaction.noretire then
			table.insert(addon.retired_labels, currentaction.label)
		end
	end,

-- return control to players in game loop
	["awaitcommand"] = function (currentaction, addon)
		addon.players[1].command = nil
		addon.players[2].command = nil
		addon.gamestate = "waiting"
		addon.battleComm:SendMessage("waiting")
	end,

	["link"] = function (currentaction, addon)
		local parent = DecorFromIdList(currentaction.parent, addon.decor_labels)
		local child = DecorFromIdList(currentaction.child, addon.decor_labels)
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
			table.insert(self.action_queue, frame)
		else
			table.insert(self.action_queue, ReverseFrame(frame))
		end
	end
end

function ProtomonBattle:ProcessQueue()
	if #self.action_queue == 0 then
		-- if no available actions, check if any old decor are waiting to be crated/cleaned
		if #self.retired_labels == 0 then
			self.animation_timer = ApolloTimer.Create(0.1, false, "ProcessQueue", self)
		else
			if self.decor_labels[self.retired_labels[1]] == nil or DecorFromIdList(self.retired_labels[1], self.decor_labels) == nil then
				self.decor_labels[self.retired_labels[1]] = nil
				table.remove(self.retired_labels,1)
				self.animation_timer = ApolloTimer.Create(0.1, false, "ProcessQueue", self)
			else
				DecorFromIdList(self.retired_labels[1], self.decor_labels):Crate()
				self.animation_timer = ApolloTimer.Create(0.3, false, "ProcessQueue", self)
			end
		end
	else
		local currentaction = table.remove(self.action_queue, 1)
		actionset[currentaction.action](currentaction, self)
		self.animation_timer = ApolloTimer.Create(currentaction.delay, false, "ProcessQueue", self)
	end
end

--------------------
-- Command parser
--------------------

function ProtomonBattle:OnChat(chan, msg)
	if string.sub(msg.arMessageSegments[1].strText, 1, 8) == "setteam " then
		self.playercodes[msg.strSender] = string.sub(msg.arMessageSegments[1].strText, 9)
		Whisper("Team set!", msg.strSender)
		return
	end

	if chan == nil or msg == nil or self.gamestate ~= "waiting" then return end
	self:HandleCommand(msg.arMessageSegments[1].strText, msg.strSender)
end

function ProtomonBattle:OnBattleChat(iccomm, strMessage, strSender)
	if self.gamestate ~= "waiting" then return end
	self:HandleCommand(strMessage, strSender)
end

function ProtomonBattle:HandleCommand(strMessage, strSender)
	local player = nil
	if strSender == self.players[1].player then player = 1 end
	if strSender == self.players[2].player then player = 2 end
	if player == nil then return end
	local message = string.lower(strMessage)

	-- only available player commands are switch protomon and use attack
	if string.sub(message, 1, 7) == "switch " then
		local protomon_id = protomonbattle_names[string.sub(message, 8)]
		if protomon_id ~= nil then
			local selection = nil
			-- switch to previously chosen protomon if available, create a new protomon if a slot remains, return error otherwise
			for i=1,3 do
				local potentialmatch = self.players[player].fighters[i].id
				if potentialmatch == nil then
					self.players[player].fighters[i].id = protomon_id
					self.players[player].fighters[i].hp = self.players[player].protomon[protomon_id].hp
					selection = i
					break
				elseif potentialmatch == protomon_id then
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
				table.insert(self.action_queue, {
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
				table.insert(self.action_queue, {
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
	if self.players[1].command ~= nil and self.players[2].command ~= nil then
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
	if command.action == "switch" then
		-- actual game logic
		local selectedfighter = self.players[player].fighters[command.which]
		local selectedprotomon = self.players[player].protomon[selectedfighter.id]
		self.players[player].activeprotomon = command.which
		self:Animate("place protoball", player ~= 1)
		
		-- animations (protoball and protomon change)
		table.insert(self.action_queue, {
			action = "crate",
			label = "protomon" .. player,
			noretire = true,
			delay = 0.5
		})
		local frame = {
			action = "place",
			label = "protomon1", -- this will get reversed where appropriate
			placement = selectedprotomon.placement,
			delay = 0.5,
		}
		if player == 1 then
			table.insert(self.action_queue, frame)
		else
			table.insert(self.action_queue, ReverseFrame(frame))
		end
		self:Animate("remove protoball", player ~= 1)
		local hp = selectedfighter.hp

		-- inform players (yell for non-addon users, update UI for addon users)
		table.insert(self.action_queue, {
			action = "yell",
			msg = self.players[player].player .. " chose " .. string.upper(selectedprotomon.name) .. "! (" .. hp .. " hp left)"
		})
		table.insert(self.action_queue, {
			action = "private",
			dest = player,
			msg = "switch " .. command.which .. " " .. selectedprotomon.name .. " " .. selectedfighter.hp,
			delay = 0.1,
		})

		-- if this is a new protomon, make a flag for it
		local flaglabel = "protomonflag" .. player .. "-" .. command.which
		if self.decor_labels[flaglabel] == nil then
			local flag = selectedprotomon.flag
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
			table.insert(self.action_queue, frame)
		end
		
		-- queue swap attack
		if self.players[other].command.action ~= "attack" or not self.players[other].command.which.skipswapattack then
			self.players[player].command = {
				action = "attack",
				which = protomonbattle_attacks[selectedprotomon.switchattack],
			}
		end
	end
	
end

function ProtomonBattle:HandleAttack(player)
	local other = 3 - player
	local command = self.players[player].command
	if command.action == "attack" and self.players[player].activeprotomon ~= nil then
		local selectedfighter = self.players[player].fighters[self.players[player].activeprotomon]
		local selectedprotomon = self.players[player].protomon[selectedfighter.id]

		local targetfighter = self.players[other].fighters[self.players[other].activeprotomon]
		local targetprotomon = self.players[other].protomon[targetfighter.id]

		-- damage is modified by elemental weaknesses
		local multiplier = protomonbattle_element_damage[command.which.element][targetprotomon.element]
		local damage = command.which.damage * multiplier
		targetfighter.hp = targetfighter.hp - damage
		if targetfighter.hp < 0 then targetfighter.hp = 0 end

		-- animation and reporting
		self:Animate(command.which.animation, player ~= 1)
		local shout = string.upper(selectedprotomon.name) .. " used " .. string.upper(command.which.name)
		if multiplier > 1 then
			shout = shout .. ", it's SUPER EFFECTIVE!"
		elseif multiplier < 1 then
			shout = shout .. ", it's not very effective..."
		else
			shout = shout .. "!"
		end
		shout = shout .. " (" .. targetfighter.hp .. " hp left)"
		table.insert(self.action_queue, {
			action = "yell",
			msg = shout
		})
		table.insert(self.action_queue, {
			action = "private",
			dest = other,
			msg = "hp " .. self.players[other].activeprotomon .. " " .. targetfighter.hp,
			delay = 0.1,
		})
		if self.players[other].command.action == "switch" then
			table.insert(self.action_queue, {
				action = "yell",
				msg = string.upper(targetprotomon.name) .. " is too stunned to attack!"
			})
		end
		
		-- check for fainting
		if targetfighter.hp <= 0 then
			table.insert(self.action_queue, {
				action = "crate",
				label = "protomon" .. other,
				delay = 0.3,
			})
			table.insert(self.action_queue, {
				action = "yell",
				msg = string.upper(targetprotomon.name) .. " fainted!",
				delay = 0.3,
			})

			local flaglabel = "protomonflag" .. other .. "-" .. self.players[other].activeprotomon
			if self.decor_labels[flaglabel] ~= nil then
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
				table.insert(self.action_queue, frame)
			end

			self.players[other].activeprotomon = nil
		end
	end
end

function ProtomonBattle:CheckWin(player)
	local other = 3 - player
	if self.players[other].fighters[1].hp <= 0 and
		self.players[other].fighters[2].hp <= 0 and
		self.players[other].fighters[3].hp <= 0 then
		table.insert(self.action_queue, {
			action = "broadcast",
			msg = "endgame",
			delay = 0.1,
		})
		table.insert(self.action_queue, {
			action = "yell",
			msg = self.players[player].player .. " wins!",
			delay = 5,
		})
		-- queue up all decor for crating
		for label, _ in pairs(self.decor_labels) do
			table.insert(self.retired_labels, label)
		end
		return true
	end
	return false
end

function ProtomonBattle:HandleTurn()
	-- stop command parser and update UIs
	self.gamestate = "playing"
	table.insert(self.action_queue, {
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
		table.insert(self.action_queue, {
			action = "awaitcommand",
			delay = 0.1,
		})
	end
end

local ProtomonBattleInst = ProtomonBattle:new()
ProtomonBattleInst:Init()

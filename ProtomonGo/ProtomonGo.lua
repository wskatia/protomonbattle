require "Window"
require "ICCommLib"
require "ICComm"
require "Sound"

local elementColors = {
	["fire"] = {r = 1, g = 0, b = 0, a = 1},
	["air"] = {r = 1, g = 1, b = 1, a = 0.7},
	["life"] = {r = 0, g = 1, b = 0, a = 1},
	["water"] = {r = 0, g = 0, b = 1, a = 1},
	["earth"] = {r = 0.8, g = 0.4, b = 0.1, a = 1},
	["normal"] = {r = 1, g = 1, b = 1, a = 1},
}

local ProtomonService

--------------------
-- Utility stuff
--------------------

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

local function PointsSpent(code)
	local result = 0
	for i=1,4 do
		result = result + code % 2
		code = math.floor(code / 2)
	end
	for i=1,2 do
		result = result + 2 * (code % 2)
		code = math.floor(code / 2)
	end
	return result
end

local ProtomonGo = {} 
 
function ProtomonGo:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function ProtomonGo:Init()
    Apollo.RegisterAddon(self, false, "", {})
end
 
function ProtomonGo:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ProtomonGo.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.RegisterSlashCommand("protomongo", "OnProtomonGo", self)
	Apollo.RegisterSlashCommand("protomonbattle", "OnProtomonBattle", self)
	Apollo.RegisterSlashCommand("protomonreset", "OnProtomonReset", self)
	Apollo.RegisterSlashCommand("music", "OnMusicStart", self)

	self.protomon = CopyTable(protomonbattle_protomon)

	self.battleConnectTimer = ApolloTimer.Create(1, true, "ConnectBattle", self)
	self.protomonServiceConnectTimer = ApolloTimer.Create(1, true, "ConnectProtomonService", self)
end

function ProtomonGo:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndBattle = Apollo.LoadForm(self.xmlDoc, "BattleControl", nil, self)
		if self.wndBattle == nil then
			Apollo.AddAddonErrorText(self, "Could not load the battle window for some reason.")
			return
		end
		
	    self.wndBattle:Show(false, true)

	    self.wndGo = Apollo.LoadForm(self.xmlDoc, "Protodex", nil, self)
		if self.wndGo == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Protodex window for some reason.")
			return
		end
		
	    self.wndGo:Show(false, true)

	    self.wndConfirm = Apollo.LoadForm(self.xmlDoc, "SwapConfirm", nil, self)
		if self.wndConfirm == nil then
			Apollo.AddAddonErrorText(self, "Could not load the swap confirmation window for some reason.")
			return
		end
		
	    self.wndConfirm:Show(false, true)
	end
end

--------------------
-- Startup connections
--------------------

function ProtomonGo:ConnectProtomonService()
	if not ProtomonService then
		ProtomonService = Apollo.GetAddon("ProtomonService")
	else
		self.protomonServiceConnectTimer:Stop()
	end
end

function ProtomonGo:ConnectBattle()
	if not self.battleComm then
		self.battleComm = ICCommLib.JoinChannel("ProtomonBattle", ICCommLib.CodeEnumICCommChannelType.Global);
		if self.battleComm then
			self.battleComm:SetReceivedMessageFunction("OnBattleChat", self)
		end
	else
		self.battleConnectTimer:Stop()
	end
end

--------------------
-- Battle music control (thx Smooth McGroove!)
--------------------

function ProtomonGo:OnMusicStart()
	self:PlayStart()
end

function ProtomonGo:PlayStart()
	self.gameend = false
	Sound.PlayFile("battlestart.wav")
	self.musictimer = ApolloTimer.Create(7.82, false, "PlayLoop", self)
	self.musictimer:Start()
end

function ProtomonGo:PlayLoop()
	if self.gameend then
		Sound.PlayFile("battleend.wav")
	else
		Sound.PlayFile("battleloop.wav")
		self.musictimer = ApolloTimer.Create(39.41, false, "PlayLoop", self)
		self.musictimer:Start()
	end
end	

--------------------
-- Battle form events
--------------------

function ProtomonGo:OnProtomonBattle()
	self.wndBattle:Invoke()
end

function ProtomonGo:OnCloseBattle()
	self.wndBattle:Close()
end

function ProtomonGo:OnSetRef(wndHandler, wndControl)
	local target = GameLib.GetTargetUnit()
	if target ~= nil and target:IsACharacter() then
		self.referee = target:GetName()
		wndHandler:SetText(self.referee)
	else
		self.referee = nil
		wndHandler:SetText("Set target player as referee")
	end
end

function ProtomonGo:OnFighter(wndHandler, wndControl)
	if wndHandler:GetText() == "" then
		local wndList = self.wndBattle:FindChild("List")
		wndList:DestroyChildren()
		for i=1,5 do
			if self.wndBattle:FindChild("Fighter1"):GetText() ~= self.protomon[i].name and
				self.wndBattle:FindChild("Fighter2"):GetText() ~= self.protomon[i].name and
				self.wndBattle:FindChild("Fighter3"):GetText() ~= self.protomon[i].name and
				not self.protomon[i].absent then
				local wndListItem = Apollo.LoadForm(self.xmlDoc, "Command", wndList, self)
				wndListItem:FindChild("Button"):SetText(self.protomon[i].name)
				wndListItem:FindChild("Button"):SetNormalTextColor(elementColors[self.protomon[i].element])
				wndListItem:FindChild("Button"):SetData("switch " .. self.protomon[i].name)
			end
		end
		wndList:ArrangeChildrenVert()
	elseif wndHandler:GetName() == self.activefighter then
		local wndList = self.wndBattle:FindChild("List")
		wndList:DestroyChildren()
		
		for attackname, _ in pairs(self.protomon[protomonbattle_names[wndHandler:GetText()]].attacks) do
			local wndListItem = Apollo.LoadForm(self.xmlDoc, "Command", wndList, self)
			wndListItem:FindChild("Button"):SetText(attackname .. "(" .. protomonbattle_attacks[attackname].damage .. ")")
			wndListItem:FindChild("Button"):SetNormalTextColor(elementColors[protomonbattle_attacks[attackname].element])
			wndListItem:FindChild("Button"):SetData("use " .. attackname)
		end
		wndList:ArrangeChildrenVert()
	else
		self.battleComm:SendPrivateMessage(self.referee, "switch " .. wndHandler:GetText())
	end
end

function ProtomonGo:OnCommand(wndHandler, wndControl)
	if self.referee and self.wndBattle:FindChild("State"):GetText() == "Awaiting command" then
		self.battleComm:SendPrivateMessage(self.referee, wndHandler:GetData())
	else
		Print("It's not time to enter commands!")
	end
end

--------------------
-- Remote control from battle referee
--------------------

function ProtomonGo:OnBattleChat(iccomm, strMessage, strSender)
	if strSender ~= self.referee then return end
	
	local arguments = {}
	for arg in string.gmatch(strMessage, "%S+") do
		table.insert(arguments, arg)
	end

	if arguments[1] == "start" then
		self.wndBattle:FindChild("State"):SetText("Awaiting command")
		self.wndBattle:FindChild("Fighter1"):SetOpacity(0.3)
		self.wndBattle:FindChild("Fighter2"):SetOpacity(0.3)
		self.wndBattle:FindChild("Fighter3"):SetOpacity(0.3)
		self.wndBattle:FindChild("Fighter1"):SetText("")
		self.wndBattle:FindChild("Fighter2"):SetText("")
		self.wndBattle:FindChild("Fighter3"):SetText("")
		self.wndBattle:FindChild("Fighter1"):SetTextColor({r=1,g=1,b=1,a=1})
		self.wndBattle:FindChild("Fighter2"):SetTextColor({r=1,g=1,b=1,a=1})
		self.wndBattle:FindChild("Fighter3"):SetTextColor({r=1,g=1,b=1,a=1})
		self.wndBattle:FindChild("Hp1"):SetText("")
		self.wndBattle:FindChild("Hp2"):SetText("")
		self.wndBattle:FindChild("Hp3"):SetText("")
		self.wndBattle:FindChild("List"):DestroyChildren()
		self.activefighter = nil
		self:PlayStart()
	elseif arguments[1] == "setteam" then
		self.protomon = CopyTable(protomonbattle_protomon)
		for i=1,5 do
			ApplyCode(self.protomon[i], tonumber(arguments[1 + i]))
		end
	elseif arguments[1] == "waiting" then
		self.wndBattle:FindChild("State"):SetText("Awaiting command")
	elseif arguments[1] == "commandready" then
		self.wndBattle:FindChild("State"):SetText("Command accepted")
	elseif arguments[1] == "playing" then
		self.wndBattle:FindChild("State"):SetText("Turn in progress")
	elseif arguments[1] == "endgame" then
		self.wndBattle:FindChild("State"):SetText("Awaiting game start")
		self.gameend = true
	elseif arguments[1] == "switch" then
		if self.activefighter ~= nil then
			self.wndBattle:FindChild(self.activefighter):SetOpacity(0.3)
		end
		self.activefighter = "Fighter" .. arguments[2]
		self.wndBattle:FindChild(self.activefighter):SetText(arguments[3])
		self.wndBattle:FindChild(self.activefighter):SetTextColor(elementColors[self.protomon[protomonbattle_names[arguments[3]]].element])
		self.wndBattle:FindChild(self.activefighter):SetOpacity(1)
		self.wndBattle:FindChild("Hp" .. arguments[2]):SetText(arguments[4])

		local wndList = self.wndBattle:FindChild("List")
		wndList:DestroyChildren()
		
		for attackname, _ in pairs(self.protomon[protomonbattle_names[arguments[3]]].attacks) do
			local wndListItem = Apollo.LoadForm(self.xmlDoc, "Command", wndList, self)
			wndListItem:FindChild("Button"):SetText(attackname .. "(" .. protomonbattle_attacks[attackname].damage .. ")")
			wndListItem:FindChild("Button"):SetNormalTextColor(elementColors[protomonbattle_attacks[attackname].element])
			wndListItem:FindChild("Button"):SetData("use " .. attackname)
		end
		wndList:ArrangeChildrenVert()
	elseif arguments[1] == "hp" then
		self.wndBattle:FindChild("Hp" .. arguments[2]):SetText(arguments[3])
		if arguments[3] == "0" then
			self.wndBattle:FindChild(self.activefighter):SetOpacity(0.3)
			self.activefighter = nil
		end
	end
end

--------------------
-- Protodex events
--------------------

function ProtomonGo:OnProtomonGo()
	self.wndGo:Invoke()
	ProtomonService:RemoteCall("ProtomonServer", "GetMyCode",
		function(code)
			self.wndGo:FindChild("Viewer"):DestroyChildren()
			self.wndGo:FindChild("Find"):SetData(nil)
			self.protomon = CopyTable(protomonbattle_protomon)
			local wndList = self.wndGo:FindChild("List")
			wndList:DestroyChildren()
			for i=1,5 do
				ApplyCode(self.protomon[i], code[i])
				local wndListItem = Apollo.LoadForm(self.xmlDoc, "ProtomonListItem", wndList, self)
				wndListItem:FindChild("Button"):SetText(self.protomon[i].name)
				wndListItem:FindChild("Button"):SetNormalTextColor(elementColors[self.protomon[i].element])
				wndListItem:FindChild("Button"):SetData({id = i, code = code[i]})
			end
			wndList:ArrangeChildrenVert()
			self.mycode = code
		end,
		function()
			Print("Can't contact server.")
		end)
end

function ProtomonGo:OnCancelGo()
	self.wndGo:Close()
end

-- A 'card' is a stat summary for a single protomon
function ProtomonGo:MakeCard(wndParent, id, code)
	local wndCard = Apollo.LoadForm(self.xmlDoc, "ProtomonCard", wndParent, self)
	local protomon = CopyTable(protomonbattle_protomon[id])
	ApplyCode(protomon, code)
	if protomon.absent then
		wndCard:SetText("ABSENT")
		wndCard:SetOpacity(0.5)
		return
	end
	wndCard:FindChild("Portrait"):SetText(self.protomon[id].name)
	wndCard:FindChild("Portrait"):SetTextColor(elementColors[self.protomon[id].element])
	wndCard:FindChild("Hp"):SetText("HP: " .. protomon.hp)
	wndCard:FindChild("Swap Attack"):SetText("Swap Attack: " .. protomon.switchattack)
	local wndList = wndCard:FindChild("Attacks")
	for attack, _ in pairs(protomonbattle_protomon[id].attacks) do
		local wndListItem = Apollo.LoadForm(self.xmlDoc, "Blank", wndList, self)
		wndListItem:SetText(attack .. " (" .. protomonbattle_attacks[attack].damage .. ")")
		wndListItem:SetTextColor(elementColors[protomonbattle_attacks[attack].element])
	end
	wndList:ArrangeChildrenVert()
	
	wndList = wndCard:FindChild("Bonuses")
	for i=1,6 do
		if code % 2 == 1 then
			local wndListItem = Apollo.LoadForm(self.xmlDoc, "Bonus", wndList, self)
			if protomon.bonuses[i].cost == 2 then
				wndListItem:SetAnchorOffsets(0,0,0,70)
			end
			wndListItem:FindChild("Button"):SetText(protomon.bonuses[i].description)
			wndListItem:FindChild("Button"):SetNormalTextColor(elementColors[protomon.bonuses[i].descriptioncolor])
		end
		code = math.floor(code / 2)
	end
	wndList:ArrangeChildrenVert()
end

function ProtomonGo:OnShowProtomon(wndHandler, wndControl)
	local toshow = wndHandler:GetData()
	self.wndGo:FindChild("Viewer"):DestroyChildren()
	self:MakeCard(self.wndGo:FindChild("Viewer"), toshow.id, toshow.code)
	self.wndGo:FindChild("Find"):SetData(toshow.id)
end

function ProtomonGo:RefreshProtodex()
	local wndList = self.wndGo:FindChild("List")
	wndList:DestroyChildren()
	for i=1,5 do
		ApplyCode(self.protomon[i], self.mycode[i])
		local wndListItem = Apollo.LoadForm(self.xmlDoc, "ProtomonListItem", wndList, self)
		wndListItem:FindChild("Button"):SetText(self.protomon[i].name)
		wndListItem:FindChild("Button"):SetNormalTextColor(elementColors[self.protomon[i].element])
		wndListItem:FindChild("Button"):SetData({id = i, code = self.mycode[i]})
	end
	wndList:ArrangeChildrenVert()
end

--------------------
-- Protomon levelling (subject to a lot of change once geo stuff is in)
--------------------

function ProtomonGo:OnProtomonReset()
	ProtomonService:RemoteCall("ProtomonServer", "JoinProtomon",
		function()
			Print("Reset to starter protomon!")
		end,
		function()
			Print("Could not contact server!")
		end)
end

function ProtomonGo:OnFind(wndHandler, wndControl)
	local id = wndHandler:GetData()
	
	if id then
		ProtomonService:RemoteCall("ProtomonServer", "FindProtomon",
			function(x)
				if PointsSpent(x) == PointsSpent(self.mycode[id]) and PointsSpent(x) > 0 then
					self.wndConfirm:FindChild("Before"):DestroyChildren()
					self:MakeCard(self.wndConfirm:FindChild("Before"), id, self.mycode[id])
					self.wndConfirm:FindChild("After"):DestroyChildren()
					self:MakeCard(self.wndConfirm:FindChild("After"), id, x)
					self.wndConfirm:Invoke()
				else
					self.protomon[id] = CopyTable(protomonbattle_protomon[id])
					ApplyCode(self.protomon[id], x)
					self.wndGo:FindChild("Viewer"):DestroyChildren()
					self:MakeCard(self.wndGo:FindChild("Viewer"), id, x)
					self.mycode[id] = x
					self:RefreshProtodex()
				end
			end,
			function()
				Print("Couldn't reach server!")
			end,
			id)
	end
end

function ProtomonGo:OnReject()
	self.wndConfirm:Close()
end

function ProtomonGo:OnAccept()
	local id = self.wndGo:FindChild("Find"):GetData()
	ProtomonService:RemoteCall("ProtomonServer", "AcceptProtomon",
		function(x)
			if x < 64 then
				self.protomon[id] = CopyTable(protomonbattle_protomon[id])
				ApplyCode(self.protomon[id], x)
				self.wndGo:FindChild("Viewer"):DestroyChildren()
				self:MakeCard(self.wndGo:FindChild("Viewer"), id, x)
				self.mycode[id] = x
				self:RefreshProtodex()
			end
		end,
		function()
			Print("Couldn't confirm!")
		end,
		id)
	self.wndConfirm:Close()
end

local ProtomonGoInst = ProtomonGo:new()
ProtomonGoInst:Init()

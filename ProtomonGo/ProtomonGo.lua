require "Window"
require "ICCommLib"
require "ICComm"
require "Sound"

local kVersion = 2
local kProximity = 30

local elementColors = {
	["fire"] = {r = 1, g = 0, b = 0, a = 1},
	["air"] = {r = 1, g = 1, b = 0, a = 0.7},
	["life"] = {r = 0, g = 1, b = 0, a = 1},
	["water"] = {r = 0, g = 0, b = 1, a = 1},
	["earth"] = {r = 0.8, g = 0.4, b = 0.1, a = 1},
	["normal"] = {r = 1, g = 1, b = 1, a = 1},
}

local sprites = {
	[1] = "ProtomonSprites:Charenok",
	[2] = "ProtomonSprites:Vindchu",
	[3] = "ProtomonSprites:Stemasaur",
	[4] = "ProtomonSprites:Squig",
	[5] = "ProtomonSprites:Boulderdude",
}

local portraits = {
	[1] = "ProtomonSprites:P_Charenok",
	[2] = "ProtomonSprites:P_Vindchu",
	[3] = "ProtomonSprites:P_Stemasaur",
	[4] = "ProtomonSprites:P_Squig",
	[5] = "ProtomonSprites:P_Boulderdude",
}

local ages = {
	[0] = "Young",
	"Adult",
	"Seasoned",
	"Elder",
	"Legendary",
}

local ProtomonService

--------------------
-- Utility stuff
--------------------

--hash a string into a number from 1 .. limit
local function HashString(input, limit)
	math.randomseed(1)
	math.random(2) -- not sure why, but first random after a seed is not random
	
	local currentHash = math.random(limit)
	for i = 1, #input do
		math.randomseed(currentHash + string.byte(string.sub(input, i, i)))
		math.random(2)
		currentHash = math.random(limit)
	end
	
	math.randomseed(os.time())
	math.random(2)
	return currentHash
end

local function MyWorldHash()
	local res = HousingLib.GetResidence()
	if res then
		return HashString(res:GetPropertyOwnerName(), 78074895) -- 94^4 - 1, 4 rpc bytes
	else
		local zone = GameLib.GetCurrentZoneMap()
		if zone.parentZoneId ~= 0 then
			return zone.nWorldId * 1000000 + zone.continentId * 1000 + zone.parentZoneId
		else
			return zone.nWorldId * 1000000 + zone.continentId * 1000 + zone.id
		end
	end
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

local function FloatText(strMessage)
	local tTextOption =	{
		strFontFace = "CRB_FloaterLarge",
		fDuration = 3.5,
		fScale = 1,
		fExpand = 1,
		fVibrate = 0,
		fSpinAroundRadius = 0,
		fFadeInDuration = 0.2,
		fFadeOutDuration = 0.5,
		fVelocityDirection = 0,
		fVelocityMagnitude = 0,
		fAccelDirection = 0,
		fAccelMagnitude = 0,
		fEndHoldDuration = 1,
		eLocation = CombatFloater.CodeEnumFloaterLocation.Bottom,
		fOffsetDirection = 0,
		fOffset = 0,
		eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal,
		fExpandCollisionBoxWidth = 1,
		fExpandCollisionBoxHeight = 1,
		nColor = 0xFF0000,
		iUseDigitSpriteSet = nil,
		bUseScreenPos = true,
		bShowOnTop = true,
		fRotation = 0,
		fDelay = 0,
		nDigitSpriteSpacing = 0,
	}
	
	CombatFloater.ShowTextFloater(GameLib.GetControlledUnit(), strMessage, tTextOption)
end

--------------------
-- Protomon Go
--------------------

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
	Apollo.LoadSprites("Protomon.xml", "ProtomonSprites")

	self.xmlDoc = XmlDoc.CreateFromFile("ProtomonGo.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	Apollo.RegisterSlashCommand("protomongo", "OnProtomonGo", self)
	Apollo.RegisterSlashCommand("protodex", "OnProtomonGo", self)
	Apollo.RegisterSlashCommand("protomonbattle", "OnProtomonBattle", self)
	Apollo.RegisterSlashCommand("protomontracker", "OnProtomonTrack", self)
	Apollo.RegisterSlashCommand("prototracker", "OnProtomonTrack", self)
	Apollo.RegisterSlashCommand("protomontrack", "OnProtomonTrack", self)
	Apollo.RegisterSlashCommand("prototrack", "OnProtomonTrack", self)
	Apollo.RegisterSlashCommand("addspawn", "OnAddSpawn", self)
	Apollo.RegisterSlashCommand("removespawn", "OnRemoveSpawn", self)
	Apollo.RegisterSlashCommand("getzoneinfo", "OnGetZoneInfo", self)
	Apollo.RegisterSlashCommand("fillzonemap", "OnFillZoneMap", self)
	Apollo.RegisterSlashCommand("clearzonemap", "OnClearZoneMap", self)

	self.protomon = CopyTable(protomonbattle_protomon)
	self.playingmusic = false
	self.nearbyProtomon = {}
	self.mapObjects = {}

	self.battleConnectTimer = ApolloTimer.Create(1, true, "ConnectBattle", self)
	self.protomonServiceConnectTimer = ApolloTimer.Create(1, true, "ConnectProtomonService", self)
	self.getVersionTimer = ApolloTimer.Create(10, true, "GetVersion", self)
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

	    self.wndTrack = Apollo.LoadForm(self.xmlDoc, "Tracker", nil, self)
		if self.wndTrack == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Tracker window for some reason.")
			return
		end
		
	    self.wndTrack:Show(false, true)

	    self.wndView = Apollo.LoadForm(self.xmlDoc, "Viewer", nil, self)
		if self.wndView == nil then
			Apollo.AddAddonErrorText(self, "Could not load the Viewer window for some reason.")
			return
		end
		
	    self.wndView:Show(false, true)

	    self.wndConfirm = Apollo.LoadForm(self.xmlDoc, "SwapConfirm", nil, self)
		if self.wndConfirm == nil then
			Apollo.AddAddonErrorText(self, "Could not load the swap confirmation window for some reason.")
			return
		end
		
	    self.wndConfirm:Show(false, true)

	    self.wndLevel = Apollo.LoadForm(self.xmlDoc, "LevelNotify", nil, self)
		if self.wndLevel == nil then
			Apollo.AddAddonErrorText(self, "Could not load the level notification window for some reason.")
			return
		end
		
	    self.wndLevel:Show(false, true)
		
	    self.wndPos = Apollo.LoadForm(self.xmlDoc, "Position", nil, self)
		if self.wndPos == nil then
			Apollo.AddAddonErrorText(self, "Could not load the position window for some reason.")
			return
		end
		
	    self.wndPos:Show(true, true)
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

function ProtomonGo:GetVersion()
	if ProtomonService then
		ProtomonService:RemoteCall("ProtomonServer", "GetVersion",
			function(version)
				self.serverVersion = version
				self.getVersionTimer:Stop()
			end,
			function() end)
	end
end

--------------------
-- Battle music control (thx Smooth McGroove!)
--------------------

function ProtomonGo:PlayStart()
	if not self.playingmusic then
		if not self.wndBattle:FindChild("Mute"):IsChecked() then
			Sound.PlayFile("battlestart.wav")
		end
		self.musictimer = ApolloTimer.Create(7.82, false, "PlayLoop", self)
	end
	self.playingmusic = true
	self.endingmusic = false
end

function ProtomonGo:PlayLoop()
	if self.endingmusic then
		if not self.wndBattle:FindChild("Mute"):IsChecked() then
			Sound.PlayFile("battleend.wav")
		end
		self.playingmusic = false
	else
		if not self.wndBattle:FindChild("Mute"):IsChecked() then
			Sound.PlayFile("battleloop.wav")
		end
		self.musictimer = ApolloTimer.Create(39.41, false, "PlayLoop", self)
	end
end	

--------------------
-- Battle form events
--------------------

function ProtomonGo:OnProtomonBattle()
	if not self.serverVersion then
		Print("Could not connect to protomon server.")
		return
	elseif self.serverVersion > kVersion then
		Print("Protomon addon needs to be updated!")
		return
	end
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
		
		for attackname, _ in pairs(self.protomon[protomonbattle_names[string.lower(wndHandler:GetText())]].attacks) do
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
		self.wndBattle:FindChild("Fighter1"):FindChild("Image"):SetSprite()
		self.wndBattle:FindChild("Fighter2"):FindChild("Image"):SetSprite()
		self.wndBattle:FindChild("Fighter3"):FindChild("Image"):SetSprite()
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
		self.endingmusic = true
	elseif arguments[1] == "switch" then
		if self.activefighter ~= nil then
			self.wndBattle:FindChild(self.activefighter):SetOpacity(0.3)
		end
		self.activefighter = "Fighter" .. arguments[2]
		self.wndBattle:FindChild(self.activefighter):SetText(self.protomon[protomonbattle_names[arguments[3]]].name)
		self.wndBattle:FindChild(self.activefighter):SetTextColor(elementColors[self.protomon[protomonbattle_names[arguments[3]]].element])
		self.wndBattle:FindChild(self.activefighter):FindChild("Image"):SetSprite(portraits[protomonbattle_names[arguments[3]]])
		self.wndBattle:FindChild(self.activefighter):SetOpacity(1)
		self.wndBattle:FindChild("Hp" .. arguments[2]):SetText(arguments[4])

		local wndList = self.wndBattle:FindChild("List")
		wndList:DestroyChildren()
		
		for attackname, _ in pairs(self.protomon[protomonbattle_names[arguments[3]]].attacks) do
			local wndListItem = Apollo.LoadForm(self.xmlDoc, "Command", wndList, self)
			wndListItem:FindChild("Button"):SetText(protomonbattle_attacks[attackname].name .. " (" .. protomonbattle_attacks[attackname].damage .. ")")
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

function ProtomonGo:OnProtomonGo(strCmd, strArg)
	if not self.serverVersion then
		Print("Could not connect to protomon server.")
		return
	elseif self.serverVersion > kVersion then
		Print("Protomon addon needs to be updated!")
		return
	end
	self.wndGo:Invoke()
	ProtomonService:RemoteCall("ProtomonServer", "GetMyCode",
		function(code)
			self.wndGo:FindChild("Viewer"):DestroyChildren()
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
	local level = ApplyCode(protomon, code)
	if protomon.absent then
		wndCard:SetText("ABSENT")
		wndCard:SetOpacity(0.5)
		return
	end
	wndCard:FindChild("Name"):SetText(ages[level] .. " " .. self.protomon[id].name)
	wndCard:FindChild("Name"):SetTextColor(elementColors[self.protomon[id].element])
	wndCard:FindChild("Portrait"):FindChild("Image"):SetSprite(portraits[id])
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
-- Protomon tracker
--------------------

function ProtomonGo:OnProtomonTrack()
	if not self.serverVersion then
		Print("Could not connect to protomon server.")
		return
	elseif self.serverVersion > kVersion then
		Print("Protomon addon needs to be updated!")
		return
	end
	self.wndTrack:Invoke()
	self.wndCompass = self.wndTrack:FindChild("Compass")
	self.wndArrow = self.wndCompass:FindChild("Arrow")
	self.compassTimer = ApolloTimer.Create(0.05, true, "UpdateCompass", self)
	self.alertTimer = ApolloTimer.Create(1, true, "UpdateAlert", self)
	self:UpdateArrow()
	ProtomonService:RemoteCall("ProtomonServer", "GetMyCode",
		function(code)
			self.mycode = code
		end,
		function()
			Print("Can't contact server.")
		end)
end

function ProtomonGo:OnCloseTracker()
	self.wndTrack:Close()
	self.wndView:Close()
	self.compassTimer:Stop()
	self.arrowTimer:Stop()
	for _, protomon in pairs(self.nearbyProtomon) do
		self.wndView:DestroyPixie(protomon.pixieId)
	end
	self.nearbyProtomon = {}
	self.alertTimer:Stop()
end

function ProtomonGo:UpdateCompass()
	if GameLib.GetPlayerUnit() == nil then
		self:OnCloseTracker()
		return
	end
	local facing = GameLib.GetPlayerUnit():GetFacing()
	local rotation = -90 - math.deg(math.atan(facing.z/facing.x))
	if facing.x < 0 then rotation = rotation + 180 end
	self.wndCompass:SetRotation(rotation)
end

function ProtomonGo:MarkForDeath(parent, label, delay)
	local child = parent[label]
	child.myParent = parent
	child.myLabel = label
	child.Die = function(dying)
		dying.deathTimer:Stop()
		self.wndView:DestroyPixie(dying.pixieId)
		dying.myParent[dying.myLabel] = nil
	end
	child.deathTimer = ApolloTimer.Create(delay, false, "Die", child)
end

function ProtomonGo:UpdateAlert()
	if not GameLib.GetPlayerUnit() then return end
	local position = GameLib.GetPlayerUnit():GetPosition()
	local callingPosition = {
		math.floor(position.x),
		math.floor(position.y),
		math.floor(position.z),		
	}
	local alert = 0
	for _, protomon in pairs(self.nearbyProtomon) do
		local distance = math.sqrt((callingPosition[1] - protomon.location.x)^2 +
			(callingPosition[2] - protomon.location.y)^2 +
			(callingPosition[3] - protomon.location.z)^2)
		if distance < kProximity then
			alert = 1
		end
	end
	self.wndTrack:FindChild("Alert"):SetOpacity(alert)
end

function ProtomonGo:UpdateArrow()
	if not self.wndTrack:IsVisible() then return end
	if not GameLib.GetPlayerUnit() then return end
	local position = GameLib.GetPlayerUnit():GetPosition()
	local callingPosition = {
		math.floor(position.x),
		math.floor(position.y),
		math.floor(position.z),		
	}
	local zoneHash = MyWorldHash()
	local relativePosition
	if protomonbattle_zones[zoneHash] then
		relativePosition = {
			callingPosition[1] - protomonbattle_zones[zoneHash].center.x,
			callingPosition[2] - protomonbattle_zones[zoneHash].center.y,
			callingPosition[3] - protomonbattle_zones[zoneHash].center.z,
		}
	else
		relativePosition = {
			callingPosition[1] - protomonbattle_zones["housing"].center.x,
			callingPosition[2] - protomonbattle_zones["housing"].center.y,
			callingPosition[3] - protomonbattle_zones["housing"].center.z,
		}
	end
	ProtomonService:RemoteCall("ProtomonServer", "RadarPulse",
		function(elementHeadingRange, nearbyProtomon)
			if elementHeadingRange[1] == 0 then
				self.wndCompass:SetOpacity(0)
				self.arrowTimer = ApolloTimer.Create(5, false, "UpdateArrow", self)
			else
				if elementHeadingRange[3] == 1 then
					self.wndCompass:SetOpacity(1)
				else
					self.wndCompass:SetOpacity(0.3)
				end
				self.wndArrow:SetRotation(elementHeadingRange[2] * 90)
				self.wndArrow:SetBGColor(elementColors[protomonbattle_protomon[elementHeadingRange[1]].element])
				self.arrowTimer = ApolloTimer.Create(5, false, "UpdateArrow", self)
			end
			for _, nearby in ipairs(nearbyProtomon) do
				local newProtomon = {
					protomonId = nearby[1][1],
					level = nearby[1][2],
					location = {
						x = (nearby[2][1] - 256) / 4 + callingPosition[1],
						y = (nearby[2][2] - 128) / 4 + callingPosition[2],
						z = (nearby[2][3] - 256) / 4 + callingPosition[3],
					},
				}
				newProtomon.pixieId = self.wndView:AddPixie({
					strSprite=sprites[protomonId],
					flagsText = {
						DT_RIGHT = true,
					},
					strText = tostring(nearby[1][2]),
					loc = {
						fPoints = {0.5,2,0.5,2},
						nOffsets = {0,0,0,0}}
					})

				if self.nearbyProtomon[nearby[1][3]] then
					self.nearbyProtomon[nearby[1][3]]:Die()
				end
				self.nearbyProtomon[nearby[1][3]] = newProtomon
				self:MarkForDeath(self.nearbyProtomon, nearby[1][3], 75)
			end
		end,
		function()
			self.wndCompass:SetOpacity(0)
			Print("Could not contact server!")
			self.arrowTimer = ApolloTimer.Create(5, false, "UpdateArrow", self)
		end,
		zoneHash, relativePosition)
end

--------------------
-- Protomon viewer
--------------------

function ProtomonGo:InFirstPerson()
	local pos = GameLib.GetPlayerUnit():GetPosition()
	local facing = GameLib.GetPlayerUnit():GetFacing()
	self.wndPos:SetWorldLocation(Vector3.New(pos.x-(1.5 * facing.x), pos.y, pos.z-(1.5 * facing.z)))
	return not self.wndPos:IsOnScreen()
end

function ProtomonGo:OnProtomonView()
	if not self.wndView:IsVisible() then
		if self:InFirstPerson() then
			self.wndView:Invoke()
			self.viewTimer = ApolloTimer.Create(0.03, true, "UpdateViewer", self)
			self.closeViewTimer = ApolloTimer.Create(0.5, true, "CloseViewer", self)
		else
			FloatText("Enter first-person before activating the viewer!")
		end
	else
		self.wndView:Close()
		
		local nearest
		local nearestId
		local nearestDist
		local myPos = GameLib.GetPlayerUnit():GetPosition()
		for zoneId, protomon in pairs(self.nearbyProtomon) do
			local distance = math.sqrt((protomon.location.x - myPos.x)^2 +
				(protomon.location.y - myPos.y)^2 +
				(protomon.location.z - myPos.z)^2)
			if not nearest or distance < nearestDist then
				nearestId = zoneId
				nearest = protomon
				nearestDist = distance
			end
		end

		if nearestDist and nearestDist < 5 then
			ProtomonService:RemoteCall("ProtomonServer", "FindProtomon",
				function(x)
					self.nearbyProtomon[nearestId]:Die()

					local currentLevel = PointsSpent(self.mycode[nearest.protomonId])
					local foundLevel = nearest.level
					local newLevel = PointsSpent(x)
					local name = protomonbattle_protomon[nearest.protomonId].name
					if newLevel == 0 and x < 64 then
						FloatText(name .. " wants her cub to train with you!")
					elseif foundLevel > currentLevel then
						FloatText(name .. " learns a lot from practicing with an older protomon!")
					elseif foundLevel == currentLevel then
						FloatText(name .. " spars with a wild protomon!")
					else
						FloatText(name .. " plays with a youngling for awhile.")
					end

					if x >= 64 then return end

					if newLevel == currentLevel and newLevel > 0 then
						self.wndConfirm:FindChild("Before"):DestroyChildren()
						self:MakeCard(self.wndConfirm:FindChild("Before"), nearest.protomonId, self.mycode[nearest.protomonId])
						self.wndConfirm:FindChild("After"):DestroyChildren()
						self:MakeCard(self.wndConfirm:FindChild("After"), nearest.protomonId, x)
						self.wndConfirm:FindChild("Accept"):SetData(nearest.protomonId)
						self.wndConfirm:Invoke()
					else
						self.wndLevel:FindChild("Before"):DestroyChildren()
						self:MakeCard(self.wndLevel:FindChild("Before"), nearest.protomonId, self.mycode[nearest.protomonId])
						self.wndLevel:FindChild("After"):DestroyChildren()
						self:MakeCard(self.wndLevel:FindChild("After"), nearest.protomonId, x)
						self.wndLevel:Invoke()

						self.protomon[nearest.protomonId] = CopyTable(protomonbattle_protomon[nearest.protomonId])
						ApplyCode(self.protomon[nearest.protomonId], x)
						self.wndGo:FindChild("Viewer"):DestroyChildren()
						self:MakeCard(self.wndGo:FindChild("Viewer"), nearest.protomonId, x)
						self.mycode[nearest.protomonId] = x
						self:RefreshProtodex()
					end
				end,
				function()
					Print("Couldn't reach server!")
				end,
				MyWorldHash(), nearestId)
		end
	end
end

function ProtomonGo:CloseViewer()
	if not self:InFirstPerson() then
		self.wndView:Close()
	end
end

function ProtomonGo:UpdateViewer()
	if not GameLib.GetPlayerUnit() then
		self.wndView:Close()
	end
	if not self.wndView:IsVisible() then
		self.viewTimer:Stop()
		self.closeViewTimer:Stop()
		return
	end
	
	local myPos = GameLib.GetPlayerUnit():GetPosition()
	local screenHeight = self.wndView:GetHeight() * 5 / 3
	local screenWidth = self.wndView:GetWidth() * 5 / 3
	for _, protomon in pairs(self.nearbyProtomon) do
		local distance = math.sqrt((protomon.location.x - myPos.x)^2 +
			(protomon.location.y - myPos.y)^2 +
			(protomon.location.z - myPos.z)^2)
		if distance > 50 then
			self.wndView:UpdatePixie(protomon.pixieId, {
				strSprite=sprites[protomon.protomonId],
				flagsText = {
					DT_RIGHT = true,
				},
				strText = tostring(protomon.level),
				loc = {
					fPoints = {0.5,2,0.5,2},
					nOffsets = {0,0,0,0}}
				})
		else
			local screenPos = GameLib.WorldLocToScreenPoint(Vector3.New(
				protomon.location.x, protomon.location.y, protomon.location.z))
			if screenPos.z > 0 then
				local adjustedX = ((screenPos.x / screenWidth) - 0.2) / 0.6
				local adjustedY = ((screenPos.y / screenHeight) - 0.2) / 0.6
				self.wndView:UpdatePixie(protomon.pixieId, {
					strSprite=sprites[protomon.protomonId],
					flagsText = {
						DT_RIGHT = true,
					},
					strText = tostring(protomon.level),
					loc = {
						fPoints = {adjustedX, adjustedY, adjustedX, adjustedY},
						nOffsets = {
							-800 / distance,
							-1200 / distance,
							800 / distance,
							400 / distance,
							}}
					})
			else
				self.wndView:UpdatePixie(protomon.pixieId, {
					strSprite=sprites[protomon.protomonId],
					flagsText = {
						DT_RIGHT = true,
					},
					strText = tostring(protomon.level),
					loc = {
						fPoints = {0.5,2,0.5,2},
						nOffsets = {0,0,0,0}}
					})
			end
		end
	end
end

--------------------
-- Protomon levelling (subject to a lot of change once geo stuff is in)
--------------------

function ProtomonGo:OnReject()
	self.wndConfirm:Close()
end

function ProtomonGo:OnAccept(wndHandler, wndControl)
	local protomonId = wndHandler:GetData()
	ProtomonService:RemoteCall("ProtomonServer", "AcceptProtomon",
		function(x)
			if x < 64 then
				self.protomon[protomonId] = CopyTable(protomonbattle_protomon[protomonId])
				ApplyCode(self.protomon[protomonId], x)
				self.mycode[protomonId] = x
				Print("Accepted protomon!")
			else
				Print("Protomon lost!")
			end
		end,
		function()
			Print("Couldn't confirm!")
		end,
		protomonId)
	self.wndConfirm:Close()
end

function ProtomonGo:OnDone()
	self.wndLevel:Close()
end

--------------------
-- Admin functions (will not work if you are not in Protomon Administrators circle)
--------------------

function ProtomonGo:OnAddSpawn(strCmd, strArg)
	local arguments = {}
	for arg in string.gmatch(strArg, "%S+") do
		table.insert(arguments, arg)
	end
	
	local gamePos = GameLib.GetPlayerUnit():GetPosition()
	local zoneHash = MyWorldHash()
	local positionArg
	if protomonbattle_zones[zoneHash] then
		positionArg = {
			math.floor(4 * (gamePos.x - protomonbattle_zones[zoneHash].center.x)),
			math.floor(4 * (gamePos.y - protomonbattle_zones[zoneHash].center.y)),
			math.floor(4 * (gamePos.z - protomonbattle_zones[zoneHash].center.z))
		}
	else
		if not HousingLib.GetResidence() then
			FloatText("This zone is not yet supported!")
			return
		end
		positionArg = {
			math.floor(4 * (gamePos.x - protomonbattle_zones["housing"].center.x)),
			math.floor(4 * (gamePos.y - protomonbattle_zones["housing"].center.y)),
			math.floor(4 * (gamePos.z - protomonbattle_zones["housing"].center.z))
		}
	end

	ProtomonService:RemoteCall("ProtomonServerAdmin", "AddSpawn",
		function(x)
			Print("Spawn added!")
		end,
		function(x)
			Print("Failed!")
		end,
		protomonbattle_names[arguments[1]], tonumber(arguments[2]), zoneHash, positionArg)
end

function ProtomonGo:OnRemoveSpawn()
	local nearestId
	local nearestDist
	local myPos = GameLib.GetPlayerUnit():GetPosition()
	for zoneId, protomon in pairs(self.nearbyProtomon) do
		local distance = math.sqrt((protomon.location.x - myPos.x)^2 +
			(protomon.location.y - myPos.y)^2 +
			(protomon.location.z - myPos.z)^2)
		if not nearestDist or distance < nearestDist then
			nearestId = zoneId
			nearestDist = distance
		end
	end

	if nearestDist and nearestDist < 5 then
		ProtomonService:RemoteCall("ProtomonServerAdmin", "RemoveSpawn",
			function(x)
				self.nearbyProtomon[nearestId]:Die()
			end,
			function()
				Print("Couldn't reach server!")
			end,
			MyWorldHash(), nearestId)
	end
end

function ProtomonGo:OnGetZoneInfo()
	ProtomonService:RemoteCall("ProtomonServerAdmin", "GetZoneInfo",
		function(stats)
			local total = 0
			for protomonId, levelStats in ipairs(stats) do
				Print(protomonbattle_protomon[protomonId].name ..
					"   1-" .. levelStats[1] ..
					"   2-" .. levelStats[2] ..
					"   3-" .. levelStats[3])
				total = total + levelStats[1] + levelStats[2] + levelStats[3]
			end
			Print("Total: " .. total)
		end,
		function()
			Print("Could not contact server.")
		end,
		MyWorldHash())
end

function ProtomonGo:OnFillZoneMap()
	self:OnClearZoneMap()

	local mapType =  Apollo.GetAddon("ZoneMap").eObjectTypeQuest
	local zoneMap = Apollo.GetAddon("ZoneMap").wndZoneMap

	local zoneHash = MyWorldHash()
	local center
	if protomonbattle_zones[zoneHash] then
		center = protomonbattle_zones[zoneHash].center
	else
		center = protomonbattle_zones["housing"].center
	end

	ProtomonService:RemoteCall("ProtomonServerAdmin", "GetZoneList",
		function(spawns)
			for i, spawn in pairs(spawns) do
				local tInfo = {
					strIcon = "CRB_NumberFloaters:sprFloater_Normal" .. spawn[1][2],
					crObject = elementColors[protomonbattle_protomon[spawn[1][1]].element],
					fRadius = 0.5,
				}
				table.insert(self.mapObjects,
					zoneMap:AddObject(
						mapType,
						{
							x = 10 * spawn[2][1] + center.x,
							y = 10 * spawn[2][2] + center.y,
							z = 10 * spawn[2][3] + center.z,
						},
						"", tInfo, {bNeverShowOnEdge = false}))
			end
		end,
		function()
			Print("Could not contact server.")
		end,
		zoneHash)
end

function ProtomonGo:OnClearZoneMap()
	local zoneMap = Apollo.GetAddon("ZoneMap").wndZoneMap
	while #self.mapObjects > 0 do
		zoneMap:RemoveObject(table.remove(self.mapObjects))
	end
end

local ProtomonGoInst = ProtomonGo:new()
ProtomonGoInst:Init()

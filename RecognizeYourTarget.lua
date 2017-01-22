local Addon = {}
Addon.name = "RecognizeYourTarget"

local GetEventManager = GetEventManager
local EVENT_MANAGER = GetEventManager()

local GetWindowManager = GetWindowManager
local WINDOW_MANAGER = GetWindowManager()

local GetAnimationManager = GetAnimationManager
local ANIMATION_MANAGER = GetAnimationManager()

local RETICLE = RETICLE

local EVENT_ADD_ON_LOADED = EVENT_ADD_ON_LOADED
local EVENT_PLAYER_ACTIVATED = EVENT_PLAYER_ACTIVATED
local EVENT_RETICLE_TARGET_CHANGED = EVENT_RETICLE_TARGET_CHANGED
local EVENT_FRIEND_ADDED = EVENT_FRIEND_ADDED
local EVENT_FRIEND_REMOVED = EVENT_FRIEND_REMOVED
local EVENT_GROUP_MEMBER_JOINED = EVENT_GROUP_MEMBER_JOINED
local EVENT_GROUP_MEMBER_LEFT = EVENT_GROUP_MEMBER_LEFT
-- local EVENT_GROUP_TYPE_CHANGED = EVENT_GROUP_TYPE_CHANGED
local EVENT_GROUP_UPDATE = EVENT_GROUP_UPDATE
local EVENT_GUILD_MEMBER_ADDED = EVENT_GUILD_MEMBER_ADDED
local EVENT_GUILD_MEMBER_REMOVED = EVENT_GUILD_MEMBER_REMOVED
local EVENT_GUILD_SELF_JOINED_GUILD = EVENT_GUILD_SELF_JOINED_GUILD
local EVENT_GUILD_SELF_LEFT_GUILD = EVENT_GUILD_SELF_LEFT_GUILD

local CHAT_SYSTEM = CHAT_SYSTEM
local ZO_ColorDef = ZO_ColorDef

local zo_strformat = zo_strformat

local IsConsoleUI = IsConsoleUI

local GetUnitDisplayName = GetUnitDisplayName
local GetUnitName = GetUnitName

local DoesUnitExist = DoesUnitExist
local IsUnitPlayer = IsUnitPlayer

local GetNumFriends = GetNumFriends
local GetFriendInfo = GetFriendInfo
local GetFriendCharacterInfo = GetFriendCharacterInfo

local GetGroupSize = GetGroupSize
local GetGroupUnitTagByIndex = GetGroupUnitTagByIndex

local GetNumGuilds = GetNumGuilds
local GetGuildId = GetGuildId
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildMemberInfo = GetGuildMemberInfo
local GetGuildMemberCharacterInfo = GetGuildMemberCharacterInfo

local GetFinalGuildRankTextureLarge = GetFinalGuildRankTextureLarge
local GetGuildName = GetGuildName

local CT_LABEL = CT_LABEL
local TOP = TOP
local BOTTOM = BOTTOM
local LEFT = LEFT
local RIGHT = RIGHT
local CENTER = CENTER

local ANIMATION_ALPHA = ANIMATION_ALPHA

local FRIEND_ICON = "EsoUI/Art/MainMenu/menuBar_social_up.dds"
local GROUP_MEMBER_ICON = "EsoUI/Art/MainMenu/menuBar_group_up.dds"
local GUILD_MEMBER_ICON = "EsoUI/Art/MainMenu/menuBar_guilds_up.dds"

local function IsTargetFriend(unitTag)
  return Addon:GetFriendIndexByName(GetUnitDisplayName(unitTag)) ~= nil
end

local function IsTargetGroupMember(unitTag)
  return Addon:GetGroupMemberIndexByName(GetUnitDisplayName(unitTag)) ~= nil
end

local function IsTargetGuildMember(unitTag)
  return Addon:GetGuildMemberIndexByName(GetUnitDisplayName(unitTag)) ~= nil
end

function Addon:FadeInControl()
  if (self.control:GetAlpha() == 1) then return end

  if (self.timeline:IsPlaying()) then
    self.timeline:PlayForward()
  else
    self.timeline:PlayFromStart()
  end
end

function Addon:FadeOutControl()
  if (self.control:GetAlpha() == 0) then return end

  if (self.timeline:IsPlaying()) then
    self.timeline:PlayBackward()
  else
    self.timeline:PlayFromEnd()
  end
end

function Addon:AddFriend(name, friendIndex)
  if (not name or name == self.playerName or name == self.playerUserId) then return end

  self.friendIndex[name] = friendIndex
end

function Addon:AddGroupMember(name, memberIndex)
  if (not name or name == self.playerName or name == self.playerUserId) then return end

  self.groupMemberIndex[name] = memberIndex
end

function Addon:AddGuildMember(name, guildId, memberIndex)
  if (not name or name == self.playerName or name == self.playerUserId) then return end

  if (not self.guildMemberIndex[name]) then
    self.guildMemberIndex[name] = {}
  end

  self.guildMemberIndex[name][guildId] = memberIndex
end

function Addon:BuildFriendIndex()
  self.friendIndex = {}

  for i = 1, GetNumFriends() do
    local displayName = GetFriendInfo(i)
    self:AddFriend(displayName, i)
  end
end

function Addon:GetFriendIndexByName(name)
  if (not name or name == "") then
    return nil
  end

  return self.friendIndex[name]
end

function Addon:BuildGroupMemberIndex()
  self.groupMemberIndex = {}

  for i = 1, GetGroupSize() do
    local unitTag = GetGroupUnitTagByIndex(i)
    if (unitTag) then
      local displayName = GetUnitDisplayName(unitTag)
      self:AddGroupMember(displayName, i)
    end
  end
end

function Addon:GetGroupMemberIndexByName(name)
  if (not name or name == "") then
    return nil
  end

  return self.groupMemberIndex[name]
end

function Addon:GetGuildMemberIndex(guildId, name)
  if (self.guildMemberIndex[name]) then
    return self.guildMemberIndex[name][guildId]
  end

  return nil
end

function Addon:GetGuildMemberIndexByName(name)
  if (not name or name == "") then
    return nil
  end

  for i = 1, GetNumGuilds() do
    local guildId = GetGuildId(i)
    local memberIndex = self:GetGuildMemberIndex(guildId, name)

    if (memberIndex) then
      return guildId, memberIndex
    end
  end

  return nil, nil
end

function Addon:BuildGuildMemberIndex()
  self.guildMemberIndex = {}

  for i = 1, GetNumGuilds() do
    local guildId = GetGuildId(i)
    for memberIndex = 1, GetNumGuildMembers(guildId) do
      local displayName = GetGuildMemberInfo(guildId, memberIndex)
      self:AddGuildMember(displayName, guildId, memberIndex)
    end
  end
end

function Addon:SetupControls()
  local control = WINDOW_MANAGER:CreateTopLevelWindow("RecognizeYourTarget")
  control:SetAnchor(CENTER, RETICLE.control, CENTER, 0, -100)
  control:SetAlpha(0)

  self.control = control

  local nameLabel = WINDOW_MANAGER:CreateControl("RecognizeYourTargetName", control, CT_LABEL)
  nameLabel:SetAnchor(CENTER, control, CENTER, 0, 0)
  nameLabel:SetFont("$(BOLD_FONT)|20|soft-shadow-thick")

  self.nameLabel = nameLabel

  local infoLabel = WINDOW_MANAGER:CreateControl("RecognizeYourTargetInfo", nameLabel, CT_LABEL)
  infoLabel:SetAnchor(TOP, nameLabel, BOTTOM, 0, 0)
  infoLabel:SetFont("$(BOLD_FONT)|14|soft-shadow-thick")

  self.infoLabel = infoLabel

  local icon = WINDOW_MANAGER:CreateControl("RecognizeYourTargetIcon", nameLabel, CT_TEXTURE)
  icon:SetAnchor(RIGHT, nameLabel, LEFT, 0, 0)
  icon:SetHeight(32)
  icon:SetWidth(32)

  self.icon = icon

  local timeline = ANIMATION_MANAGER:CreateTimeline()

  local fadeIn = timeline:InsertAnimation(ANIMATION_ALPHA, self.control)
  fadeIn:SetAlphaValues(0, 1)
  fadeIn:SetDuration(50)

  self.timeline = timeline
end

function Addon:BuildIndex()
  self:BuildFriendIndex()
  self:BuildGroupMemberIndex()
  self:BuildGuildMemberIndex()
end

function Addon:OnPlayerActivated()
  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_ACTIVATED)

  local color = ZO_ColorDef:New(1, .7, 1)
  CHAT_SYSTEM:AddMessage(color:Colorize(self.name.." loaded"))

  self.playerName = GetUnitName("player")
  self.playerUserId = GetDisplayName()

  self:BuildIndex()
end

function Addon:OnTargetChanged()
  if (DoesUnitExist("reticleover") and IsUnitPlayer("reticleover")) then
    if (IsTargetFriend("reticleover")) then
      local name = GetUnitName("reticleover")

      self.nameLabel:SetText(name)
      self.infoLabel:SetColor(.5, .7, .8)
      self.infoLabel:SetText("<friend>")
      self.icon:SetTexture(FRIEND_ICON)

      self:FadeInControl()
    elseif (IsTargetGroupMember("reticleover")) then
      local name = GetUnitName("reticleover")

      self.nameLabel:SetText(name)
      self.infoLabel:SetColor(1, .5, .1)
      self.infoLabel:SetText("<group>")
      self.icon:SetTexture(GROUP_MEMBER_ICON)

      self:FadeInControl()
    elseif (IsTargetGuildMember("reticleover")) then
      local displayName = GetUnitDisplayName("reticleover")
      local name = GetUnitName("reticleover")

      local guildId, memberIndex = self:GetGuildMemberIndexByName(displayName)
      local _, _, rankIndex = GetGuildMemberInfo(guildId, memberIndex)

      self.nameLabel:SetText(name)
      self.infoLabel:SetColor(.3, .8, .3)
      self.infoLabel:SetText("<"..GetGuildName(guildId)..">")
      self.icon:SetTexture(GetFinalGuildRankTextureLarge(guildId, rankIndex))

      self:FadeInControl()
    else
      self:FadeOutControl()
    end
  else
    self:FadeOutControl()
  end
end

function Addon:OnFriendAdded()
  self:BuildFriendIndex()
end

function Addon:OnFriendRemoved()
  self:BuildFriendIndex()
end

function Addon:OnGroupMemberJoined()
  self:BuildGroupMemberIndex()
end

function Addon:OnGroupMemberLeft()
  self:BuildGroupMemberIndex()
end

function Addon:OnGroupTypeChanged()
  self:BuildGroupMemberIndex()
end

function Addon:OnGroupUpdate()
  self:BuildGroupMemberIndex()
end

function Addon:OnGuildMemberAdded()
  self:BuildGuildMemberIndex()
end

function Addon:OnGuildMemberRemoved()
  self:BuildGuildMemberIndex()
end

function Addon:OnSelfJoinedGuild()
  self:BuildGuildMemberIndex()
end

function Addon:OnSelfLeftGuild()
  self:BuildGuildMemberIndex()
end

function Addon:OnAddOnLoaded(name)
  if (name ~= self.name) then return end

  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

  self:SetupControls()
  self:RegisterForEvents()
end

do
  local function OnAddOnLoaded(event, ...)
    Addon:OnAddOnLoaded(...)
  end

  local function OnPlayerActivated(event, ...)
    Addon:OnPlayerActivated(...)
  end

  local function OnTargetChanged(event, ...)
    Addon:OnTargetChanged(...)
  end

  local function OnFriendAdded(event, ...)
    Addon:OnFriendAdded(...)
  end

  local function OnFriendRemoved(event, ...)
    Addon:OnFriendRemoved(...)
  end

  local function OnGroupMemberJoined(event, ...)
    Addon:OnGroupMemberJoined(...)
  end

  local function OnGroupMemberLeft(event, ...)
    Addon:OnGroupMemberLeft(...)
  end

  local function OnGroupTypeChanged(event, ...)
    Addon:OnGroupTypeChanged(...)
  end

  local function OnGroupUpdate(event, ...)
    Addon:OnGroupUpdate(...)
  end

  local function OnGuildMemberAdded(event, ...)
    Addon:OnGuildMemberAdded(...)
  end

  local function OnGuildMemberRemoved(event, ...)
    Addon:OnGuildMemberRemoved(...)
  end

  local function OnSelfJoinedGuild(event, ...)
    Addon:OnSelfJoinedGuild(...)
  end

  local function OnSelfLeftGuild(event, ...)
    Addon:OnSelfLeftGuild(...)
  end

  function Addon:Load()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
  end

  function Addon:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_RETICLE_TARGET_CHANGED, OnTargetChanged)

    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_FRIEND_ADDED, OnFriendAdded)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_FRIEND_REMOVED, OnFriendRemoved)

    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    -- EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GROUP_TYPE_CHANGED, OnGroupTypeChanged)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GROUP_UPDATE, OnGroupUpdate)

    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GUILD_MEMBER_ADDED, OnGuildMemberAdded)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GUILD_MEMBER_REMOVED, OnGuildMemberRemoved)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GUILD_SELF_JOINED_GUILD, OnSelfJoinedGuild)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GUILD_SELF_LEFT_GUILD, OnSelfLeftGuild)
  end
end

Addon:Load()

﻿--[[
  ****************************************************************
  EavesDrop

  Author: Grayhoof. Original idea by Bant. Coding help/samples
          from Andalia`s SideCombatLog and CombatChat.

  Notes: Code comments coming at a later time.
  ****************************************************************]] --
EavesDrop = LibStub("AceAddon-3.0"):NewAddon("EavesDrop", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")
local EavesDrop = EavesDrop
local db

local L = LibStub("AceLocale-3.0"):GetLocale("EavesDrop", true)
local media = LibStub("LibSharedMedia-3.0")

local OUTGOING = 1
local INCOMING = -1
local MISC = 3

local critchar = "*"
local deathchar = "†"
local crushchar = "^"
local glancechar = "~"
local newhigh = "|cffffff00!|r"

local arrEventData = {}
local arrEventFrames = {}
local frameSize = 21
local arrSize = 10
local arrDisplaySize = 20
local arrMaxSize = 128
local scroll = 0
local allShown = false
local totDamageIn = 0
local totDamageOut = 0
local totHealingIn = 0
local totHealingOut = 0
local timeStart = 0
local curTime = 0
local lastTime = 0

-- LUA calls
local _G = _G
local tonumber = tonumber
local strsub = strsub
local string_format = string.format
local string_match = string.match
local gsub = gsub
local tremove = tremove
local tinsert = tinsert
local function string_nil(val)
  if val then
    return val
  else
    return UNKNOWN
  end
end

-- API calls
local UnitName = UnitName
local UnitXP = UnitXP
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown

-- Combat log locals
local pxp = UnitXP("player")
local skillmsg = gsub(gsub(gsub(SKILL_RANK_UP, '%d%$', ''), '%%s', '(.+)'), '%%d', '(%%d+)')
local CombatLog_Object_IsA = CombatLog_Object_IsA
local Blizzard_CombatLog_CurrentSettings

local COMBATLOG_OBJECT_NONE = COMBATLOG_OBJECT_NONE
local COMBATLOG_FILTER_MINE = COMBATLOG_FILTER_MINE
local COMBATLOG_FILTER_MY_PET = COMBATLOG_FILTER_MY_PET
local COMBATLOG_FILTER_HOSTILE = bit.bor(COMBATLOG_FILTER_HOSTILE_PLAYERS, COMBATLOG_FILTER_HOSTILE_UNITS)

local COMBAT_EVENTS = {
  ["SWING_DAMAGE"] = "DAMAGE",
  ["RANGE_DAMAGE"] = "DAMAGE",
  ["SPELL_DAMAGE"] = "DAMAGE",
  ["SPELL_PERIODIC_DAMAGE"] = "DAMAGE",
  ["ENVIRONMENTAL_DAMAGE"] = "DAMAGE",
  ["DAMAGE_SHIELD"] = "DAMAGE",
  ["DAMAGE_SPLIT"] = "DAMAGE",
  ["SPELL_HEAL"] = "HEAL",
  ["SPELL_PERIODIC_HEAL"] = "HEAL",
  ["SWING_MISSED"] = "MISS",
  ["RANGE_MISSED"] = "MISS",
  ["SPELL_MISSED"] = "MISS",
  ["SPELL_PERIODIC_MISSED"] = "MISS",
  ["DAMAGE_SHIELD_MISSED"] = "MISS",
  ["SPELL_DRAIN"] = "DRAIN",
  ["SPELL_LEECH"] = "DRAIN",
  ["SPELL_PERIODIC_DRAIN"] = "DRAIN",
  ["SPELL_PERIODIC_LEECH"] = "DRAIN",
  ["SPELL_ENERGIZE"] = "POWER",
  ["SPELL_PERIODIC_ENERGIZE"] = "POWER",
  ["PARTY_KILL"] = "DEATH",
  ["UNIT_DIED"] = "DEATH",
  ["UNIT_DESTROYED"] = "DEATH"
}

-- LoadAddOn("Blizzard_DebugTools")
local SCHOOL_STRINGS = {}
for index, value in ipairs(_G["SCHOOL_STRINGS"]) do SCHOOL_STRINGS[bit.lshift(1, index - 1)] = value end
local SCHOOL_MASK_PHYSICAL = 1
-- DevTools_Dump(SCHOOL_STRINGS)
--[[ local SCHOOL_STRINGS = {
  [SCHOOL_MASK_PHYSICAL] = SPELL_SCHOOL0_CAP,
  [SCHOOL_MASK_HOLY] = SPELL_SCHOOL1_CAP,
  [SCHOOL_MASK_FIRE] = SPELL_SCHOOL2_CAP,
  [SCHOOL_MASK_NATURE] = SPELL_SCHOOL3_CAP,
  [SCHOOL_MASK_FROST] = SPELL_SCHOOL4_CAP,
  [SCHOOL_MASK_SHADOW] = SPELL_SCHOOL5_CAP,
  [SCHOOL_MASK_ARCANE] = SPELL_SCHOOL6_CAP,
} ]]

local POWER_STRINGS = {
  [Enum.PowerType.Mana] = MANA,
  [Enum.PowerType.Rage] = RAGE,
  [Enum.PowerType.Focus] = FOCUS,
  [Enum.PowerType.Energy] = ENERGY,
  [Enum.PowerType.ComboPoints] = COMBO_POINTS,
  [Enum.PowerType.Runes] = RUNES,
  [Enum.PowerType.RunicPower] = RUNIC_POWER,
  [Enum.PowerType.SoulShards] = SHARDS,
  [Enum.PowerType.LunarPower] = LUNAR_POWER,
  [Enum.PowerType.HolyPower] = HOLY_POWER,
  [Enum.PowerType.Alternate] = ALTERNATE_RESOURCE_TEXT,
  [Enum.PowerType.Maelstrom] = MAELSTROM_POWER,
  [Enum.PowerType.Chi] = CHI_POWER,
  [Enum.PowerType.Insanity] = INSANITY_POWER,
  -- [Enum.PowerType.Obsolete] = 14;
  -- [Enum.PowerType.Obsolete2] = 15;
  [Enum.PowerType.ArcaneCharges] = ARCANE_CHARGES_POWER,
  [Enum.PowerType.Fury] = FURY,
  [Enum.PowerType.Pain] = PAIN
}

-- set table default size sense table.insert no longer does
for i = 1, arrMaxSize do arrEventData[i] = {} end

--- Returns the core school type of a multi-school type `a`.
---
--- If `a` is one of the core schools, return value will be the same as `a`
---
--- Example: Chaos school type consists of types Arcane, Shadow, Nature and Holy.
--- Since its bitmask is 106 (01101010), then its core school is (01000000) which
--- is the same as Arcane. Thus getSpellSchoolCoreType(106) will return 64.
---@param a number
---@return number
local function getSpellSchoolCoreType(a)
  local count = 0
  while true do
    a = bit.rshift(a, 1)
    if a == 0 then break end
    count = count + 1
  end
  local stype = bit.lshift(1, count)
  return stype
end

local function convertRGBtoHEXString(color, text)
  return string_format("|cFF%02x%02x%02x%s|r", ceil(color.r * 255), ceil(color.g * 255), ceil(color.b * 255), text)
end

local function shortenValue(value)
  if value >= 10000000 then
    value = string_format("%.1fm", value / 1000000)
  elseif value >= 1000000 then
    value = string_format("%.2fm", value / 1000000)
  elseif value >= 100000 then
    value = string_format("%.0fk", value / 1000)
  elseif value >= 10000 then
    value = string_format("%.1fk", value / 1000)
  end
  return value
end

local function round(num, idp) return tonumber(string_format("%." .. (idp or 0) .. "f", num)) end

local function cleanstring(s)
  s = gsub(s, "|r", "")
  s = gsub(s, "|c........", "")
  s = gsub(s, "|Hunit:..................:([%w%s*%-*]*)|h", "")
  s = gsub(s, "|Haction:([%w_*]*)|h", "")
  s = gsub(s, "|Hitem:(%d+)|h", "")
  s = gsub(s, "|Hicon:%d+:dest|h", "")
  s = gsub(s, "|Hicon:%d+:source|h", "")
  s = gsub(s, "|Hspell:%d+:([%w_*]*)|h", "")
  s = gsub(s, "|TInterface.TargetingFrame.UI.RaidTargetingIcon.%d.blp:0|t", "")
  s = gsub(s, "|h", "")
  s = gsub(s, "\n", ", ")
  s = gsub(s, "\124", "\124\124")
  return s
end

local function clearSummary()
  totDamageIn = 0
  totDamageOut = 0
  totHealingIn = 0
  totHealingOut = 0
end

-- Main Functions
function EavesDrop:OnInitialize()

  -- setup table for display frame objects
  for i = 1, arrDisplaySize do
    arrEventFrames[i] = {}
    arrEventFrames[i].frame = _G[string_format("EavesDropEvent%d", i)]
    arrEventFrames[i].text = _G[string_format("EavesDropEvent%dEventText", i)]
    arrEventFrames[i].intexture = _G[string_format("EavesDropEvent%dIncomingTexture", i)]
    arrEventFrames[i].intextureframe = _G[string_format("EavesDropEvent%dIncoming", i)]
    arrEventFrames[i].outtexture = _G[string_format("EavesDropEvent%dOutgoingTexture", i)]
    arrEventFrames[i].outtextureframe = _G[string_format("EavesDropEvent%dOutgoing", i)]
  end

  self.db = LibStub("AceDB-3.0"):New("EavesDropDB", self:GetDefaultConfig())
  self.chardb = LibStub("AceDB-3.0"):New("EavesDropStatsDB", { profile = { [OUTGOING] = {}, [INCOMING] = {} } })

  self:SetupOptions()

  -- callbacks for profile changes
  self.db.RegisterCallback(self, "OnProfileChanged", "UpdateFrame")
  self.db.RegisterCallback(self, "OnProfileCopied", "UpdateFrame")
  self.db.RegisterCallback(self, "OnProfileReset", "UpdateFrame")

  -- local the profile table
  db = self.db.profile

  self:PerformDisplayOptions()

  self:RegisterEvent("ADDON_LOADED", self.SetFonts)
end

function EavesDrop:OnEnable()
  self:RegisterEvent("PLAYER_DEAD")
  self:UpdateExpEvents()
  self:UpdateRepHonorEvents()
  self:UpdateCombatEvents()
  self:UpdateBuffEvents()
  self:UpdateBuffFadeEvents()
  self:UpdateSkillEvents()

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CombatEvent")

  -- show frame
  EavesDropFrame:Show()
  if (db["FADEFRAME"]) then self:HideFrame() end

end

function EavesDrop:OnDisable()
  self:UnregisterAllEvents()
  EavesDropFrame:Hide()
end

function EavesDrop:UpdateCombatEvents()
  if (db["COMBAT"] == true) then
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  end
end

function EavesDrop:UpdateExpEvents()
  if (db["EXP"] == true) then
    self:RegisterEvent("PLAYER_XP_UPDATE")
  else
    self:UnregisterEvent("PLAYER_XP_UPDATE")
  end
end

function EavesDrop:UpdateRepHonorEvents()
  if (db["REP"] or db["HONOR"]) then
    self:RegisterEvent("COMBAT_TEXT_UPDATE")
  else
    self:UnregisterEvent("COMBAT_TEXT_UPDATE")
  end
end

function EavesDrop:UpdateBuffEvents()
  if (db["DEBUFF"] == true or db["BUFF"] == true) then
    COMBAT_EVENTS["SPELL_AURA_APPLIED"] = "BUFF"
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_APPLIED"] = "BUFF"
    COMBAT_EVENTS["SPELL_AURA_APPLIED_DOSE"] = "BUFF"
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_APPLIED_DOSE"] = "BUFF"
    COMBAT_EVENTS["ENCHANT_APPLIED"] = "ENCHANT_APPLIED"
  else
    COMBAT_EVENTS["SPELL_AURA_APPLIED"] = nil
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_APPLIED"] = nil
    COMBAT_EVENTS["SPELL_AURA_APPLIED_DOSE"] = nil
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_APPLIED_DOSE"] = nil
    COMBAT_EVENTS["ENCHANT_APPLIED"] = nil
  end
end

function EavesDrop:UpdateBuffFadeEvents()
  if (db["DEBUFFFADE"] == true or db["BUFFFADE"] == true) then
    COMBAT_EVENTS["SPELL_AURA_REMOVED"] = "FADE"
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_REMOVED"] = "FADE"
    COMBAT_EVENTS["SPELL_AURA_REMOVED_DOSE"] = "FADE"
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_REMOVED_DOSE"] = "FADE"
    COMBAT_EVENTS["ENCHANT_REMOVED"] = "ENCHANT_REMOVED"
  else
    COMBAT_EVENTS["SPELL_AURA_REMOVED"] = nil
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_REMOVED"] = nil
    COMBAT_EVENTS["SPELL_AURA_REMOVED_DOSE"] = nil
    COMBAT_EVENTS["SPELL_PERIODIC_AURA_REMOVED_DOSE"] = nil
    COMBAT_EVENTS["ENCHANT_REMOVED"] = nil
  end
end

function EavesDrop:UpdateSkillEvents()
  if (db["SKILL"] == true) then
    self:RegisterEvent("CHAT_MSG_SKILL")
  else
    self:UnregisterEvent("CHAT_MSG_SKILL")
  end
end

----------------------
-- Reset everything to default
function EavesDrop:UpdateFrame()
  -- local the profile table
  db = self.db.profile
  self:UpdateExpEvents()
  self:UpdateRepHonorEvents()
  self:UpdateCombatEvents()
  self:UpdateBuffEvents()
  self:UpdateBuffFadeEvents()
  self:UpdateSkillEvents()
  self:PerformDisplayOptions()
  self:UpdateEvents()
end

function EavesDrop:PerformDisplayOptions()
  -- set size
  arrSize = db["NUMLINES"]
  frameSize = db["LINEHEIGHT"] + 1
  local totalh = (frameSize * arrSize) + 50
  local totalw = (db["LINEHEIGHT"] * 2) + db["LINEWIDTH"]
  EavesDropFrame:SetHeight(totalh)
  EavesDropFrame:SetWidth(totalw)
  -- update look of frame
  local r, g, b, a = db["FRAME"].r, db["FRAME"].g, db["FRAME"].b, db["FRAME"].a
  -- main frame
  EavesDropFrame:SetBackdropColor(r, g, b, a)
  EavesDropTopBar:SetGradientAlpha("VERTICAL", r * .1, g * .1, b * .1, 0, r * .2, g * .2, b * .2, a)
  EavesDropBottomBar:SetGradientAlpha("VERTICAL", r * .2, g * .2, b * .2, a, r * .1, g * .1, b * .1, 0)
  EavesDropTopBar:SetWidth(totalw - 10)
  EavesDropBottomBar:SetWidth(totalw - 10)
  r, g, b, a = db["BORDER"].r, db["BORDER"].g, db["BORDER"].b, db["BORDER"].a
  EavesDropFrame:SetBackdropBorderColor(r, g, b, a)
  EavesDropFrame:EnableMouse(not db["LOCKED"])
  -- tooltips
  EavesDropTab.tooltipText = L["TabTip"]
  if (db["SCROLLBUTTON"]) then
    EavesDropFrameDownButton:Hide()
    EavesDropFrameUpButton:Hide()
  else
    EavesDropFrameDownButton.tooltipText = L["DownTip"]
    EavesDropFrameUpButton.tooltipText = L["UpTip"]
    self:UpdateScrollButtons()
  end
  self.ToolTipAnchor = "ANCHOR_" .. strupper(db["TOOLTIPSANCHOR"])
  -- labels
  r, g, b, a = db["LABELC"].r, db["LABELC"].g, db["LABELC"].b, db["LABELC"].a
  if (db["FLIP"] == true) then
    EavesDropFramePlayerText:SetText(L["TargetLabel"])
    EavesDropFrameTargetText:SetText(L["PlayerLabel"])
  else
    EavesDropFramePlayerText:SetText(L["PlayerLabel"])
    EavesDropFrameTargetText:SetText(L["TargetLabel"])
  end
  EavesDropFramePlayerText:SetTextColor(r, g, b, a)
  EavesDropFrameTargetText:SetTextColor(r, g, b, a)
  -- fonts
  self:SetFonts()
  -- tab
  if (db["HIDETAB"] == true) then
    EavesDropTab:Hide()
  else
    EavesDropTab:Show()
  end
  -- position frame (have to schedule cause UI scale is still 1 for some reason during init)
  self:ScheduleTimer("PlaceFrame", .1, self)

  self:ResetEvents()
  self:SetupHistory()

  if (db["FADEFRAME"]) then
    self:HideFrame()
  else
    self:ShowFrame()
  end
end

function EavesDrop:SetFonts()
  EavesDropFontNormal:SetFont(media:Fetch("font", db["FONT"]), db["TEXTSIZE"])
  EavesDropFontNormalSmall:SetFont(media:Fetch("font", db["FONT"]), db["TEXTSIZE"])
end

function EavesDrop:PlaceFrame()
  local frame, x, y = EavesDropFrame, db.x, db.y
  frame:ClearAllPoints()
  if x == 0 and y == 0 then
    frame:SetPoint("CENTER", UIParent, "CENTER")
  else
    local es = frame:GetEffectiveScale()
    frame:SetPoint("TOPLEFT", UIParent, "CENTER", x / es, y / es)
  end
end

function EavesDrop:HideFrame() EavesDropFrame:SetAlpha(0) end

function EavesDrop:ShowFrame()
  EavesDropFrame:SetAlpha(1)
  EavesDropTab:SetAlpha(0)
end

function EavesDrop:CombatEvent(larg1, ...)
  --local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags,
  local _, event, _, _, sourceName, sourceFlags, _, _, destName, destFlags, _ = CombatLogGetCurrentEventInfo()
  local etype = COMBAT_EVENTS[event]
  if not etype then return end

  if not Blizzard_CombatLog_CurrentSettings then
    Blizzard_CombatLog_CurrentSettings = Blizzard_CombatLog_Filters.filters[Blizzard_CombatLog_Filters.currentFilter]
  end

  -- check for reflect damage
  if event == "SPELL_DAMAGE" and sourceName == destName and CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_HOSTILE) then
    self:ParseReflect(CombatLogGetCurrentEventInfo())
    return
  end

  local toPlayer, fromPlayer, toPet, fromPet
  if (sourceName and not CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_NONE)) then
    fromPlayer = CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_MINE)
    fromPet = CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_MY_PET)
  end
  if (destName and not CombatLog_Object_IsA(destFlags, COMBATLOG_OBJECT_NONE)) then
    toPlayer = CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_MINE)
    toPet = CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_MY_PET)
  end

  if not fromPlayer and not toPlayer and not fromPet and not toPet then return end
  if (not fromPlayer and not toPlayer) and (toPet or fromPet) and not db["PET"] then return end

  local amount, school, resisted, blocked, absorbed, critical, glancing, crushing
  local spellId, spellName, spellSchool, missType, powerType, extraAmount, overHeal
  local text, texture, message, inout, color, auraType

  -- defaults
  if toPet or fromPet then texture = "pet" end
  if toPlayer or toPet then inout = INCOMING end
  if fromPlayer or fromPet then inout = OUTGOING end
  if toPet then color = db["PETI"] end
  if fromPet then color = db["PETO"] end

  -- get combat log message (for tooltip)
  message = CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, CombatLogGetCurrentEventInfo())

  ------------damage----------------
  if etype == "DAMAGE" then
    local intype, outtype
    if event == "SWING_DAMAGE" then
      amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing = select(12,
                                                                                                     CombatLogGetCurrentEventInfo())
      if school == SCHOOL_MASK_PHYSICAL then
        outtype, intype = "TMELEE", "PHIT"
      else
        outtype, intype = "TSPELL", "PSPELL"
      end
    elseif event == "RANGE_DAMAGE" then
      _, spellName, _, amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing =
          select(12, CombatLogGetCurrentEventInfo())
      if school == SCHOOL_MASK_PHYSICAL then
        outtype, intype = "TMELEE", "PHIT"
      else
        outtype, intype = "TSPELL", "PSPELL"
      end
    elseif event == "ENVIRONMENTAL_DAMAGE" then
      _, amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing = select(
                                                                                                                     12,
                                                                                                                     CombatLogGetCurrentEventInfo())
      outtype, intype = "TSPELL", "PSPELL"
    else
      spellId, spellName, _, amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing =
          select(12, CombatLogGetCurrentEventInfo())
      texture = select(3, GetSpellInfo(spellId))
      outtype, intype = "TSPELL", "PSPELL"
    end
    text = tostring(shortenValue(amount))

    if (critical) then text = critchar .. text .. critchar end
    if (crushing) then text = crushchar .. text .. crushchar end
    if (glancing) then text = glancechar .. text .. glancechar end
    if (resisted) then text = string_format("%s (%d)", text, shortenValue(resisted)) end
    if (blocked) then text = string_format("%s (%d)", text, shortenValue(blocked)) end
    if (absorbed) then text = string_format("%s (%d)", text, shortenValue(absorbed)) end

    local school_new = getSpellSchoolCoreType(school or 1)
    --[[     if school_new ~= school then
      print("converted", school, school_new)
    end ]]
    school = school_new

    --[[     print("school", school)
    print("fromPlayer", fromPlayer)
    print("toPlayer", toPlayer)
    print(amount)
    DevTools_Dump(db[outtype])
    DevTools_Dump(SCHOOL_STRINGS[school])
    print(sourceGUID, sourceName, sourceFlags, sourceFlags2)
    print("-------------------")
    if fromPet then
      print("from pet", school, db[outtype])
      color = self:SpellColor(db[outtype], SCHOOL_STRINGS[school])
    end
    print("from pet:", fromPet, "outtype:", outtype)
    DevTools_Dump(db[outtype]) ]]

    local icon
    if fromPlayer or fromPet then
      local fake = nil
      icon = texture
      if fromPet then texture = fake end
      if (self:TrackStat(inout, "hit", spellName, texture, SCHOOL_STRINGS[school], amount, critical, message)) then
        text = newhigh .. text .. newhigh
      end
      if fromPet then outtype = "PETI" end
      color = self:SpellColor(db[outtype], SCHOOL_STRINGS[school])
      if not toPlayer then -- Don't count self damag in total
        totDamageOut = totDamageOut + amount
      else
        inout = -inout -- Show self damag under player column
      end
    elseif toPlayer or toPet then
      local fake = nil
      icon = texture
      if toPet then texture = fake end
      if (self:TrackStat(inout, "hit", spellName, texture, SCHOOL_STRINGS[school], amount, critical, message)) then
        text = newhigh .. text .. newhigh
      end
      if toPet then intype = "PETO" end
      color = self:SpellColor(db[intype], SCHOOL_STRINGS[school])
      text = "-" .. text
      totDamageIn = totDamageIn + amount
    elseif toPet then
      text = "-" .. text
    end
    self:DisplayEvent(inout, text, icon, color, message, spellName)
    ------------buff/debuff gain----------------
  elseif etype == "BUFF" then
    spellId, spellName, _, auraType, _ = select(12, CombatLogGetCurrentEventInfo())
    texture = select(3, GetSpellInfo(spellId))
    if toPlayer and db[auraType] then
      self:DisplayEvent(INCOMING, self:ShortenString(spellName) .. " " .. L["Gained"], texture, db["P" .. auraType],
                        message, spellName)
    else
      return
    end
    ------------buff/debuff lose----------------
  elseif etype == "FADE" then
    spellId, spellName, _, auraType, _ = select(12, CombatLogGetCurrentEventInfo())
    texture = select(3, GetSpellInfo(spellId))
    if toPlayer and db[auraType .. "FADE"] then
      self:DisplayEvent(INCOMING, self:ShortenString(spellName) .. " " .. L["Fades"], texture, db["P" .. auraType],
                        message, spellName)
    else
      return
    end
    ------------heals----------------
  elseif etype == "HEAL" then
    spellId, spellName, spellSchool, amount, overHeal, _, critical = select(12, CombatLogGetCurrentEventInfo())
    text = tostring(shortenValue(amount))
    texture = select(3, GetSpellInfo(spellId))

    if toPlayer or toPet then
      totHealingIn = totHealingIn + amount
      if (amount < db["HFILTER"]) then return end
      if (db["OVERHEAL"]) and overHeal > 0 then
        text = string_format("%d {%d}", shortenValue(amount - overHeal), shortenValue(overHeal))
      end
      if (critical) then text = critchar .. text .. critchar end
      if (db["HEALERID"] == true and not fromPlayer and not fromPet) then
        text = text .. " (" .. (sourceName or "Unknown") .. ")"
      end
      color = db["PHEAL"]
      if (self:TrackStat(inout, "heal", spellName, texture, SCHOOL_STRINGS[spellSchool], amount, critical, message)) then
        text = newhigh .. text .. newhigh
      end
      if fromPlayer and not toPet then -- Show self healing under player column & with correct color.
        color = db["THEAL"]
        inout = -inout
      end
      text = "+" .. text
    elseif fromPlayer or fromPet then
      totHealingOut = totHealingOut + amount
      if (amount < db["HFILTER"]) then return end
      if (db["OVERHEAL"]) and overHeal > 0 then
        text = string_format("%d {%d}", shortenValue(amount - overHeal), shortenValue(overHeal))
      end
      if (critical) then text = critchar .. text .. critchar end
      color = db["THEAL"]
      if (self:TrackStat(inout, "heal", spellName, texture, SCHOOL_STRINGS[spellSchool], amount, critical, message)) then
        text = newhigh .. text .. newhigh
      end
      text = "+" .. text
      if (db["HEALERID"] == true) then text = (destName or "Unknown") .. ": " .. text end
    end
    self:DisplayEvent(inout, text, texture, color, message, spellName)
    ------------misses----------------
  elseif etype == "MISS" then
    local tcolor
    if event == "SWING_MISSED" or event == "RANGE_MISSED" then
      missType = select(12, CombatLogGetCurrentEventInfo())
      tcolor = "TMELEE"
    else
      spellId, spellName, _, missType = select(12, CombatLogGetCurrentEventInfo())
      texture = select(3, GetSpellInfo(spellId))
      tcolor = "TSPELL"
    end
    text = _G[missType]
    if toPet then
      inout = INCOMING
      color = db["PETO"]
    elseif fromPet then
      inout = OUTGOING
      color = db["PETI"]
    elseif fromPlayer then
      color = db[tcolor]
    elseif toPlayer then
      if missType == "REFLECT" then self:SetReflect(sourceName, spellName) end
      color = db["PMISS"]
    end
    self:DisplayEvent(inout, text, texture, color, message, spellName)
    ------------leech and drains----------------
  elseif etype == "DRAIN" then
    if (db["GAINS"]) then
      spellId, spellName, _, amount, powerType, extraAmount = select(12, CombatLogGetCurrentEventInfo())
      texture = select(3, GetSpellInfo(spellId))
      if toPlayer then
        text = string_format("-%d %s", amount, string_nil(POWER_STRINGS[powerType]))
        color = db["PGAIN"]
      elseif fromPlayer and extraAmount then
        if (extraAmount < db["MFILTER"]) then return end
        text = string_format("+%d %s", extraAmount, string_nil(POWER_STRINGS[powerType]))
        color = db["PGAIN"]
      elseif fromPlayer then
        return
        -- for showing your drain damage
        -- text = string_format("%d %s", amount, string_nil(POWER_STRINGS[powerType]))
        -- color = db["TSPELL"]
      end
      self:DisplayEvent(inout, text, texture, color, message, spellName)
    end
    ------------power gains----------------
  elseif etype == "POWER" then
    if (db["GAINS"]) then
      spellId, spellName, _, amount, _, powerType = select(12, CombatLogGetCurrentEventInfo())
      texture = select(3, GetSpellInfo(spellId))
      if toPlayer then
        if (amount < db["MFILTER"]) then return end
        color = db["PGAIN"]
      elseif not toPet then
        return
      end
      text = string_format("+%d %s", amount, string_nil(POWER_STRINGS[powerType]))
      self:DisplayEvent(inout, text, texture, color, message, spellName)
    end
    ------------deaths----------------
  elseif etype == "DEATH" then
    if fromPlayer then
      text = deathchar .. destName .. deathchar
      self:DisplayEvent(MISC, text, texture, db["DEATH"], message)
    else
      return
    end
    ------------enchants----------------
  elseif etype == "ENCHANT_APPLIED" then
    spellName = select(12, CombatLogGetCurrentEventInfo())
    self:DisplayEvent(INCOMING, self:ShortenString(spellName), texture, db["PBUFF"], message, spellName)
  elseif etype == "ENCHANT_REMOVED" then
    spellName = select(12, CombatLogGetCurrentEventInfo())
    self:DisplayEvent(INCOMING, self:ShortenString(spellName) .. " " .. L["Fades"], texture, db["PBUFF"], message,
                      spellName)
    -------------anything else-------------
    -- else
    -- self:Print(event, sourceName, destName)
  end
end

function EavesDrop:PLAYER_XP_UPDATE()
  local xp = UnitXP("player")
  local xpgained = xp - pxp
  self:DisplayEvent(MISC, string_format("+%d (%s)", shortenValue(xpgained), XP), nil, db["EXPC"], nil)
  pxp = xp
end

function EavesDrop:COMBAT_TEXT_UPDATE(event, larg1)
  local larg2, larg3 = GetCurrentCombatTextEventInfo() -- Thanks DTuloJr for pointing this out!
  if larg1 == "FACTION" then
    local sign = "+"
    if larg2 == nil then larg2 = 0 end
    if larg3 == nil then
      larg3 = 0
      sign = ""
    end
    if (tonumber(larg3) < 0) then sign = "" end
    self:DisplayEvent(MISC, string_format("%s%d (%s)", sign, larg3, larg2), nil, db["REPC"], nil)
  elseif larg1 == "HONOR_GAINED" then
    self:DisplayEvent(MISC, string_format("+%d (%s)", larg2, HONOR), nil, db["HONORC"], nil)
  end
end

function EavesDrop:PLAYER_REGEN_DISABLED()
  pxp = UnitXP("player")
  timeStart = GetTime()
  clearSummary()
  self:DisplayEvent(MISC, L["StartCombat"], nil, db["MISC"])
  -- stop on update, since in combat
  self:StopOnUpdate()
  -- show frame, if its hidden
  self:ShowFrame()
  -- flag all as being shown, so buttons appear
  allShown = true
end

function EavesDrop:PLAYER_REGEN_ENABLED()
  self:DisplayEvent(MISC, L["EndCombat"], nil, db["MISC"])
  if (db["SUMMARY"] == true) then
    local duration = round(GetTime() - timeStart, 1)
    local DPS = round(totDamageOut / duration, 1) or 0
    local HPS = round(totHealingOut / duration, 1) or 0
    local IDPS = round(totDamageIn / duration, 1) or 0
    local IHPS = round(totHealingIn / duration, 1) or 0
    local strSummary = convertRGBtoHEXString(db["MISC"], duration .. " " .. L["IncombatSummary"]) .. "\n" ..
                           convertRGBtoHEXString(db["PHIT"],
                                                 L["IncomingDamge"] .. ": " .. totDamageIn .. " (" .. IDPS .. ")") ..
                           "\n" ..
                           convertRGBtoHEXString(db["PHEAL"],
                                                 L["IncomingHeals"] .. ": " .. totHealingIn .. " (" .. IHPS .. ")") ..
                           "\n" ..
                           convertRGBtoHEXString(db["THEAL"],
                                                 L["OutgoingHeals"] .. ": " .. totHealingOut .. " (" .. HPS .. ")") ..
                           "\n" ..
                           convertRGBtoHEXString(db["TSPELL"],
                                                 L["OutgoingDamage"] .. ": " .. totDamageOut .. " (" .. DPS .. ")")

    self:DisplayEvent(MISC, convertRGBtoHEXString(db["PHIT"], shortenValue(totDamageIn)) .. " | " ..
                          convertRGBtoHEXString(db["PHEAL"], shortenValue(totHealingIn)) .. " | " ..
                          convertRGBtoHEXString(db["THEAL"], shortenValue(totHealingOut)) .. " | " ..
                          convertRGBtoHEXString(db["TSPELL"], shortenValue(totDamageOut)), nil, db["MISC"], strSummary)
  end
  clearSummary()
  -- since out of combat, try and start onupdate to count down frames
  self:StartOnUpdate()
end

function EavesDrop:PLAYER_DEAD() self:DisplayEvent(MISC, deathchar .. UnitName("player") .. deathchar, nil, db["DEATH"]) end

function EavesDrop:CHAT_MSG_SKILL(event, larg1)
  local skill, rank = string_match(larg1, skillmsg)
  if skill then self:DisplayEvent(MISC, string_format("%s: %d", skill, rank), nil, db["SKILLC"], larg1) end
end

local tempcolor = { r = 1, g = 1, b = 1 }
function EavesDrop:DisplayEvent(type, text, texture, color, message, spellname)
  -- remove oldest table and create new display event
  local pEvent = tremove(arrEventData, 1)
  local tooltiptext = message
  if (db["FLIP"] == true) then type = type * -1 end
  pEvent.type = type
  pEvent.text = text
  pEvent.texture = texture
  pEvent.color = color or tempcolor
  -- Messages probably already have a timestamp, so let's clear that up
  if (db["TIMESTAMP"] == true and message) then

    -- Check if we have a timestamp here and remove to use our own
    local timecutoff = string.find(message, '> ')

    -- If we did, skip those two characters "> "
    if timecutoff then message = strsub(message, timecutoff + 2) end

    pEvent.tooltipText = string_format('|cffffffff%s\n%s', date('%I:%M:%S'), message)

  elseif (db["TIMESTAMP"] == true and text) then
    pEvent.tooltipText = string_format('|cffffffff%s|r\n%s', date('%I:%M:%S'), text)

  elseif (db["TIMESTAMP"] == true) then
    pEvent.tooltipText = string_format('|cffffffff%s|r\n%s', date('%I:%M:%S'), tooltiptext or '')
  elseif spellname then
    pEvent.tooltipText = spellname
  else
    pEvent.tooltipText = tooltiptext
  end

  tinsert(arrEventData, arrMaxSize, pEvent)
  self:UpdateEvents()
end

function EavesDrop:UpdateEvents()
  local key, value
  local frame, text, intexture
  local start, finish
  local delay = db["FADETIME"] + (4 * arrSize)
  start = arrMaxSize - scroll
  finish = arrMaxSize - arrSize + 1 - scroll
  for i = start, finish, -1 do
    value = arrEventData[i]
    key = i - (arrMaxSize - arrSize) + scroll
    frame = arrEventFrames[key].frame
    text = arrEventFrames[key].text
    intexture = arrEventFrames[key].intexture
    local outtexture = arrEventFrames[key].outtexture
    if (not value.text) then
      text:SetText(nil)
      intexture:SetTexture(nil)
      outtexture:SetTexture(nil)
      frame.delay = 0
      frame.alpha = 0
      frame.tooltipText = nil
      frame:Hide()
    else
      if (value.type == INCOMING) then
        text:SetJustifyH("LEFT")
        text:SetWidth(db["LINEWIDTH"] - 20)
        text:SetPoint("LEFT", intexture, "RIGHT", 5, 0)
        intexture:SetTexCoord(.1, .9, .1, .9)
        outtexture:SetTexture(nil)
        if value.texture == "pet" then
          SetPortraitTexture(intexture, value.texture)
        else
          intexture:SetTexture(value.texture)
        end
      elseif (value.type == OUTGOING) then
        text:SetJustifyH("RIGHT")
        text:SetWidth(db["LINEWIDTH"] - 20)
        text:SetPoint("LEFT", intexture, "RIGHT", 5, 0)
        intexture:SetTexture(nil)
        outtexture:SetTexCoord(.1, .9, .1, .9)
        if value.texture == "pet" then
          SetPortraitTexture(outtexture, value.texture)
        else
          outtexture:SetTexture(value.texture)
        end
      else
        text:SetJustifyH("CENTER")
        text:SetWidth((db["LINEHEIGHT"] * 2) + (db["LINEWIDTH"] - 10))
        text:SetPoint("LEFT", intexture, "LEFT", 0, 0)
        intexture:SetTexture(nil)
        outtexture:SetTexture(nil)
      end
      text:SetText(value.text)
      text:SetTextColor(value.color.r, value.color.g, value.color.b)
      frame.delay = delay
      frame.alpha = 1
      if (db["TOOLTIPS"] == true) then
        frame.tooltipText = value.tooltipText
      else
        frame.tooltipText = nil
      end
      frame:Show()
      frame:SetAlpha(frame.alpha)
    end
    delay = delay - 4
    -- set clickthru
    if (frame.tooltipText) then
      frame:EnableMouse(true)
    else
      frame:EnableMouse(false)
    end
  end
  -- Update scrolls
  self:UpdateScrollButtons()
  -- try to start up onUpdate. if in combat it won't start.
  self:StartOnUpdate()
end

function EavesDrop:StartOnUpdate()
  -- only start on update if not in combat, and not already started.
  if not InCombatLockdown() and not self.OnUpdateStarted then
    lastTime = GetTime()
    self.OnUpdateStarted = self:ScheduleRepeatingTimer("OnUpdate", .2, self)
  end
end

function EavesDrop:StopOnUpdate()
  self:CancelTimer(self.OnUpdateStarted, true)
  self.OnUpdateStarted = nil
end

function EavesDrop:ResetEvents()
  local frame, text, intexture
  for i = 1, arrDisplaySize do
    frame = arrEventFrames[i].frame
    text = arrEventFrames[i].text
    intexture = arrEventFrames[i].intextureframe
    local outtexture = arrEventFrames[i].outtextureframe
    frame.delay = 0
    frame.alpha = 0
    frame.tooltipText = nil
    frame:SetHeight(db["LINEHEIGHT"] + 1)
    frame:SetWidth((db["LINEHEIGHT"] * 2) + db["LINEWIDTH"])
    frame:Hide()
    text:SetHeight(db["LINEHEIGHT"])
    intexture:SetHeight(db["LINEHEIGHT"])
    intexture:SetWidth(db["LINEHEIGHT"])
    intexture:SetPoint("LEFT", frame, "RIGHT", 5, 0)
    outtexture:SetHeight(db["LINEHEIGHT"])
    outtexture:SetWidth(db["LINEHEIGHT"])
  end
end

function EavesDrop:OnUpdate()
  local frame
  local count = 0
  curTime = GetTime()
  local elapsed = curTime - lastTime
  lastTime = curTime
  for i = 1, arrSize do
    frame = arrEventFrames[i].frame
    if (frame:IsShown()) then
      count = count + 1
      frame.delay = frame.delay - elapsed
      if frame.delay <= 0 then
        frame.alpha = frame.alpha - .2
        frame:SetAlpha(frame.alpha)
      end
      if (frame.alpha <= 0) then
        frame:Hide()
        EavesDropFrameUpButton:Hide()
        count = count - 1
      end
    end
  end
  if (count == arrSize) then
    allShown = true
  else
    allShown = false
  end
  -- if none are active, stop onUpdate
  if (count == 0) then self:StopOnUpdate() end
  -- hide frame when none active
  if (db["FADEFRAME"]) then
    if ((count == 0) and (scroll == 0)) then
      self:HideFrame()
    else
      self:ShowFrame()
    end
  end
end

function EavesDrop:Scroll(this, dir)
  -- local self = EavesDrop
  if dir > 0 then
    if IsShiftKeyDown() then
      self:ScrollToTop()
    elseif IsControlKeyDown() then
      self:FindCombatUp()
    else
      self:ScrollUp()
    end
  elseif dir < 0 then
    if IsShiftKeyDown() then
      self:ScrollToBottom()
    elseif IsControlKeyDown() then
      self:FindCombatDown()
    else
      self:ScrollDown()
    end
  end
end

function EavesDrop:FindCombatUp()
  for i = arrMaxSize - scroll - arrSize, 1, -1 do
    if arrEventData[i].text and arrEventData[i].text == L["StartCombat"] then
      scroll = arrMaxSize - i - arrSize + 1
      self:UpdateScrollButtons()
      self:UpdateEvents()
      return
    end
  end
end

function EavesDrop:FindCombatDown()
  for i = arrMaxSize - scroll + 1, arrMaxSize do
    if arrEventData[i].text and arrEventData[i].text == L["EndCombat"] then
      scroll = arrMaxSize - i
      self:UpdateScrollButtons()
      self:UpdateEvents()
      return
    end
  end
end

function EavesDrop:ScrollToTop()
  scroll = arrMaxSize - arrSize
  self:UpdateScrollButtons()
  self:UpdateEvents()
end

function EavesDrop:ScrollToBottom()
  scroll = 0
  self:UpdateScrollButtons()
  self:UpdateEvents()
end

function EavesDrop:ScrollUp()
  scroll = scroll + 1
  if (scroll > (arrMaxSize - arrSize)) then scroll = arrMaxSize - arrSize end
  self:UpdateScrollButtons()
  self:UpdateEvents()
end

function EavesDrop:ScrollDown()
  scroll = scroll - 1
  if (scroll < 0) then scroll = 0 end
  self:UpdateScrollButtons()
  self:UpdateEvents()
end

function EavesDrop:UpdateScrollButtons()
  if (not db["SCROLLBUTTON"]) then

    if (scroll > 0) then
      EavesDropFrameDownButton:Show()
      if (scroll == arrMaxSize - arrSize) then
        EavesDropFrameUpButton:Hide()
      else
        EavesDropFrameUpButton:Show()
      end
    else
      EavesDropFrameDownButton:Hide()
      if (not allShown) then
        EavesDropFrameUpButton:Hide()
      else
        EavesDropFrameUpButton:Show()
      end
    end
  end
end

function EavesDrop:SpellColor(option, type)
  if (db["SPELLCOLOR"] == true) then
    return db[type] or option
  else
    return option
  end
end

-------------------------
-- Set last reflection
function EavesDrop:ParseReflect(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2,
                                destGUID, destName, destFlags, destFlags2, ...)
  local spellId, spellName, _, amount, school, _, _, _, critical, _, _ = select(1, ...)
  local texture = select(3, GetSpellInfo(spellId))
  local text
  local messsage = CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, timestamp, event, hideCaster, sourceGUID,
                                     sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2,
                                     ...)

  -- reflected events
  if (self.ReflectTarget == sourceName and sourceName == destName and self.ReflectSkill == spellName) then
    text = string_format("%s: %d", REFLECT, shortenValue(amount))
    if (critical) then text = critchar .. text .. critchar end
    self:DisplayEvent(OUTGOING, text, texture, self:SpellColor(db["TSPELL"], SCHOOL_STRINGS[school]), messsage,
                      spellName)
    self:ClearReflect()
  end
end

-------------------------
-- Set last reflection
function EavesDrop:SetReflect(target, skill)
  self.ReflectTarget = target
  self.ReflectSkill = skill
  -- clear reflection after 3 seconds.
  self:ScheduleTimer(self.ClearReflect, 3, self)
end

-------------------------
-- Clear last reflection
function EavesDrop:ClearReflect()
  self.ReflectTarget = nil
  self.ReflectSkill = nil
end

------------------------------
---Shorten a spell/buff
function EavesDrop:ShortenString(strString)
  if (db["TRUNCATETYPE"] ~= "0") and strlen(strString) > db["TRUNCATESIZE"] then
    if (db["TRUNCATETYPE"] == "1") then
      return strsub(strString, 1, db["TRUNCATESIZE"]) .. "..."
    elseif (db["TRUNCATETYPE"] == "2") then
      return gsub(gsub(gsub(strString, " of ", "O"), "%s", ""), "(%u)%l*", "%1")
    end
  else
    return strString
  end
end

------------------------------
---Send Text to the editbox
function EavesDrop:SendToChat(text)
  local tmptext = cleanstring(text)
  if tmptext == "" then return end
  local edit_box = _G.ChatEdit_ChooseBoxForSend()
  if edit_box:IsShown() then
    edit_box:Insert(tmptext)
  else
    _G.ChatEdit_ActivateChat(edit_box)
    edit_box:Insert(tmptext)
  end
end

------------------------------
---Show/Hide history frame
function EavesDrop:ShowHistory()
  if (not EavesDropHistoryFrame:IsShown()) then
    EavesDropHistoryFrame:Show()
  else
    EavesDropHistoryFrame:Hide()
  end
  -- PlaySound("igMainMenuOptionCheckBoxOn")
  PlaySound(888)
end

--[==[ ****************************************************************
  EavesDrop

  Author: Grayhoof. Original idea by Bant. Coding help/samples
          from Andalia`s SideCombatLog and CombatChat.

  Notes: Code comments coming at a later time.
  ****************************************************************]==]
--

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

EavesDrop.BLACKLIST_DB_VERSION = "v2"

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
local GetSpellTexture = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture or GetSpellTexture
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown

EavesDrop.showPrints = true
local print = function(...)
  if EavesDrop.showPrints == false then return end
  local flag = select(1, ...)
  if type(flag) == "boolean" then
    if flag == true then
      print(select(2, ...))
    else
      return
    end
  else
    print(...)
  end
end

--- Returns true if s is either nil or an empty string
---
---@param s string
---@return boolean
local function isEmptyString(s) --luacheck: ignore
  return s == nil or s == ""
end

-- Combat log locals
local maxXP = UnitXPMax("player")
local pxp = UnitXP("player")
local PLAYER_MAX_LEVEL
local PLAYER_CURRENT_LEVEL
local skillmsg = gsub(gsub(gsub(SKILL_RANK_UP, "%d%$", ""), "%%s", "(.+)"), "%%d", "(%%d+)")
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
  ["SPELL_HEAL_ABSORBED"] = "HEALABSORB",
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
  ["UNIT_DESTROYED"] = "DEATH",
  ["SPELL_INSTAKILL"] = "DEATH",
}

-- LoadAddOn("Blizzard_DebugTools")
local SCHOOL_STRINGS = {}
for index, value in ipairs(_G["SCHOOL_STRINGS"]) do
  SCHOOL_STRINGS[bit.lshift(1, index - 1)] = value
end
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
  [Enum.PowerType.Pain] = PAIN,
  [Enum.PowerType.Essence] = L["Essence"],
  [Enum.PowerType.AlternateMount] = L["Vigor"],
}

-- set table default size sense table.insert no longer does
for i = 1, arrMaxSize do
  arrEventData[i] = {}
end

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

EavesDrop.blacklist = {}
-- Checks if `spell` is in the Blacklist DB
--
-- Returns true if any of input `spell`s is blacklisted
--
---@param spell string|number
---@return boolen
local function isBlacklisted(spell, ...)
  local blacklist = EavesDrop.blacklist
  if blacklist[spell] then return true end
  local args = { ... }
  for i = 1, #args do
    if blacklist[args[i]] then return true end
  end
  return false
end

--@debug@
EavesDrop.DEBUG = false
function EavesDrop:AddToInspector(data, strName)
  local l, f = select(2, C_AddOns.IsAddOnLoaded("DevTool"))
  if l and f and self.DEBUG then DevTool:AddData(data, strName) end
end
--@end-debug@

function EavesDrop:IsClassic()
  return (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC)
    or (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
    or (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC)
    or (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC)
end
function EavesDrop:IsRetail()
  return (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE)
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
  return tostring(value)
end
EavesDrop.shortenValue = shortenValue

local function round(num, idp)
  return tonumber(string_format("%." .. (idp or 0) .. "f", num))
end

-- 05:13:54, |Hunit:Player-4384-047F64F1:Yadeek|hYadeek's|h |Hspell:45462:0:SPELL_MISSED|hPlague Strike|h was parried by |Hunit:Creature-0-4412-609-151-28611-0000468525:Scarlet Captain|hScarlet Captain|h.
local function cleanstring(s)
  s = gsub(s, "|r", "")
  s = gsub(s, "|c........", "")
  s = gsub(s, "|Hunit:([%w%s*%-*:%']*)|h", "")
  s = gsub(s, "|Haction:([%w_*]*)|h", "")
  s = gsub(s, "|Hitem:(%d+)|h", "")
  s = gsub(s, "|Hicon:%d+:dest|h", "")
  s = gsub(s, "|Hicon:%d+:source|h", "")
  s = gsub(s, "|Hspell:%d+:%d+:([%w_*]*)|h", "")
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

  if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC then
    PLAYER_MAX_LEVEL = 60
  else
    PLAYER_MAX_LEVEL = GetMaxLevelForExpansionLevel(GetExpansionLevel())
  end

  -- local tww = select(4, GetBuildInfo()) -- REMOVE this on release of TWW, it's just a hack to test the addon on Beta server
  -- if tww >= 110000 then
  --   PLAYER_MAX_LEVEL = 80
  -- elseif self.IsRetail() then
  --   PLAYER_MAX_LEVEL = 70
  -- elseif _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC then
  --   PLAYER_MAX_LEVEL = 85
  -- elseif _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC then
  --   PLAYER_MAX_LEVEL = 80
  -- elseif _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
  --   PLAYER_MAX_LEVEL = 70
  -- elseif _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC then
  --   PLAYER_MAX_LEVEL = 60
  -- end

  PLAYER_CURRENT_LEVEL = UnitLevel("player")
  maxXP = UnitXPMax("player")
  pxp = UnitXP("player")
  --@debug@
  print("OnInitialize, maxXP:", maxXP)
  print("OnInitialize, pxp:", pxp)
  --@end-debug@
  if PLAYER_CURRENT_LEVEL ~= PLAYER_MAX_LEVEL then
    --@debug@
    print("Not max level, checking XP numbers")
    --@end-debug@
    if maxXP == 0 then
      --@debug@
      print("Getting player's maxXP in 3 seconds!")
      --@end-debug@
      C_Timer.NewTimer(3, function()
        maxXP = UnitXPMax("player")
        --@debug@
        print(string_format("After 3 seconds: maxXP: %d, pxp: %d", maxXP, pxp))
        -- stylua: ignore
        --@end-debug@
        if maxXP == 0 then
          print(WrapTextInColorCode("EavesDrop", "fff48cba") .. ": Couldn't get player's MAX EXP!")
        end
      end)
    end
    if pxp == 0 then
      --@debug@
      print("Getting player's pxp in 4 seconds!")
      --@end-debug@
      C_Timer.NewTimer(4, function()
        pxp = UnitXP("player")
        --@debug@
        print(string_format("After 4 seconds: maxXP: %d, pxp: %d", maxXP, pxp))
        -- stylua: ignore
        --@end-debug@
        if pxp == 0 then
          print(WrapTextInColorCode("EavesDrop", "fff48cba") .. ": Couldn't get player's EXP!")
        end
      end)
    end
  else
    --@debug@
    print("At max level, NOT checking XP numbers")
    --@end-debug@
  end

  self:RegisterEvent("ADDON_LOADED", self.SetFonts)
  if EavesDrop.db.profile["BLACKLIST"]["version"] == EavesDrop.BLACKLIST_DB_VERSION then -- latest version
    EavesDrop.blacklist = EavesDrop.db.profile["BLACKLIST"]["spells"]
    --@debug@
    print("Loading new db")
    DevTools_Dump(EavesDrop.blacklist)
    --@end-debug@
  elseif next(EavesDrop.db.profile["BLACKLIST"]) == nil then -- empty blacklist
    EavesDrop.blacklist = {}
    EavesDrop.db.profile["BLACKLIST"] = { version = EavesDrop.BLACKLIST_DB_VERSION, spells = {} }
    --@debug@
    print("Empty blacklist. Updating format")
    DevTools_Dump(EavesDrop.db.profile.BLACKLIST)
    --@end-debug@
  elseif EavesDrop.db.profile["BLACKLIST"]["version"] == nil then -- old/first version
    EavesDrop.blacklist = EavesDrop.db.profile["BLACKLIST"]
    --@debug@
    print("Loading old db")
    DevTools_Dump(EavesDrop.blacklist)
    --@end-debug@
    C_Timer.NewTimer(5, function()
      print(
        string.format(
          "|cffF48CBAEavesDrop|r: Options file format has changed!\n"
            .. "Open EavesDrop options and refresh the blacklisted spells under |cffFFF468Misc.|r tab "
            .. "by insering a blank new line and then clicking |cffffff00Accept|r button!\n"
        )
      )
    end)
  else
    C_Timer.NewTimer(5, function()
      print(
        string.format(
          "|cffF48CBAEavesDrop|r: Saved profile DB seems to be corrupted!\nExit the game and delete EavesDrop.lua under |cffFFF468Saved Variables|r folder."
        )
      )
    end)
  end
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
  if db["FADEFRAME"] then self:HideFrame() end
end

function EavesDrop:OnDisable()
  self:UnregisterAllEvents()
  EavesDropFrame:Hide()
end

function EavesDrop:UpdateCombatEvents()
  if db["COMBAT"] == true then
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  end
end

function EavesDrop:UpdateExpEvents()
  if db["EXP"] == true then
    self:RegisterEvent("PLAYER_XP_UPDATE")
  else
    self:UnregisterEvent("PLAYER_XP_UPDATE")
  end
end

function EavesDrop:UpdateRepHonorEvents()
  if db["REP"] or db["HONOR"] then
    self:RegisterEvent("COMBAT_TEXT_UPDATE")
  else
    self:UnregisterEvent("COMBAT_TEXT_UPDATE")
  end
end

function EavesDrop:UpdateBuffEvents()
  if db["DEBUFF"] == true or db["BUFF"] == true then
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
  if db["DEBUFFFADE"] == true or db["BUFFFADE"] == true then
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
  if db["SKILL"] == true then
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
  EavesDropTopBar:SetGradient(
    "VERTICAL",
    { r = r * 0.1, g = g * 0.1, b = b * 0.1, a = 0 },
    { r = r * 0.2, g = g * 0.2, b = b * 0.2, a = a }
  )
  EavesDropBottomBar:SetGradient(
    "VERTICAL",
    { r = r * 0.2, g = g * 0.2, b = b * 0.2, a = a },
    { r = r * 0.1, g = g * 0.1, b = b * 0.1, a = 0 }
  )
  EavesDropTopBar:SetWidth(totalw - 10)
  EavesDropBottomBar:SetWidth(totalw - 10)
  r, g, b, a = db["BORDER"].r, db["BORDER"].g, db["BORDER"].b, db["BORDER"].a
  EavesDropFrame:SetBackdropBorderColor(r, g, b, a)
  EavesDropFrame:EnableMouse(not db["LOCKED"])
  -- tooltips
  EavesDropTab.tooltipText = L["TabTip"]
  if db["SCROLLBUTTON"] then
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
  if db["FLIP"] == true then
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
  if db["HIDETAB"] == true then
    EavesDropTab:Hide()
  else
    EavesDropTab:Show()
  end
  -- position frame (have to schedule cause UI scale is still 1 for some reason during init)
  self:ScheduleTimer("PlaceFrame", 0.1, self)

  self:ResetEvents()
  self:SetupHistory()

  if db["FADEFRAME"] then
    self:HideFrame()
  else
    self:ShowFrame()
  end
end

function EavesDrop:SetFonts()
  local flag = db["FONTOUTLINE"] == "None" and "" or strupper(db["FONTOUTLINE"])
  EavesDropFontNormal:SetFont(media:Fetch("font", db["FONT"]), db["TEXTSIZE"], flag)
  EavesDropFontNormalSmall:SetFont(media:Fetch("font", db["FONT"]), db["TEXTSIZE"], flag)
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

function EavesDrop:HideFrame()
  EavesDropFrame:SetAlpha(0)
end

function EavesDrop:ShowFrame()
  EavesDropFrame:SetAlpha(1)
  EavesDropTab:SetAlpha(0)
end

-- function EavesDrop:CombatEvent(larg1, ...)
function EavesDrop:CombatEvent(_, _)
  -- local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags,
  local _, event, _, _, sourceName, sourceFlags, _, _, destName, destFlags, _ = CombatLogGetCurrentEventInfo()

  -- Ensure the event is related to player and his pet
  local toPlayer, fromPlayer, toPet, fromPet
  if sourceName and not CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_NONE) then
    fromPlayer = CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_MINE)
    fromPet = CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_MY_PET)
  end
  if destName and not CombatLog_Object_IsA(destFlags, COMBATLOG_OBJECT_NONE) then
    toPlayer = CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_MINE)
    toPet = CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_MY_PET)
  end

  if not fromPlayer and not toPlayer and not fromPet and not toPet then return end
  if (not fromPlayer and not toPlayer) and (toPet or fromPet) and not db["PET"] then return end

  local etype = COMBAT_EVENTS[event]
  if not etype then return end

  if not Blizzard_CombatLog_CurrentSettings then
    Blizzard_CombatLog_CurrentSettings = Blizzard_CombatLog_Filters.filters[Blizzard_CombatLog_Filters.currentFilter]
  end

  -- check for reflect damage
  if
    event == "SPELL_DAMAGE"
    and sourceName == destName
    and CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_HOSTILE)
  then
    self:ParseReflect(CombatLogGetCurrentEventInfo())
    return
  end

  local amount, school, resisted, blocked, absorbed, critical, glancing, crushing
  local spellId, spellName, spellSchool, missType, powerType, extraAmount, overHeal
  local text, texture, message, inout, color, auraType
  local playerRelated, petRelated, whiteDMG

  -- defaults
  if toPet or fromPet then
    texture = "pet"
    petRelated = true
  end
  if toPlayer or fromPlayer then playerRelated = true end
  if toPlayer or toPet then inout = INCOMING end
  if fromPlayer or fromPet then inout = OUTGOING end
  if toPet then color = db["PETI"] end
  if fromPet then color = db["PETO"] end

  local swordTexture = "Interface\\Icons\\INV_SWORD_04"
  local bowTexture = "Interface\\Icons\\INV_WEAPON_BOW_07"

  -- get combat log message (for tooltip)
  message = CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, CombatLogGetCurrentEventInfo())

  ------------damage----------------
  if etype == "DAMAGE" then
    local intype, outtype
    if event == "SWING_DAMAGE" then
      amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing =
        select(12, CombatLogGetCurrentEventInfo())
      if school == SCHOOL_MASK_PHYSICAL then
        outtype, intype = "TMELEE", "PHIT"
      else
        outtype, intype = "TSPELL", "PSPELL"
      end
      if playerRelated then texture = swordTexture end
      whiteDMG = true
    elseif event == "RANGE_DAMAGE" then
      _, spellName, _, amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing =
        select(12, CombatLogGetCurrentEventInfo())
      if school == SCHOOL_MASK_PHYSICAL then
        outtype, intype = "TMELEE", "PHIT"
      else
        outtype, intype = "TSPELL", "PSPELL"
      end
      if toPlayer then texture = swordTexture end
      if fromPlayer then texture = bowTexture end
      whiteDMG = true
    elseif event == "ENVIRONMENTAL_DAMAGE" then
      _, amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing =
        select(12, CombatLogGetCurrentEventInfo())
      outtype, intype = "TSPELL", "PSPELL"
      whiteDMG = false
    else
      spellId, spellName, _, amount, _, school, resisted, blocked, absorbed, critical, glancing, crushing =
        select(12, CombatLogGetCurrentEventInfo())
      texture = GetSpellTexture(spellId)
      outtype, intype = "TSPELL", "PSPELL"
      whiteDMG = false
    end

    -- local a, o = false, false
    local realDamage_All, netDamage = amount

    if blocked and blocked > 0 then realDamage_All = realDamage_All + blocked end
    if resisted and resisted > 0 then realDamage_All = realDamage_All + resisted end
    if absorbed and absorbed > 0 then realDamage_All = realDamage_All + absorbed end

    netDamage = realDamage_All

    text = tostring(shortenValue(amount))

    if critical then text = critchar .. text .. critchar end
    if crushing then text = crushchar .. text .. crushchar end
    if glancing then text = glancechar .. text .. glancechar end
    if resisted then text = string_format("%s (%s)", text, shortenValue(resisted)) end
    if blocked then text = string_format("%s (%s)", text, shortenValue(blocked)) end
    if absorbed then text = string_format("%s (%s)", text, shortenValue(absorbed)) end
    -- totHealingIn = totHealingIn + absorbed
    local school_new = getSpellSchoolCoreType(school or 1)
    school = school_new

    local trackIcon = texture
    if event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" then trackIcon = swordTexture end
    if fromPlayer or fromPet then
      if fromPet then
        outtype = "PETI"
        color = self:SpellColor(db[outtype], SCHOOL_STRINGS[school])
      elseif whiteDMG then
        color = db["TMELEE"]
      else
        color = self:SpellColor(db[outtype], SCHOOL_STRINGS[school])
      end
      if not toPlayer and not toPet then -- Don't count self damage in total
        totDamageOut = totDamageOut + netDamage
      else
        inout = -inout -- Show self damage under player column
        totDamageIn = totDamageIn + netDamage
        if absorbed then totHealingOut = totHealingOut + absorbed end
      end
      if self:TrackStat(inout, "hit", spellName, trackIcon, SCHOOL_STRINGS[school], netDamage, critical, message) then
        text = newhigh .. text .. newhigh
      end
    elseif toPlayer or toPet then
      if absorbed then totHealingOut = totHealingOut + absorbed end
      if self:TrackStat(inout, "hit", spellName, trackIcon, SCHOOL_STRINGS[school], netDamage, critical, message) then
        text = newhigh .. text .. newhigh
      end
      if toPet and not whiteDMG then
        intype = "PSPELL"
        color = self:SpellColor(db[intype], SCHOOL_STRINGS[school])
      elseif whiteDMG then
        color = db["PHIT"]
      else
        color = self:SpellColor(db[intype], SCHOOL_STRINGS[school])
      end
      text = "-" .. text
      totDamageIn = totDamageIn + netDamage
    elseif toPet then
      text = "-" .. text
    end
    -- If spell is blacklisted or too small, don't show it
    if isBlacklisted(spellName, spellId) or netDamage < db["DFILTER"] then return end

    self:DisplayEvent(inout, text, texture, color, message, spellName)
    ------------buff/debuff gain----------------
  elseif etype == "BUFF" then
    spellId, spellName, _, auraType, _ = select(12, CombatLogGetCurrentEventInfo())
    -- If spell is blacklisted, don't show it
    if isBlacklisted(spellName, spellId) then return end
    texture = GetSpellTexture(spellId)
    if toPlayer and db[auraType] then
      self:DisplayEvent(
        INCOMING,
        self:ShortenString(spellName) .. " " .. L["Gained"],
        texture,
        db["P" .. auraType],
        message,
        spellName
      )
    else
      return
    end
    ------------buff/debuff lose----------------
  elseif etype == "FADE" then
    spellId, spellName, _, auraType, _ = select(12, CombatLogGetCurrentEventInfo())
    -- If spell is blacklisted, don't show it
    if isBlacklisted(spellName, spellId) then return end
    texture = GetSpellTexture(spellId)
    if toPlayer and db[auraType .. "FADE"] then
      self:DisplayEvent(
        INCOMING,
        self:ShortenString(spellName) .. " " .. L["Fades"],
        texture,
        db["P" .. auraType],
        message,
        spellName
      )
    else
      return
    end
    ------------heals----------------
  elseif etype == "HEAL" then
    local absorbed --luacheck: ignore
    spellId, spellName, spellSchool, amount, overHeal, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
    local original_overheal = overHeal
    texture = GetSpellTexture(spellId)

    local _dshow = true
    local a, o = false, false
    local realHeal_All, netHeal

    if absorbed and absorbed > 0 then
      realHeal_All = amount + absorbed
    else
      realHeal_All = amount
    end
    netHeal = realHeal_All

    if db["OVERHEAL"] and overHeal and overHeal > 0 then
      o = true
      netHeal = realHeal_All - overHeal
    end
    if db["HEALABSORB"] and absorbed and absorbed > 0 then
      a = true
      netHeal = netHeal - absorbed
    end

    -- Is this a bug in game?!!!
    if realHeal_All < 0 or netHeal < 0 then
      --@debug@
      print(_dshow, string_format("|cffff0000Found An Issue|r"))
      print(
        _dshow,
        string_format("ORIGINAL: Amount: %d, absorbed: %d, overHeal: %d", amount, absorbed, original_overheal)
      )
      print(_dshow, string_format("ADJUSTED: realHeal_All: %d, netHeal: %d", realHeal_All, netHeal))
      --@end-debug@
      -- Until we figure this out, we will just show what game reported to us.
      netHeal = amount
    end

    if a and o then
      text = string_format("%s (%s) {%s}", shortenValue(netHeal), shortenValue(absorbed), shortenValue(overHeal))
    elseif a then
      text = string_format("%s (%s)", shortenValue(netHeal), shortenValue(absorbed))
    elseif o then
      text = string_format("%s {%s}", shortenValue(netHeal), shortenValue(overHeal))
    else
      text = shortenValue(netHeal)
    end

    if critical then text = critchar .. text .. critchar end
    if toPlayer or toPet then
      if
        self:TrackStat(inout, "heal", spellName, texture, SCHOOL_STRINGS[spellSchool], realHeal_All, critical, message)
      then
        text = newhigh .. text .. newhigh
      end
      if db["HEALERID"] == true and not fromPlayer and not fromPet then
        text = text .. " (" .. (sourceName or "Unknown") .. ")"
      end
      color = db["PHEAL"]
      if fromPlayer and not toPet then -- Show self healing under player column & with correct color.
        color = db["THEAL"]
        inout = -inout
      end
      -- Add healing to total healing received (incoming) if it is from others
      if not fromPlayer and not fromPet then
        totHealingIn = totHealingIn + realHeal_All
      else -- otherwise add self healing (from player or his pet) to total healing done (outgoing)
        totHealingOut = totHealingOut + realHeal_All
      end
      text = "+" .. text
    elseif fromPlayer or fromPet then
      color = db["THEAL"]
      if
        self:TrackStat(inout, "heal", spellName, texture, SCHOOL_STRINGS[spellSchool], realHeal_All, critical, message)
      then
        text = newhigh .. text .. newhigh
      end
      text = "+" .. text
      if db["HEALERID"] == true then text = (destName or "Unknown") .. ": " .. text end
      totHealingOut = totHealingOut + realHeal_All
    end
    -- If spell is blacklisted or too small, don't show it
    if isBlacklisted(spellName, spellId) or realHeal_All < db["HFILTER"] then return end
    self:DisplayEvent(inout, text, texture, color, message, spellName)
    ------------misses----------------
  elseif etype == "MISS" then
    local tcolor
    if event == "SWING_MISSED" then
      missType, _, amount = select(12, CombatLogGetCurrentEventInfo())
      tcolor = "TMELEE"
    else
      spellId, spellName, _, missType, _, amount = select(12, CombatLogGetCurrentEventInfo())
      texture = GetSpellTexture(spellId)
      tcolor = "TSPELL"
    end
    text = _G[missType]
    if missType == "ABSORB" and amount then
      if fromPlayer or fromPet then
        totHealingIn = totHealingIn + amount
      else
        totHealingOut = totHealingOut + amount
      end
      --@debug@
      print(
        false,
        string_format(
          "Heal in |cffffff00ABSORB|r is: |cff00aa00%s|r (%d)\n  fromPlayer %s, fromPet %s, toPlayer %s, toPet: %s\n  event: %s",
          spellName or "SWING_MISSED",
          amount,
          tostring(fromPlayer),
          tostring(fromPet),
          tostring(toPlayer),
          tostring(toPet),
          event
        )
      )
      --@end-debug@
    end
    -- If spell is blacklisted, don't show it
    if isBlacklisted(spellName, spellId) then return end
    --@debug@
    if missType == "DEFLECT" or missType == "BLOCK" then
      EavesDrop:AddToInspector({ CombatLogGetCurrentEventInfo() }, "deflectCLEU")
      print(" ")
      print(
        string_format(
          "spellID: %s, spellName: |cffff1000%s|r\namount: %s event: %s",
          tostring(spellId),
          tostring(spellName),
          tostring(amount),
          tostring(event)
        )
      )
      print("-->", message)
      print(" ")
    end
    --@end-debug@

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
    if db["GAINS"] then
      spellId, spellName, _, amount, powerType, extraAmount = select(12, CombatLogGetCurrentEventInfo())
      texture = GetSpellTexture(spellId)
      --@debug@
      print(string_format("|cffff0000DRAIN!|r"))
      print(
        string_format(
          "INC: %s, OUT: %s, amount: %s, extraAmount: %s",
          tostring(inout == INCOMING),
          tostring(inout == OUTGOING),
          tostring(amount),
          tostring(extraAmount)
        )
      )
      print(string_format("powerType: %s, STRING: %s", tostring(powerType), tostring(POWER_STRINGS[powerType])))
      --@end-debug@
      if toPlayer then
        if not fromPlayer and not fromPet then
          totHealingIn = totHealingIn + amount
        else
          totHealingOut = totHealingOut + amount
        end
        text = string_format("-%d %s", amount, string_nil(POWER_STRINGS[powerType]))
        color = db["PGAIN"]
      elseif fromPlayer and extraAmount then
        if extraAmount < db["MFILTER"] then return end
        text = string_format("+%d %s", extraAmount, string_nil(POWER_STRINGS[powerType]))
        color = db["PGAIN"]
      elseif fromPlayer then
        --@debug@
        print(
          string_format("|cff00ff00DRAIN happened|r with fromPlayer! %s %s", tostring(amount), tostring(extraAmount))
        )
        print(string_format("spellId: %d, spellname: %s", spellId, spellName))
        --@end-debug@
        return
        -- for showing your drain damage
        -- text = string_format("%d %s", amount, string_nil(POWER_STRINGS[powerType]))
        -- color = db["TSPELL"]
      end
      --@debug@
      print(
        string_format(
          "Heal in |cffffff00DRAIN|r is: %s amount: %s extraAmount: %s",
          spellName,
          tostring(amount),
          tostring(extraAmount)
        )
      )
      --@end-debug@
      -- If spell is blacklisted, don't show it
      if isBlacklisted(spellName, spellId) or amount < db["HFILTER"] then return end
      self:DisplayEvent(inout, text, texture, color, message, spellName)
    end
    ------------power gains----------------
  elseif etype == "POWER" then
    if db["GAINS"] then
      spellId, spellName, _, amount, _, powerType = select(12, CombatLogGetCurrentEventInfo())
      -- If spell is blacklisted, don't show it
      if isBlacklisted(spellName, spellId) then return end
      texture = GetSpellTexture(spellId)
      if toPlayer then
        if amount < db["MFILTER"] then return end
        color = db["PGAIN"]
      elseif not toPet then
        return
      end
      text = string_format("+%d %s", amount, string_nil(POWER_STRINGS[powerType]))
      self:DisplayEvent(inout, text, texture, color, message, spellName)
    end
    ------------deaths----------------
  elseif etype == "DEATH" then
    texture = nil
    if (playerRelated or petRelated) and not toPlayer then
      local _color
      if toPet then _color = { r = 1, g = 0.27, b = 0.2, a = 1 } end
      text = deathchar .. destName .. deathchar
      self:DisplayEvent(MISC, text, texture, _color or db["DEATH"], message)
    end
    return
    ------------enchants----------------
  elseif etype == "ENCHANT_APPLIED" then
    texture = "Interface\\Icons\\UI_PROFESSION_ENCHANTING"
    spellName = select(12, CombatLogGetCurrentEventInfo())
    self:DisplayEvent(MISC, self:ShortenString(spellName), texture, db["PBUFF"], message, spellName)
  elseif etype == "ENCHANT_REMOVED" then
    texture = "Interface\\Icons\\INV_ENCHANT_DISENCHANT"
    spellName = select(12, CombatLogGetCurrentEventInfo())
    self:DisplayEvent(
      MISC,
      self:ShortenString(spellName) .. " " .. L["Fades"],
      texture,
      db["PBUFF"],
      message,
      spellName
    )
    -------------anything else-------------
  else
    -- self:Print(event, sourceName, destName)
    --@debug@
    local _d = false
    if etype == "HEALABSORB" then
      print(_d, "|cffaabbff HEALABSORB event ==============================|r")
      local load = { select(12, CombatLogGetCurrentEventInfo()) }
      for idx, v in ipairs(load) do
        print(_d, string_format("Arg%s: %s", tostring(idx), tostring(v)))
      end
    end
    print(
      _d,
      string_format(
        "Event: %s, |cffff0000source: %s, |cffF48CBAdest: %s|r",
        tostring(event),
        tostring(sourceName),
        tostring(destName)
      )
    )
    print(_d, "|cff0000ee================================================|r")
    --@end-debug@
  end
end

function EavesDrop:PLAYER_XP_UPDATE(_, unitID)
  if unitID ~= "player" then return end
  local xp = UnitXP("player")
  local xpgained -- = xp - pxp
  local msg

  --@debug@
  local debug = false
  print(debug, string_format("========= %s =========>", unitID))
  if PLAYER_CURRENT_LEVEL ~= UnitLevel("player") then
    print(debug, "----")
    print(debug, string.format("LEVEL CHANGED"))
    print(debug, "xp < pxp?", xp < pxp)
    if xp >= pxp then print("|cffff0000Player leveled but xp > pxp!|r") end
    local foo = maxXP - pxp + xp
    local x = string.format(
      "xp: %d, pxp: %d, xpgained: %d\nmaxXP: %d, UnitXPMax: %d\nPLAYER_CURRENT_LEVEL: %d, UnitLevel: %d",
      xp,
      pxp,
      foo,
      maxXP,
      UnitXPMax("player"),
      PLAYER_CURRENT_LEVEL,
      UnitLevel("player")
    )
    print(debug, x)
    print(debug, "----")
  end
  --@end-debug@
  if xp < pxp or PLAYER_CURRENT_LEVEL ~= UnitLevel("player") then -- xpgained <= 0 then
    xpgained = maxXP - pxp + xp
    --@debug@
    print(debug, "xp < pxp")
    if PLAYER_CURRENT_LEVEL + 1 ~= UnitLevel("player") then
      print(
        debug,
        string_format("|cffff0000PLAYER_CURRENT_LEVEL+1 ~= UnitLevel('player'), xp < pxp but player didn't level up!|r")
      )
    end
    local x = string.format(
      "xp: %d, pxp: %d, xpgained: %d\nmaxXP: %d, UnitXPMax: %d\nPLAYER_CURRENT_LEVEL: %d, UnitLevel: %d",
      xp,
      pxp,
      xpgained,
      maxXP,
      UnitXPMax("player"),
      PLAYER_CURRENT_LEVEL,
      UnitLevel("player")
    )
    print(debug, string.format("LEVELED UP!"))
    if UnitLevel("player") == PLAYER_MAX_LEVEL then
      print(debug, string.format("PLAYER at MAX LEVEL"))
    else
      print(debug, "Detected level up but player is not at MAX level.")
    end
    print(debug, x)
    --@end-debug@
    maxXP = UnitXPMax("player")
    PLAYER_CURRENT_LEVEL = UnitLevel("player")
    local gratz = string.format(L["NewLevel"], UnitLevel("player"))
    self:DisplayEvent(MISC, gratz, nil, db["EXPC"], nil)
  elseif xp > pxp then
    xpgained = xp - pxp
    --@debug@
    local x = string.format(
      "xp: %d, pxp: %d, xpgained: %d\nmaxXP: %d, UnitXPMax: %d\nPLAYER_CURRENT_LEVEL: %d, UnitLevel: %d",
      xp,
      pxp,
      xpgained,
      maxXP,
      UnitXPMax("player"),
      PLAYER_CURRENT_LEVEL,
      UnitLevel("player")
    )
    print(debug, "xp > pxp: Gained XP.")
    print(debug, x)
    --@end-debug@
  elseif xp == pxp then
    xpgained = xp - pxp
    --@debug@
    local x = string.format(
      "xp: %d, pxp: %d, xpgained: %d\nmaxXP: %d, UnitXPMax: %d\nPLAYER_CURRENT_LEVEL: %d, UnitLevel: %d",
      xp,
      pxp,
      xpgained,
      maxXP,
      UnitXPMax("player"),
      PLAYER_CURRENT_LEVEL,
      UnitLevel("player")
    )
    print(debug, "xp and pxp are the same!")
    print(debug, x)
    --@end-debug@
  else
    print("Unreachable?")
    xpgained = xp - pxp
    local x = string.format(
      "xp: %d, pxp: %d, xpgained: %d\nmaxXP: %d, UnitXPMax: %d\nPLAYER_CURRENT_LEVEL: %d, UnitLevel: %d",
      xp,
      pxp,
      xpgained,
      maxXP,
      UnitXPMax("player"),
      PLAYER_CURRENT_LEVEL,
      UnitLevel("player")
    )
    print(x)
  end
  --@debug@
  local cc = "ffff1a88"
  if xpgained == 0 then cc = "ff0044ff" end
  cc = WrapTextInColorCode("**GAINED**", cc)
  print(debug, string.format("PLAYER_XP_UPDATE %s: %d", cc, xpgained))
  --@end-debug@
  if xpgained ~= 0 then
    msg = string_format("+%s (%s)", shortenValue(xpgained), XP)
    self:DisplayEvent(MISC, msg, nil, db["EXPC"], nil)
  end
  pxp = xp
  --@debug@
  print(debug, "<=================")
  --@end-debug@
end

function EavesDrop:COMBAT_TEXT_UPDATE(_, larg1)
  local larg2, larg3 = GetCurrentCombatTextEventInfo() -- Thanks DTuloJr for pointing this out!
  if larg1 == "FACTION" then
    local sign = "+"
    if larg2 == nil then larg2 = 0 end
    if larg3 == nil then
      larg3 = 0
      sign = ""
    end
    if tonumber(larg3) < 0 then sign = "" end
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
  if db["SUMMARY"] == true then
    local duration = round(GetTime() - timeStart, 1)
    local _nz = duration ~= 0
    local DPS = _nz and round(totDamageOut / duration, 1) or 0
    local HPS = _nz and round(totHealingOut / duration, 1) or 0
    local IDPS = _nz and round(totDamageIn / duration, 1) or 0
    local IHPS = _nz and round(totHealingIn / duration, 1) or 0
    local strSummary = convertRGBtoHEXString(db["MISC"], duration .. " " .. L["IncombatSummary"])
      .. "\n"
      .. convertRGBtoHEXString(db["PHIT"], L["IncomingDamge"] .. ": " .. totDamageIn .. " (" .. IDPS .. ")")
      .. "\n"
      .. convertRGBtoHEXString(db["PHEAL"], L["IncomingHeals"] .. ": " .. totHealingIn .. " (" .. IHPS .. ")")
      .. "\n"
      .. convertRGBtoHEXString(db["THEAL"], L["OutgoingHeals"] .. ": " .. totHealingOut .. " (" .. HPS .. ")")
      .. "\n"
      .. convertRGBtoHEXString(db["TSPELL"], L["OutgoingDamage"] .. ": " .. totDamageOut .. " (" .. DPS .. ")")

    self:DisplayEvent(
      MISC,
      convertRGBtoHEXString(db["PHIT"], shortenValue(totDamageIn))
        .. " | "
        .. convertRGBtoHEXString(db["PHEAL"], shortenValue(totHealingIn))
        .. " | "
        .. convertRGBtoHEXString(db["THEAL"], shortenValue(totHealingOut))
        .. " | "
        .. convertRGBtoHEXString(db["TSPELL"], shortenValue(totDamageOut)),
      nil,
      db["MISC"],
      strSummary
    )
  end
  clearSummary()
  -- since out of combat, try and start onupdate to count down frames
  self:StartOnUpdate()
end

function EavesDrop:PLAYER_DEAD()
  -- PLAYER_DEAD event sometimes fires twice in a row!
  if GetTime() < (EavesDrop.lastDeath or 0) + 2 then return end
  EavesDrop.lastDeath = GetTime()
  --@debug@
  print("*****", date("%H:%M:%S"))
  print("PLAYER_DEAD fired at ", GetTime())
  print("Processing PLAYER_DEAD event")
  print("*****")
  print(" ")
  --@end-debug@
  local classColor
  if EavesDrop:IsRetail() then
    classColor = C_ClassColor.GetClassColor(select(2, UnitClass("player")))
  else
    classColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
  end
  classColor = { r = classColor.r, g = classColor.g, b = classColor.b, a = 1 }
  self:DisplayEvent(MISC, deathchar .. UnitName("player") .. deathchar, nil, classColor or db["DEATH"], L["YOUDIED"])
  if db["DEATHSOUND"] and UnitIsDeadOrGhost("player") and UnitIsDead("player") then
    local _, xx = PlaySound(98429)
    C_Timer.NewTimer(2, function()
      StopSound(xx, 500)
    end)
  end
end

function EavesDrop:CHAT_MSG_SKILL(_, larg1)
  local skill, rank = string_match(larg1, skillmsg)
  if skill then self:DisplayEvent(MISC, string_format("%s: %d", skill, rank), nil, db["SKILLC"], larg1) end
end

local tempcolor = { r = 1, g = 1, b = 1, a = 1 }
function EavesDrop:DisplayEvent(inout, text, texture, color, message, spellname)
  -- remove oldest table and create new display event
  local pEvent = tremove(arrEventData, 1)
  local tooltiptext = message
  if db["FLIP"] == true then inout = inout * -1 end
  pEvent.type = inout
  pEvent.text = text
  pEvent.texture = texture

  if not color or color == {} then
    --@debug@
    print(true, string_format("|cffff0000color is empty!|r"))
    EavesDrop:AddToInspector({ color, message, spellname, text, inout }, "colorIssue:DisplayEvent")
    --@end-debug@
    pEvent.r = tempcolor.r
    pEvent.g = tempcolor.g
    pEvent.b = tempcolor.b
    pEvent.a = tempcolor.a
  else
    pEvent.r = color.r
    pEvent.g = color.g
    pEvent.b = color.b
    pEvent.a = color.a or 1.0
  end

  -- Messages probably already have a timestamp, so let's clear that up
  if db["TIMESTAMP"] == true and message then
    -- Check if we have a timestamp here and clean it up before using it.
    local timecutoff = string.find(message, "> ")

    local combat_message, timestamp
    -- If we did, skip those two characters "> "
    if timecutoff then
      combat_message = strsub(message, timecutoff + 2)
      timestamp = strsub(message, 1, timecutoff - 1)
      pEvent.tooltipText = string_format("|cffffffff%s|r\n%s", timestamp, combat_message)
    else
      pEvent.tooltipText = string_format("|cffffffff%s|r\n%s", date("%H:%M:%S"), message)
    end
  elseif db["TIMESTAMP"] == true and text then
    pEvent.tooltipText = string_format("|cffffffff%s|r\n%s", date("%H:%M:%S"), text)
  elseif db["TIMESTAMP"] == true then
    pEvent.tooltipText = string_format("|cffffffff%s|r\n%s", date("%H:%M:%S"), tooltiptext or "")
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
    if not value.text then
      text:SetText(nil)
      intexture:SetTexture(nil)
      outtexture:SetTexture(nil)
      frame.delay = 0
      frame.alpha = 0
      frame.tooltipText = nil
      frame:Hide()
    else
      if value.type == INCOMING then
        text:SetJustifyH("LEFT")
        text:SetWidth(db["LINEWIDTH"] - 20)
        text:SetPoint("LEFT", intexture, "RIGHT", 5, 0)
        intexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        outtexture:SetTexture(nil)
        if value.texture == "pet" then
          SetPortraitTexture(intexture, value.texture)
        else
          intexture:SetTexture(value.texture)
        end
      elseif value.type == OUTGOING then
        text:SetJustifyH("RIGHT")
        text:SetWidth(db["LINEWIDTH"] - 20)
        text:SetPoint("LEFT", intexture, "RIGHT", 5, 0)
        intexture:SetTexture(nil)
        outtexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
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
      --@debug@
      if type(value.text) ~= "string" then
        print("-----------")
        print("|cffff0000value.text caused error|r")
        DevTools_Dump(value)
        DevTools_Dump(value.text)
        print("-----------")
        print("******")
        print(" ")
        EavesDrop:AddToInspector(value, "value_NoText:UpdateEvents")
      end
      --@end-debug@
      text:SetText(value.text or "")
      if not value or not value.r or not value.g or not value.b then
        --@debug@
        print("|cffff0000value doesn't have color info!|r")
        EavesDrop:AddToInspector(value, "colorIssue:UpdateEvents")
        --@end-debug@
        text:SetTextColor(tempcolor.r, tempcolor.g, tempcolor.b, 1)
      else
        text:SetTextColor(value.r, value.g, value.b, value.a or 1)
      end

      frame.delay = delay
      frame.alpha = 1
      if db["TOOLTIPS"] == true then
        frame.tooltipText = value.tooltipText
      else
        frame.tooltipText = nil
      end
      frame:Show()
      frame:SetAlpha(frame.alpha)
    end
    delay = delay - 4
    -- set clickthru
    if frame.tooltipText then
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
    self.OnUpdateStarted = self:ScheduleRepeatingTimer("OnUpdate", 0.2, self)
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
    if frame:IsShown() then
      count = count + 1
      frame.delay = frame.delay - elapsed
      if frame.delay <= 0 then
        frame.alpha = frame.alpha - 0.2
        if frame.alpha > 0 then frame:SetAlpha(frame.alpha) end
      end
      if frame.alpha <= 0 then
        frame:Hide()
        EavesDropFrameUpButton:Hide()
        count = count - 1
      end
    end
  end
  if count == arrSize then
    allShown = true
  else
    allShown = false
  end
  -- if none are active, stop onUpdate
  if count == 0 then self:StopOnUpdate() end
  -- hide frame when none active
  if db["FADEFRAME"] then
    if (count == 0) and (scroll == 0) then
      self:HideFrame()
    else
      self:ShowFrame()
    end
  end
end

function EavesDrop:Scroll(_, dir)
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
  if scroll > (arrMaxSize - arrSize) then scroll = arrMaxSize - arrSize end
  self:UpdateScrollButtons()
  self:UpdateEvents()
end

function EavesDrop:ScrollDown()
  scroll = scroll - 1
  if scroll < 0 then scroll = 0 end
  self:UpdateScrollButtons()
  self:UpdateEvents()
end

function EavesDrop:UpdateScrollButtons()
  if not db["SCROLLBUTTON"] then
    if scroll > 0 then
      EavesDropFrameDownButton:Show()
      if scroll == arrMaxSize - arrSize then
        EavesDropFrameUpButton:Hide()
      else
        EavesDropFrameUpButton:Show()
      end
    else
      EavesDropFrameDownButton:Hide()
      if not allShown then
        EavesDropFrameUpButton:Hide()
      else
        EavesDropFrameUpButton:Show()
      end
    end
  end
end

function EavesDrop:SpellColor(option, type)
  if db["SPELLCOLOR"] == true then
    return db[type] or option
  else
    return option
  end
end

-------------------------
-- Set last reflection
function EavesDrop:ParseReflect(
  timestamp,
  event,
  hideCaster,
  sourceGUID,
  sourceName,
  sourceFlags,
  sourceFlags2,
  destGUID,
  destName,
  destFlags,
  destFlags2,
  ...
)
  local spellId, spellName, _, amount, school, _, _, _, critical, _, _ = select(1, ...)
  local texture = GetSpellTexture(spellId)
  local text
  local messsage = CombatLog_OnEvent(
    Blizzard_CombatLog_CurrentSettings,
    timestamp,
    event,
    hideCaster,
    sourceGUID,
    sourceName,
    sourceFlags,
    sourceFlags2,
    destGUID,
    destName,
    destFlags,
    destFlags2,
    ...
  )

  -- reflected events
  if self.ReflectTarget == sourceName and sourceName == destName and self.ReflectSkill == spellName then
    text = string_format("%s: %s", REFLECT, shortenValue(amount))
    if critical then text = critchar .. text .. critchar end
    self:DisplayEvent(
      OUTGOING,
      text,
      texture,
      self:SpellColor(db["TSPELL"], SCHOOL_STRINGS[school]),
      messsage,
      spellName
    )
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
function EavesDrop:ShortenString(incString)
  local strString = tostring(incString)
  if (db["TRUNCATETYPE"] ~= "0") and strlen(strString) > db["TRUNCATESIZE"] then
    if db["TRUNCATETYPE"] == "1" then
      return strsub(strString, 1, db["TRUNCATESIZE"]) .. "..."
    elseif db["TRUNCATETYPE"] == "2" then
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
  if not EavesDropHistoryFrame:IsShown() then
    EavesDropHistoryFrame:Show()
    PlaySound(888)
  else
    EavesDropHistoryFrame:Hide()
  end
end

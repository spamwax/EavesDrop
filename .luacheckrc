std = "lua51"
max_line_length = false
exclude_files = {
    "**/libs/**/*.lua",
    "locals",
    ".luacheckrc"
}
ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "11./BINDING_.*", -- Setting an undefined (Keybinding header) global variable
    "212/self.*", -- Unused argument
    -- "211", -- Unused local variable
    -- "211/L", -- Unused local variable "L"
    -- "211/CL", -- Unused local variable "CL"
    -- "43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
    -- "431", -- shadowing upvalue
    -- "542", -- An empty if branch
}
globals = {
    -- self
    "std",
    "max_line_length",
    "ignore",
    "exclude_files",
    "globals",
    -- Lua
    "bit.band",
    "bit",
    "ceil",
    "date",
    "string.split",
    "table.wipe",
    "table.foreach",
    "time",
    "wipe",

    -- Utility functions
    "geterrorhandler",
    "fastrandom",
    "format",
    "strjoin",
    "strtrim",
    "strsplit",
    "strmatch",
    "strupper",
    "strlen",
    "strsub",
    "tContains",
    "tDeleteItem",
    "tIndexOf",
    "tinsert",
    "tostringall",
    "tremove",
    "gsub",
    "DevTools_Dump",

    -- WoW
    "C_Timer",
    "C_ClassColor",
    "ALL",
    "ACCEPT",
    "ALWAYS",
    "UNKNOWN",
    "BNET_CLIENT_WOW",
    "BOSS",
    "BOSSES_KILLED",
    "SKILL_RANK_UP",
    "MELEE_ATTACK",
    "CANCEL",
    "CHALLENGE_MODE",
    "CLOSE",
    "COMBATLOG_OBJECT_AFFILIATION_MINE",
    "COMBATLOG_FILTER_HOSTILE_PLAYERS",
    "COMBATLOG_FILTER_HOSTILE_UNITS",
    "COMBATLOG_FILTER_MY_PET",
    "COMBATLOG_FILTER_MINE",
    "COMBATLOG_OBJECT_NONE",
    "CombatLog_Object_IsA",
    "Blizzard_CombatLog_Filters",
    "CombatLogGetCurrentEventInfo",
    "SetPortraitTexture",
    "REFLECT",
    "SPELL_SCHOOL0_CAP",
    "SPELL_SCHOOL1_CAP",
    "SPELL_SCHOOL2_CAP",
    "SPELL_SCHOOL3_CAP",
    "SPELL_SCHOOL3_CAP",
    "SPELL_SCHOOL4_CAP",
    "SPELL_SCHOOL5_CAP",
    "SPELL_SCHOOL6_CAP",
    "RAID_CLASS_COLORS",
    "ALTERNATE_RESOURCE_TEXT",
    "MAELSTROM_POWER",
    "CHI_POWER",
    "ARCANE_CHARGES_POWER",
    "INSANITY_POWER",
    "HOLY_POWER",
    "RUNIC_POWER",
    "LUNAR_POWER",
    "SHARDS",
    "FURY",
    "PAIN",
    "MANA",
    "RAGE",
    "FOCUS",
    "COMBO_POINTS",
    "RUNES",
    "ENERGY",
    "Enum",
    "HONOR",
    "XP",
    "CombatLog_OnEvent",
    "IsShiftKeyDown",
    "IsControlKeyDown",
    "WrapTextInColorCode",

    "BackdropTemplateMixin",
    "UIParent",
    "GetTime",
    "GetLocale",
    "UnitName",
    "UnitXP",
    "UnitXPMax",
    "UnitClass",
    "UnitLevel",
    "InCombatLockdown",
    "PlaySound",
    "StopSound",
    "CreateFrame",
    "ChatFontNormal",
    "GameFontHighlightNormal",
    "ChatEdit_ActivateChat",
    "ChatEdit_ChooseBoxForSend",
    "AceGUIMultiLineEditBoxInsertLink",
    "GetSpellInfo",
    "IsSpellKnown",
    "GetCurrentCombatTextEventInfo",
    "IsAddOnLoaded",
    "hooksecurefunc",

    -- Ace3
    "LibStub",
    -- EavesDrop
    "EavesDrop",
    "EavesDropFrame",
    "EavesDropFrameDownButton",
    "EavesDropFrameUpButton",
    "EavesDropHistoryFrame",
    "EavesDropHistoryButton",
    "EavesDropFramePlayerText",
    "EavesDropFrameTargetText",
    "EavesDropStatsDB",
    "EavesDropTab",
    "EavesDropTopBar",
    "EavesDropBottomBar",
    "EavesDropFontNormal",
    "EavesDropFontNormalSmall",
    "EavesDropHistoryTopBar",
    "EavesDropHistoryBottomBar",
    "EavesDropHistoryFrameOutgoingHit",
    "EavesDropHistoryFrameOutgoingHeal",
    "EavesDropHistoryFrameIncomingHit",
    "EavesDropHistoryFrameIncomingHeal",
    "EavesDropHistoryFrameSkillText",
    "EavesDropHistoryFrameAmountCritText",
    "EavesDropHistoryFrameAmountNormalText",
    "EavesDropHistoryFrameResetText",
    "FauxScrollFrame_Update",
    "FauxScrollFrame_SetOffset",
    "EavesDropHistoryScrollBar",
    "FauxScrollFrame_GetOffset",
    "InterfaceOptionsFrame_OpenToCategory",

    -- Deubg
    "ViragDevTool",
}


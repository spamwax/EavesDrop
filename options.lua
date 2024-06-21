-- ^^ Example for addon options settings?
-- https://discord.com/channels/327414731654692866/1014994401644269670/1234228949459144765
-- https://github.com/tg123/myslot/commit/23f7863661310f40dab63dcf55b0f8ed3fadf667

local L = LibStub("AceLocale-3.0"):GetLocale("EavesDrop", true)
local EavesDrop = EavesDrop

local media = LibStub("LibSharedMedia-3.0")

local GetSpellName = C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellName
-- common functions for options callbacks
local function getOption(info)
  return (info.arg and EavesDrop.db.profile[info.arg] or EavesDrop.db.profile[info[#info]])
end

local function setOption(info, value)
  local key = info.arg or info[#info]
  EavesDrop.db.profile[key] = value
  EavesDrop:UpdateFrame()
end

local function getColorOption(info)
  local key = info.arg or info[#info]
  return EavesDrop.db.profile[key].r,
    EavesDrop.db.profile[key].g,
    EavesDrop.db.profile[key].b,
    EavesDrop.db.profile[key].a
end

local function setColorOption(info, r, g, b, a)
  local key = info.arg or info[#info]
  EavesDrop.db.profile[key].r, EavesDrop.db.profile[key].g, EavesDrop.db.profile[key].b, EavesDrop.db.profile[key].a =
    r, g, b, a
  EavesDrop:PerformDisplayOptions()
end

local getBlacklistOption = function(info)
  local spell_table = info.arg and EavesDrop.db.profile[info.arg] or EavesDrop.db.profile[info[#info]]
  local auras = {}
  local aname
  if spell_table["version"] == nil then
    --@debug@
    print("--> Reading old DB for excluded spells.")
    --@end-debug@
    local temp = {}
    for _, value in pairs(spell_table) do
      temp[value] = true
    end
    for key, _ in pairs(temp) do
      auras[#auras + 1] = key
    end
  elseif spell_table["version"] == EavesDrop.BLACKLIST_DB_VERSION then
    spell_table = spell_table["spells"]
    --@debug@
    print("--> Reading new DB for excluded spells.", EavesDrop.BLACKLIST_DB_VERSION)
    --@end-debug@
    for key, value in pairs(spell_table) do
      if type(value) == "boolean" and value == true then
        aname = string.format("%s", key)
      elseif type(key) == "number" and type(value) == "string" then
        aname = string.format("%d |cd0ff7d0a-- %s|r", key, value)
      else
        print(string.format("|cffff0000BIG ISSUE:|r"), key, value, type(key), type(value))
        aname = "INVALID"
      end
      auras[#auras + 1] = aname
    end
  end
  table.sort(auras)
  return table.concat(auras, "\n")
end

local setBlacklistOption = function(info, inp)
  local auras = { strsplit("\n,", strtrim(inp)) }
  local dbkey = info.arg or info[#info]
  --@debug@
  print("dbkey:", dbkey)
  --@end-debug@
  wipe(EavesDrop.db.profile[dbkey])
  local idx = 0
  local new_spells = {}

  for _, v in pairs(auras) do
    (function()
      local key, value
      local id, name
      local aura_name, aura_id
      v = gsub(v, "|r", "")
      v = gsub(v, "|c........", "")
      aura_name, aura_id = strsplit("-", v, 2)
      aura_name = strtrim(aura_name)
      if not (aura_name and (#aura_name > 0)) then
        --@debug@
        print(string.format("EavesDrop: Blacklist entry is empty: >%s<", v))
        --@end-debug@
        return
      end
      if aura_id then
        aura_id = strtrim(aura_id, "\r\n\t -")
        if #aura_id == 0 then aura_id = nil end
      end
      if aura_name and aura_id then -- TWO ITEMS
        --@debug@
        assert(#aura_id > 0 and #aura_name > 0)
        print(string.format("TWO ITEM, >%s<, >%s<", aura_name, aura_id))
        --@end-debug@
        if not tonumber(aura_name) and tonumber(aura_id) then -- string, number
          key = aura_name
          value = true
          print(string.format("EavesDrop: |cffff0000Removing spell id:|r %s", aura_id))
        elseif not tonumber(aura_name) and not tonumber(aura_id) then -- string, string
          print(string.format("EavesDrop: |cffff0000Only enter a single spell name per line|r"))
          return
        elseif tonumber(aura_name) and tonumber(aura_id) then -- number, number
          id = tonumber(aura_name)
          name = GetSpellName(id)
          if not name then
            print(string.format("EavesDrop: |cffff0000Invalid spell ID:|r %d", id))
            return
          else
            key = id
            value = name
            --@debug@
            print("|cffff0000Removing 2nd id|r", aura_id)
            --@end-debug@
          end
        elseif tonumber(aura_name) and not tonumber(aura_id) then -- number, string
          id = tonumber(aura_name)
          name = GetSpellName(id)
          if name then
            key = id
            value = name
          else
            print(string.format("EavesDrop: |cffff0000Invalid spell ID:|r %d", id))
            return
          end
        end
      elseif aura_name and not aura_id then -- ONE ITEM
        --@debug@
        assert(#aura_name > 0 and aura_id == nil)
        print(string.format("ONE ITEM, >%s<, >%s<", aura_name, aura_id or "NIL"))
        --@end-debug@
        if tonumber(aura_name) then
          -- it's spell id
          id = tonumber(aura_name)
          name = GetSpellName(id)
          if name then
            key = id
            value = name
          else
            print(string.format("EavesDrop: |cffff0000Invalid spell ID:|r %d", id))
            return
          end
        else
          key = aura_name
          value = true
        end
      else
        print(
          string.format("|cffff0000Can't understand your entry!|r\n\tPlease eport your entry (%s) to the author.", v)
        )
        return
      end
      --@debug@
      assert(key ~= nil and value ~= nil)
      print("Inserting", key, value)
      --@end-debug@
      idx = idx + 1
      new_spells[key] = value
    end)()
  end
  EavesDrop.db.profile[dbkey]["version"] = EavesDrop.BLACKLIST_DB_VERSION
  EavesDrop.db.profile[dbkey]["spells"] = new_spells
  EavesDrop.blacklist = new_spells
  EavesDrop:UpdateFrame()
  --@debug@
  print(string.format("EavesDrop: Processed % items for Blacklist table.", idx))
  --@end-debug@
end

function EavesDrop:SetupOptions()
  self.options = {
    type = "group",
    name = "EavesDrop",
    childGroups = "tab",
    plugins = {},
    args = {
      events = {
        name = L["Events"],
        desc = L["Events"],
        type = "group",
        order = 1,
        args = {
          COMBAT = {
            name = L["ECombat"],
            type = "toggle",
            desc = L["ECombatD"],
            order = 1,
            get = getOption,
            set = setOption,
          },
          GAINS = {
            name = L["EPower"],
            type = "toggle",
            desc = L["EPowerD"],
            order = 2,
            get = getOption,
            set = setOption,
          },
          BUFF = {
            name = L["EBuffs"],
            type = "toggle",
            desc = L["EBuffsD"],
            order = 3,
            get = getOption,
            set = setOption,
          },
          DEBUFF = {
            name = L["EDebuffs"],
            type = "toggle",
            desc = L["EDebuffsD"],
            order = 4,
            get = getOption,
            set = setOption,
          },
          BUFFFADE = {
            name = L["EBuffFades"],
            type = "toggle",
            desc = L["EBuffFadesD"],
            order = 5,
            get = getOption,
            set = setOption,
          },
          DEBUFFFADE = {
            name = L["EDebuffFades"],
            type = "toggle",
            desc = L["EDebuffFadesD"],
            order = 6,
            get = getOption,
            set = setOption,
          },
          EXP = {
            name = L["EExperience"],
            type = "toggle",
            desc = L["EExperienceD"],
            order = 7,
            get = getOption,
            set = setOption,
          },
          HONOR = {
            name = L["EHonor"],
            type = "toggle",
            desc = L["EHonorD"],
            order = 8,
            get = getOption,
            set = setOption,
          },
          REP = {
            name = L["EReputation"],
            type = "toggle",
            desc = L["EReputationD"],
            order = 9,
            get = getOption,
            set = setOption,
          },
          SKILL = {
            name = L["ESkill"],
            type = "toggle",
            desc = L["ESkillD"],
            order = 10,
            get = getOption,
            set = setOption,
          },
          PET = { name = L["EPet"], type = "toggle", desc = L["EPetD"], order = 11, get = getOption, set = setOption },
          SPELLCOLOR = {
            name = L["ESpellcolor"],
            type = "toggle",
            desc = L["ESpellcolorD"],
            order = 12,
            get = getOption,
            set = setOption,
          },
          OVERHEAL = {
            name = L["EOverhealing"],
            type = "toggle",
            desc = L["EOverhealingD"],
            order = 13,
            get = getOption,
            set = setOption,
          },
          HEALERID = {
            name = L["EHealers"],
            type = "toggle",
            desc = L["EHealersD"],
            order = 14,
            get = getOption,
            set = setOption,
          },
          SUMMARY = {
            name = L["ESummary"],
            type = "toggle",
            desc = L["ESummaryD"],
            order = 15,
            get = getOption,
            set = setOption,
          },
        },
      },

      colors = {
        name = L["Colors"],
        desc = L["Colors"],
        type = "group",
        order = 2,
        childGroups = "tree",
        args = {
          icolor = {
            name = L["IColors"],
            desc = L["IColorsD"],
            type = "group",
            order = 1,
            args = {
              PHIT = {
                name = L["ICHits"],
                type = "color",
                desc = L["ICHitsD"],
                order = 1,
                get = getColorOption,
                set = setColorOption,
              },
              PMISS = {
                name = L["ICMiss"],
                type = "color",
                desc = L["ICMissD"],
                order = 2,
                get = getColorOption,
                set = setColorOption,
              },
              PHEAL = {
                name = L["ICHeals"],
                type = "color",
                desc = L["ICHealsD"],
                order = 3,
                get = getColorOption,
                set = setColorOption,
              },
              PSPELL = {
                name = L["ICSpells"],
                type = "color",
                desc = L["ICSpellsD"],
                order = 4,
                get = getColorOption,
                set = setColorOption,
              },
              PGAIN = {
                name = L["EPower"],
                type = "color",
                desc = L["ICGainsD"],
                order = 5,
                get = getColorOption,
                set = setColorOption,
              },
              PBUFF = {
                name = L["EBuffs"],
                type = "color",
                desc = L["ICBuffsD"],
                order = 6,
                get = getColorOption,
                set = setColorOption,
              },
              PDEBUFF = {
                name = L["EDebuffs"],
                type = "color",
                desc = L["ICDebuffsD"],
                order = 7,
                get = getColorOption,
                set = setColorOption,
              },
              PETO = {
                name = L["EPet"],
                type = "color",
                desc = L["ICPetD"],
                order = 8,
                get = getColorOption,
                set = setColorOption,
              },
            },
          },
          ocolor = {
            name = L["OColors"],
            desc = L["OColorsD"],
            type = "group",
            order = 2,
            args = {
              TMELEE = {
                name = L["ICHits"],
                type = "color",
                desc = L["OCHitsD"],
                order = 1,
                get = getColorOption,
                set = setColorOption,
              },
              TSPELL = {
                name = L["ICSpells"],
                type = "color",
                desc = L["OCSpellsD"],
                order = 2,
                get = getColorOption,
                set = setColorOption,
              },
              THEAL = {
                name = L["ICHeals"],
                type = "color",
                desc = L["OCHealsD"],
                order = 3,
                get = getColorOption,
                set = setColorOption,
              },
              PETI = {
                name = L["EPet"],
                type = "color",
                desc = L["OCPetD"],
                order = 4,
                get = getColorOption,
                set = setColorOption,
              },
            },
          },
          scolor = {
            name = L["OSColors"],
            desc = L["OSColorsD"],
            type = "group",
            order = 3,
            args = {
              SPELL_SCHOOL0_CAP = {
                arg = SPELL_SCHOOL0_CAP,
                name = SPELL_SCHOOL0_CAP,
                type = "color",
                desc = SPELL_SCHOOL0_CAP,
                order = 1,
                get = getColorOption,
                set = setColorOption,
              },
              SPELL_SCHOOL1_CAP = {
                arg = SPELL_SCHOOL1_CAP,
                name = SPELL_SCHOOL1_CAP,
                type = "color",
                desc = SPELL_SCHOOL1_CAP,
                order = 2,
                get = getColorOption,
                set = setColorOption,
              },
              SPELL_SCHOOL2_CAP = {
                arg = SPELL_SCHOOL2_CAP,
                name = SPELL_SCHOOL2_CAP,
                type = "color",
                desc = SPELL_SCHOOL2_CAP,
                order = 3,
                get = getColorOption,
                set = setColorOption,
              },
              SPELL_SCHOOL3_CAP = {
                arg = SPELL_SCHOOL3_CAP,
                name = SPELL_SCHOOL3_CAP,
                type = "color",
                desc = SPELL_SCHOOL3_CAP,
                order = 4,
                get = getColorOption,
                set = setColorOption,
              },
              SPELL_SCHOOL4_CAP = {
                arg = SPELL_SCHOOL4_CAP,
                name = SPELL_SCHOOL4_CAP,
                type = "color",
                desc = SPELL_SCHOOL4_CAP,
                order = 5,
                get = getColorOption,
                set = setColorOption,
              },
              SPELL_SCHOOL5_CAP = {
                arg = SPELL_SCHOOL5_CAP,
                name = SPELL_SCHOOL5_CAP,
                type = "color",
                desc = SPELL_SCHOOL5_CAP,
                order = 6,
                get = getColorOption,
                set = setColorOption,
              },
              SPELL_SCHOOL6_CAP = {
                arg = SPELL_SCHOOL6_CAP,
                name = SPELL_SCHOOL6_CAP,
                type = "color",
                desc = SPELL_SCHOOL6_CAP,
                order = 7,
                get = getColorOption,
                set = setColorOption,
              },
            },
          },
          mcolor = {
            name = L["MColors"],
            desc = L["MColorsD"],
            type = "group",
            order = 4,
            args = {
              DEATH = {
                name = L["MCDeath"],
                type = "color",
                desc = L["MCDeathD"],
                order = 1,
                get = getColorOption,
                set = setColorOption,
              },
              MISC = {
                name = L["MCMisc"],
                type = "color",
                desc = L["MCMiscD"],
                order = 2,
                get = getColorOption,
                set = setColorOption,
              },
              EXPC = {
                name = L["EExperience"],
                type = "color",
                desc = L["MCExperienceD"],
                order = 3,
                get = getColorOption,
                set = setColorOption,
              },
              REPC = {
                name = L["EReputation"],
                type = "color",
                desc = L["MCReputationD"],
                order = 4,
                get = getColorOption,
                set = setColorOption,
              },
              HONORC = {
                name = L["EHonor"],
                type = "color",
                desc = L["MCHonorD"],
                order = 5,
                get = getColorOption,
                set = setColorOption,
              },
              SKILLC = {
                name = L["ESkill"],
                type = "color",
                desc = L["MCSkillD"],
                order = 6,
                get = getColorOption,
                set = setColorOption,
              },
            },
          },
          framecolor = {
            name = L["Frame"],
            desc = L["Frame"],
            type = "group",
            order = 5,
            args = {
              FRAME = {
                name = L["MCFrame"],
                type = "color",
                desc = L["MCFrameD"],
                order = 5,
                get = getColorOption,
                set = setColorOption,
                hasAlpha = true,
              },
              BORDER = {
                name = L["MCBorder"],
                type = "color",
                desc = L["MCBorderD"],
                order = 6,
                get = getColorOption,
                set = setColorOption,
                hasAlpha = true,
              },
              LABELC = {
                name = L["MCLabel"],
                type = "color",
                desc = L["MCLabelD"],
                order = 7,
                get = getColorOption,
                set = setColorOption,
                hasAlpha = true,
              },
            },
          },
        },
      },

      frame = {
        name = L["Frame"],
        desc = L["Frame"],
        type = "group",
        order = 3,
        args = {
          NUMLINES = {
            name = L["FNumber"],
            type = "range",
            desc = L["FNumberD"],
            order = 1,
            get = getOption,
            set = setOption,
            min = 1,
            max = 20,
            step = 1,
          },
          LINEHEIGHT = {
            name = L["FHeight"],
            type = "range",
            desc = L["FHeightD"],
            order = 2,
            get = getOption,
            set = setOption,
            min = 10,
            max = 30,
            step = 1,
          },
          LINEWIDTH = {
            name = L["FWidth"],
            type = "range",
            desc = L["FWidthD"],
            order = 3,
            get = getOption,
            set = setOption,
            min = 100,
            max = 400,
            step = 10,
          },
          TEXTSIZE = {
            name = L["FText"],
            type = "range",
            desc = L["FTextD"],
            order = 4,
            get = getOption,
            set = setOption,
            min = 8,
            max = 24,
            step = 1,
          },
          FONT = {
            type = "select",
            name = L["FFont"],
            desc = L["FFont"],
            values = media:List("font"),
            get = function(_)
              local mt = media:List("font")
              for k, v in pairs(mt) do
                if v == self.db.profile.FONT then return k end
              end
            end,
            set = function(_, v)
              local mt = media:List("font")
              self.db.profile.FONT = mt[v]
              self:PerformDisplayOptions()
            end,
            order = 5,
          },
          FONTOUTLINE = {
            name = L["FFontOutline"],
            type = "select",
            desc = L["FFontOutlineD"],
            order = 6,
            get = getOption,
            set = function(_, v)
              self.db.profile["FONTOUTLINE"] = v
              self:PerformDisplayOptions()
            end,
            values = {
              Monochrome = "Monochrome",
              MonochromeOutline = "Monochrome Outline",
              MonochromeThickOutline = "Monochrome Thick Outline",
              None = "None",
              Outline = "Outline",
              ThickOutline = "Thick Outline",
            },
          },
          FADETIME = {
            name = L["FFade"],
            type = "range",
            desc = L["FFadeD"],
            order = 7,
            get = getOption,
            set = setOption,
            min = 0,
            max = 60,
            step = 5,
          },
          FADEFRAME = {
            name = L["FFadeFrame"],
            type = "toggle",
            desc = L["FFadeFrameD"],
            order = 8,
            get = getOption,
            set = setOption,
          },
          HIDETAB = {
            name = L["MHideTab"],
            type = "toggle",
            desc = L["MHideTabD"],
            order = 9,
            get = getOption,
            set = setOption,
          },
          LOCKED = {
            name = L["MLock"],
            type = "toggle",
            desc = L["MLockD"],
            order = 10,
            get = getOption,
            set = function(_, v)
              self.db.profile["LOCKED"] = v
              EavesDropFrame:EnableMouse(not self.db.profile["LOCKED"])
            end,
          },
        },
      },
      misc = {
        name = L["Misc"],
        desc = L["Misc"],
        type = "group",
        order = 4,
        childGroups = "tab",
        args = {
          SCROLLBUTTON = {
            name = L["MButtons"],
            type = "toggle",
            desc = L["MButtonsD"],
            order = 1,
            get = getOption,
            set = setOption,
          },
          TOOLTIPS = {
            name = L["MTooltip"],
            type = "toggle",
            desc = L["MTooltipD"],
            order = 2,
            get = getOption,
            set = setOption,
          },
          TIMESTAMP = {
            name = L["MTimestamp"],
            type = "toggle",
            desc = L["MTimestampD"],
            order = 3,
            get = getOption,
            set = setOption,
            disabled = function()
              return not self.db.profile["TOOLTIPS"]
            end,
          },
          TOOLTIPSANCHOR = {
            name = L["MTooltipAnchor"],
            type = "select",
            desc = L["MTooltipAnchorD"],
            order = 4,
            get = getOption,
            set = function(_, v)
              self.db.profile["TOOLTIPSANCHOR"] = v
              self.ToolTipAnchor = "ANCHOR_" .. strupper(v)
            end,
            values = {
              Left = "Left",
              TopLeft = "TopLeft",
              BottomLeft = "BottomLeft",
              Right = "Right",
              TopRight = "TopRight",
              BottomRight = "BottomRight",
            },
            disabled = function()
              return not self.db.profile["TOOLTIPS"]
            end,
          },
          FLIP = { name = L["MFlip"], type = "toggle", desc = L["MFlipD"], order = 5, get = getOption, set = setOption },
          HISTORY = {
            name = L["MHistory"],
            type = "toggle",
            desc = L["MHistoryD"],
            order = 6,
            get = getOption,
            set = function(_, v)
              self.db.profile["HISTORY"] = v
              if v == true then
                EavesDropHistoryButton:Show()
              else
                EavesDropHistoryButton:Hide()
                EavesDropHistoryFrame:Hide()
              end
            end,
          },
          HFILTER = {
            name = L["MHFilter"],
            type = "range",
            desc = L["MHFilterD"],
            order = 7,
            get = getOption,
            set = setOption,
            min = 0,
            max = 2000,
            step = 25,
          },
          MFILTER = {
            name = L["MMFilter"],
            type = "range",
            desc = L["MMFilterD"],
            order = 8,
            get = getOption,
            set = setOption,
            min = 0,
            max = 2000,
            step = 25,
          },
          DFILTER = {
            name = L["MDFilter"],
            type = "range",
            desc = L["MDFilterD"],
            order = 9,
            get = getOption,
            set = setOption,
            min = 0,
            max = 2000,
            step = 25,
          },
          TRUNCATETYPE = {
            name = L["MBuffTruncType"],
            type = "select",
            desc = L["MBuffTruncTypeD"],
            order = 10,
            get = getOption,
            set = setOption,
            values = { ["0"] = L["MBuffTruncNone"], ["1"] = L["MBuffTruncTrunc"], ["2"] = L["MBuffTruncShorten"] },
          },
          TRUNCATESIZE = {
            name = L["MBuffTruncSize"],
            type = "range",
            desc = L["MBuffTruncSize"],
            order = 11,
            get = getOption,
            set = setOption,
            min = 0,
            max = 50,
            step = 1,
          },
          DEATHSOUND = {
            name = L["BWONSAMDI"],
            type = "toggle",
            desc = L["BWONSAMDID"],
            order = 12,
            get = getOption,
            set = setOption,
            -- stylua: ignore
            disabled = function() return not EavesDrop:IsRetail() end,
          },
          BLACKLIST = {
            name = L["MBlacklist"],
            type = "input",
            desc = L["MBlacklistD"],
            order = 13,
            width = "full",
            multiline = 16,
            get = getBlacklistOption,
            set = setBlacklistOption,
          },
        },
      },
    },
  }

  self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }
  LibStub("AceConfig-3.0"):RegisterOptionsTable("EavesDrop", self.options)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("EavesDrop", "EavesDrop")
  self:RegisterChatCommand("ed", self.OpenMenu)
  self:RegisterChatCommand("eavesdrop", self.OpenMenu)
end

function EavesDrop:GetDefaultConfig()
  local default = {
    profile = {
      ["PHIT"] = { r = 1.0, g = 0.0, b = 0.0 },
      ["PMISS"] = { r = 0.0, g = 0.0, b = 1.0 },
      ["PHEAL"] = { r = 0.0, g = 1.0, b = 0.0 },
      ["PSPELL"] = { r = 0.5, g = 0.0, b = 0.5 },
      ["TSPELL"] = { r = 1.0, g = 1.0, b = 0.0 },
      ["THEAL"] = { r = 0, g = 0.7, b = 0 },
      ["TMELEE"] = { r = 1.0, g = 1.0, b = 1.0 },
      ["DEATH"] = { r = 0.6, g = 0.6, b = 0.6 },
      ["MISC"] = { r = 1, g = 1, b = 1 },
      ["EXPC"] = { r = 0.5, g = 0.7, b = 0.5 },
      ["HONORC"] = { r = 0.7, g = 0.5, b = 0.7 },
      ["REPC"] = { r = 0.5, g = 0.5, b = 1 },
      ["SKILLC"] = { r = 0, g = 0, b = 1 },
      ["FRAME"] = { r = 0, g = 0, b = 0, a = 0.33 },
      ["BORDER"] = { r = 1, g = 1, b = 1, a = 0.75 },
      ["LABELC"] = { r = 1, g = 1, b = 0, a = 1 },
      ["PETO"] = { r = 0.6, g = 0.6, b = 0.0 },
      ["PETI"] = { r = 0.6, g = 0.6, b = 0.0 },
      ["PGAIN"] = { r = 1.0, g = 1.0, b = 0.0 },
      ["PBUFF"] = { r = 0.7, g = 0.7, b = 0.0 },
      ["PDEBUFF"] = { r = 0.0, g = 0.5, b = 0.5 },
      [SPELL_SCHOOL0_CAP] = { r = 1, g = 0, b = 0 },
      [SPELL_SCHOOL1_CAP] = { r = 1, g = 1, b = 0 },
      [SPELL_SCHOOL2_CAP] = { r = 1, g = 0.3, b = 0 },
      [SPELL_SCHOOL3_CAP] = { r = 0.5, g = 1, b = 0.2 },
      [SPELL_SCHOOL4_CAP] = { r = 0.4, g = 0.6, b = 0.9 },
      [SPELL_SCHOOL5_CAP] = { r = 0.4, g = 0.4, b = 0.5 },
      [SPELL_SCHOOL6_CAP] = { r = 0.8, g = 0.8, b = 1 },
      ["NUMLINES"] = 10,
      ["FADETIME"] = 10,
      ["LINEHEIGHT"] = 20,
      ["LINEWIDTH"] = 160,
      ["HFILTER"] = 0,
      ["MFILTER"] = 0,
      ["DFILTER"] = 0,
      ["DEATHSOUND"] = false,
      ["BLACKLIST"] = {},
      ["SPELLCOLOR"] = true,
      ["EXP"] = true,
      ["HONOR"] = true,
      ["REP"] = true,
      ["SKILL"] = false,
      ["COMBAT"] = true,
      ["GAINS"] = false,
      ["BUFFS"] = false,
      ["DEBUFFS"] = false,
      ["BUFFSFADE"] = false,
      ["DEBUFFSFADE"] = false,
      ["PET"] = false,
      ["SCROLLBUTTON"] = false,
      ["TOOLTIPS"] = true,
      ["TOOLTIPSANCHOR"] = "Right",
      ["TIMESTAMP"] = true,
      ["LOCKED"] = false,
      ["FADEFRAME"] = false,
      ["FLIP"] = false,
      ["OVERHEAL"] = false,
      ["HEALERID"] = false,
      ["HISTORY"] = true,
      ["TEXTSIZE"] = 14,
      ["TRUNCATETYPE"] = "2",
      ["TRUNCATESIZE"] = 10,
      ["SUMMARY"] = true,
      ["HIDETAB"] = false,
      ["x"] = 0,
      ["y"] = 0,
      ["hx"] = 0,
      ["hy"] = 0,
      ["FONT"] = "Friz Quadrata TT",
      ["FONTOUTLINE"] = "Outline",
    },
  }
  return default
end

function EavesDrop:OpenMenu()
  -- LibStub("AceConfigDialog-3.0"):Open("EavesDrop")
  -- InterfaceOptionsFrame_OpenToCategory("EavesDrop")
  Settings.OpenToCategory("EavesDrop")
end

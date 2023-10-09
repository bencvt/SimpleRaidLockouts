local PREFIX = "|cff33ff99"..(...).."|r:"
local GetClassColor, GetServerTime, pairs, print, tinsert, tsort = GetClassColor, GetServerTime, pairs, print, table.insert, table.sort


-- Some people use "ak" or "tok". Manually change it here if it bothers you. :)
local OLD_KINGDOM_ABBREV = "ok"


-- Dungeons are ordered to match the LFG tool.
local CURRENT_DUNGEONS = { OLD_KINGDOM_ABBREV, "an", "dtk", "gun", "hol", "hos", "cos", "nex", "ocu", "toc", "uk", "up", "vh", }
local CURRENT_RAIDS = { "voa10", "voa25", "ony10", "ony25", "toc10", "toc25", }
local _, _, _, version = GetBuildInfo()
if version > 30402 then
  -- Assuming Blizzard bumps the interface version every classic phase.
  tinsert(CURRENT_DUNGEONS, "fos")
  tinsert(CURRENT_DUNGEONS, "pos")
  tinsert(CURRENT_DUNGEONS, "hor")
  if version > 30403 then
    CURRENT_RAIDS = { "voa10", "voa25", "rs10", "rs25", "icc10", "icc25", }
  else
    CURRENT_RAIDS = { "voa10", "voa25", "icc10", "icc25", }
  end
end
local IS_CURRENT_DUNGEON = {}
for _, v in pairs(CURRENT_DUNGEONS) do
  IS_CURRENT_DUNGEON[v] = true
end
local IS_CURRENT_RAID = {}
for _, v in pairs(CURRENT_RAIDS) do
  IS_CURRENT_RAID[v] = true
end


local DUNGEON_ABBREVS = {
  ["Ahn'kahet: The Old Kingdom"] = OLD_KINGDOM_ABBREV,
  ["Azjol-Nerub"] = "an",
  ["Drak'Tharon Keep"] = "dtk",
  ["Gundrak"] = "gun",
  ["Halls of Lightning"] = "hol",
  ["Halls of Stone"] = "hos",
  ["The Culling of Stratholme"] = "cos",
  ["The Nexus"] = "nex",
  ["The Oculus"] = "ocu",
  ["Trial of the Champion"] = "toc",
  ["Trial of the Champions"] = "toc", -- NWB alias
  ["Utgarde Keep"] = "uk",
  ["Utgarde Pinnacle"] = "up",
  ["Violet Hold"] = "vh",
  ["The Violet Hold"] = "vh", -- NWB alias
  ["The Forge of Souls"] = "fos",
  ["Pit of Saron"] = "pos",
  ["Halls of Reflection"] = "hor",
}
local function getDungeonAbbrev(name)
  return DUNGEON_ABBREVS[name]
end
local RAID_ABBREVS = {
  ["Vault of Archavon"] = "voa",
  ["The Ruby Sanctum"] = "rs",
  ["Icecrown Citadel"] = "icc",
  ["Trial of the Crusader"] = "toc",
  ["Onyxia's Lair"] = "ony",
  ["Ulduar"] = "uld",
  ["The Obsidian Sanctum"] = "os",
  ["The Eye of Eternity"] = "eoe",
  ["Naxxramas"] = "naxx",
}
local function getRaidAbbrev(name, difficulty)
  name = RAID_ABBREVS[name]
  if name and difficulty then
    if difficulty:find("^10") then
      name = name.."10"
    elseif difficulty:find("^25") then
      name = name.."25"
    elseif difficulty:find("^40") then
      name = name.."40"
    end
  end
  return name
end


-- Rely on the Nova Instance Tracker addon (required) to get lockout data.
-- This dependency could be removed with some additional tracking code.
-- Alternately, NIT could be made into an optional dependency that just
-- initially hydrates the character data.
local function isMissingAddon()
  if not NIT or not NIT.data or not NIT.data["myChars"] then
    print(PREFIX.." this addon requires Nova Instance Tracker")
    return true
  end
  return false
end
local MAX_LEVEL = MAX_PLAYER_LEVEL_TABLE[2]
local function getSortedMaxLevelCharNames()
  local result = {}
  for k, v in pairs(NIT.data["myChars"]) do
    if v.level and v.level >= MAX_LEVEL then
      tinsert(result, k)
    end
  end
  tsort(result)
  return result
end
local function getClass(charName)
  return NIT.data["myChars"][charName].classEnglish or "PRIEST"
end
local function getSavedInstances(charName)
  return NIT.data["myChars"][charName].savedInstances or {}
end


-- Rely on the Nova World Buffs addon (optional dependency) to get daily dungeon quest data.
-- NWB broadcasts this data on addon channels whenever someone visits a quest giver.
-- Definitely not worth duplicating that infrastructure.
local SECONDS_IN_A_DAY = 60 * 60 * 24
local dailyHeroic = nil
local dailyNormal = nil
local function lookupDailyDungeons()
  dailyHeroic = nil
  dailyNormal = nil
  local NWB = LibStub("AceAddon-3.0"):GetAddon("NovaWorldBuffs", true)
  if not NWB or not NWB.data then
    return false
  end
  if NWB.data.tbcHD and NWB.data.tbcHDT and GetServerTime() - NWB.data.tbcHDT < SECONDS_IN_A_DAY then
    local questData = NWB:getHeroicDailyData(NWB.data.tbcHD);
    if questData then
      dailyHeroic = DUNGEON_ABBREVS[questData.dungeon]
    end
  end
  if NWB.data.tbcDD and NWB.data.tbcDDT and GetServerTime() - NWB.data.tbcDDT < SECONDS_IN_A_DAY then
    local questData = NWB:getDungeonDailyData(NWB.data.tbcDD);
    if questData then
      dailyNormal = DUNGEON_ABBREVS[questData.dungeon]
    end
  end
  return true
end


-- Logic to output color codes only when needed.
local COLOR_DARK = "|cff667676"
local COLOR_HIGHLIGHT = "|cff1eff0c"
local COLOR_HIGHLIGHT_DAILY_HEROIC = "|cffffb000"
local COLOR_HIGHLIGHT_DAILY_NORMAL = "|cffffffff"
local currentColor = nil
local function resetColor()
  currentColor = nil
end
local function colorDark()
  if currentColor ~= COLOR_DARK then
    currentColor = COLOR_DARK
    return currentColor
  end
  return ""
end
local function colorHighlight()
  if currentColor ~= COLOR_HIGHLIGHT then
    currentColor = COLOR_HIGHLIGHT
    return currentColor
  end
  return ""
end
local function colorHighlightDungeon(name)
  local color = COLOR_HIGHLIGHT
  if name == dailyHeroic then
    color = COLOR_HIGHLIGHT_DAILY_HEROIC
  elseif name == dailyNormal then
    color = COLOR_HIGHLIGHT_DAILY_NORMAL
  end
  if currentColor ~= color then
    currentColor = color
    return currentColor
  end
  return ""
end
local function colorClass(charName)
  local _, _, _, classColorHex = GetClassColor(getClass(charName))
  return "|c"..classColorHex
end


local function printHeader(charNames, message)
  if #charNames == 0 then
    print(PREFIX.." you have no max-level characters on this realm")
  else
    print(PREFIX..(message or ""))
  end
end


local function showRaidLockouts()
  if isMissingAddon() then return end
  local charNames = getSortedMaxLevelCharNames()
  printHeader(charNames)
  for _, charName in pairs(charNames) do
    local allInstanceData = getSavedInstances(charName)
    local lockouts = {}
    local extraLockouts = {}
    for _, instanceData in pairs(allInstanceData) do
      if instanceData.locked and instanceData.resetTime and instanceData.resetTime > GetServerTime() then
        local name = getRaidAbbrev(instanceData.name, instanceData.difficultyName)
        if name then
          if IS_CURRENT_RAID[name] then
            lockouts[name] = true
          else
            tinsert(extraLockouts, name)
          end
        end
      end
    end
    tsort(extraLockouts)
    resetColor()
    local text = ""
    for _, v in pairs(CURRENT_RAIDS) do
      if lockouts[v] then
        text = text.." "..colorDark()..v
      else
        text = text.." "..colorHighlight()..v
      end
    end
    for _, v in pairs(extraLockouts) do
      text = text.." "..colorDark()..v
    end
    text = text.." "..colorClass(charName)..charName.."|r"
    print(text)
  end
end


local function showDungeonLockouts()
  if isMissingAddon() then return end
  local message = " Dungeons:"
  if lookupDailyDungeons() then
    message = COLOR_HIGHLIGHT_DAILY_HEROIC.." Daily H"..COLOR_HIGHLIGHT_DAILY_NORMAL.."/N dungeons:|r"
  end
  local charNames = getSortedMaxLevelCharNames()
  printHeader(charNames, message)
  for _, charName in pairs(charNames) do
    local allInstanceData = getSavedInstances(charName)
    local lockouts = {}
    for _, instanceData in pairs(allInstanceData) do
      if instanceData.locked and instanceData.resetTime and instanceData.resetTime > GetServerTime() then
        local name = getDungeonAbbrev(instanceData.name)
        if IS_CURRENT_DUNGEON[name] then
          lockouts[name] = true
        end
      end
    end
    resetColor()
    local text = ""
    for _, v in pairs(CURRENT_DUNGEONS) do
      if lockouts[v] then
        text = text.." "..colorDark()..v
      else
        text = text.." "..colorHighlightDungeon(v)..v
      end
    end
    text = text.." "..colorClass(charName)..charName.."|r"
    print(text)
  end
end


local function printHelp()
  isMissingAddon()
  print(PREFIX.." "..COLOR_HIGHLIGHT.."/lo|r and "..COLOR_HIGHLIGHT.."/srl|r are equivalent. Usage:")
  print(" "..COLOR_HIGHLIGHT.."/lo|r - show raid lockouts")
  print(" "..COLOR_HIGHLIGHT.."/lo d|r or "..COLOR_HIGHLIGHT.."/lo dungeons|r - show dungeon lockouts; if Nova World Buffs is installed, the "
    ..COLOR_HIGHLIGHT_DAILY_HEROIC.."daily heroic|r"..COLOR_HIGHLIGHT_DAILY_NORMAL.."/normal".."|r will be highlighted")
end


local function slashCommand(args)
  args = string.lower(args or "")
  if args == "" or args == "r" or args == "raid" or args == "raids" then
    showRaidLockouts()
  elseif args == "d" or args == "dungeon" or args == "dungeons" then
    showDungeonLockouts()
  else
    printHelp()
  end
end

SLASH_SRL1 = "/srl"
SlashCmdList["SRL"] = slashCommand

SLASH_LO1 = "/lo"
SlashCmdList["LO"] = slashCommand

SLASH_LOD1 = "/lod"
SlashCmdList["LOD"] = function(args)
  if not args or args == "" then
    showDungeonLockouts()
  else
    printHelp()
  end
end

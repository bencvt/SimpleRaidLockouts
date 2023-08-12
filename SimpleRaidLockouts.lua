local PREFIX = "|cff33ff99"..(...).."|r:"
local LOCALE = GetLocale()
local GetClassColor, GetServerTime, print, SendChatMessage, SlashCmdList = GetClassColor, GetServerTime, print, SendChatMessage, SlashCmdList

-- TODO update for Wrath Classic phases 4 and 5
local CURRENT_TIER_RAIDS = { "voa10", "voa25", "ony10", "ony25", "toc10", "toc25", }
--local CURRENT_TIER_RAIDS = { "voa10", "voa25", "icc10", "icc25", }
--local CURRENT_TIER_RAIDS = { "voa10", "voa25", "rs10", "rs25", "icc10", "icc25", }


local MAX_LEVEL = MAX_PLAYER_LEVEL_TABLE[2]
local CURRENT_TIER_RAIDS_KEYS = {}
for _, v in pairs(CURRENT_TIER_RAIDS) do
  CURRENT_TIER_RAIDS_KEYS[v] = true
end


local function GetSortedMaxLevelCharNames()
  local result = {}
  for k, v in pairs(NIT.data["myChars"]) do
    if v.level and v.level >= 80 then
      table.insert(result, k)
    end
  end
  table.sort(result)
  return result
end


local function GetShortRaidName(name, difficulty)
  if name == "Vault of Archavon" then
    name = "voa"
  elseif name == "The Ruby Sanctum" then
    name = "rs"
  elseif name == "Icecrown Citadel" then
    name = "icc"
  elseif name == "Trial of the Crusader" then
    name = "toc"
  elseif name == "Onyxia's Lair" then
    name = "ony"
  elseif name == "Ulduar" then
    name = "uld"
  elseif name == "The Obsidian Sanctum" then
    name = "os"
  elseif name == "The Eye of Eternity" then
    name = "eoe"
  elseif name == "Naxxramas" then
    name = "naxx"
  else
    name = nil
  end
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


local function ShowRaidLockouts(args)
  if not NIT or not NIT.data or not NIT.data["myChars"] then
    print(PREFIX.." this addon requires NovaInstanceTracker")
    return
  end
  
  print(PREFIX)
  local charNames = GetSortedMaxLevelCharNames()
  for _, charName in pairs(charNames) do
    local charData = NIT.data["myChars"][charName]
    local currentTierLockouts = {}
    local extraLockouts = {}
    if (charData.savedInstances) then
      for _, instanceData in pairs(charData.savedInstances) do
        if (instanceData.locked and instanceData.resetTime and instanceData.resetTime > GetServerTime()) then
          local name = GetShortRaidName(instanceData.name, instanceData.difficultyName)
          if name then
            if CURRENT_TIER_RAIDS_KEYS[name] then
              currentTierLockouts[name] = true
            else
              table.insert(extraLockouts, name)
            end
          end
        end
      end
      table.sort(extraLockouts)
    end
    local text = ""
    for _, v in pairs(CURRENT_TIER_RAIDS) do
      if currentTierLockouts[v] then
        text = text.." |cff606060"..v
      else
        text = text.." |cff00ff00"..v
      end
    end
    for _, v in pairs(extraLockouts) do
      text = text.." |cff606060"..v
    end
    local _, _, _, classColorHex = GetClassColor(charData.classEnglish)
    text = text.." |c"..classColorHex..charName.."|r"
    print(text)
  end
end


SLASH_SRL1 = "/srl"
SlashCmdList["SRL"] = ShowRaidLockouts

SLASH_LO1 = "/lo"
SlashCmdList["LO"] = ShowRaidLockouts

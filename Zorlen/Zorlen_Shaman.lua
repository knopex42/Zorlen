
Zorlen_Shaman_FileBuildNumber = 684

--[[
  Zorlen Library - Started by Marcus S. Zarra
 
  4.23
		isRockbiterWeaponActive() added by Nosrac
		isFlametongueWeaponActive() added by Nosrac
		isFrostbrandWeaponActive() added by Nosrac
		isWindfuryWeaponActive() added by Nosrac
		isShamanWeaponBuffActive() added by Nosrac
		isFarsightActive() added by Nosrac
		isWaterBreathingActive() added by Nosrac
		isWaterWalkingActive() added by Nosrac
		isLightningShieldActive() added by Nosrac

  3.00  Rewrite by Wynn (Bleeding Hollow), break units into class functions.
		  
--]]


-- TODO
-- 

Zorlen_SpellInfo = Zorlen_SpellInfo or {}

local SpellInfo = {}
local SpellIdsByRankbySpellName = {}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SpellInfo = {}

	local B = Book or BOOKTYPE_SPELL
	for i = 1, GetNumSpellTabs() do
		local name, _, offset, numSpells = GetSpellTabInfo(i)
		for j = 1, numSpells do
			local spellIndex = offset + j
			local spellName, rank = GetSpellName(spellIndex, B)
			local found, _, Rank = string.find(rank, "(%d+)")
			if found then
				RankNum = tonumber(Rank)
			else
				RankNum = 1
			end
			if spellName then
				--print(spellIndex .. " Spell Name: " .. spellName .. ", Rank: " .. RankNum)
				local spellInfo = ExtractSpellInfo(spellName, RankNum)
				if spellInfo then
					SpellInfo[spellInfo.id] = spellInfo
				end
			end
		end
	end

	Zorlen_SpellInfo = SpellInfo

	-- Fill SpellIdsByRankbySpellName
	for _, info in pairs(SpellInfo) do
		local spellId = info.id
		local spellName = info.name
		if not SpellIdsByRankbySpellName[spellName] then
			SpellIdsByRankbySpellName[spellName] = {}
		end
		SpellIdsByRankbySpellName[spellName][info.rank] = spellId
	end

	Zorlen_SpellIdsByRankbySpellName = SpellIdsByRankbySpellName
end)

function ExtractSpellInfo(spellName, rank)
	if not spellName then return nil end

	local spellID = Zorlen_GetSpellID(spellName, rank)
	if not spellID then return nil end

	local minVal, maxVal = Zorlen_SpellMinMaxValue(spellName, rank)
	local spellInfo = {
		name = spellName,
		id = spellID,
		rank = rank,
		castTime = Zorlen_SpellCastTime(spellName, rank) or 0,
		cost = Zorlen_SpellCost(spellName, rank),
		minVal = minVal,
		maxVal = maxVal,
	}
	return spellInfo
end

-- /run dumpSpellInfo()
function dumpSpellInfo()
	for _, info in pairs(SpellInfo) do
		print("ID: " .. info.id .. ", Name: " .. info.name .. ", Rank: " .. info.rank
			.. ", Cast Time: " .. info.castTime
			.. ", Cost: " .. info.cost .. ", Min Value: " .. info.minVal
			.. ", Max Value: " .. info.maxVal)

		print("---")
	end
end


function dumpAllSpellBySpellNameToRankUp(SpellName)
	local spellIds = SpellIdsByRankbySpellName[SpellName]
	if not spellIds then
		print("No spells found for: " .. SpellName)
		return
	end

	for _, spellId in pairs(spellIds) do
		local spellInfo = SpellInfo[spellId]
		if spellInfo then
			print("Spell ID: " .. spellInfo.id .. " - Spell Name: " .. spellInfo.name .. " - Rank: " .. spellInfo.rank)
			print(" Cast Time: " .. spellInfo.castTime .. " - Cost: " .. spellInfo.cost)
			print(" Values: " .. spellInfo.minVal .. " - " .. spellInfo.maxVal)
		end
	end
end



--------   All functions below this line will only load if you are playing the corresponding class   --------
if not Zorlen_isCurrentClassShaman then return end





-- Added by Nosrac
function isRockbiterWeaponActive()
	local SpellName = LOCALIZATION_ZORLEN.RockbiterWeapon
	Zorlen_checkItemBuffByName(SpellName)
end

-- Added by Nosrac
function isFlametongueWeaponActive()
	local SpellName = LOCALIZATION_ZORLEN.FlametongueWeapon
	Zorlen_checkItemBuffByName(SpellName)
end

-- Added by Nosrac
function isFrostbrandWeaponActive()
	local SpellName = LOCALIZATION_ZORLEN.FrostbrandWeapon
	Zorlen_checkItemBuffByName(SpellName)
end

-- Added by Nosrac
function isWindfuryWeaponActive()
	local SpellName = LOCALIZATION_ZORLEN.WindfuryWeapon
	Zorlen_checkItemBuffByName(SpellName)
end

-- Added by Nosrac
function isShamanWeaponBuffActive()
	if isRockbiterWeaponActive() or isFlametongueWeaponActive() or isFrostbrandWeaponActive() or isWindfuryWeaponActive() then
		return true
	end
	return false
end

-- Added by Nosrac
function isFarsightActive()
	local SpellName = LOCALIZATION_ZORLEN.FarSight
	return Zorlen_checkBuffByName(SpellName)
end

-- Added by Nosrac
function isWaterBreathingActive()
	local SpellName = LOCALIZATION_ZORLEN.WaterBreathing
	return Zorlen_checkBuffByName(SpellName)
end

-- Added by Nosrac
function isWaterWalkingActive()
	local SpellName = LOCALIZATION_ZORLEN.WaterWalking
	return Zorlen_checkBuffByName(SpellName)
end

-- Added by Nosrac
function isLightningShieldActive()
	local SpellName = LOCALIZATION_ZORLEN.LightningShield
	return Zorlen_checkBuffByName(SpellName)
end

-- Map for basic casting functions
local CastSpellMap = {
	castLightningBolt = {key = "LightningBolt", checkMoving = true},
	castMoltenBlast = {key = "MoltenBlast", checkMoving = true},
	castFlameShock = {key = "FlameShock", hasDebuff = true},
	castFrostShock = {key = "FrostShock", hasDebuff = true},
	castEarthShock = {key = "EarthShock"},
	castEarthShield = {key = "EarthShield", hasBuff = true, enemyTargetNotNeeded = true},
	castLightningShield = {key = "LightningShield", hasBuff = true, enemyTargetNotNeeded = true},
	castWaterShield = {key = "WaterShield", hasBuff = true, enemyTargetNotNeeded = true},
}

-- Generate casting functions
for funcName, config in pairs(CastSpellMap) do
	do
		local f = funcName
		local cfg = config
		
		global[f] = function(SpellRank)
			if cfg.checkMoving and Zorlen_isMoving() then
				return false
			end
			
			local spellName = LOCALIZATION_ZORLEN and LOCALIZATION_ZORLEN[cfg.key]
			if not spellName then return false end
			
			local debuffName = cfg.hasDebuff and spellName or nil
			local buffName = cfg.hasBuff and spellName or nil
			local enemyTargetNotNeeded = cfg.enemyTargetNotNeeded and 1 or nil
			local noRangeCheck = cfg.noRangeCheck and 1 or nil
			local debuffTimer = cfg.hasTimer and 1 or nil
			
			return Zorlen_CastCommonRegisteredSpell(SpellRank, spellName, debuffName, nil, nil, nil, 
				enemyTargetNotNeeded, buffName, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 
				noRangeCheck, nil, debuffTimer)
		end
		
		countFunctions = countFunctions + 1
	end
end


-- Map for healing variant functions (Under/Over/Max)
local HealingVariantMap = {
	-- Individual healing spells
	{base = "castLesserHealingWave", params = {"RankAdj", "unit"}},
	{base = "castHealingWave", params = {"RankAdj", "unit"}},
	{base = "castChainHeal", params = {"RankAdj", "unit"}},
	{base = "castShamanHeal", params = {"RankAdj", "unit"}},
	
	
	-- Group healing spells (different parameter order)
	{base = "castGroupShamanHeal", params = {"pet", "RankAdj"}}
}

-- Generate healing variant functions
for _, config in ipairs(HealingVariantMap) do	
	do
		local baseName = config.base
		local params = config.params
		
		-- Generate Under variant
		local underFunc = string.gsub(baseName, "^cast", "castUnder")
		global[underFunc] = function(param1, param2)
			if params[1] == "pet" then
				-- Group healing: (pet, RankAdj) -> (pet, "under", RankAdj)
				local DefaultAdj = param2 or -1
				return global[baseName](param1, "under", DefaultAdj)
			else
				-- Individual healing: (RankAdj, unit) -> ("under", RankAdj, unit)
				local DefaultAdj = param1 or -1
				return global[baseName]("under", DefaultAdj, param2)
			end
		end
		
		-- Generate Over variant  
		local overFunc = string.gsub(baseName, "^cast", "castOver")
		global[overFunc] = function(param1, param2)
			if params[1] == "pet" then
				-- Group healing: (pet, RankAdj) -> (pet, "over", RankAdj)
				local DefaultAdj = param2 or 1
				return global[baseName](param1, "over", DefaultAdj)
			else
				-- Individual healing: (RankAdj, unit) -> ("over", RankAdj, unit)
				local DefaultAdj = param1 or 1
				return global[baseName]("over", DefaultAdj, param2)
			end
		end
		
		-- Generate Max variant
		local maxFunc = string.gsub(baseName, "^cast", "castMax")
		global[maxFunc] = function(param1, param2)
			if params[1] == "pet" then
				-- Group healing: (pet, RankAdj) -> (pet, "maximum", RankAdj)
				return global[baseName](param1, "maximum", param2)
			else
				-- Individual healing: (RankAdj, unit) -> ("maximum", RankAdj, unit)
				return global[baseName]("maximum", param1, param2)
			end
		end
		
		countFunctions = countFunctions + 3
	end
end

Zorlen_debug("Zorlen Shaman successfully loaded " .. countFunctions .. " functions.", 1)

function Zorlen_Shaman_SpellTimerSet()
	local Duration = 0
	local TargetName = Zorlen_CastingSpellTargetName
	local SpellName = Zorlen_CastingSpellName
	local DebuffName = nil
	local DebuffTargetName = nil

	if SpellName == LOCALIZATION_ZORLEN.FlameShock then
		Duration = 15
	end

	Zorlen_SetTimer(1, DebuffName, DebuffTargetName, "InternalZorlenSpellCastDelay", 2)
	if Zorlen_CastingSpellTargetName then
		Zorlen_SetTimer(Duration, SpellName, TargetName, "InternalZorlenSpellTimers", nil, nil, 1)
	end
end

-- From: Jiral
function castHealingWave(Mode, RankAdj, unit)
	if Zorlen_isMoving() then
		return false
	end

	local SpellName = LOCALIZATION_ZORLEN.HealingWave
	local SpellButton = Zorlen_Button[SpellName]

	return Zorlen_CastHealingSpell(SpellName, nil, nil, nil, nil, nil, Mode, RankAdj, unit, SpellButton)
end

--This will try to heal party or raid members as long as you are not targeting a party or raid member that can be healed by the spell.
--I made it give priority to your current target so that you have the option to choose priority in the heat of battle.
--If you want it to always select for you then just clear your target or target an enemy before using the function.
function castGroupShamanHeal(pet, Mode, RankAdj)
	-- Early return if moving
	if Zorlen_isMoving() then
		return false
	end
	
	local SpellName = LOCALIZATION_ZORLEN.HealingWave
	
	-- Priority 1: Try to heal current target first
	if UnitExists("target") and castShamanHeal(Mode, RankAdj, "target") then
		return true
	end
	
	-- Early return if spell not known or low mana
	if not Zorlen_IsSpellKnown(SpellName) or UnitMana("player") < 25 then
		return false
	end
	
	-- Handle casting interruption logic
	local healSpells = {SpellName, LOCALIZATION_ZORLEN.HealingWave}
	local isCastingHeal = false
	for _, spell in ipairs(healSpells) do
		if Zorlen_isCasting(spell) then
			isCastingHeal = true
			break
		end
	end
	
	if isCastingHeal then
		local u = Zorlen_GiveGroupUnitWithLowestHealth(pet, 0, nil, Zorlen_CastingNotUnitArray)
		
		-- If we're casting on the same unit, continue
		if u and Zorlen_CastingUnit == u then
			return false
		end
		
		-- If no unit found or casting unit changed, stop casting
		if not u or Zorlen_CastingUnit then
			SpellStopCasting()
			return true
		end
		
		return false
	end
	
	-- Early return if spell not ready
	if not Zorlen_checkCooldownByName(SpellName) then
		return false
	end
	
	-- Find group members who need healing
	local counter = 1
	local notunitarray = {}
	
	while counter do
		local u = Zorlen_GiveGroupUnitWithLowestHealth(pet, nil, nil, notunitarray)
		
		if not u then
			break
		end
		
		-- Skip current target (already tried above)
		if UnitIsUnit("target", u) then
			notunitarray[counter] = u
		-- Heal player directly
		elseif UnitIsUnit("player", u) then
			return castShamanHeal(Mode, RankAdj, u)
		-- Heal other group member (requires targeting)
		else
			TargetUnit(u)
			if castShamanHeal(Mode, RankAdj, u) then
				Zorlen_CastingUnit = u
				Zorlen_CastingNotUnitArray = notunitarray
				TargetLastTarget()
				return true
			end
			TargetLastTarget()
			notunitarray[counter] = u
		end
		
		counter = counter + 1
	end
	
	-- Clean up any ongoing casting if no unit found
	for _, spell in ipairs(healSpells) do
		if Zorlen_isCasting(spell) then
			SpellStopCasting()
			break
		end
	end
	
	return false
end

-- From: Jiral
-- castShamanHeal
function castShamanHeal(Mode, RankAdj, unit)
	if Zorlen_isMoving() then
		return false
	end

	local LevelLearnedArray = nil

	local ManaArray, MinHealArray, MaxHealArray, TimeArray = {}, {}, {}, {}
	local SpellNameArray, SpellButtonArray, SpellRankArray = {}, {}, {}
	local idx = 1

	-- helper to append ranks from a spell-id list
	local function addRanks(spellIds, button)
		if not (spellIds and button) then
			Zorlen_debug("No spellIds or button provided for addRanks")
			return
		end

		for _, spellId in ipairs(spellIds) do
			local info = Zorlen_SpellInfo[spellId]
			if info then
				--Zorlen_debug("Adding spell: " .. info.name .. " (ID: " .. spellId .. ")")
				ManaArray[idx]         = info.cost
				MinHealArray[idx]      = info.minVal
				MaxHealArray[idx]      = info.maxVal
				TimeArray[idx]         = info.castTime
				SpellNameArray[idx]    = info.name
				SpellButtonArray[idx]  = button
				SpellRankArray[idx]    = info.rank
				idx = idx + 1
		end
		end
	end

	addRanks(Zorlen_SpellIdsByRankbySpellName[LOCALIZATION_ZORLEN.HealingWave],        Zorlen_Button_Any[LOCALIZATION_ZORLEN.HealingWave])

	-- nothing gathered? bail
	if idx == 1 then
		Zorlen_debug("No healing spells found for shaman.")
		return false
	end

	return Zorlen_CastMultiNamedHealingSpell(SpellNameArray, SpellRankArray, ManaArray, MinHealArray, MaxHealArray,
		TimeArray, LevelLearnedArray, Mode, RankAdj, unit, SpellButtonArray)
end


-- Added by Bam
function castLesserHealingWave(Mode, RankAdj, unit)
	local SpellName = LOCALIZATION_ZORLEN.LesserHealingWave
	local SpellButton = Zorlen_Button[SpellName]

	return Zorlen_CastHealingSpell(SpellName, nil, nil, nil, nil, nil, Mode, RankAdj, unit, SpellButton)
end



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
	castHealingWave = {key = "HealingWave", checkMoving = true},
	castFlameShock = {key = "FlameShock", hasDebuff = true},
	castDivineSpirit = {key = "DivineSpirit", hasBuff = true, enemyTargetNotNeeded = true},
	castDevouringPlague = {key = "DevouringPlague"},
	castPsychicScream = {key = "PsychicScream", enemyTargetNotNeeded = true, noRangeCheck = true},
	castFear = {key = "Fear", hasDebuff = true},
	castMindVision = {key = "MindVision", enemyTargetNotNeeded = true}
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
	{base = "castLesserHeal", params = {"RankAdj", "unit"}},
	{base = "castHeal", params = {"RankAdj", "unit"}},
	{base = "castGreaterHeal", params = {"RankAdj", "unit"}},
	{base = "castPriestHeal", params = {"RankAdj", "unit"}},
	{base = "castFlashHeal", params = {"RankAdj", "unit"}},
	
	-- Group healing spells (different parameter order)
	{base = "castGroupPriestHeal", params = {"pet", "RankAdj"}}
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

Zorlen_debug("Zorlen Priest successfully loaded " .. countFunctions .. " functions.", 1)
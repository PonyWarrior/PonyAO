---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- here is where your mod sets up all the things it will do.
-- this file will not be reloaded if it changes during gameplay
-- 	so you will most likely want to have it reference
--	values and functions later defined in `reload.lua`.

mod = modutil.mod.Mod.Register(_PLUGIN.guid)

ModUtil.LoadOnce(function()
	rom.data.reload_game_data()
end)

if config.TranquilGainRework.Enabled then
	local textfile = rom.path.combine(rom.paths.Content, 'Game/Text/en/TraitText.en.sjson')

	sjson.hook(textfile, function(sjsonData)
		return sjson_TraitText(sjsonData)
	end)

	local ids_to_descriptions = {
		DemeterManaBoon =
		"When your {!Icons.Mana} falls under {#BoldFormat}{$TooltipData.ExtractData.TooltipManaThreshold}% {#Prev}, your {!Icons.Mana} is fully restored after a {#BoldFormat}{$TooltipData.ExtractData.TooltipRegenPenaltyDuration} Sec. {#Prev}delay without taking damage. This delay increases by {#BoldFormat}{$TooltipData.ExtractData.TooltipDelayIncreaseDuration} Sec. {#Prev} every time this occurs, resetting each {$Keywords.Room}.",
	}

	function sjson_TraitText(sjsonData)
		for _, v in ipairs(sjsonData.Texts) do
			local description = ids_to_descriptions[v.Id]
			if description then v.Description = description end
		end
	end

	ModUtil.Path.Wrap("DamagePresentation", function(base, victim, args)
		base(victim, args)
		DamagePresentation_wrap(victim, args)
	end)

	ModUtil.Path.Wrap("ManaDelta", function(base, delta, args)
		base(delta, args)
		ManaDelta_wrap()
	end)
end

if config.AlwaysManaRegen.Enabled then
	ModUtil.Path.Context.Wrap("ManaRegen", function()
		ModUtil.Path.Wrap("SetThreadWait", function(base, tag, duration)
			base(tag, 0.05)
		end)
		ModUtil.Path.Wrap("waitUnmodified", function(base, duration, tag, persist)
			if duration ~= HeroData.ManaData.ManaRegenCooldown and duration ~= 0.3 then
				base(duration, tag, persist)
			else
				base(0.05, tag)
			end
		end)
		ModUtil.Path.Wrap("IsEmpty", function(base, tableArg)
			if tableArg == MapState.ChargedManaWeapons then
				return true
			else
				return base(tableArg)
			end
		end)
	end)
end

if config.WhiteAntlerHealthCap.Enabled then
	ModUtil.Path.Wrap("ValidateMaxHealth", function(base, blockDelta)
		if HeroHasTrait("LowHealthCritKeepsake") then
			ValidateMaxHealth_wrap(blockDelta)
		else
			base(blockDelta)
		end
	end)

	ModUtil.Path.Context.Wrap("KeepsakeScreenClose", function()
		ModUtil.Path.Wrap("UnequipKeepsake", function(base, heroUnit, traitName)
			base(heroUnit, traitName)
			if traitName == "LowHealthCritKeepsake" then
				ValidateMaxHealth()
			end
		end)
	end)
end

if config.HexChanges.Enabled then
	if config.HexChanges.HexChargeInvulnerable.Enabled then
		ModUtil.Path.Wrap("StartSpellCharge", function(base, triggerArgs, weaponData, dataArgs)
			SetPlayerInvulnerable("StartSpellCharge")
			base(triggerArgs, weaponData, dataArgs)
			SetPlayerVulnerable("StartSpellCharge")
		end)
	end
end

if config.TorchImprovements.Enabled then
	local projectileFile = rom.path.combine(rom.paths.Content, 'Game/Projectiles/PlayerProjectiles.sjson')

	sjson.hook(projectileFile, function(sjsonData)
		return sjson_TorchProjectile(sjsonData)
	end)

	function sjson_TorchProjectile(sjsonData)
		for _, v in ipairs(sjsonData.Projectiles) do
			if v.Name == "ProjectileTorchBall" then
				v.MaxAdjustRate = 1800
				v.AdjustRateAcceleration = 450
			elseif v.Name == "ProjectileTorchSpiral" or v.Name == "ProjectileTorchOrbit" then
				v.Effects[1].Active = true
			end
		end
	end

	local weaponFile = rom.path.combine(rom.paths.Content, 'Game/Weapons/PlayerWeapons.sjson')

	sjson.hook(weaponFile, function(sjsonData)
		return sjson_TorchWeapon(sjsonData)
	end)

	function sjson_TorchWeapon(sjsonData)
		for _, v in ipairs(sjsonData.Weapons) do
			if v.Name == "WeaponTorch" then
				v.Cooldown = 0.33
			end
		end
	end
end

if config.TestamentsChanges.Enabled then
	local textfile = rom.path.combine(rom.paths.Content, 'Game/Text/en/TraitText.en.sjson')

	sjson.hook(textfile, function(sjsonData)
		return sjson_TraitText(sjsonData)
	end)

	local extraRanks = {
		{
			Id = "ShrineLevel7",
			DisplayName = "Rank VII",
		},
		{
			Id = "ShrineLevel8",
			DisplayName = "Rank VIII",
		},
		{
			Id = "ShrineLevel9",
			DisplayName = "Rank IX",
		},
		{
			Id = "ShrineLevel10",
			DisplayName = "Rank X",
		},
		{
			Id = "ShrineLevel11",
			DisplayName = "Rank XI",
		},
		{
			Id = "ShrineLevel12",
			DisplayName = "Rank XII",
		},
		{
			Id = "ShrineLevel13",
			DisplayName = "Rank XIII",
		},
	}

	function sjson_TraitText(sjsonData)
		local order = { 'Id', 'DisplayName' }
		for index, value in ipairs(extraRanks) do
			table.insert(sjsonData.Texts, sjson.to_object(value, order))
		end
	end


	if config.TestamentsChanges.VowOfAbandon.Enabled then
		ModUtil.Path.Wrap("EquipMetaUpgrades", function(base, hero, args)
			if GetNumShrineUpgrades("NoMetaUpgradesShrineUpgrade") >= 1 then
				EquipMetaUpgrades_wrap(hero, args)
			else
				base(hero, args)
			end
		end)

		ModUtil.Path.Wrap("GetCurrentMetaUpgradeCost", function(base)
			if GetNumShrineUpgrades("NoMetaUpgradesShrineUpgrade") >= 1 then
				return GetCurrentMetaUpgradeCost_wrap()
			else
				return base()
			end
		end)

		ModUtil.Path.Wrap("TraitTrayShowMetaUpgrades", function(base, screen, activeCategory, args)
			if GetNumShrineUpgrades("NoMetaUpgradesShrineUpgrade") >= 1 then
				TraitTrayShowMetaUpgrades_wrap(screen, activeCategory, args)
			else
				base(screen, activeCategory, args)
			end
		end)

		ModUtil.Path.Context.Wrap("CreateMetaUpgradeCard", function()
			ModUtil.Path.Wrap("UpdateMetaUpgradeCard", function(base, screen, row, column)
				if GetNumShrineUpgrades("NoMetaUpgradesShrineUpgrade") >= 1 then
					UpdateMetaUpgradeCard_wrap(screen, row, column)
				else
					base(screen, row, column)
				end
			end)
		end)
	end
end

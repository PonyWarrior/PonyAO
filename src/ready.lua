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

-- rom.inputs.on_key_pressed("None E", function() print("hi") end)

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
		if HeroHasTrait("LowHealthCritKeepsake") or GameState.LastAwardTrait == "LowHealthCritKeepsake" then
			ValidateMaxHealth_wrap(blockDelta)
		else

			base(blockDelta)
		end
	end)

	ModUtil.Path.Context.Wrap("KeepsakeScreenClose", function()
		ModUtil.Path.Wrap("UnequipKeepsake", function(base, heroUnit, traitName)
			base(heroUnit, traitName)
			if traitName == "LowHealthCritKeepsake" then
				ValidateMaxHealth_wrap()
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
				v.Cooldown = config.TorchImprovements.AttackSpeed
			end
		end
	end
end

if config.AxeSpecialUnlimitedBlock.Enabled then
	OverwriteTableKeys(WeaponData.WeaponAxeBlock2.ChargeWeaponStages[1], {
		ForceRelease = false,
	})
end

if config.StaffImprovements.Enabled then
	local weaponFile = rom.path.combine(rom.paths.Content, 'Game/Weapons/PlayerWeapons.sjson')

	sjson.hook(weaponFile, function(sjsonData)
		return sjson_StaffWeapon(sjsonData)
	end)

	function sjson_StaffWeapon(sjsonData)
		for _, v in ipairs(sjsonData.Weapons) do
			if v.Name == "WeaponStaffBall" then
				v.FireOnRelease = false
				v.OnlyChargeOnce = true
				v.CanCancelDisables = false
			elseif v.Name == "WeaponStaffSwing5" then
				v.FireOnRelease = true
				v.CancelChargeOnControlRemoved = false
				v.ChargeTime = config.StaffImprovements.OmegaAttackChargeSpeed
			end
		end
	end

	ModUtil.Path.Override("EmptyStaffCharge", function(weaponName, stageReached)
		if stageReached > 0 then
			local angle = GetAngle({ Id = CurrentRun.Hero.ObjectId })
			CreateProjectileFromUnit({ WeaponName = weaponName, Name = "ProjectileStaffBallCharged", Id = CurrentRun.Hero.ObjectId, DestinationId = CurrentRun.Hero.ObjectId, Angle = angle })
		end
	end)

	OverwriteTableKeys(WeaponData.WeaponStaffBall.ChargeWeaponStages[1], {
		WeaponProperties = {},
		ChannelSlowEventOnStart = false
	})
end

if config.SkullImprovements.Enabled then

	local gameplayFile = rom.path.combine(rom.paths.Content, 'Game/Obstacles/Gameplay.sjson')

	sjson.hook(gameplayFile, function(sjsonData)
		return sjson_SkullObstacle(sjsonData)
	end)

	function sjson_SkullObstacle(sjsonData)
		for _, v in ipairs(sjsonData.Obstacles) do
			if v.Name == "LobAmmoPack" then
				v.Magnetism = 500
			end
		end
	end

end

if config.CardChanges.Enabled then

	local textfile = rom.path.combine(rom.paths.Content, 'Game/Text/en/TraitText.en.sjson')

	if config.CardChanges.SwiftRunner.Enabled then
		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "SprintShield" or v.Id == "SprintShieldMetaUpgrade" then
					v.Description = "Your {$Keywords.Dash} gains {#UpgradeFormat}{$TooltipData.ExtractData.DashBonus} {#Prev} extra charge(s)."
				end
			end
		end)

		OverwriteTableKeys(TraitData.SprintShieldMetaUpgrade, {
			RarityLevels =
			{
				Common =
				{
					Multiplier = 1
				},
				Rare =
				{
					Multiplier = 1
				},
				Epic =
				{
					Multiplier = 1
				},
				Heroic =
				{
					Multiplier = 1
				},
			},
			PropertyChanges =
			{
				{
					WeaponNames = WeaponSets.HeroRushWeapons,
					WeaponProperty = "ClipSize",
					ChangeValue = 1,
					ChangeType = "Add",
					ReportValues = { ReportedDashBonus = "ChangeValue" },
				},
			},
			ExtractValues = {
				{
					Key = "ReportedDashBonus",
					ExtractAs = "DashBonus",
				},
			}
		})
	end

	if config.CardChanges.Messenger.Enabled then
		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "BonusDodge" or v.Id == "DodgeBonusMetaUpgrade" then
					v.Description = "You move and {$Keywords.Sprint} {#AltUpgradeFormat}{$TooltipData.ExtractData.TooltipSpeed}% {#Prev}faster."
				end
			end
		end)

		OverwriteTableKeys(TraitData.DodgeBonusMetaUpgrade, {
			RarityLevels =
			{
				Common =
				{
					Multiplier = 1
				},
				Rare =
				{
					Multiplier = 1.5
				},
				Epic =
				{
					Multiplier = 2.0
				},
				Heroic =
				{
					Multiplier = 2.5
				},
			},
			PropertyChanges =
			{
				{
					WeaponNames = { "WeaponSprint" },
					WeaponProperty = "SelfVelocity",
					BaseValue = 119,
					ChangeType = "Add",
					ExcludeLinked = true,
				},
				{
					WeaponNames = { "WeaponSprint" },
					WeaponProperty = "SelfVelocityCap",
					BaseValue = 53,
					ChangeType = "Add",
					ExcludeLinked = true,
				},
				{
					UnitProperty = "Speed",
					ChangeType = "Multiply",
					BaseValue = 1.06,
					SourceIsMultiplier = true,
					ReportValues = { ReportedBaseSpeed = "ChangeValue" },
				},
			},
			ExtractValues = {
				{
					Key = "ReportedBaseSpeed",
					ExtractAs = "TooltipSpeed",
					Format = "PercentDelta",
				},
			}
		})
	end

	if config.CardChanges.Night.Enabled then

		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "SorceryRegenUpgrade" or v.Id == "SorceryRegenMetaUpgrade" then
					v.Description = "You {$Keywords.HoldNoTooltip} your {$Keywords.Omega} {#AltUpgradeFormat}{$TooltipData.ExtractData.TooltipSpeed}% {#Prev}faster."
				end
			end
		end)

		local lookup = ToLookup({ "WeaponTorch", "WeaponTorchSpecial", "WeaponLob", "WeaponLobSpecial", "WeaponAxeBlock2", "WeaponAxeSpin", "WeaponCastArm", "WeaponStaffBall", "WeaponStaffSwing5", "WeaponDaggerThrow", "WeaponDagger5" })

		OverwriteTableKeys(TraitData.SorceryRegenMetaUpgrade, {
			SetupFunction = {},
			RarityLevels =
			{
				Common =
				{
					Multiplier = 1
				},
				Rare =
				{
					Multiplier = 1.67
				},
				Epic =
				{
					Multiplier = 2.33
				},
				Heroic =
				{
					Multiplier = 3.0
				},
			},
			PropertyChanges =
			{
				{
					WeaponNames = { "WeaponLobSpecial", "WeaponCastArm", "WeaponStaffBall", "WeaponStaffSwing5", "WeaponDaggerThrow", "WeaponDagger5" },
					ChangeValue = 0.90,
					SourceIsMultiplier = true,
					SpeedPropertyChanges = true,
				}
			},
			WeaponSpeedMultiplier =
			{
				WeaponNames = { "WeaponTorch", "WeaponTorchSpecial", "WeaponLob", "WeaponLobSpecial", "WeaponAxeBlock2", "WeaponAxeSpin", "WeaponCastArm", "WeaponStaffBall", "WeaponStaffSwing5", "WeaponDaggerThrow", "WeaponDagger5" },
				WeaponNamesLookup = lookup,
				Value =
				{
					BaseValue = 0.90,
					SourceIsMultiplier = true,
				},
				ReportValues = { ReportedWeaponMultiplier = "Value" }
			},
			ExtractValues =
			{
				{
					Key = "ReportedWeaponMultiplier",
					ExtractAs = "TooltipSpeed",
					Format = "NegativePercentDelta"
				},
			}
		})
	end

	if config.CardChanges.Unseen then
		OverwriteTableKeys(MetaUpgradeCardData.ManaOverTime, {
			Cost = 2
		})
	end

	if config.CardChanges.Death then

		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "MagicCrit" or v.Id == "MagicCritMetaUpgrade" then
					v.Description = "Your {$Keywords.Omega} deal {#UpgradeFormat}{$TooltipData.ExtractData.TooltipDamageBonus:P} {#Prev}damage."
				end
			end
		end)

		OverwriteTableKeys(TraitData.MagicCritMetaUpgrade, {
			AddOutgoingCritModifiers = {},
			RarityLevels =
			{
				Common =
				{
					Multiplier = 1
				},
				Rare =
				{
					Multiplier = 1.1
				},
				Epic =
				{
					Multiplier = 1.2,
				},
				Heroic =
				{
					Multiplier = 1.3,
				}
			},
			AddOutgoingDamageModifiers =
			{
				ValidWeapons = WeaponSets.HeroAllWeapons,
				ExMultiplier =
				{
					BaseValue = 1.15,
					SourceIsMultiplier = true,
				},
				ReportValues =
				{
					ReportedTotalDamageChange = "ExMultiplier",
				}
			},
			-- Display variable only! Match this with the above valid weapon multiplier!
			ReportedDamageChange =
			{
				BaseValue = 1.15,
				SourceIsMultiplier = true,
			},
			TrayStatLines =
			{
				"ChaosTotalExDamageStatDisplay1",
			},
			ExtractValues =
			{
				{
					Key = "ReportedTotalDamageChange",
					ExtractAs = "TooltipTotalDamageBonus",
					SkipAutoExtract = true,
					Format = "PercentDelta",
				},
				{
					Key = "ReportedDamageChange",
					ExtractAs = "TooltipDamageBonus",
					Format = "PercentDelta",
				},
			},
		})
	end

	if config.CardChanges.Artificer.Enabled then

		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "MetaToRunUpgrade" or v.Id == "MetaToRunMetaUpgrade" then
					v.Description = "Increases the {$Keywords.Rarity} of your {$Keywords.Keepsakes} by {#BoldFormatGraft}1 Rank {#Prev} ."
				end
			end
		end)

		OverwriteTableKeys(TraitData.MetaToRunMetaUpgrade, {
			MetaConversionUses = nil,
			ExtractValues = nil
		})

		ModUtil.Path.Wrap("EquipKeepsake", function(base, heroUnit, traitName, args)
			if HeroHasTrait("MetaToRunMetaUpgrade") then
				EquipKeepsake_wrap(heroUnit, traitName, args)
			else
				base(heroUnit, traitName, args)
			end
		end)
	end

end

if config.TestamentsChanges.Enabled then
	local textfile = rom.path.combine(rom.paths.Content, 'Game/Text/en/TraitText.en.sjson')

	sjson.hook(textfile, function(sjsonData)
		return sjson_TraitText2(sjsonData)
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

	function sjson_TraitText2(sjsonData)
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

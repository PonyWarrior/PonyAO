---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- here is where your mod sets up all the things it will do.
-- this file will not be reloaded if it changes during gameplay
-- 	so you will most likely want to have it reference
--	values and functions later defined in `reload.lua`.

local package = rom.path.combine(_PLUGIN.plugins_data_mod_folder_path, _PLUGIN.guid)
modutil.mod.Path.Wrap("SetupMap", function(base)
	LoadPackages({ Name = package })
	base()
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

--removed from the game
-- if config.AxeSpecialUnlimitedBlock.Enabled then
-- 	local weaponFile = rom.path.combine(rom.paths.Content, 'Game/Weapons/PlayerWeapons.sjson')

-- 	sjson.hook(weaponFile, function(sjsonData)
-- 		for _, v in ipairs(sjsonData.Weapons) do
-- 			if v.Name == "WeaponAxeBlock2" then
-- 				for key, value in pairs(v) do
-- 					if key ~= "Effects" then
-- 						v[key] = nil
-- 					end
-- 				end
-- 				v.Name = "WeaponAxeBlock2"
-- 				v.InheritFrom = "1_BaseDamagingWeapon"
-- 				v.Control = "Attack3"
-- 				v.Type = "GUN"
-- 				v.Projectile = "ProjectileAxeBlockSpin"
-- 				v.ClipSize = 1
-- 				v.ChargeSoundFadeTime = 0.25
-- 				v.FullyAutomatic = true
-- 				v.ChargeCancelMovement = true
-- 				v.CancelMovement = true
-- 				v.RootOwnerWhileFiring = true
-- 				v.BlockMoveInput = true
-- 				v.AutoLock = false
-- 				v.ChargeStartFx = "null"
-- 				v.ProjectileOffsetStart = "LEFT"
-- 				v.FireGraphic = "Melinoe_Axe_Special1_FireLoop"
-- 				v.FireOnRelease = false
-- 				v.TurboReleaseTimeRequireRelease = 0.2
-- 				v.OnlyChargeOnce = true
-- 				v.OnWeaponChargingSound = "/VO/MelinoeEmotes/EmoteCastingAlt"
-- 				v.OnWeaponChargingSoundChance = 1
-- 				v.ChargeTimeFrames = 6
-- 				v.Cooldown = 0.24
-- 				v.ChargeStartAnimation = "Melinoe_Axe_Special1_Start"
-- 				v.LockTriggerForCharge = true
-- 				v.TriggerReleaseGraphic = "Melinoe_Axe_Special1_End"
-- 				v.ChargeCancelGraphic = "null"
-- 				v.BarrelLength = 140
-- 				v.AllowExternalForceRelease = true
-- 				v.FailedToFireCooldownAnimation = "null"
-- 				v.FailedToFireCooldownDuration = 0.15
-- 				v.BlockedByAllOtherFireRequest = true
-- 			elseif v.Name == "WeaponAxeSpecialSwing" then
-- 				for key, value in pairs(v) do
-- 					if key ~= "Effects" then
-- 						v[key] = nil
-- 					end
-- 				end
-- 				v.Name = "WeaponAxeSpecialSwing"
-- 				v.InheritFrom = "1_BaseDamagingWeapon"
-- 				v.Control = "Attack3"
-- 				v.Type = "GUN"
-- 				v.Projectile = "ProjectileAxeBlock2"
-- 				v.ClipSize = 1
-- 				v.ChargeSoundFadeTime = 0.25
-- 				v.FullyAutomatic = true
-- 				v.ChargeCancelMovement = true
-- 				v.CancelMovement = true
-- 				v.RootOwnerWhileFiring = true
-- 				v.BlockMoveInput = true
-- 				v.AutoLock = false
-- 				v.ChargeStartFx = "null"
-- 				v.ProjectileOffsetStart = "LEFT"
-- 				v.FireGraphic = "Melinoe_Axe_SpecialEx1_Fire"
-- 				v.FireOnRelease = false
-- 				v.DefaultControl = false
-- 				v.OnlyChargeOnce = true
-- 				v.ChargeTime = 0.05
-- 				v.ChargeStartAnimation = "Melinoe_Axe_SpecialEx1_Start"
-- 				v.ChargeCancelGraphic = "null"
-- 				v.LockTriggerForCharge = true
-- 				v.TriggerReleaseGraphic = "null"
-- 				v.AllowExternalForceRelease = true
-- 				v.FailedToFireCooldownAnimation = "null"
-- 				v.FailedToFireCooldownDuration = 0.15
-- 				v.LoseControlIfNotCharging = true
-- 				v.ControlWindow = 0.25
-- 				v.PriorityFireRequest = true
-- 				v.SetCompleteAngleOnFire = true
-- 				v.FireAtAttackTarget = true
-- 				v.LockTriggerTransferFromOnSwap = false
-- 				v.RemoveControlOnCharge = "WeaponCast"
-- 				v.RemoveControlOnCharge2 = "WeaponAxeBlock2"
-- 				v.AddControlOnFire = "WeaponCast"
-- 				v.AddControlOnFire2 = "WeaponAxeBlock2"
-- 				v.AddControlOnChargeCancel = "WeaponCast"
-- 				v.AddControlOnChargeCancel2 = "WeaponAxeBlock2"
-- 				v.BarrelLength = 820
-- 				v.NumProjectiles = 3
-- 				v.ProjectileIntervalStart = 0.01
-- 				v.ProjectileInterval = 0.2
-- 				v.ProjectileSpacing = 460
-- 				v.ProjectileAngleOffset = 0
-- 				v.ProjectileAngleStartOffset = 90
-- 			end
-- 		end
-- 	end)

-- 	WeaponData.WeaponAxeBlock2 = {
-- 		Name = "WeaponAxeBlock2",
-- 		StartingWeapon = false,
-- 		ShowManaIndicator = true,
-- 		ExpireProjectilesOnFire = { "ProjectileAxeSpin" },
-- 		DoProjectileBlockPresentation = true,
-- 		OnChargeFunctionNames = { "DoWeaponCharge", "CheckAxeBlockThread" },
-- 		ChargeWeaponData =
-- 		{
-- 			EmptyChargeFunctionName = "EmptyAxeBlockCharge",
-- 			OnStageReachedFunctionName = "AxeBlockChargeStage",
-- 		},
-- 		ChargeWeaponStages =
-- 		{
-- 			{
-- 				ManaCost = 30,
-- 				Wait = 0.77,
-- 				SkipManaSpendOnFire = true,
-- 				DeferSwap = "WeaponAxeSpecialSwing",
-- 				ChannelSlowEventOnStart = true,
-- 				CompleteObjective = "WeaponAxeSpecialSwing",
-- 			},
-- 		},

-- 		DefaultKnockbackForce = 480,
-- 		DefaultKnockbackScale = 0.6,
-- 		HideChargeDuration = 0.45,
-- 		SkipAttackNotReadySounds = true,
-- 		NoControlSound = "/Leftovers/SFX/OutOfAmmo2",

-- 		Sounds =
-- 		{
-- 			FireSounds =
-- 			{
-- 				{ Name = "/SFX/Player Sounds/ZagreusFistWhoosh" },
-- 			},
-- 			ImpactSounds =
-- 			{
-- 				Invulnerable = "/SFX/Player Sounds/ZagreusShieldRicochet",
-- 				Armored = "/SFX/Player Sounds/ZagreusShieldRicochet",
-- 				Bone = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				Brick = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				Stone = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				Organic = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				StoneObstacle = "/SFX/SwordWallHitClankSmall",
-- 				BrickObstacle = "/SFX/SwordWallHitClankSmall",
-- 				MetalObstacle = "/SFX/SwordWallHitClankSmall",
-- 				BushObstacle = "/Leftovers/World Sounds/LeavesRustle",
-- 				Shell = "/SFX/ShellImpact",
-- 			},
-- 		},

-- 		Upgrades = {},
-- 	}

-- 	WeaponData.WeaponAxeSpecialSwing = {
-- 		Name = "WeaponAxeSpecialSwing",
-- 		StartingWeapon = false,
-- 		IsExWeapon = true,
-- 		OnChargeFunctionName = "SpendQueuedMana",

-- 		DefaultKnockbackForce = 960,
-- 		DefaultKnockbackScale = 1.2,

-- 		Sounds =
-- 		{
-- 			FireSounds =
-- 			{
-- 				{ Name = "/VO/MelinoeEmotes/EmotePoweringUp" },
-- 				{ Name = "/SFX/Player Sounds/ZagreusFistWhoosh" },
-- 			},
-- 			ImpactSounds =
-- 			{
-- 				Invulnerable = "/SFX/SwordWallHitClank",
-- 				Armored = "/SFX/Player Sounds/ZagreusShieldRicochet",
-- 				Bone = "/SFX/MetalBoneSmashSHIELD",
-- 				Brick = "/SFX/MetalStoneClangSHIELD",
-- 				Stone = "/SFX/MetalStoneClangSHIELD",
-- 				Organic = "/SFX/MetalOrganicHitSHIELD",
-- 				StoneObstacle = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				BrickObstacle = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				MetalObstacle = "/SFX/Player Sounds/ShieldObstacleHit",
-- 				BushObstacle = "/Leftovers/World Sounds/LeavesRustle",
-- 			},
-- 		},
-- 		OnFiredFunctionName = "RevertWeaponChanges",
-- 		Upgrades = {},
-- 	}

-- end

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
				v.ForceMaxChargeRelease = false
				v.CancelChargeOnControlRemoved = false
				v.ChargeTime = config.StaffImprovements.OmegaAttackChargeSpeed
			end
		end
	end

	local function GetCost()
		local manacost = GetManaCost(WeaponData["WeaponStaffBall"], false, { ManaCostOverride = WeaponData["WeaponStaffBall"].ChargeWeaponStages[1].ManaCost })
		print(manacost)
		return manacost
	end

	local function HasManaCost()
		local manacost = GetCost()
		if CurrentRun.Hero.Mana < manacost then
			return false
		end
		return true
	end

	ModUtil.Path.Override("EmptyStaffCharge", function(weaponName, stageReached)
		if stageReached > 0 then
			if HasManaCost() then
				ManaDelta(-GetCost())
			else
				return
			end
			local angle = GetAngle({ Id = CurrentRun.Hero.ObjectId })
			local playerLocation = GetLocation({ Id = CurrentRun.Hero.ObjectId })
			local startX = playerLocation.X
			local startY = playerLocation.Y
			local derivedValues = GetDerivedPropertyChangeValues({
				ProjectileName = "ProjectileStaffBallCharged",
				WeaponName = weaponName,
				Type = "Projectile",
			})
			local dropLocation = SpawnObstacle({ Name = "InvisibleTarget", LocationX = startX, LocationY = startY })
			CreateProjectileFromUnit({ WeaponName = weaponName, Name = "ProjectileStaffBallCharged", Id = CurrentRun.Hero.ObjectId, DestinationId = dropLocation, FireFromTarget = true, DataProperties = derivedValues.PropertyChanges, ThingProperties = derivedValues.ThingPropertyChanges, Angle = angle })
			if HeroHasTrait("StaffSelfHitAspect") then
				local triggerArgs = { ProjectileVolley = 1 }
				if SessionMapState.ProjectileChargeStageReached[triggerArgs.ProjectileVolley] == nil then
					SessionMapState.ProjectileChargeStageReached[triggerArgs.ProjectileVolley] = 1
				end
				local traitData = GetHeroTrait("StaffSelfHitAspect")
				local functionArgs = traitData.OnWeaponFiredFunctions.FunctionArgs
				local threadName = "RepeatSpecialThread"

				if HasThread(threadName) then
					killTaggedThreads(threadName)
					waitUnmodified(0.1)
					local id = SessionMapState.OriginMarkers.WeaponCast
					SessionMapState.OriginMarkers.WeaponCast = nil
					SetAnimation({ Name = functionArgs.ExpiringAnimationName, DestinationId = id })
					thread(DestroyOnDelay, { id }, functionArgs.DestroyDelay)
					id = SessionMapState.OriginMarkers.WeaponStaffBall
					SessionMapState.OriginMarkers.WeaponStaffBall = nil
					SetAnimation({ Name = functionArgs.ExpiringAnimationName, DestinationId = id })
					thread(DestroyOnDelay, { id }, functionArgs.DestroyDelay)
				end
				thread(StartSpecialRepeatThread, startX, startY, GetAngle({ Id = CurrentRun.Hero.ObjectId }), functionArgs, triggerArgs)

				local zOffset = 90
				local originMarkerId = SpawnObstacle({ Name = "BlankObstacle", Group = "FX_Standing", LocationX = startX, LocationY = startY, OffsetZ = zOffset })
				SetAnimation({ Name = functionArgs.AnimationName, DestinationId = originMarkerId })
				SessionMapState.OriginMarkers[weaponName] = originMarkerId
			end
		end
	end)

	OverwriteTableKeys(TraitData.StaffRaiseDeadAspect.WeaponDataOverride.WeaponStaffBall.ChargeWeaponStages[1], {
		WeaponProperties = {},
		ProjectileProperties = {},
		ChannelSlowEventOnStart = false
	})
	table.insert(TraitData.StaffRaiseDeadAspect.PropertyChanges, {
		WeaponName = "WeaponStaffBall",
		ProjectileName = "ProjectileStaffBallCharged",
		ProjectileProperty = "DamageRadius",
		ChangeValue = 435,
		ChangeType = "Absolute",
	})
	table.insert(TraitData.StaffRaiseDeadAspect.PropertyChanges, {
		WeaponName = "WeaponStaffBall",
		ProjectileName = "ProjectileStaffBallCharged",
		ProjectileProperty = "Damage",
		ChangeValue = 110,
		ChangeType = "Absolute",
	})

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
				if v.Id == "SprintShield" or v.Id == "SprintShieldMetaUpgrade_Tray" then
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
			},
			OnSprintStartAction = 
			{
				FunctionName = "",
				Args =
				{
				}
			},
			
			OnSprintEndAction =
			{
				FunctionName = "",
			},
			OnBlinkEndAction =
			{
				FunctionName = "",
				FunctionArgs = {},
			},
		})
	end

	-- if config.CardChanges.Messenger.Enabled then
	-- 	sjson.hook(textfile, function(sjsonData)
	-- 		for _, v in ipairs(sjsonData.Texts) do
	-- 			if v.Id == "BonusDodge" or v.Id == "DodgeBonusMetaUpgrade" then
	-- 				v.Description = "You move and {$Keywords.Sprint} {#AltUpgradeFormat}{$TooltipData.ExtractData.TooltipSpeed}% {#Prev}faster."
	-- 			end
	-- 		end
	-- 	end)

	-- 	OverwriteTableKeys(TraitData.DodgeBonusMetaUpgrade, {
	-- 		RarityLevels =
	-- 		{
	-- 			Common =
	-- 			{
	-- 				Multiplier = 1
	-- 			},
	-- 			Rare =
	-- 			{
	-- 				Multiplier = 1.5
	-- 			},
	-- 			Epic =
	-- 			{
	-- 				Multiplier = 2.0
	-- 			},
	-- 			Heroic =
	-- 			{
	-- 				Multiplier = 2.5
	-- 			},
	-- 		},
	-- 		PropertyChanges =
	-- 		{
	-- 			{
	-- 				WeaponNames = { "WeaponSprint" },
	-- 				WeaponProperty = "SelfVelocity",
	-- 				BaseValue = 119,
	-- 				ChangeType = "Add",
	-- 				ExcludeLinked = true,
	-- 			},
	-- 			{
	-- 				WeaponNames = { "WeaponSprint" },
	-- 				WeaponProperty = "SelfVelocityCap",
	-- 				BaseValue = 53,
	-- 				ChangeType = "Add",
	-- 				ExcludeLinked = true,
	-- 			},
	-- 			{
	-- 				UnitProperty = "Speed",
	-- 				ChangeType = "Multiply",
	-- 				BaseValue = 1.06,
	-- 				SourceIsMultiplier = true,
	-- 				ReportValues = { ReportedBaseSpeed = "ChangeValue" },
	-- 			},
	-- 		},
	-- 		ExtractValues = {
	-- 			{
	-- 				Key = "ReportedBaseSpeed",
	-- 				ExtractAs = "TooltipSpeed",
	-- 				Format = "PercentDelta",
	-- 			},
	-- 		}
	-- 	})
	-- end

	-- if config.CardChanges.Night.Enabled then

	-- 	sjson.hook(textfile, function(sjsonData)
	-- 		for _, v in ipairs(sjsonData.Texts) do
	-- 			if v.Id == "MagicCrit" or v.Id == "MagicCritMetaUpgrade_Tray" then
	-- 				v.Description = "You {$Keywords.HoldNoTooltip} your {$Keywords.Omega} {#AltUpgradeFormat}{$TooltipData.ExtractData.TooltipSpeed}% {#Prev}faster."
	-- 			end
	-- 		end
	-- 	end)

	-- 	local lookup = ToLookup({ "WeaponTorch", "WeaponTorchSpecial", "WeaponLob", "WeaponLobSpecial", "WeaponAxeBlock2", "WeaponAxeSpin", "WeaponCastArm", "WeaponStaffBall", "WeaponStaffSwing5", "WeaponDaggerThrow", "WeaponDagger5" })

	-- 	OverwriteTableKeys(TraitData.MagicCritMetaUpgrade, {
	-- 		SetupFunction = {},
	-- 		RarityLevels =
	-- 		{
	-- 			Common =
	-- 			{
	-- 				Multiplier = 1
	-- 			},
	-- 			Rare =
	-- 			{
	-- 				Multiplier = 1.67
	-- 			},
	-- 			Epic =
	-- 			{
	-- 				Multiplier = 2.33
	-- 			},
	-- 			Heroic =
	-- 			{
	-- 				Multiplier = 3.0
	-- 			},
	-- 		},
	-- 		PropertyChanges =
	-- 		{
	-- 			{
	-- 				WeaponNames = { "WeaponLobSpecial", "WeaponCastArm", "WeaponStaffBall", "WeaponStaffSwing5", "WeaponDaggerThrow", "WeaponDagger5" },
	-- 				ChangeValue = 0.90,
	-- 				SourceIsMultiplier = true,
	-- 				SpeedPropertyChanges = true,
	-- 			}
	-- 		},
	-- 		WeaponSpeedMultiplier =
	-- 		{
	-- 			WeaponNames = { "WeaponTorch", "WeaponTorchSpecial", "WeaponLob", "WeaponLobSpecial", "WeaponAxeBlock2", "WeaponAxeSpin", "WeaponCastArm", "WeaponStaffBall", "WeaponStaffSwing5", "WeaponDaggerThrow", "WeaponDagger5" },
	-- 			WeaponNamesLookup = lookup,
	-- 			Value =
	-- 			{
	-- 				BaseValue = 0.90,
	-- 				SourceIsMultiplier = true,
	-- 			},
	-- 			ReportValues = { ReportedWeaponMultiplier = "Value" }
	-- 		},
	-- 		ExtractValues =
	-- 		{
	-- 			{
	-- 				Key = "ReportedWeaponMultiplier",
	-- 				ExtractAs = "TooltipSpeed",
	-- 				Format = "NegativePercentDelta"
	-- 			},
	-- 		},
	-- 		AddOutgoingCritModifiers =
	-- 		{
	-- 			IsEx = true,
	-- 			DifferentOmegaChance = {},
	-- 			ReportValues = {}
	-- 		},
	-- 		OnProjectileDeathFunction =
	-- 		{
	-- 			Name = "",
	-- 		},
	-- 		OnWeaponFiredFunctions =
	-- 		{
	-- 			ValidWeapons = WeaponSets.HeroAllWeaponsAndSprint,
	-- 			FunctionName = "",
	-- 		},
	-- 	})
	-- end

	-- if config.CardChanges.Unseen then
	-- 	OverwriteTableKeys(MetaUpgradeCardData.ManaOverTime, {
	-- 		Cost = 3
	-- 	})
	-- end

	if config.CardChanges.Night then

		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "MagicCrit" or v.Id == "MagicCritMetaUpgrade_Tray" then
					v.Description = "Your {$Keywords.Omega} deal {#UpgradeFormat}{$TooltipData.ExtractData.TooltipDamageBonus:P} {#Prev}damage."
				end
			end
		end)

		OverwriteTableKeys(TraitData.MagicCritMetaUpgrade, {
			RarityLevels =
			{
				Common =
				{
					Multiplier = 1
				},
				Rare =
				{
					Multiplier = 1.8
				},
				Epic =
				{
					Multiplier = 2.54,
				},
				Heroic =
				{
					Multiplier = 3.34,
				}
			},
			AddOutgoingDamageModifiers =
			{
				ValidWeapons = WeaponSets.HeroAllWeaponsAndSprint,
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
			AddOutgoingCritModifiers =
			{
				IsEx = true,
				DifferentOmegaChance = {},
				ReportValues = {}
			},
			OnProjectileDeathFunction =
			{
				Name = "",
			},
			OnWeaponFiredFunctions =
			{
				ValidWeapons = WeaponSets.HeroAllWeaponsAndSprint,
				FunctionName = "",
			},
		})
	end

	if config.CardChanges.Enabled and config.CardChanges.Artificer.Enabled then
		function IsArtificerEquipped()
			if GetNumShrineUpgrades("LimitGraspShrineUpgrade") >= 1 then
				return false
			end
			for metaUpgradeName, metaUpgradeData in pairs(GameState.MetaUpgradeState) do
				if metaUpgradeName == "MetaToRunUpgrade" and MetaUpgradeCardData[metaUpgradeName] and metaUpgradeData.Equipped and MetaUpgradeCardData[metaUpgradeName].TraitName then
					return true
				end
			end
			return false
		end

		function IsArtificerUpgradeValid(traitName)
			local trait = TraitData[traitName]
			if trait.RarityLevels == nil or trait.RarityLevels.Heroic == nil then
				return false
			end
			return true
		end

		sjson.hook(textfile, function(sjsonData)
			for _, v in ipairs(sjsonData.Texts) do
				if v.Id == "MetaToRunUpgrade" or v.Id == "MetaToRunMetaUpgrade_Tray" then
					v.Description = "Increases the {$Keywords.Rarity} of your {$Keywords.Keepsakes} by {#BoldFormatGraft}1 Rank {#Prev} ."
				end
			end
		end)

		OverwriteTableKeys(TraitData.MetaToRunMetaUpgrade, {
			MetaConversionUses = nil,
			ExtractValues = nil
		})

		ModUtil.Path.Wrap("EquipKeepsake", function(base, heroUnit, traitName, args)
			if IsArtificerEquipped() and traitName ~= nil and IsArtificerUpgradeValid(traitName) then
				EquipKeepsake_wrap(heroUnit, traitName, args)
			elseif IsArtificerEquipped() then
				print("Equipped keepsake can't be upgraded by artificer!")
				base(heroUnit, traitName, args)
			else
				base(heroUnit, traitName, args)
			end
		end)

		ModUtil.LoadOnce(function()
			table.insert(TraitData.KeepsakeLevelBoon.GameStateRequirements,
				{
					PathFalse = { "CurrentRun", "Hero", "TraitDictionary", "MetaToRunMetaUpgrade" },
				})
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

	--fix vow pips on testament screen
	ModUtil.Path.Override("OpenShrineScreen", function(args)
		OpenShrineScreen_override(args)
	end)

	if config.TestamentsChanges.VowOfVoid.Enabled then
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

if config.PolyphemusJump.Enabled then
	local projectileFile = rom.path.combine(rom.paths.Content, 'Game/Projectiles/Enemy_BiomeN_Projectiles.sjson')

	sjson.hook(projectileFile, function(sjsonData)
		for _, v in ipairs(sjsonData.Projectiles) do
			if v.Name == "PolyphemusLeapKnockback" then
				v.Damage = config.PolyphemusJump.DamageValue
				if config.PolyphemusJump.EnableStun then
					for _, value in ipairs(v.Effects) do
						if value.Name == "HeroOnHitStun" then
							value.Duration = config.PolyphemusJump.StunDuration
							value.FrontFx = "DionysusStunnedFx"
							value.Cancelable = false
						end
					end
				end
			end
		end
	end)
end

if config.TroveChanges.Enabled then
	if config.TroveChanges.EqualWeight.Enabled then
		EncounterSets.TimeChallengeOptions = {
			"TimeChallengeSwitch_Money",
			--"MoneyTimeChallengeSwitch2",
			--"MoneyTimeChallengeSwitch3",

			--"HealthTimeChallengeSwitch",
			--"HealthTimeChallengeSwitch2",
			--"HealthTimeChallengeSwitch3",

			--"MetaCurrencyTimeChallengeSwitch",
			--"MetaCurrencyTimeChallengeSwitch2",
			--"MetaCurrencyTimeChallengeSwitch3",
		}
	end
	if config.TroveChanges.DisableDecay.Enabled then
		ObstacleData.ChallengeSwitch.UseLootDecay = false
	end
	if config.TroveChanges.EnableHealthTroves.Enabled then
		--TODO BROKEN
		-- for index, req in ipairs(ObstacleData.ChallengeSwitch.Requirements) do
		-- 	if req.PathTrue and Contains(req.PathTrue, "TimeChallenge") then
		-- 		ObstacleData.ChallengeSwitch.Requirements[index] = {
		-- 			Path = { "GameState", "EncountersCompletedCache" },
		-- 			HasAny = { "TimeChallengeF", "TimeChallengeG", "TimeChallengeI", "TimeChallengeO" }
		-- 		}
		-- 	end
		-- end
	end
	if config.TroveChanges.EnableBoneTroves then
		--TODO BROKEN
		-- for index, req in ipairs(ObstacleData.MetaCurrencyTimeChallengeSwitch.Requirements) do
		-- 	if req.PathTrue and Contains(req.PathTrue, "TimeChallenge") then
		-- 		ObstacleData.MetaCurrencyTimeChallengeSwitch.Requirements[index] = {
		-- 			Path = { "GameState", "EncountersCompletedCache" },
		-- 			HasAny = { "TimeChallengeF", "TimeChallengeG", "TimeChallengeI", "TimeChallengeO" }
		-- 		}
		-- 	end
		-- end
	end
end

if config.EchoKeepsakeChange.Enabled then

	local textfile = rom.path.combine(rom.paths.Content, 'Game/Text/en/TraitText.en.sjson')

	sjson.hook(textfile, function(sjsonData)
		for _, v in ipairs(sjsonData.Texts) do
			if v.Id == "UnpickedBoonKeepsake" then
				v.Description = "After choosing a {$Keywords.GodBoon}, {#AltUpgradeFormat}{$TooltipData.ExtractData.Chance}% {#Prev}of the time create a copy, {#BoldFormatGraft}{$TooltipData.ExtractData.Uses} {#Prev} time(s) this night."
			end
		end
	end)

	OverwriteTableKeys(TraitData.UnpickedBoonKeepsake, {
		DoubleBoonChance = 0.25,
		Uses = { BaseValue = 1 },
		ExtractValues =
		{
			{
				Key = "DoubleBoonChance",
				ExtractAs = "Chance",
				Format = "Percent",
			},
			{
				Key = "Uses",
				ExtractAs = "Uses",
			},
		},
	})

	ModUtil.Path.Wrap("HandleUpgradeChoiceSelection", function(base, screen, button, args)
		if HasHeroTraitValue("DoubleBoonChance") then
			HandleUpgradeChoiceSelection_wrap(screen, button, args)
		else
			base(screen, button, args)
		end
	end)
end

if config.EphyraOverhaul.Enabled then
	ModUtil.Path.Override("ChooseAvailableN_HubDoors", function(room, args)
		if room.DoorsChosen then
			return
		end
		local roomData = RoomData[room.Name] or room
		local doorIds = GetAllKeys(roomData.PredeterminedDoorRooms)

		CurrentRun.PylonRooms = {}
		local pylonCount = 0

		for doorId, roomName in pairs(roomData.PredeterminedDoorRooms) do
			if not IsGameStateEligible(CurrentRun, RoomData[roomName], RoomData[roomName].GameStateRequirements) then
				doorIds[doorId] = nil
				room.UnavailableDoors[doorId] = true
			elseif pylonCount < 6 then
				CurrentRun.PylonRooms[roomName] = true
				pylonCount = pylonCount + 1
			end
		end

		-- Remove all doors which dont have a room assigned yet
		local allDoors = GetIdsByType({ Names = args.Types })
		for k, doorId in pairs(allDoors) do
			if not Contains(doorIds, doorId) then
				room.UnavailableDoors[doorId] = true
			end
		end

		room.DoorsChosen = true
	end)

	RoomData.BaseN.ForcedRewardStore = "HubRewards"
	RoomData.N_CombatData.ForcedRewardStore = "HubRewards"
	RoomData.N_MiniBoss01.ForcedRewardStore = "HubRewards"

	-- ObstacleData.EphyraExitDoor.LockWhenEphyraBossExitReady = false

	RewardStoreData.HubRewards = {
		{
			Name = "MaxHealthDrop",
		},
		{
			Name = "MaxManaDrop",
		},
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		-- extra boons
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		{
			Name = "Boon",
			AllowDuplicates = true
		},
		{
			Name = "Devotion",
			GameStateRequirements =
			{
				{
					PathTrue = { "GameState", "TextLinesRecord", "PoseidonDevotionIntro01" },
				},
			}
		},
		{
			Name = "RoomMoneyDrop",
		},
		{
			Name = "ElementalBoost",
			AllowDuplicates = true
		},
		{
			Name = "GiftDrop",
		},
		{
			Name = "MetaCurrencyDrop",
		},
		{
			Name = "MetaCardPointsCommonDrop",
		},
		{
			Name = "MemPointsCommonDrop",
		},
		{
			Name = "WeaponUpgrade",
			GameStateRequirements =
			{
				NamedRequirements = { "HammerLootRequirements" },
			}
		},
		{
			Name = "HermesUpgrade",
			GameStateRequirements =
			{
				-- rule 0: only unlock at this point
				{
					PathTrue = { "GameState", "RoomCountCache", "G_Boss01" },
				},
				{
					Path = { "GameState", "TextLinesRecord" },
					HasAll = { "HermesFirstPickUp", "PoseidonLegacyBoonIntro01" },
				},
				-- rule 1: have x or fewer of this specific upgrade in a Biome
				{
					Path = { "CurrentRun", "LootBiomeRecord" },
					SumOf = { "HermesUpgrade" },
					Comparison = "<=",
					Value = 0,
				},
				-- rule 2: have y or fewer of the non-Boon power set
				{
					Path = { "CurrentRun", "LootBiomeRecord" },
					SumOf = { "WeaponUpgrade", "HermesUpgrade" },
					Comparison = "<=",
					Value = 1,
				},
				-- rule 3: only drop up to z per run
				{
					Path = { "CurrentRun", "LootTypeHistory", "HermesUpgrade" },
					Comparison = "<=",
					Value = 2,
				},

			}
		},
		{
			Name = "SpellDrop",
			GameStateRequirements =
			{
				RequiredNotInStore = "SpellDrop",
				RequiredFalseRewardType = "SpellDrop",
				{
					PathFalse = { "CurrentRun", "UseRecord", "SpellDrop" },
				},
				{
					Path = { "GameState", "TextLinesRecord" },
					HasAll = { "ArtemisFirstMeeting", "SeleneFirstPickUp" },
				},
			},
		},
	}

	ConsumableData.ElementalBoost.DoorIcon = "ElementalEssenceDrop"

	ModUtil.Path.Override("SpawnSoulPylon", function(room, args)
		if GetConfigOptionValue({ Name = "EditingMode" }) then
			return
		end

		--MOD START
		EphyraScalingDifficulty()
		if not CurrentRun.PylonRooms[room.Name] then
			return
		end
		--MOD END

		args = args or {}
		local spawnName = args.SpawnName or "SoulPylon"

		local pylonId = SpawnUnit({ Name = spawnName, Group = "Standing", DestinationId = GetRandomValue(GetIds({ Name = "SoulPylonSpawnPoints"}) or GetIds({Name = "SpawnPoints"})) })
		local pylon = DeepCopyTable( EnemyData[spawnName] )
		pylon.ObjectId = pylonId
		thread(SetupUnit, pylon, CurrentRun)
	end)

	function EphyraScalingDifficulty()
		if CurrentRun.CurrentRoom.ReinforcementsSpawned then
			return
		else
			CurrentRun.CurrentRoom.ReinforcementsSpawned = true
		end
		if not CurrentRun.EphyraRoomCount then
			CurrentRun.EphyraRoomCount = 1
		else
			CurrentRun.EphyraRoomCount = CurrentRun.EphyraRoomCount + 1
		end

		if CurrentRun.EphyraRoomCount > 6 then
			local count = CurrentRun.EphyraRoomCount - 6
			thread(SpawnEphyraReinforcements, count)
		end
	end

	local enemyWave1 = {
		"TimeElemental",
		"TimeElemental_Elite",
		"TimeElemental_Elite",
	}

	local enemyWave2 = {
		"TimeElemental",
		"TimeElemental_Elite",
		"TimeElemental_Elite",
		"GoldElemental",
		"GoldElemental_Elite",
		"GoldElemental_Elite",
	}

	local enemyWave3 = {
		"TimeElemental",
		"TimeElemental_Elite",
		"TimeElemental_Elite",
		"GoldElemental",
		"GoldElemental_Elite",
		"GoldElemental_Elite",
		"SatyrRatCatcher_Elite",
	}

	local enemyWave4 = {
		"TimeElemental_Elite",
		"TimeElemental_Elite",
		"GoldElemental_Elite",
		"GoldElemental_Elite",
		"SatyrLancer_Elite",
		"SatyrRatCatcher_Elite",
	}

	function SpawnEphyraReinforcements(count)
		local args = {
			Name = "",
			Active = true,
		}
		wait(3)
		if count <= 2 then
			for _, value in ipairs(enemyWave1) do
				args.Name = value
				DebugSpawnEnemy(nil, args)
			end
		elseif count <= 4 then
			for _, value in ipairs(enemyWave2) do
				args.Name = value
				DebugSpawnEnemy(nil, args)
			end
		elseif count <= 6 then
			for _, value in ipairs(enemyWave3) do
				args.Name = value
				DebugSpawnEnemy(nil, args)
			end
		else
			for _, value in ipairs(enemyWave4) do
				args.Name = value
				DebugSpawnEnemy(nil, args)
				DebugSpawnEnemy(nil, args)
			end
		end
	end

	-- Add nil check for EliteAttributes
	ModUtil.Path.Override("CalculateEnemyDifficultyRating", function(enemyName, room)
		local difficultyRating = EnemyData[enemyName].GeneratorData.DifficultyRating

		if EnemyData[enemyName].IsElite and room.EliteAttributes ~= nil and room.EliteAttributes[enemyName] ~= nil then
			local difficultyRatingMultiplier = 1
			for k, attributeName in pairs(room.EliteAttributes[enemyName]) do
				if EnemyData[enemyName].EliteAttributeData[attributeName].DifficultyRatingMultiplier ~= nil then
					difficultyRatingMultiplier = difficultyRatingMultiplier + EnemyData[enemyName].EliteAttributeData[attributeName].DifficultyRatingMultiplier - 1
				end
			end
			difficultyRating = difficultyRating * difficultyRatingMultiplier
		end

		return difficultyRating
	end)
end

if config.ExtraLastStandsFirst.Enabled then
	ModUtil.Path.Override("CheckLastStand", function(victim, triggerArgs)
		CheckLastStand_override(victim, triggerArgs)
	end)
end

-- if config.ExcludeHeroic.Enabled then
-- 	ModUtil.Path.Context.Wrap("HeroicDowngradeBoons", function()
-- 		ModUtil.Path.Wrap("IsGodTrait", function(base, traitName, args)
-- 			local bool = base(traitName, args)
-- 			if bool then
-- 				local traitData = GetHeroTrait(traitName)
-- 				if traitData and traitData.Rarity and traitData.Rarity == "Heroic" then
-- 					return false
-- 				end
-- 			end
-- 			return bool
-- 		end)
-- 	end)
-- end

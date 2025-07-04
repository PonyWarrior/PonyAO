---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

if config.TranquilGainRework.Enabled then
	import 'Data/TraitData_Demeter.lua'
	function mod.DemeterRegenSetup(hero, args)
		thread(ManaRegen)
	end

	function DemeterRegen()
		local regenTrait = nil
		for i, traitData in pairs(CurrentRun.Hero.Traits) do
			if traitData.Name == "DemeterManaBoon" then
				regenTrait = traitData
			end
		end
		if not regenTrait or HasThread("DemeterRegen") then
			return
		end
		if (CurrentRun.Hero.Mana / CurrentRun.Hero.MaxMana) > 0.1 then
			return
		end
		if CurrentRun.CurrentRoom.DemeterRegenProcTimes == nil then
			CurrentRun.CurrentRoom.DemeterRegenProcTimes = 1
		else
			CurrentRun.CurrentRoom.DemeterRegenProcTimes = CurrentRun.CurrentRoom.DemeterRegenProcTimes + 1
		end
		local traitArgs = regenTrait.SetupFunction.Args
		local delay = traitArgs.RegenPenaltyDuration + ((CurrentRun.CurrentRoom.DemeterRegenProcTimes - 1) * traitArgs.DelayIncreaseDuration)
		CreateAnimation({ Name = traitArgs.ManaRegenStartFx, DestinationId = CurrentRun.Hero.ObjectId, OffsetX = 0, Scale = 10 })
		PlaySound({ Name = traitArgs.ManaRegenStartSound, Id = CurrentRun.Hero.ObjectId })
		wait(delay, "DemeterRegen")
		RefillMana()
	end

	function DamagePresentation_wrap(victim, args)
		if victim == CurrentRun.Hero and HeroHasTrait("DemeterManaBoon") then
			killTaggedThreads("DemeterRegen")
			thread(DemeterRegen)
		end
	end

	function ManaDelta_wrap()
		if HeroHasTrait("DemeterManaBoon") then
			thread(DemeterRegen)
		end
	end
end

if config.WhiteAntlerHealthCap.Enabled then
	import 'Data/TraitData_Keepsake.lua'
	function mod.WhiteAntlerSetup()
		ValidateMaxHealth_wrap()
	end

	function ValidateMaxHealth_wrap(blockDelta)
		-- todo : make max health rewards that heal work
		local expectedMaxHealth = HeroData.MaxHealth
		expectedMaxHealth = math.max(1, round(expectedMaxHealth * GetTotalHeroTraitValue("MaxHealthMultiplier", { IsMultiplier = true })))
		if expectedMaxHealth ~= CurrentRun.Hero.MaxHealth then
			local delta = expectedMaxHealth - CurrentRun.Hero.MaxHealth
			local newMaxHealth = math.max(1, round(CurrentRun.Hero.MaxHealth + delta))
			if newMaxHealth > 30 then
				newMaxHealth = 30
			end
			CurrentRun.Hero.MaxHealth = newMaxHealth
			if not blockDelta then
				CurrentRun.Hero.Health = round(CurrentRun.Hero.Health + delta)
			end
		end
		if CurrentRun.Hero.MaxHealth > 30 then
			CurrentRun.Hero.MaxHealth = 30
		end
		if CurrentRun.Hero.Health > 30 then
			CurrentRun.Hero.Health = 30
		end
		CurrentRun.Hero.Health = math.max(1, math.min(CurrentRun.Hero.Health, CurrentRun.Hero.MaxHealth))
	end
end

if config.CardChanges.Enabled then
	if config.CardChanges.Artificer.Enabled then
		function EquipKeepsake_wrap(heroUnit, traitName, args)
			local unit = heroUnit or CurrentRun.Hero
			traitName = traitName or GameState.LastAwardTrait
			if traitName == nil or HeroHasTrait(traitName) then
				UnequipKeepsake(CurrentRun.Hero, traitName)
			end

			local rarity = GetRarityKey(GetKeepsakeLevel(traitName))
			rarity = GetUpgradedRarity(rarity)

			local traitData = AddTrait(unit, traitName, rarity, args)
			if not CurrentRun.Hero.IsDead then
				CurrentRun.TraitCache[traitName] = CurrentRun.TraitCache[traitName] or 1
			end

			if traitName == "DecayingBoostKeepsake" then
				traitData.CurrentKeepsakeDamageBonus = traitData.InitialKeepsakeDamageBonus
			end
			if traitName == "ReincarnationKeepsake" then
				AddLastStand({
					Name = "ReincarnationKeepsake",
					ExpiresKeepsake = "ReincarnationKeepsake",
					InsertAtEnd = true,
					IncreaseMax = true,
					Icon = "ExtraLifeSkelly",
					HealAmount = GetTotalHeroTraitValue("KeepsakeLastStandHealAmount"),
				})
				RecreateLifePips()
			end
		end
	end

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
end

if config.TestamentsChanges.Enabled then
	-- Extra ranks text
	OverwriteTableKeys(TraitRarityData.ShrineRarityText, {
		[0] = "ShrineLevel0",
		"ShrineLevel1",
		"ShrineLevel2",
		"ShrineLevel3",
		"ShrineLevel4",
		"ShrineLevel5",
		"ShrineLevel6",
		"ShrineLevel7",
		"ShrineLevel8",
		"ShrineLevel9",
		"ShrineLevel10",
		"ShrineLevel11",
		"ShrineLevel12",
		"ShrineLevel13",
		"ShrineLevel5",
	})
	if config.TestamentsChanges.VowOfVoid.Enabled then
		OverwriteTableKeys(MetaUpgradeData.LimitGraspShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 20 },
			{ Points = 1, ChangeValue = 40 },
			{ Points = 1, ChangeValue = 60 },
			{ Points = 1, ChangeValue = 80 },
			{ Points = 1, ChangeValue = 100 },
		})
	
		function EquipMetaUpgrades_wrap(hero, args)
			local skipTraitHighlight = args.SkipTraitHighlight or false
			local ranks = GetNumShrineUpgrades("LimitGraspShrineUpgrade")
	
			for metaUpgradeName, metaUpgradeData in pairs(GameState.MetaUpgradeState) do
				if IsMetaupgradeDisabled(metaUpgradeName, ranks) then
					GameState.MetaUpgradeState[metaUpgradeName].Equipped = nil
				elseif MetaUpgradeCardData[metaUpgradeName] and metaUpgradeData.Equipped and MetaUpgradeCardData[metaUpgradeName].TraitName and not HeroHasTrait(MetaUpgradeCardData[metaUpgradeName].TraitName) then
					local cardMultiplier = 1
					if GameState.MetaUpgradeState[metaUpgradeName].AdjacencyBonuses and GameState.MetaUpgradeState[metaUpgradeName].AdjacencyBonuses.CustomMultiplier then
						cardMultiplier = cardMultiplier + GameState.MetaUpgradeState[metaUpgradeName].AdjacencyBonuses.CustomMultiplier
					end
					AddTraitToHero({
						SkipNewTraitHighlight = skipTraitHighlight,
						TraitName = MetaUpgradeCardData[metaUpgradeName].TraitName,
						Rarity = TraitRarityData.RarityUpgradeOrder[GetMetaUpgradeLevel(metaUpgradeName)],
						CustomMultiplier = cardMultiplier,
						SourceName = metaUpgradeName,
					})
				end
			end
		end
	
		function GetCurrentMetaUpgradeCost_wrap()
			local totalCost = 0
			local ranks = GetNumShrineUpgrades("LimitGraspShrineUpgrade")
	
			for metaUpgradeName, metaUpgradeData in pairs(GameState.MetaUpgradeState) do
				if MetaUpgradeCardData[metaUpgradeName] and MetaUpgradeCardData[metaUpgradeName].Cost and metaUpgradeData.Equipped then
					if IsMetaupgradeDisabled(metaUpgradeName, ranks) then
						GameState.MetaUpgradeState[metaUpgradeName].Equipped = nil
					else
						totalCost = MetaUpgradeCardData[metaUpgradeName].Cost + totalCost
					end
				end
			end
	
			GameState.MetaUpgradeCostCache = totalCost
			return totalCost
		end
	
		function TraitTrayShowMetaUpgrades_wrap(screen, activeCategory, args)
			local ranks = GetNumShrineUpgrades("LimitGraspShrineUpgrade")
			local equippedMetaUpgradesNum = 0
			for k, upgrade in pairs(GameState.MetaUpgradeState) do
				if upgrade.Equipped then
					equippedMetaUpgradesNum = equippedMetaUpgradesNum + 1
				end
			end
	
			local traitSpacingX = activeCategory.TraitSpacingX or screen.TraitSpacingX
			if equippedMetaUpgradesNum >= activeCategory.TraitsNeededForExtendedSpacing then
				traitSpacingX = activeCategory.ExtendedTraitSpacingX
			end
	
			local components = screen.Components
			local firstTrait = nil
			local highlightedTrait = nil
			local displayedTraitNum = 0
			local xOffset = activeCategory.TraitStartX or screen.TraitStartX
			local yOffset = ScreenHeight - (activeCategory.TraitStartBottomOffset or screen.TraitStartBottomOffset)
			--for metaUpgradeName, metaUpgradeState in pairs( GameState.MetaUpgradeState ) do
			for rowIndex, row in ipairs(MetaUpgradeDefaultCardLayout) do
				for colIndex, metaUpgradeName in ipairs(row) do
					local metaUpgradeState = GameState.MetaUpgradeState[metaUpgradeName]
					if metaUpgradeState ~= nil and metaUpgradeState.Equipped and not IsMetaupgradeDisabled(metaUpgradeName, ranks) then
						--DebugPrint({ Text = "metaUpgradeName = "..metaUpgradeName })
						local metaUpgradeCardData = MetaUpgradeCardData[metaUpgradeName]
						if metaUpgradeCardData.TraitName ~= nil and HeroHasTrait(metaUpgradeCardData.TraitName) then
							local trait = GetHeroTrait(metaUpgradeCardData.TraitName)
							local traitFrameId = CreateScreenObstacle({ Name = "BlankObstacle", X = xOffset, Y = yOffset, Group = screen.ComponentData.DefaultGroup, Scale = 0.7, Alpha = 0.0 })
							--Attach({ Id = traitFrameId, DestinationId = traitIcon.Id })
							SetAnimation({ Name = "DevCard_EquippedHighlight", DestinationId = traitFrameId })
							SetAlpha({ Id = traitFrameId, Fraction = 1.0, Duration = 0.1 })
							table.insert(screen.Frames, traitFrameId)
	
							local iconScale = 0.15
							local traitIcon = CreateScreenComponent({ Name = "TraitTrayIconButton", X = xOffset, Y = yOffset, Group = screen.ComponentData.DefaultGroup, Animation = metaUpgradeCardData.Image, Scale = iconScale, Alpha = 0.0 })
							AttachLua({ Id = traitIcon.Id, Table = traitIcon })
							traitIcon.Screen = screen
							traitIcon.OnMouseOverFunctionName = "TraitTrayIconButtonMouseOver"
							traitIcon.OnMouseOffFunctionName = "TraitTrayIconButtonMouseOff"
							traitIcon.OnPressedFunctionName = "PinTraitDetails"
							--trait.AnchorId = traitIcon.Id
							traitIcon.Icon = metaUpgradeCardData.Image
							traitIcon.IconScale = iconScale
							traitIcon.PinIconScale = 0.08
							traitIcon.PinIconFrameScale = 0.4
							traitIcon.OffsetX = xOffset
							traitIcon.OffsetY = yOffset
							traitIcon.HighlightAnim = "DevCard_Hover"
							traitIcon.HighlightAnimScale = 0.33
							traitIcon.TrayHighlightAnimScale = 1.1
							SetAlpha({ Id = traitIcon.Id, Fraction = 1.0, Duration = 0.1 })
							CreateTextBox({
								Id = traitIcon.Id,
								UseDescription = true,
								VariableAutoFormat = "BoldFormatGraft",
								Scale = 0.0,
								Hide = true,
							})
	
							if args.DisableTooltips then
								ModifyTextBox({ Id = traitIcon.Id, BlockTooltip = true })
							end
	
							table.insert(components, traitIcon)
							traitIcon.TraitData = trait
							screen.Icons[traitIcon.Id] = traitIcon
	
							if not firstTrait then
								highlightedTrait = traitIcon
								firstTrait = true
							end
	
							local uniqueTraitName = TraitTrayGetUniqueName(traitIcon)
							if uniqueTraitName == args.HighlightName or uniqueTraitName == activeCategory.PrevHighlightName then
								highlightedTrait = traitIcon
							end
							if trait.Name == MapState.TraitTrayMetaUpgradePriorityHighlight then
								highlightedTrait = traitIcon
								MapState.TraitTrayMetaUpgradePriorityHighlight = nil
							end
	
							screen.TraitComponentDictionary[uniqueTraitName] = traitIcon
							if screen.AutoPin and not activeCategory.OpenedOnce and IsPossibleMetaUpgradeAutoPin(trait) then
								table.insert(screen.PossibleAutoPins, traitIcon)
							end
	
							displayedTraitNum = displayedTraitNum + 1
							if displayedTraitNum % (activeCategory.TraitsPerColumn or screen.TraitsPerColumn) == 0 then
								xOffset = xOffset + traitSpacingX
								yOffset = ScreenHeight - (activeCategory.TraitStartBottomOffset or screen.TraitStartBottomOffset)
							else
								yOffset = yOffset + (activeCategory.TraitSpacingY or screen.TraitSpacingY)
							end
						end
					end
				end
			end
	
			highlightedTrait = highlightedTrait
			if highlightedTrait ~= nil then
				wait(0.02)
				SetHighlightedTraitFrame(screen, highlightedTrait)
			end
		end
	
		function UpdateMetaUpgradeCard_wrap(screen, row, column)
			local ranks = GetNumShrineUpgrades("LimitGraspShrineUpgrade")
			local button = screen.Components[GetMetaUpgradeKey(row, column)]
			local cardName = button.CardName
			local text = "MetaUpgrade_Locked"
			local state = "HIDDEN"
	
			DestroyTextBox({ Id = button.Id })
			if not GameState.MetaUpgradeState[cardName] then
				return
			end
	
			if GameState.MetaUpgradeState[cardName].Unlocked then
				text = cardName
				state = "UNLOCKED"
			elseif HasNeighboringUnlockedCards(row, column) or (row == 1 and column == 1) then
				text = cardName
				state = "LOCKED"
			end
	
			--MOD START
			if IsMetaupgradeDisabled(cardName, ranks) then
				text = cardName
				state = "HIDDEN"
				button.CardDisabled = true
			end
			--MOD END
	
			local metaUpgradeData = MetaUpgradeCardData[cardName]
			local newZoom = {}
			if state == "UNLOCKED" then
				newZoom.OffsetX = screen.DefaultCardCostTitleArgs.OffsetX * 5 / screen.ZoomLevel
				newZoom.OffsetY = screen.DefaultCardCostTitleArgs.OffsetY * 5 / screen.ZoomLevel
				if screen.Name == "MetaUpgradeCardUpgradeLayout" then
					SetAlpha({ Id = button.CardCornersId, Fraction = 0.0 })
					CreateTextBox(MergeAllTables({ { Id = button.Id, Text = " " },
						screen.DefaultCardCostTitleArgs, newZoom }))
					if not MetaUpgradeAtMaxLevel(cardName) then
						local metaUpgradeData = MetaUpgradeCardData[cardName]
						local resourceCost = metaUpgradeData.UpgradeResourceCost[GetMetaUpgradeLevel(cardName)]
						if HasResources(resourceCost) then
							SetAlpha({ Id = button.UpgradeIconId, Fraction = 1, Duration = 0.2 })
						end
					end
				else
					CreateTextBox(MergeAllTables({ { Id = button.Id, Text = MetaUpgradeCardData[cardName].Cost },
						screen.DefaultCardCostTitleArgs, newZoom }))
				end
			elseif state == "LOCKED" then
				newZoom.OffsetX = screen.LockedCardCostTitleArgs.OffsetX * 5 / screen.ZoomLevel
				newZoom.OffsetY = screen.LockedCardCostTitleArgs.OffsetY * 5 / screen.ZoomLevel
				CreateTextBox(MergeAllTables({ { Id = button.Id, Text = MetaUpgradeCardData[cardName].Cost }, screen.LockedCardCostTitleArgs, newZoom }))
	
				newZoom.OffsetX = screen.LockedCardResourceTextArgs.OffsetX * 5 / screen.ZoomLevel
				newZoom.OffsetY = nil
			elseif state == "HIDDEN" then
				newZoom.OffsetX = screen.HiddenCardTitleTextArgs.OffsetX * 5 / screen.ZoomLevel
				newZoom.OffsetY = screen.HiddenCardTitleTextArgs.OffsetY * 5 / screen.ZoomLevel
				SetAlpha({ Id = button.CardCornersId, Fraction = 0.0 })
				CreateTextBox(MergeAllTables({ { Id = button.Id, Text = text }, screen.HiddenCardTitleTextArgs, newZoom }))
			end
	
			if state ~= "HIDDEN" then
				-- Hidden description for tooltip
				CreateTextBox({
					Id = button.Id,
					Text = metaUpgradeData.Name,
					SkipDraw = true,
					Color = Color.Transparent,
					UseDescription = true,
					LuaKey = "TooltipData",
					LuaValue = button.TraitData or {},
				})
				if metaUpgradeData.AutoEquipText ~= nil then
					CreateTextBox({
						Id = button.Id,
						Text = metaUpgradeData.AutoEquipText,
						SkipDraw = true,
						Color = Color.Transparent,
					})
				end
	
				if GetMetaUpgradeLevel(button.CardName) > 1 then
					SetAnimation({ DestinationId = button.TypeIconId, Name = "CardRarityPatch", OffsetX = -400 / screen.ZoomLevel, OffsetY = -500 / screen.ZoomLevel })
					local rarity = TraitRarityData.RarityUpgradeOrder[GetMetaUpgradeLevel(button.CardName)]
					SetColor({ Id = button.TypeIconId, Color = Color["BoonPatch" .. rarity] })
				else
					SetAnimation({ Name = "Blank", DestinationId = button.TypeIconId })
				end
				SetAnimation({ Name = MetaUpgradeCardData[button.CardName].Image, DestinationId = button.CardArtId, Scale = screen.DefaultArtScale })
				if state == "LOCKED" then
					SetHSV({ Id = button.CardArtId, HSV = { 0, -1, -0.1 }, ValueChangeType = "Absolute" })
					SetHSV({ Id = button.CardCornersId, HSV = { 0, -1, -0.25 }, ValueChangeType = "Absolute" })
					SetAlpha({ Id = button.CardArtId, Fraction = 0.15 })
					SetAlpha({ Id = button.CardCornersId, Fraction = 0.5 })
				end
				if HasStoreItemPin(button.StoreName) then
					AddStoreItemPinPresentation(button, { AnimationName = "MetaUpgradeItemPin", SkipVoice = true })
					-- Silent toolip
					CreateTextBox({ Id = button.Id, TextSymbolScale = 0, Text = "StoreItemPinTooltip", Color = Color.Transparent, })
				end
			else
				SetAnimation({ Name = "DevBacking", DestinationId = button.CardArtId, Scale = screen.DefaultArtScale })
			end
			button.CardState = state
			UpdateMetaUpgradeCardAnimation(button)
		end

		function IsMetaupgradeDisabled(metaUpgradeName, ranks)
			-- If max rank everything is disabled
			if ranks == 5 then
				return true
			end

			-- Row 5
			if ranks >= 1 and Contains(MetaUpgradeDefaultCardLayout[5], metaUpgradeName) then
				print("Disabled : " .. metaUpgradeName)
				return true
			end
			-- Row 4
			if ranks >= 2 and Contains(MetaUpgradeDefaultCardLayout[4], metaUpgradeName) then
				print("Disabled : " .. metaUpgradeName)
				return true
			end
			-- Row 3
			if ranks >= 3 and Contains(MetaUpgradeDefaultCardLayout[3], metaUpgradeName) then
				print("Disabled : " .. metaUpgradeName)
				return true
			end
			-- Row 2
			if ranks >= 4 and Contains(MetaUpgradeDefaultCardLayout[2], metaUpgradeName) then
				print("Disabled : " .. metaUpgradeName)
				return true
			end

			return false
		end
	end
	if config.TestamentsChanges.VowOfForsaking.Enabled then
		OverwriteTableKeys(MetaUpgradeData.BanUnpickedBoonsShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 1 },
			{ Points = 1, ChangeValue = 2 },
		})
	end
	if config.TestamentsChanges.VowOfBlood.Enabled then
		OverwriteTableKeys(MetaUpgradeData.EnemyDamageShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 1.2 }, -- 1
			{ Points = 1, ChangeValue = 1.4 }, -- 2
			{ Points = 1, ChangeValue = 1.6 }, -- 3
			{ Points = 1, ChangeValue = 1.8 }, -- 4
			{ Points = 1, ChangeValue = 2.0 }, -- 5
			{ Points = 2, ChangeValue = 2.4 }, -- 6
			{ Points = 2, ChangeValue = 3.0 }, -- 7
			{ Points = 3, ChangeValue = 3.8 }, -- 8
			{ Points = 3, ChangeValue = 5.0 }, -- 9
			{ Points = 4, ChangeValue = 7.0 }, -- 10
			{ Points = 4, ChangeValue = 9.0 }, -- 11
			{ Points = 5, ChangeValue = 12.0 }, -- 12
			{ Points = 6, ChangeValue = 15.0 }, -- 13
		})
	end
	if config.TestamentsChanges.VowOfDominance.Enabled then
		OverwriteTableKeys(MetaUpgradeData.EnemyHealthShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 1.1 }, -- 1
			{ Points = 1, ChangeValue = 1.2 }, -- 2
			{ Points = 1, ChangeValue = 1.3 }, -- 3
			{ Points = 1, ChangeValue = 1.5 }, -- 4
			{ Points = 2, ChangeValue = 1.8 }, -- 5
			{ Points = 2, ChangeValue = 2.2 }, -- 6
			{ Points = 2, ChangeValue = 2.7 }, -- 7
			{ Points = 3, ChangeValue = 3.3 }, -- 8
			{ Points = 3, ChangeValue = 4.0 }, -- 9
			{ Points = 3, ChangeValue = 4.7 }, -- 10
			{ Points = 4, ChangeValue = 5.5 }, -- 11
			{ Points = 5, ChangeValue = 6.4 }, -- 12
			{ Points = 6, ChangeValue = 7.4 }, -- 13
		})
	end
	if config.TestamentsChanges.VowOfFury.Enabled then
		OverwriteTableKeys(MetaUpgradeData.EnemySpeedShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 1.05 }, -- 1
			{ Points = 1, ChangeValue = 1.1 }, -- 2
			{ Points = 1, ChangeValue = 1.2 }, -- 3
			{ Points = 1, ChangeValue = 1.26 }, -- 4
			{ Points = 1, ChangeValue = 1.32 }, -- 5
			{ Points = 1, ChangeValue = 1.4 }, -- 6
			{ Points = 3, ChangeValue = 1.6 }, -- 7
			{ Points = 3, ChangeValue = 1.9 }, -- 8
			{ Points = 4, ChangeValue = 2.2 }, -- 9
			{ Points = 4, ChangeValue = 2.6 }, -- 10
			{ Points = 5, ChangeValue = 3.1 }, -- 11
			{ Points = 5, ChangeValue = 3.7 }, -- 12
			{ Points = 6, ChangeValue = 4.3 }, -- 13
		})
	end
	if config.TestamentsChanges.VowOfCommotion.Enabled then
		OverwriteTableKeys(MetaUpgradeData.EnemyCountShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 1.2 }, -- 1
			{ Points = 1, ChangeValue = 1.4 }, -- 2
			{ Points = 1, ChangeValue = 1.6 }, -- 3
			{ Points = 2, ChangeValue = 1.9 }, -- 4
			{ Points = 2, ChangeValue = 2.3 }, -- 5
			{ Points = 2, ChangeValue = 2.8 }, -- 6
			{ Points = 2, ChangeValue = 3.4 }, -- 7
			{ Points = 3, ChangeValue = 4.1 }, -- 8
			{ Points = 3, ChangeValue = 4.9 }, -- 9
			{ Points = 3, ChangeValue = 5.8 }, -- 10
			{ Points = 4, ChangeValue = 6.8 }, -- 11
			{ Points = 4, ChangeValue = 7.9 }, -- 12
			{ Points = 5, ChangeValue = 9.0 }, -- 13
		})
	end
	if config.TestamentsChanges.VowOfHaunting.Enabled then
		OverwriteTableKeys(MetaUpgradeData.EnemyRespawnShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 0.25 }, -- 1
			{ Points = 1, ChangeValue = 0.5 }, -- 2
			{ Points = 2, ChangeValue = 0.75 }, -- 3
			{ Points = 4, ChangeValue = 1.0 }, -- 4
		})
	end
	if config.TestamentsChanges.VowOfWandering.Enabled then
		OverwriteTableKeys(MetaUpgradeData.NextBiomeEnemyShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 0.10 }, -- 1
			{ Points = 2, ChangeValue = 0.25 }, -- 2
			{ Points = 2, ChangeValue = 0.45 }, -- 3
			{ Points = 3, ChangeValue = 0.75 }, -- 4
			{ Points = 5, ChangeValue = 1.0 }, -- 5
		})
	end
	if config.TestamentsChanges.VowOfBitterness.Enabled then
		OverwriteTableKeys(MetaUpgradeData.BoonSkipShrineUpgrade.Ranks, {
			{ Points = 3, ChangeValue = 1 }, -- 1
			{ Points = 3, ChangeValue = 2 }, -- 2
			{ Points = 4, ChangeValue = 3 }, -- 3
			{ Points = 4, ChangeValue = 4 }, -- 4
			{ Points = 5, ChangeValue = 5 }, -- 5
			{ Points = 5, ChangeValue = 6 }, -- 6
		})
	end
	if config.TestamentsChanges.VowOfDesperation.Enabled then
		OverwriteTableKeys(MetaUpgradeData.BiomeSpeedShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 540 }, -- 1
			{ Points = 2, ChangeValue = 420 }, -- 2
			{ Points = 3, ChangeValue = 300 }, -- 3
			{ Points = 5, ChangeValue = 240 }, -- 4
			{ Points = 7, ChangeValue = 210 }, -- 5
			{ Points = 9, ChangeValue = 180 }, -- 6
			{ Points = 12, ChangeValue = 150 }, -- 7
		})
	end
	--TODO removed from game, reimplement?
	-- if config.TestamentsChanges.VowOfPanic.Enabled then
	-- 	OverwriteTableKeys(MetaUpgradeData.RoomStartManaShrineUpgrade.Ranks, {
	-- 		{ Points = 1, ChangeValue = 0.5 }, -- 1
	-- 		{ Points = 1, ChangeValue = 0.0 }, -- 2
	-- 	})
	-- end
	if config.TestamentsChanges.VowOfArrogance.Enabled then
		OverwriteTableKeys(MetaUpgradeData.BoonManaReserveShrineUpgrade.Ranks, {
			{ Points = 1, ChangeValue = 5 }, -- 1
			{ Points = 3, ChangeValue = 10 }, -- 2
			{ Points = 4, ChangeValue = 15 }, -- 3
			{ Points = 5, ChangeValue = 20 }, -- 4
		})
	end
end

if config.EchoKeepsakeChange.Enabled then
	function HandleUpgradeChoiceSelection_wrap(screen, button, args)
		local buttonId = button.Id
		local upgradeData = button.Data
		local currentRun = CurrentRun
		args = args or {}

		screen.ChoiceMade = true

		currentRun.CurrentRoom.ReplacedTraitSource = nil

		-- handle trait
		local newTrait = nil
		if upgradeData.TraitToReplace then
			local numOldTrait = CurrentRun.Hero.TraitDictionary[upgradeData.TraitToReplace][1].StackNum or 1
			numOldTrait = numOldTrait + GetTotalHeroTraitValue("ExchangeLevelBonus")
			RemoveWeaponTrait(upgradeData.TraitToReplace)
			newTrait = AddTraitToHero({ TraitData = upgradeData, FromLoot = true })
			IncreaseTraitLevel(upgradeData, numOldTrait - 1)
			currentRun.CurrentRoom.ReplacedTraitSource = GetLootSourceName(upgradeData.TraitToReplace)
		else
			if button.LootData.StackOnly and upgradeData.Name ~= "FallbackGold" then
				local traitData = CurrentRun.Hero.TraitDictionary[upgradeData.Name][1]
				if traitData then
					IncreaseTraitLevel(traitData, button.LootData.StackNum)
				end
			else
				if button.LootData.UpgradeOnPick then
					local newButton = TryUpgradeBoon(button.LootData, screen, button)
					if newButton then
						upgradeData = newButton.Data
						waitUnmodified(0.8)
					end
				end
				newTrait = AddTraitToHero({ TraitData = upgradeData, PreProcessedForDisplay = true, FromLoot = true })
			end
		end
		if button.LootData.BanUnpickedBoonsEligible and not args.DoubleBoonChance then
			local numBans = MetaUpgradeData.BanUnpickedBoonsShrineUpgrade.ChangeValue
			if numBans >= 1 then
				local banCount = 0
				for index, otherUpgradeButton in ipairs(screen.UpgradeButtons) do
					if otherUpgradeButton.Data.Name ~= upgradeData.Name then
						CurrentRun.BannedTraits[otherUpgradeButton.Data.Name] = true
						thread(BanUnpickedBoonPresentation, screen, otherUpgradeButton)
						banCount = banCount + 1
						if banCount >= numBans then
							break
						end
					end
				end
			end
		end
		LogUpgradeChoice(button)
		PlaySound({ Name = button.LootData.UpgradeSelectedSound or "/SFX/HeatRewardDrop", Id = buttonId })
		CreateAnimation({ Name = "BoonGetBlack", DestinationId = buttonId, Scale = 1.0, GroupName = "Combat_Menu" })
		CreateAnimation({ Name = "BoonGet", DestinationId = buttonId, Scale = 1.0, GroupName = "Combat_Menu_Additive", Color = button.BoonGetColor or button.LootColor })
		--wait( 0.4, RoomThreadName )
		local source = screen.Source
		local spawnTarget = nil
		local duplicateOnClose = false
		local name = source.Name
		if source.CanDuplicate and RandomChance(GetTotalHeroTraitValue("DoubleRewardChance")) then
			duplicateOnClose = true
			spawnTarget = SpawnObstacle({ Name = "InvisibleTarget", Group = "Standing", DestinationId = source.ObjectId })
		end
		if source.DestroyOnPickup then
			Destroy({ Id = source.ObjectId })
			RemoveScreenEdgeIndicator(source)
		end
		MapState.RoomRequiredObjects[source.ObjectId] = nil
		if source.LastRewardEligible then
			CurrentRun.LastReward = { Type = "Boon", Name = source.Name, DisplayName = source.Name }
		end
		local doubleBoonTrait = HasHeroTraitValue("DoubleBoonChance")
		if doubleBoonTrait
			and doubleBoonTrait.Uses > 0
			and not CurrentRun.CurrentRoom.EchoedReward
			and button.LootData.GodLoot and not button.LootData.BlockDoubleBoon and RandomChance(doubleBoonTrait.DoubleBoonChance) then
			CurrentRun.CurrentRoom.EchoedReward = true
			waitUnmodified(0.8)
			EchoKeepsakeReward()
			ReduceTraitUses(doubleBoonTrait)
		end

		CloseUpgradeChoiceScreen(screen, button)
		IncrementTableValue(GameState.LootPickups, button.UpgradeName)
		CheckCodexUnlock("OlympianGods", button.UpgradeName)
		CheckCodexUnlock("ChthonicGods", button.UpgradeName)
		CheckCodexUnlock("Items", button.UpgradeName)
		if not screen.SkipUpgradePresentationAndExitUnlock then
			UpgradeAcquiredPresentation(screen, button.LootData)
		end
		if duplicateOnClose and spawnTarget then
			local newLoot = CreateLoot({ Name = name, SpawnPoint = spawnTarget })
			newLoot.CanDuplicate = false
			thread(DoubleRewardPresentation, newLoot.ObjectId)
			Destroy({ Id = spawnTarget })
		end
		if not screen.SkipUpgradePresentationAndExitUnlock then
			waitUnmodified(0.2, RoomThreadName)
			if CheckRoomExitsReady(CurrentRun.CurrentRoom) then
				UnlockRoomExits(CurrentRun, CurrentRun.CurrentRoom)
			end
		end

		CheckNewTraitManaReserveShrineUpgrade(newTrait, args)

		SetLightBarColor({ PlayerIndex = 1, Color = CurrentRun.Hero.LightBarColor or { 0.0, 0.0, 0.0, 0.0 } })
	end

	function EchoKeepsakeReward()
		local spawnPoint = GetClosest({ Id = CurrentRun.Hero.ObjectId, DestinationNames = "SpawnPoints" })
		if spawnPoint == 0 then
			spawnPoint = CurrentRun.Hero.ObjectId
		end
		CreateLoot({ Name = CurrentRun.LastReward.Name, SpawnPoint = spawnPoint })
		EchoKeepsakeRewardPresentation(spawnPoint)
	end

	function EchoKeepsakeRewardPresentation(spawnPoint)
		wait(0.05)

		LoadVoiceBanks({ Name = "Echo" })
		PlaySound({ Name = "/SFX/Menu Sounds/PortraitEmoteSparklySFX" })
		thread(PlayVoiceLines, GlobalVoiceLines.EchoKeepsakeLines, true)
		CreateAnimation({
			Name = "BiomeStateGoldFx",
			DestinationId = spawnPoint,
			OffsetX = 0,
			OffsetY = 0,
			Group =
			"Combat_Menu_Additive"
		})
		thread(InCombatTextArgs,
			{
				TargetId = spawnPoint,
				Text = "DoubleBoonSuccess",
				ScreenSpace = true,
				SkipRise = true,
				PreDelay = 0.05,
				Duration = 1.0,
				OffsetX = 0,
				OffsetY = 0,
				Group =
				"Combat_Menu_Additive",
				Justification = "Center",
				FontSize = 30
			})
	end
end

if config.ExtraLastStandsFirst.Enabled then
	function CheckLastStand_override(victim, triggerArgs)
		if not HasLastStand(victim) then
			return false
		end

		if ActiveScreens.TraitTrayScreen ~= nil then
			thread(TraitTrayScreenClose, ActiveScreens.TraitTrayScreen)
		end
		CancelFishing()
		ToggleCombatControl(CombatControlsDefaults, false, "LastStand")


		local lastStandData = nil
		if HasHeroTraitValue("BlockDeathTimer") and not MapState.UsedBlockDeath then
			MapState.UsedBlockDeath = true
			lastStandData =
			{
				HealAmount = GetTotalHeroTraitValue("BlockDeathHealth"),
				FunctionName = "SetupBlockDeathThread"
			}
		else
			--MOD START
			lastStandData = PickLastStand(victim.LastStands)
			--MOD END
		end
		local weaponName = lastStandData.WeaponName
		local lastStandManaFraction = lastStandData.ManaFraction or 0
		local lastStandHealth = lastStandData.HealAmount or 0
		local lastStandFraction = lastStandData.HealFraction or 0
		lastStandFraction = lastStandFraction + GetTotalHeroTraitValue("LastStandHealFraction")

		if lastStandData.RandomHeal then
			for i, data in ipairs(lastStandData.RandomHeal) do
				if data.Chance and RandomChance(data.Chance) then
					lastStandHealth = data.HealAmount
					break
				else
					if type(data.HealFraction) == "table" then
						lastStandFraction = RandomFloat(data.HealFraction.Min, data.HealFraction.Max)
					else
						lastStandFraction = data.HealFraction
					end
				end
			end
		end

		if lastStandData.ExpiresKeepsake then
			CurrentRun.ExpiredKeepsakes[lastStandData.ExpiresKeepsake] = true
			LogTraitUses(lastStandData.ExpiresKeepsake)
		end

		CurrentRun.Hero.LastStandsUsed = (CurrentRun.Hero.LastStandsUsed or 0) + 1

		SetPlayerInvulnerable("LastStand")
		ClearEffect({ Id = CurrentRun.Hero.ObjectId, Name = "HecatePolymorphStun" })
		ClearEffect({ Id = CurrentRun.Hero.ObjectId, Name = "MiasmaSlow" })
		if HasHeroTraitValue("RechargeSpellOnLastStand") then
			ChargeSpell(-1000)
		end
		triggerArgs.HasLastStand = HasLastStand(victim)
		ExpireProjectiles({ ExcludeNames = ConcatTableValues(ShallowCopyTable(WeaponSets.ExpireProjectileExcludeProjectileNames), ShallowCopyTable(WeaponSets.ExpireProjectileLastStandExcludeProjectileNames)) })

		if MapState.FamiliarUnit ~= nil then
			RunEventsGeneric(MapState.FamiliarUnit.LastStandEvents, MapState.FamiliarUnit)
		end

		PlayerLastStandPresentationStart(triggerArgs)

		PlayerLastStandHeal(victim, triggerArgs, lastStandHealth, lastStandFraction)
		thread(UpdateHealthUI, triggerArgs)

		local manaRestoreAmount = round(victim.MaxMana * lastStandManaFraction)
		ManaDelta(manaRestoreAmount)
		thread(PlayerLastStandManaGainText, { Amount = manaRestoreAmount, Delay = 0.5 })

		PlayerLastStandPresentationEnd()

		ToggleCombatControl(CombatControlsDefaults, true, "LastStand")
		if weaponName ~= nil then
			FireWeaponFromUnit({ Weapon = weaponName, Id = victim.ObjectId, DestinationId = victim.ObjectId, AutoEquip = true })
		end
		CallFunctionName(lastStandData.FunctionName, victim, lastStandData.FunctionArgs)

		for i, functionData in pairs(GetHeroTraitValues("OnLastStandFunction")) do
			CallFunctionName(functionData.Name, functionData.FunctionArgs, triggerArgs)
		end

		wait(1.5, RoomThreadName)


		SetPlayerVulnerable("LastStand")
		return true
	end

	function PickLastStand(lastStands)
		local lastStand = nil
		for i, lastStandData in pairs(lastStands) do
			if lastStandData.Icon ~= "ExtraLifeStyx" then
				lastStand = table.remove(lastStands, i)
				return lastStand
			end
		end
		lastStand = table.remove(lastStands)
		return lastStand
	end
end

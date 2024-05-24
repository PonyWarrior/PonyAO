OverwriteTableKeys(TraitData.DemeterManaBoon, {
	InheritFrom = { "BaseTrait", "ManaOverTimeSource", "EarthBoon" },
	Icon = "Boon_Demeter_31",
	Slot = "Mana",
	BlockStacking = true,
	RarityLevels =
	{
		Common =
		{
			Multiplier = config.TranquilGainRework.CommonMultiplier,
		},
		Rare =
		{
			Multiplier = config.TranquilGainRework.RareMultiplier,
		},
		Epic =
		{
			Multiplier = config.TranquilGainRework.EpicMultiplier,
		},
		Heroic =
		{
			Multiplier = config.TranquilGainRework.HeroicMultiplier,
		},
	},
	SetupFunction =
	{
		Name = _PLUGIN.guid .. '.' .. 'DemeterRegenSetup',
		Args =
		{
			RegenPenaltyDuration = config.TranquilGainRework.InitialDelay,
			DelayIncreaseDuration = {
				BaseValue = config.TranquilGainRework.BaseDelayIncrease
			},
			ManaRegenStartFx = "ManaRegenFlashFx",
			ManaRegenStartSound = "/Leftovers/SFX/SprintChargeUp",
			ManaThreshold = config.TranquilGainRework.ManaThreshold,
			ReportValues = { ReportedManaThreshold = "ManaThreshold", ReportedRegenPenaltyDuration = "RegenPenaltyDuration", ReportedRegenDelayDuration = "DelayIncreaseDuration" }
		},
		RunOnce = true
	},
	StatLines = {},
	ExtractValues =
	{
		{
			Key = "ReportedManaThreshold",
			ExtractAs = "TooltipManaThreshold",
			Format = "Percent"
		},
		{
			Key = "ReportedRegenPenaltyDuration",
			ExtractAs = "TooltipRegenPenaltyDuration",
			DecimalPlaces = 1,
		},
		{
			Key = "ReportedRegenDelayDuration",
			ExtractAs = "TooltipDelayIncreaseDuration",
			DecimalPlaces = 2,
		},
	}
})

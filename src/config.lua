---@meta PonyWarrior-PonyAO-config
local config = {
	enabled = true,
	TorchImprovements = {
		Enabled = true,
		AttackSpeed = 0.33
	},
	TranquilGainRework = {
		Enabled = true,
		InitialDelay = 3.0,
		BaseDelayIncrease = 1.0,
		ManaThreshold = 0.1,
		CommonMultiplier = 1.0,
		RareMultiplier = 0.75,
		EpicMultiplier = 0.5,
		HeroicMultiplier = 0.25
	},
	AxeSpecialUnlimitedBlock = {
		Enabled = true,
	},
	AlwaysManaRegen = {
		Enabled = true,
	},
	WhiteAntlerHealthCap = {
		Enabled = true,
	},
	HexChanges = {
		Enabled = true,
		HexChargeInvulnerable = {
			Enabled = true
		},
		-- LunarRayFrontBlock = {
		-- 	Enabled = true
		-- }
	},
	TestamentsChanges = {
		Enabled = true,
		VowOfAbandon = {
			Enabled = true
		},
		VowOfForsaking = {
			Enabled = true
		},
		VowOfBlood = {
			Enabled = true
		},
		VowOfDominance = {
			Enabled = true
		},
		VowOfFury = {
			Enabled = true
		},
		VowOfCommotion = {
			Enabled = true
		},
		VowOfHaunting = {
			Enabled = true
		},
		VowOfWandering = {
			Enabled = true
		},
		VowOfBitterness = {
			Enabled = true
		},
		VowOfDesperation = {
			Enabled = true
		},
		VowOfPanic = {
			Enabled = true
		},
		VowOfArrogance = {
			Enabled = true
		},
	},
}

local description = {
	enabled = "Set to true to enable the mod, set to false to disable it.",
	TorchImprovements = {
		Enabled = "Enable to improve the torches, increasing their attack speed, giving attacks homing and making specials stagger enemies.",
		AttackSpeed = "Set a custom attack speed. Original is 0.45."
	},
	TranquilGainRework = {
		Enabled = "Enable to rework Demeter's Tranquil Gain. When your Magick falls under a percentage, your magick is fully restored after a delay. This delay increases every time this occurs, resetting each location.",
		InitialDelay = "Initial delay before regenerating magick.",
		BaseDelayIncrease = "Base delay increase per time regeneration has occured in a location.",
		ManaThreshold = "Mana threshold, will not regenerate above it.",
		CommonMultiplier = "Common rarity multiplier. Affects BaseDelayIncrease.",
		RareMultiplier = "Rare rarity multiplier. Affects BaseDelayIncrease.",
		EpicMultiplier = "Epic rarity multiplier. Affects BaseDelayIncrease.",
		HeroicMultiplier = "Heroic rarity multiplier. Affects BaseDelayIncrease.",
	},
	AxeSpecialUnlimitedBlock = {
		Enabled = "Enable to be able to block indefinitely with the axe special."
	},
	AlwaysManaRegen = {
		Enabled = "Enable to make mana regeneration never be canceled."
	},
	WhiteAntlerHealthCap = {
		Enabled = "Enable to cap your maximum health to 30 when using the White Antler.",
	},
	HexChanges = {
		Enabled = "Enable to apply various changes to Hexes.",
		HexChargeInvulnerable = {
			Enabled = "Enable to make the player invulnerable during hex charging animations."
		},
		-- LunarRayFrontBlock = {
		-- 	Enabled = "Enable to make the Lunar Ray Hex block from the front."
		-- }
	},
	TestamentsChanges = {
		Enabled = "Enable to apply testament changes. Each change can be disabled and enabled individually.",
		VowOfAbandon = {
			Enabled = "Enable to make the vow of abandon incremental."
		},
		VowOfForsaking = {
			Enabled = "Enable to make the vow of forsaking incremental"
		},
		VowOfBlood = {
			Enabled = "Enable to add intermediate and higher levels to the vow of blood."
		},
		VowOfDominance = {
			Enabled = "Enable to add higher levels to the vow of dominance."
		},
		VowOfFury = {
			Enabled = "Enable to add intermediate and higher levels to the vow of fury."
		},
		VowOfCommotion = {
			Enabled = "Enable to add higher levels to the vow of commotion."
		},
		VowOfHaunting = {
			Enabled = "Enable to add higher levels to the vow of haunting."
		},
		VowOfWandering = {
			Enabled = "Enable to add higher levels to the vow of wandering."
		},
		VowOfBitterness = {
			Enabled = "Enable to add higher levels to the vow of bitterness."
		},
		VowOfDesperation = {
			Enabled = "Enable to add higher levels to the vow of desperation."
		},
		VowOfPanic = {
			Enabled = "Enable to add an intermediate level to the vow of panic."
		},
		VowOfArrogance = {
			Enabled = "Enable to add higher levels to the vow of arrogance."
		},
	},
}

return config, description

---@meta PonyWarrior-PonyAO-config
local config = {
	enabled = true,
	TorchImprovements = {
		Enabled = true,
		AttackSpeed = 0.33
	},
	StaffImprovements = {
		Enabled = true,
		OmegaAttackChargeSpeed = 0.6
	},
	SkullImprovements = {
		Enabled = true,
		PickupRange = 500
	},
	CardChanges = {
		Enabled = true,
		SwiftRunner = {
			Enabled = true
		},
		Messenger = {
			Enabled = true
		},
		Night = {
			Enabled = true
		},
		Unseen = {
			Enabled = true
		},
		Death = {
			Enabled = true
		},
		Artificer = {
			Enabled = true
		},
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
	-- AxeSpecialUnlimitedBlock = {
	-- 	Enabled = true,
	-- },
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
		VowOfVoid = {
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
		-- VowOfPanic = {
		-- 	Enabled = true
		-- },
		VowOfArrogance = {
			Enabled = true
		},
	},
	PolyphemusJump = {
		Enabled = true,
		DamageValue = 0,
		EnableStun = true,
		StunDuration = 0.4,
	},
	TroveChanges = {
		Enabled = true,
		DisableDecay = {
			Enabled = true
		},
		EqualWeight = {
			Enabled = true
		},
		EnableHealthTroves = {
			Enabled = true
		},
		EnableBoneTroves = {
			Enabled = true
		},
	},
	EchoKeepsakeChange = {
		Enabled = true
	},
	EphyraOverhaul = {
		Enabled = true
	},
	ExtraLastStandsFirst = {
		Enabled = true
	},
	-- ExcludeHeroic = {
	-- 	Enabled = true
	-- },
}

local description = {
	enabled = "Set to true to enable the mod, set to false to disable it.",
	TorchImprovements = {
		Enabled =
		"Enable to improve the torches, increasing their attack speed, giving attacks homing and making specials stagger enemies.",
		AttackSpeed = "Set a custom attack speed. Original is 0.45."
	},
	StaffImprovements = {
		Enabled =
		"Enable to improve the staff, letting you charge the omega attack faster and release it whenever you want, plus making the special fire full auto and charge the omega special while shooting the regular special.",
		OmegaAttackChargeSpeed = "Set a custom charge time for the omega attack. Original is 0.8."
	},
	SkullImprovements = {
		Enabled = "Enable to improve the skull, increasing the ammo pickup range.",
		PickupRange = "Set a custom pickup range. Original is 250."
	},
	CardChanges = {
		Enabled = "Enable to improve the altar of ashes' cards.",
		SwiftRunner = {
			Enabled = "Enable to make the swift runner increase the number of dashes you can do by 1 (at all ranks)."
		},
		Messenger = {
			Enabled = "Enable to make the messenger increase your movement speed by 6/9/12/15%."
		},
		Night = {
			Enabled = "Enable to make night increase your omega channeling speed by 10/17/23/30%."
		},
		Unseen = {
			Enabled = "Enable to make the unseen cost 2 grasp instead of 5."
		},
		Death = {
			Enabled = "Enable to make death increase your omega damage by 15/27/38/50%."
		},
		Artificer = {
			Enabled = "Enable to make the artificer increase the rarity of your keepsakes by 1 level (at all ranks)."
		},
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
	-- AxeSpecialUnlimitedBlock = {
	-- 	Enabled = "Enable to be able to block indefinitely with the axe special."
	-- },
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
		VowOfVoid = {
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
	PolyphemusJump = {
		Enabled = "Enable to remove the damage from Polyphemus' jump windup attack and make it stun the player briefly instead.",
		DamageValue = "Set a custom damage value. Original is 11.",
		EnableStun = "Enable to make the jump stun the player.",
		StunDuration = "Set a custom duration for the stun. Original is 0.2.",
	},
	TroveChanges = {
		Enabled = "Enable to make various changes to the troves.",
		DisableDecay = {
			Enabled = "Enable to disable the trove reward from decaying over time."
		},
		EqualWeight = {
			Enabled = "Enable to make all 3 troves equally likely to appear. Gold trove is 3 times more likely to appear if disabled."
		},
		EnableHealthTroves = {
			Enabled = "Enable to make troves containing health appear."
		},
		EnableBoneTroves = {
			Enabled = "Enable to make troves containing bones appear."
		},
	},
	EchoKeepsakeChange = {
		Enabled = "Enable to make Echo's keepsake duplicate your current reward on activation, with the number of occurences increasing per rank instead of the chance."
	},
	EphyraOverhaul = {
		Enabled = "Enable to overhaul Ephyra. 6 Rooms containing pylons are designated, and shown with PonyQOL2 installed. Completing rooms with no pylon does not increase the pylon counter, letting you complete more than 6. Every door in Ephyra is open and contains a reward. Completing the 6 pylon rooms unseals the boss room and locks all doors as normal. If you complete more than 6 rooms, each room you enter beyond the 6th will contain reinforcements from Tartarus."
	},
	ExtraLastStandsFirst = {
		Enabled = "Enable to make extra last stands be used first."
	},
	-- ExcludeHeroic = {
	-- 	Enabled = "Enable to make Bridal Glow and Rare Crop never pick Heroic boons."
	-- },
}

return config, description

---@meta _
-- grabbing our dependencies,
-- these funky (---@) comments are just there
--	 to help VS Code find the definitions of things

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()
-- ^ this gives us `public` and `import`, among others
--	and makes all globals we define private to this plugin.
---@diagnostic disable: lowercase-global

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = _PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game

---@module 'SGG_Modding-SJSON'
sjson = mods['SGG_Modding-SJSON']
---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]
---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module 'PonyWarrior-PonyAO-config'
config = chalk.auto 'config.lua'
-- ^ this updates our `.cfg` file in the config folder!
public.config = config -- so other mods can access our config

---@module 'game.import'
import_as_fallback(rom.game)

local function on_ready()
	-- what to do when we are ready, but not re-do on reload.
	if config.enabled == false then return end
	import 'ready.lua'
end

local function on_reload()
	-- what to do when we are ready, but also again on every reload.
	-- only do things that are safe to run over and over.
	if config.enabled == false then return end
	mod = modutil.mod.Mod.Register(_PLUGIN.guid)
	import 'reload.lua'
end

-- this allows us to limit certain functions to not be reloaded.
local loader = reload.auto_multiple()

-- this runs only when modutil and the game's lua is ready
modutil.once_loaded.game(function()
	loader.load('PonyAO A', on_ready, on_reload)
end)

local function on_TraitData_Keepsake()
	if config.enabled == false then return end
	local GUIAnimationsFile = rom.path.combine(rom.paths.Content, 'Game/Animations/GUIAnimations.sjson')

	local gui_order = {
		"Name", "InheritFrom", "FilePath"
	}

	local newFrame = sjson.to_object({
		Name = "Frame_Keepsake_Rank4",
		InheritFrom = "Menu_Frame",
		FilePath = "GUI\\Screens\\AwardMenu\\keepsake_frame_4",
	}, gui_order)

	sjson.hook(GUIAnimationsFile, function(data)
		table.insert(data.Animations, newFrame)
	end)

	TraitData.GiftTrait.FrameRarities.Heroic = "Frame_Keepsake_Rank4"
end

loader.queue.post_import_file('PonyAO B', 'TraitData_Keepsake.lua', on_TraitData_Keepsake)

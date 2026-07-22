extends Node


const MOD_DIR = "opaaaaaaaaaaaa-ModOptionsTabs/"
const LOG_NAME = "opaaaaaaaaaaaa-ModOptionsTabs"


func _init(_mod_loader = ModLoader):
	ModLoaderLog.info("Init", LOG_NAME)
	var ext_dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR + "extensions/"
	ModLoaderMod.install_script_extension(ext_dir + "mod_options_tab.gd")

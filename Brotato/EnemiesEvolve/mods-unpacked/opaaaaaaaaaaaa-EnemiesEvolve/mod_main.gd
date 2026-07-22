extends Node

const MOD_DIR = "opaaaaaaaaaaaa-EnemiesEvolve/"
const LOG_NAME = "opaaaaaaaaaaaa-EnemiesEvolve"


func _init() -> void :
	ModLoaderLog.info("Init", LOG_NAME)
	var dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	ModLoaderMod.install_script_extension(dir + "extensions/singletons/entity_service.gd")

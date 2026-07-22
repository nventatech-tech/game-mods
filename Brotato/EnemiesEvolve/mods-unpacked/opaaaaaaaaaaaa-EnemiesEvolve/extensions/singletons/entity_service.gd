extends "res://singletons/entity_service.gd"

const SE_MOD_ID = "opaaaaaaaaaaaa-EnemiesEvolve"
const SE_MODE_FLAT = "Flat multiplier"

var se_mode: String = "Per wave"
var se_hp_per_wave: float = 0.05
var se_damage_per_wave: float = 0.05
var se_speed_per_wave: float = 0.0
var se_hp_mult: float = 2.0
var se_damage_mult: float = 2.0
var se_speed_mult: float = 1.0
var se_options_section: Node = null


func _ready() -> void :
	se_load_config()
	call_deferred("se_connect_mod_options")
	get_tree().connect("node_added", self, "se_on_node_added")


func se_on_node_added(node: Node) -> void :
	if node is Label and node.text == SE_MOD_ID:
		se_options_section = node.get_parent()
		call_deferred("se_apply_slider_visibility")


func se_apply_slider_visibility() -> void :
	if not is_instance_valid(se_options_section) or se_options_section.get_child_count() < 2:
		return
	var values = se_options_section.get_child(1)
	var flat: bool = se_mode == SE_MODE_FLAT
	for i in values.get_child_count():
		if i == 0:
			continue
		values.get_child(i).visible = (i >= 4) if flat else (i <= 3)


func se_load_config() -> void :
	var config = ModLoaderConfig.get_current_config(SE_MOD_ID)
	if config == null:
		config = ModLoaderConfig.get_default_config(SE_MOD_ID)
	if config == null:
		return
	se_mode = str(config.data.get("mode", se_mode))
	se_hp_per_wave = float(config.data.get("hp_percent_per_wave", se_hp_per_wave))
	se_damage_per_wave = float(config.data.get("damage_percent_per_wave", se_damage_per_wave))
	se_speed_per_wave = float(config.data.get("speed_percent_per_wave", se_speed_per_wave))
	se_hp_mult = float(config.data.get("hp_multiplier", se_hp_mult))
	se_damage_mult = float(config.data.get("damage_multiplier", se_damage_mult))
	se_speed_mult = float(config.data.get("speed_multiplier", se_speed_mult))


func se_connect_mod_options() -> void :
	var iface = get_node_or_null("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	if iface != null and not iface.is_connected("setting_changed", self, "se_on_setting_changed"):
		iface.connect("setting_changed", self, "se_on_setting_changed")


func se_on_setting_changed(setting_name: String, value, mod_name: String) -> void :
	if mod_name != SE_MOD_ID:
		return
	match setting_name:
		"mode":
			se_mode = str(value)
		"hp_percent_per_wave":
			se_hp_per_wave = float(value)
		"damage_percent_per_wave":
			se_damage_per_wave = float(value)
		"speed_percent_per_wave":
			se_speed_per_wave = float(value)
		"hp_multiplier":
			se_hp_mult = float(value)
		"damage_multiplier":
			se_damage_mult = float(value)
		"speed_multiplier":
			se_speed_mult = float(value)
	se_save_config()
	if setting_name == "mode":
		se_apply_slider_visibility()


func se_save_config() -> void :
	var data: = {
		"mode": se_mode,
		"hp_percent_per_wave": se_hp_per_wave,
		"damage_percent_per_wave": se_damage_per_wave,
		"speed_percent_per_wave": se_speed_per_wave,
		"hp_multiplier": se_hp_mult,
		"damage_multiplier": se_damage_mult,
		"speed_multiplier": se_speed_mult
	}
	var config = ModLoaderConfig.get_config(SE_MOD_ID, "current")
	if config == null:
		config = ModLoaderConfig.create_config(SE_MOD_ID, "current", data)
	else:
		config.data = data
		config = ModLoaderConfig.update_config(config)
	if config != null:
		ModLoaderConfig.set_current_config(config)


func reset_cache() -> void :
	.reset_cache()
	se_load_config()
	ModLoaderLog.info("wave %s (%s) -> hp x%.2f, damage x%.2f, speed x%.2f" % [
		RunData.current_wave,
		se_mode,
		se_hp_factor(),
		se_damage_factor(),
		se_speed_factor()
	], SE_MOD_ID)


func se_wave_factor(fraction_per_wave: float) -> float:
	return 1.0 + max(0, RunData.current_wave) * fraction_per_wave


func se_hp_factor() -> float:
	return se_hp_mult if se_mode == SE_MODE_FLAT else se_wave_factor(se_hp_per_wave)


func se_damage_factor() -> float:
	return se_damage_mult if se_mode == SE_MODE_FLAT else se_wave_factor(se_damage_per_wave)


func se_speed_factor() -> float:
	return se_speed_mult if se_mode == SE_MODE_FLAT else se_wave_factor(se_speed_per_wave)


func get_final_enemy_health(from_value: int, percent_modifier: int = 0) -> int:
	var base: int = .get_final_enemy_health(from_value, percent_modifier)
	return round(base * se_hp_factor()) as int


func get_final_enemy_damage(from_value: float, percent_modifier: int = 0) -> int:
	var base: int = .get_final_enemy_damage(from_value, percent_modifier)
	return round(base * se_damage_factor()) as int


func get_final_enemy_speed(from_value: int, effects_factor: float, percent_modifier: int = 0) -> int:
	var base: int = .get_final_enemy_speed(from_value, effects_factor, percent_modifier)
	return round(base * se_speed_factor()) as int

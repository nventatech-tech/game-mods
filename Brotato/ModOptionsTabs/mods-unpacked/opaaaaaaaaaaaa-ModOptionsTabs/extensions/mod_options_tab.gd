extends "res://mods-unpacked/dami-ModOptions/mod_options_tab/mod_options_tab.gd"


const SIDEBAR_WIDTH = 320


# Godot 3 calls _ready for every script in the extension chain (base first),
# so the original list is already built here; calling ._ready() would build it twice
func _ready():
	_build_sidebar()


func _build_sidebar():
	var outer_vbox = $VBoxContainer
	var margin = $VBoxContainer/MarginContainer
	var end_space = mod_list_vbox.get_node("EndSpace")

	var mod_containers := []
	for child in mod_list_vbox.get_children():
		if child != end_space and child is VBoxContainer:
			mod_containers.push_back(child)

	if mod_containers.size() < 2:
		return

	mod_containers.sort_custom(self, "_sort_by_display_name")

	# HBox takes MarginContainer's place; parent's onready refs keep working
	# because they hold node references, not paths
	var hbox = HBoxContainer.new()
	hbox.set("custom_constants/separation", 40)
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.size_flags_vertical = SIZE_EXPAND_FILL
	var margin_index = margin.get_index()
	outer_vbox.remove_child(margin)
	outer_vbox.add_child(hbox)
	outer_vbox.move_child(hbox, margin_index)

	# outer vbox must fill the root ScrollContainer's height so the sidebar
	# and content get their own independent scrolls instead of the root's
	outer_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	scroll_vertical_enabled = false

	var sidebar_scroll = ScrollContainer.new()
	sidebar_scroll.scroll_horizontal_enabled = false
	sidebar_scroll.follow_focus = true
	sidebar_scroll.rect_min_size.x = SIDEBAR_WIDTH
	sidebar_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	hbox.add_child(sidebar_scroll)

	var sidebar = VBoxContainer.new()
	sidebar.set("custom_constants/separation", 4)
	sidebar.size_flags_horizontal = SIZE_EXPAND_FILL
	sidebar_scroll.add_child(sidebar)

	var content_scroll = ScrollContainer.new()
	content_scroll.scroll_horizontal_enabled = false
	content_scroll.follow_focus = true
	content_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	hbox.add_child(content_scroll)

	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	margin.size_flags_vertical = SIZE_EXPAND_FILL
	content_scroll.add_child(margin)

	var group = ButtonGroup.new()
	var font = preload("res://resources/fonts/actual/base/font_26_outline.tres")

	for i in mod_containers.size():
		var container = mod_containers[i]
		var button = Button.new()
		button.toggle_mode = true
		button.group = group
		button.set("custom_fonts/font", font)
		button.text = _display_name(container)
		button.align = Button.ALIGN_LEFT
		button.clip_text = true
		sidebar.add_child(button)
		button.connect("toggled", self, "_on_sidebar_toggled", [container])
		button.pressed = i == 0
		container.visible = i == 0


func _on_sidebar_toggled(pressed: bool, container: Node):
	container.visible = pressed


func _sort_by_display_name(a: Node, b: Node) -> bool:
	return _display_name(a).nocasecmp_to(_display_name(b)) < 0


func _display_name(container: Node) -> String:
	# first child is the label ModOptions creates with the mod dir name
	var full_name := ""
	if container.get_child_count() > 0 and container.get_child(0) is Label:
		full_name = container.get_child(0).text
	# "namespace-ModName" -> "ModName"
	var parts = full_name.split("-", true, 1)
	return parts[parts.size() - 1]

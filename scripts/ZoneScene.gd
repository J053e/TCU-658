extends Control

var zone_title: Label
var zone_description: Label
var minigames_list: ItemList
var status_label: Label
var complete_button: Button

var zone := {}

func _ready() -> void:
	_build_ui()
	zone = GameState.get_zone(GameState.current_zone_id)
	_render_zone()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(760, 500)
	root_vbox.add_theme_constant_override("separation", 10)
	center.add_child(root_vbox)

	zone_title = Label.new()
	zone_title.text = "Zone Title"
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(zone_title)

	zone_description = Label.new()
	zone_description.text = "Zone description."
	zone_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zone_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(zone_description)

	var minigame_title := Label.new()
	minigame_title.text = "Minigames"
	minigame_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(minigame_title)

	minigames_list = ItemList.new()
	minigames_list.custom_minimum_size = Vector2(520, 220)
	root_vbox.add_child(minigames_list)

	status_label = Label.new()
	status_label.text = "Complete this zone to earn your stamp."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	root_vbox.add_child(actions)

	complete_button = Button.new()
	complete_button.text = "Complete Zone"
	complete_button.pressed.connect(_on_CompleteButton_pressed)
	actions.add_child(complete_button)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(_on_BackButton_pressed)
	actions.add_child(back_button)

func _render_zone() -> void:
	if zone.is_empty():
		zone_title.text = "Zone not found"
		zone_description.text = "The selected zone is not available in data/game_content.json."
		complete_button.disabled = true
		return

	zone_title.text = zone.get("title", "Zone")
	zone_description.text = zone.get("description", "")

	minigames_list.clear()
	for minigame_name in zone.get("minigames", []):
		minigames_list.add_item(minigame_name + " (placeholder)")

	if GameState.is_zone_completed(GameState.current_zone_id):
		status_label.text = "Stamp already earned for this zone."
		complete_button.disabled = true
	else:
		status_label.text = "Complete this zone to earn your stamp."
		complete_button.disabled = false

func _on_CompleteButton_pressed() -> void:
	if zone.is_empty():
		return
	GameState.mark_zone_complete(GameState.current_zone_id)
	GameState.save_progress()
	status_label.text = "Stamp earned! Zone complete."
	complete_button.disabled = true

func _on_BackButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

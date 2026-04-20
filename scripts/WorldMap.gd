extends Control

var progress_label: Label
var final_screen_button: Button
var zone_buttons := {}

func _ready() -> void:
	_build_ui()
	GameState.load_progress()
	_refresh()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(520, 430)
	root_vbox.add_theme_constant_override("separation", 8)
	center.add_child(root_vbox)

	var header := Label.new()
	header.text = "Choose a Zone"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(header)

	progress_label = Label.new()
	progress_label.text = "Stamps: 0/5"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(progress_label)

	_add_zone_button(root_vbox, "school_gate", "1. School Gate")
	_add_zone_button(root_vbox, "classroom_survival", "2. Classroom Survival")
	_add_zone_button(root_vbox, "meet_classmates", "3. Meet Your Classmates")
	_add_zone_button(root_vbox, "my_school_card", "4. My School Card")
	_add_zone_button(root_vbox, "final_passport", "5. Final Passport Challenge")

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	root_vbox.add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_on_SaveButton_pressed)
	actions.add_child(save_button)

	final_screen_button = Button.new()
	final_screen_button.text = "Final Screen"
	final_screen_button.pressed.connect(_on_FinalScreenButton_pressed)
	actions.add_child(final_screen_button)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(_on_BackButton_pressed)
	actions.add_child(back_button)

func _add_zone_button(container: VBoxContainer, zone_id: String, label: String) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(_on_zone_pressed.bind(zone_id))
	container.add_child(button)
	zone_buttons[zone_id] = {
		"button": button,
		"label": label
	}

func _refresh() -> void:
	progress_label.text = "Stamps: %d/%d" % [
		GameState.completed_count(),
		GameState.total_stamps()
	]
	final_screen_button.disabled = not GameState.all_zones_completed()
	_update_button_labels()

func _update_button_labels() -> void:
	for zone_key in zone_buttons.keys():
		var zone_id := String(zone_key)
		var zone_meta: Dictionary = zone_buttons[zone_id]
		var button: Button = zone_meta["button"]
		var base_label: String = zone_meta["label"]
		var suffix := " [STAMP]" if GameState.is_zone_completed(zone_id) else ""
		button.text = base_label + suffix

func _on_zone_pressed(zone_id: String) -> void:
	GameState.current_zone_id = zone_id
	get_tree().change_scene_to_file("res://scenes/ZoneScene.tscn")

func _on_SaveButton_pressed() -> void:
	GameState.save_progress()
	_refresh()

func _on_FinalScreenButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FinalScreen.tscn")

func _on_BackButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

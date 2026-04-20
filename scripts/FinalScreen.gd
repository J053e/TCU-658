extends Control

var result_label: Label

func _ready() -> void:
	_build_ui()
	_render_summary()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(820, 420)
	root_vbox.add_theme_constant_override("separation", 12)
	center.add_child(root_vbox)

	var title := Label.new()
	title.text = "My English Passport"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(result_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	root_vbox.add_child(actions)

	var play_again := Button.new()
	play_again.text = "Play Again"
	play_again.pressed.connect(_on_PlayAgainButton_pressed)
	actions.add_child(play_again)

	var main_menu := Button.new()
	main_menu.text = "Main Menu"
	main_menu.pressed.connect(_on_BackToMenuButton_pressed)
	actions.add_child(main_menu)

func _render_summary() -> void:
	var lines := []
	var completed := GameState.completed_count()
	var total := GameState.total_stamps()

	if GameState.all_zones_completed():
		lines.append("Congratulations! You completed your English Passport.")
	else:
		lines.append("You still need to complete all zones before final completion.")
	lines.append("")
	lines.append("Stamps collected: %d/%d" % [completed, total])
	lines.append("School Gate: %s" % _done("school_gate"))
	lines.append("Classroom Survival: %s" % _done("classroom_survival"))
	lines.append("Meet Your Classmates: %s" % _done("meet_classmates"))
	lines.append("My School Card: %s" % _done("my_school_card"))
	lines.append("Final Passport Challenge: %s" % _done("final_passport"))

	result_label.text = "\n".join(lines)

func _done(zone_id: String) -> String:
	return "Done" if GameState.is_zone_completed(zone_id) else "Pending"

func _on_PlayAgainButton_pressed() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

func _on_BackToMenuButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

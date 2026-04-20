extends Control

var progress_label: Label

func _ready() -> void:
	_build_ui()
	progress_label = get_node("Center/VBox/ProgressLabel")
	GameState.load_progress()
	_refresh_progress()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(700, 280)
	root_vbox.add_theme_constant_override("separation", 12)
	center.add_child(root_vbox)

	var title := Label.new()
	title.text = "English Passport: Here I Am!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Godot 4.x project scaffold"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(subtitle)

	var progress := Label.new()
	progress.name = "ProgressLabel"
	progress.text = "Stamps: 0/5"
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(progress)

	var new_game := Button.new()
	new_game.text = "New Game"
	new_game.pressed.connect(_on_NewGameButton_pressed)
	root_vbox.add_child(new_game)

	var continue_game := Button.new()
	continue_game.text = "Continue"
	continue_game.pressed.connect(_on_ContinueButton_pressed)
	root_vbox.add_child(continue_game)

	var exit_game := Button.new()
	exit_game.text = "Exit"
	exit_game.pressed.connect(_on_ExitButton_pressed)
	root_vbox.add_child(exit_game)

func _refresh_progress() -> void:
	progress_label.text = "Stamps: %d/%d" % [
		GameState.completed_count(),
		GameState.total_stamps()
	]

func _on_NewGameButton_pressed() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

func _on_ContinueButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

func _on_ExitButton_pressed() -> void:
	get_tree().quit()

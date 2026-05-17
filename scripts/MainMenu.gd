extends Control

const MENU_BG_PATH := "res://assets/ui/backgrounds/main_menu_bg.png"

func _ready() -> void:
	_build_ui()
	GameState.load_progress()

func _build_ui() -> void:
	GameState.decorate_screen(self, MENU_BG_PATH)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(760, 320)
	root_vbox.add_theme_constant_override("separation", 12)
	center.add_child(root_vbox)

	var title := Label.new()
	title.text = "English Passport: Here I Am!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title, 56, true)
	root_vbox.add_child(title)

	var new_game := Button.new()
	new_game.text = "New Game"
	GameState.style_menu_button(new_game, "blue")
	new_game.pressed.connect(_on_NewGameButton_pressed)
	root_vbox.add_child(new_game)

	var continue_game := Button.new()
	continue_game.text = "Continue"
	GameState.style_menu_button(continue_game, "green")
	continue_game.pressed.connect(_on_ContinueButton_pressed)
	root_vbox.add_child(continue_game)

	var exit_game := Button.new()
	exit_game.text = "Exit"
	GameState.style_menu_button(exit_game, "orange")
	exit_game.pressed.connect(_on_ExitButton_pressed)
	root_vbox.add_child(exit_game)

func _on_NewGameButton_pressed() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/IntroScreen.tscn")

func _on_ContinueButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

func _on_ExitButton_pressed() -> void:
	get_tree().quit()

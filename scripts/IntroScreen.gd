extends Control

const INTRO_BG_PATH := "res://assets/ui/backgrounds/intro_screen_bg.png"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	GameState.decorate_screen(self, INTRO_BG_PATH)

	var screen_margin := MarginContainer.new()
	screen_margin.name = "ScreenMargin"
	screen_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_margin.add_theme_constant_override("margin_left", 110)
	screen_margin.add_theme_constant_override("margin_top", 44)
	screen_margin.add_theme_constant_override("margin_right", 110)
	screen_margin.add_theme_constant_override("margin_bottom", 44)
	add_child(screen_margin)

	var panel := PanelContainer.new()
	screen_margin.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 20)
	content_margin.add_theme_constant_override("margin_top", 14)
	content_margin.add_theme_constant_override("margin_right", 20)
	content_margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(content_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	content_margin.add_child(root_vbox)

	var intro_text := Label.new()
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_text.text = "Welcome to school! Today is your first day and you're the new student. Time to start talking! Choose the right words, follow simple instructions, and complete your English Passport.\n\nGame Objective Collect 5 stamps to complete your English Passport.\n\nStamps to Earn:\nSchool Gate\nClassroom Survival\nMeet Your Classmates\nMy School Card\nFinal Passport Challenge\n\nHow to Play\nRead or listen to each situation.\nChoose the best response.\nDrag and drop when necessary.\nComplete sentences with helpful hints.\nEarn a stamp in every zone."
	GameState.style_label(intro_text, 20, false)
	root_vbox.add_child(intro_text)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(actions)

	var start_button := Button.new()
	start_button.text = "Start"
	GameState.style_menu_button(start_button, "green")
	start_button.pressed.connect(_on_Start_pressed)
	actions.add_child(start_button)

	var back_button := Button.new()
	back_button.text = "Back to Menu"
	GameState.style_menu_button(back_button, "purple")
	back_button.pressed.connect(_on_Back_pressed)
	actions.add_child(back_button)

func _on_Start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")

func _on_Back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

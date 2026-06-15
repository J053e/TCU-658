extends Control

const CREDITS_BG_PATH := "res://assets/ui/backgrounds/intro_screen_bg.png"
const CREDITS_TEXT := "Juego creado y diseñado por Jose Carlos Mena Díaz\n\nMúsica por Jose Carlos Díaz\n\nImágenes diseñadas por Jose Carlos Mena Díaz y tratadas con Inteligencia Artificial\n\nPara el Trabajo Comunal 658: Cooperación con el Proceso de Enseñanza-Aprendizaje del Inglés en Educación Secundaria\n\nEscuela de Lenguas Modernas\n\nUniversidad de Costa Rica"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.play_menu_music()
	_build_ui()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	GameState.decorate_screen(self, CREDITS_BG_PATH)

	var screen_margin := MarginContainer.new()
	screen_margin.name = "ScreenMargin"
	screen_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_margin.add_theme_constant_override("margin_left", 150)
	screen_margin.add_theme_constant_override("margin_top", 78)
	screen_margin.add_theme_constant_override("margin_right", 150)
	screen_margin.add_theme_constant_override("margin_bottom", 78)
	add_child(screen_margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _credits_panel_style())
	screen_margin.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 34)
	content_margin.add_theme_constant_override("margin_top", 28)
	content_margin.add_theme_constant_override("margin_right", 34)
	content_margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(content_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_theme_constant_override("separation", 22)
	content_margin.add_child(root_vbox)

	var title := Label.new()
	title.text = "Credits"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title, 42, true)
	root_vbox.add_child(title)

	var credits_label := Label.new()
	credits_label.text = CREDITS_TEXT
	credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credits_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	GameState.style_label(credits_label, 24, false)
	root_vbox.add_child(credits_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	root_vbox.add_child(actions)

	var new_game := Button.new()
	new_game.text = "New Game"
	GameState.style_menu_button(new_game, "green")
	new_game.pressed.connect(_on_NewGame_pressed)
	actions.add_child(new_game)

	var menu_button := Button.new()
	menu_button.text = "Menu"
	GameState.style_menu_button(menu_button, "purple")
	menu_button.pressed.connect(_on_Menu_pressed)
	actions.add_child(menu_button)

func _on_NewGame_pressed() -> void:
	GameState.reset_progress()
	GameState.change_scene_with_transition("res://scenes/IntroScreen.tscn")

func _on_Menu_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MainMenu.tscn", true)

func _credits_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.18, 0.72)
	sb.border_color = Color(0.76, 0.88, 1.0, 0.88)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	return sb

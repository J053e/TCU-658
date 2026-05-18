extends Control

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("classroom_survival", "classroom_language"))
	_build_ui()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(880, 360)
	v.add_theme_constant_override("separation", 12)
	center.add_child(v)

	var t := Label.new()
	t.text = "Classroom Language"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(t, 38, true)
	v.add_child(t)

	var d := Label.new()
	d.text = "This challenge is ready for your next implementation step."
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(d, 24, false)
	v.add_child(d)

	var back := Button.new()
	back.text = "Back"
	GameState.style_menu_button(back, "orange")
	back.pressed.connect(_on_back_pressed)
	v.add_child(back)

func _on_back_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)


extends Control

const CHALLENGE_ID := "my_school_card_fill_profile"
const PASS_RATIO := 0.70

var title_label: Label
var info_label: Label
var feedback_label: Label
var complete_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label

var finished: bool = false

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("my_school_card", "fill_profile"))
	_build_ui()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_show_intro()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(980, 540)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_theme_constant_override("separation", 14)
	center.add_child(root)

	title_label = Label.new()
	title_label.text = "Fill the Profile"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 40, true)
	root.add_child(title_label)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(0, 120)
	GameState.style_label(info_label, 24, false)
	root.add_child(info_label)

	complete_button = Button.new()
	complete_button.text = "Complete Placeholder"
	complete_button.custom_minimum_size = Vector2(420, 88)
	complete_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(complete_button, "green")
	complete_button.pressed.connect(_on_complete_pressed)
	root.add_child(complete_button)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 68)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	continue_button = Button.new()
	continue_button.text = "Back to Zone"
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	actions.add_child(continue_button)

	back_button = Button.new()
	back_button.text = "Back"
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_back_pressed)
	actions.add_child(back_button)

	repeat_button = Button.new()
	repeat_button.text = "Repeat"
	GameState.style_menu_button(repeat_button, "purple")
	repeat_button.visible = false
	repeat_button.pressed.connect(_on_repeat_pressed)
	actions.add_child(repeat_button)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(status_label, 20, true)
	actions.add_child(status_label)

func _show_intro() -> void:
	finished = false
	info_label.text = "Placeholder challenge for Zone 4.\nPress the button to simulate completion and validate medal flow."
	feedback_label.text = ""
	complete_button.visible = true
	complete_button.disabled = false
	continue_button.visible = false
	repeat_button.visible = false
	status_label.visible = false

func _on_complete_pressed() -> void:
	var result := GameState.record_challenge_result(CHALLENGE_ID, 1, 1, PASS_RATIO)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", 1)), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	info_label.text = "Challenge Complete"
	complete_button.visible = false
	continue_button.visible = true
	repeat_button.visible = true
	status_label.visible = true

	if passed:
		feedback_label.text = "Stamp progress saved.\nBest score: " + str(best_correct) + "/" + str(total)
		status_label.text = "Status: Approved"
		status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		feedback_label.text = "You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
		status_label.text = "Status: Failed"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

func _on_repeat_pressed() -> void:
	_show_intro()

func _on_continue_pressed() -> void:
	_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)

func _on_back_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _exit_with_badge_popup(scene_path: String, is_back: bool) -> void:
	GameState.show_badge_popup_or_continue(
		self,
		"my_school_card",
		Callable(self, "_change_scene_after_popup").bind(scene_path, is_back)
	)

func _change_scene_after_popup(scene_path: String, is_back: bool) -> void:
	GameState.change_scene_with_transition(scene_path, is_back)

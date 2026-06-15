extends Control

const DATA_PATH := "res://data/meet_politeness_fix.json"
const PASS_RATIO := 0.70
const CHALLENGE_ID := "meet_politeness_fix"

const DropSlotScript = preload("res://scripts/DialogueDropSlot.gd")
const DragSentenceButtonScript = preload("res://scripts/DragSentenceButton.gd")
const BankDropAreaScript = preload("res://scripts/DialogueBankDropArea.gd")

var progress_label: Label
var prompt_label: Label
var feedback_label: Label
var screen_title_label: Label
var top_spacer: Control
var image_rect: TextureRect
var dialogue_context_label: Label
var dialogue_speaker_label: Label
var dialogue_suffix_label: Label
var socket_slot
var bank_title: Label
var bank_flow: FlowContainer
var bank_panel
var content_vbox: VBoxContainer
var check_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var result_status_label: Label

var quiz_data: Dictionary = {}
var situations: Array = []
var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var finished: bool = false

var current_option_map: Dictionary = {}
var current_option_ids: Array[String] = []
var selected_option_id: String = ""
var bank_ids: Array[String] = []

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("meet_classmates", "politeness_fix"))
	_build_ui()
	_load_data()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_start_new_attempt()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	screen_title_label = Label.new()
	screen_title_label.text = "Politeness Fix"
	screen_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(screen_title_label, 36, true)
	root.add_child(screen_title_label)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 0)
	root.add_child(top_spacer)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 22, false)
	root.add_child(progress_label)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(0, 34)
	GameState.style_label(prompt_label, 22, true)
	root.add_child(prompt_label)

	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_vbox.add_theme_constant_override("separation", 10)
	root.add_child(content_vbox)

	var image_panel := PanelContainer.new()
	image_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image_panel.custom_minimum_size = Vector2(0, 142)
	image_panel.add_theme_stylebox_override("panel", _panel_style())
	content_vbox.add_child(image_panel)

	var image_margin := MarginContainer.new()
	image_margin.add_theme_constant_override("margin_left", 10)
	image_margin.add_theme_constant_override("margin_top", 10)
	image_margin.add_theme_constant_override("margin_right", 10)
	image_margin.add_theme_constant_override("margin_bottom", 10)
	image_panel.add_child(image_margin)

	image_rect = TextureRect.new()
	image_rect.custom_minimum_size = Vector2(0, 118)
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_margin.add_child(image_rect)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_panel.custom_minimum_size = Vector2(0, 96)
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style())
	content_vbox.add_child(dialogue_panel)

	var dialogue_margin := MarginContainer.new()
	dialogue_margin.add_theme_constant_override("margin_left", 12)
	dialogue_margin.add_theme_constant_override("margin_top", 10)
	dialogue_margin.add_theme_constant_override("margin_right", 12)
	dialogue_margin.add_theme_constant_override("margin_bottom", 10)
	dialogue_panel.add_child(dialogue_margin)

	var dialogue_vbox := VBoxContainer.new()
	dialogue_vbox.add_theme_constant_override("separation", 8)
	dialogue_margin.add_child(dialogue_vbox)

	dialogue_context_label = Label.new()
	dialogue_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameState.style_label(dialogue_context_label, 22, true)
	dialogue_vbox.add_child(dialogue_context_label)

	var blank_row := HBoxContainer.new()
	blank_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blank_row.alignment = BoxContainer.ALIGNMENT_CENTER
	blank_row.add_theme_constant_override("separation", 8)
	dialogue_vbox.add_child(blank_row)

	dialogue_speaker_label = Label.new()
	GameState.style_label(dialogue_speaker_label, 24, true)
	blank_row.add_child(dialogue_speaker_label)

	socket_slot = DropSlotScript.new()
	socket_slot.custom_minimum_size = Vector2(320, 64)
	socket_slot.add_theme_stylebox_override("panel", _slot_style())
	socket_slot.configure(0)
	socket_slot.sentence_dropped.connect(_on_slot_sentence_dropped)
	socket_slot.sentence_cleared.connect(_on_slot_sentence_cleared)
	blank_row.add_child(socket_slot)

	dialogue_suffix_label = Label.new()
	GameState.style_label(dialogue_suffix_label, 24, true)
	blank_row.add_child(dialogue_suffix_label)

	bank_panel = BankDropAreaScript.new()
	bank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bank_panel.custom_minimum_size = Vector2(0, 110)
	bank_panel.add_theme_stylebox_override("panel", _panel_style())
	bank_panel.sentence_returned.connect(_on_bank_sentence_returned)
	content_vbox.add_child(bank_panel)

	var bank_margin := MarginContainer.new()
	bank_margin.add_theme_constant_override("margin_left", 10)
	bank_margin.add_theme_constant_override("margin_top", 10)
	bank_margin.add_theme_constant_override("margin_right", 10)
	bank_margin.add_theme_constant_override("margin_bottom", 10)
	bank_panel.add_child(bank_margin)

	var bank_vbox := VBoxContainer.new()
	bank_vbox.add_theme_constant_override("separation", 4)
	bank_margin.add_child(bank_vbox)

	bank_title = Label.new()
	bank_title.text = "Word Bank (drag to socket)"
	bank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(bank_title, 20, false)
	bank_vbox.add_child(bank_title)

	bank_flow = FlowContainer.new()
	bank_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	bank_flow.last_wrap_alignment = FlowContainer.LAST_WRAP_ALIGNMENT_CENTER
	bank_flow.add_theme_constant_override("h_separation", 8)
	bank_flow.add_theme_constant_override("v_separation", 8)
	bank_vbox.add_child(bank_flow)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 22)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	actions.custom_minimum_size = Vector2(0, 56)
	root.add_child(actions)

	check_button = Button.new()
	check_button.text = "Check"
	GameState.style_menu_button(check_button, "green")
	check_button.pressed.connect(_on_check_pressed)
	actions.add_child(check_button)

	continue_button = Button.new()
	continue_button.text = "Continue"
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.disabled = true
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

	result_status_label = Label.new()
	result_status_label.visible = false
	result_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(result_status_label, 18, true)
	actions.add_child(result_status_label)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 10)
	root.add_child(bottom_spacer)

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.09, 0.18, 0.84)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.92)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	return sb

func _slot_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.24, 0.9)
	sb.border_color = Color(0.76, 0.88, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.set_content_margin_all(10)
	return sb

func _bank_chip_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.21, 0.55, 0.93, 0.97)
	sb.border_color = Color(0.76, 0.92, 1.0, 0.98)
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_right = 20
	sb.corner_radius_bottom_left = 20
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _load_data() -> void:
	quiz_data = GameState.load_json_data(DATA_PATH)
	situations = quiz_data.get("situations", [])

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	finished = false
	_show_situation()

func _show_situation() -> void:
	if situations.is_empty():
		progress_label.text = "Data missing"
		prompt_label.text = ""
		return
	if current_index >= situations.size():
		_finish_challenge()
		return

	answered_current = false
	screen_title_label.visible = true
	check_button.visible = true
	back_button.visible = true
	continue_button.visible = false
	continue_button.disabled = true
	continue_button.text = "Continue"
	check_button.disabled = false
	repeat_button.visible = false
	result_status_label.visible = false
	feedback_label.text = ""
	bank_title.text = "Word Bank (drag to socket)"
	top_spacer.custom_minimum_size = Vector2(0, 0)
	content_vbox.visible = true
	progress_label.add_theme_font_size_override("font_size", 22)
	progress_label.add_theme_constant_override("outline_size", 0)
	progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	prompt_label.add_theme_font_size_override("font_size", 22)
	prompt_label.custom_minimum_size = Vector2(0, 34)
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.custom_minimum_size = Vector2(0, 22)
	result_status_label.add_theme_font_size_override("font_size", 18)

	var item: Dictionary = situations[current_index]
	progress_label.text = "Situation " + str(current_index + 1) + "/" + str(situations.size())
	prompt_label.text = String(quiz_data.get("instruction", "Choose the option that best completes the mini dialogue."))

	var image_path := String(item.get("image", ""))
	if image_path != "" and ResourceLoader.exists(image_path):
		image_rect.texture = _load_fitted_image(image_path, Vector2i(1000, 112))
	else:
		image_rect.texture = null

	var prefix_text := String(item.get("prompt_prefix", ""))
	var suffix_text := String(item.get("prompt_suffix", ""))
	var prefix_lines := prefix_text.split("\n")
	if prefix_lines.size() > 1:
		dialogue_context_label.text = "\n".join(prefix_lines.slice(0, prefix_lines.size() - 1))
		dialogue_speaker_label.text = String(prefix_lines[prefix_lines.size() - 1])
	else:
		dialogue_context_label.text = ""
		dialogue_speaker_label.text = prefix_text
	dialogue_suffix_label.text = suffix_text

	current_option_map.clear()
	current_option_ids.clear()
	selected_option_id = ""
	var options: Array = item.get("options", [])
	for i in range(options.size()):
		var sid := "q" + str(i)
		current_option_ids.append(sid)
		current_option_map[sid] = String(options[i])

	bank_ids = current_option_ids.duplicate()
	bank_ids.shuffle()

	_render_socket()
	_render_bank()

func _render_socket() -> void:
	if socket_slot == null:
		return
	socket_slot.set_locked(answered_current)
	if selected_option_id != "" and current_option_map.has(selected_option_id):
		socket_slot.set_sentence(selected_option_id, String(current_option_map[selected_option_id]))
	else:
		socket_slot.clear_sentence()

func _render_bank() -> void:
	for child in bank_flow.get_children():
		child.queue_free()
	for sid_variant in bank_ids:
		var sid := String(sid_variant)
		if not current_option_map.has(sid):
			continue
		var chip = DragSentenceButtonScript.new()
		chip.setup(sid, String(current_option_map[sid]))
		chip.drag_enabled = not answered_current
		chip.custom_minimum_size = Vector2(230, 56)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.set_chip_style(_bank_chip_style())
		if chip.has_method("set_label_style"):
			chip.set_label_style(GameState.pretty_font, 20)
		bank_flow.add_child(chip)
	if bank_panel != null:
		bank_panel.set_locked(answered_current)

func _on_slot_sentence_dropped(_slot_index: int, sentence_id: String) -> void:
	if answered_current:
		return
	if sentence_id == "" or not current_option_map.has(sentence_id):
		return

	if selected_option_id != "":
		bank_ids.append(selected_option_id)

	var idx := bank_ids.find(sentence_id)
	if idx >= 0:
		bank_ids.remove_at(idx)

	selected_option_id = sentence_id
	_render_socket()
	_render_bank()

func _on_slot_sentence_cleared(_slot_index: int) -> void:
	if answered_current:
		return
	if selected_option_id == "":
		return
	bank_ids.append(selected_option_id)
	selected_option_id = ""
	_render_socket()
	_render_bank()

func _on_bank_sentence_returned(sentence_id: String) -> void:
	if answered_current:
		return
	if sentence_id == "":
		return
	if selected_option_id == sentence_id:
		selected_option_id = ""
		if bank_ids.find(sentence_id) < 0:
			bank_ids.append(sentence_id)
	_render_socket()
	_render_bank()

func _on_check_pressed() -> void:
	if answered_current:
		return
	if selected_option_id == "":
		feedback_label.text = "Drag one option into the socket first."
		return

	answered_current = true
	check_button.disabled = true
	continue_button.disabled = true

	var item: Dictionary = situations[current_index]
	var correct_index: int = int(item.get("correct_index", -1))
	var correct_id := "q" + str(correct_index)
	var is_correct := selected_option_id == correct_id
	var popup_text := ""

	if is_correct:
		correct_total += 1
		popup_text = String(item.get("correct_feedback", "Correct!"))
	else:
		popup_text = String(item.get("incorrect_feedback", "Try again."))

	feedback_label.text = ""
	bank_title.text = "Word Bank"
	_render_socket()
	_render_bank()
	GameState.show_answer_feedback_popup(self, popup_text, is_correct, Callable(self, "_on_continue_pressed"))

func _on_continue_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_situation()

func _finish_challenge() -> void:
	finished = true
	var result := GameState.record_challenge_result(CHALLENGE_ID, correct_total, situations.size(), PASS_RATIO)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("meet_classmates")
	_show_summary(result)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("meet_classmates")
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", situations.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	progress_label.text = "Challenge Complete"
	screen_title_label.visible = false
	progress_label.add_theme_font_size_override("font_size", 26)
	progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	progress_label.add_theme_constant_override("outline_size", 4)
	top_spacer.custom_minimum_size = Vector2(0, 84)
	prompt_label.custom_minimum_size = Vector2(0, 120)
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.text = "Choose the most polite option for each mini dialogue."
	feedback_label.custom_minimum_size = Vector2(0, 64)
	feedback_label.add_theme_font_size_override("font_size", 20)
	result_status_label.add_theme_font_size_override("font_size", 20)

	content_vbox.visible = false
	check_button.visible = false
	if passed:
		feedback_label.text = "Stamp progress saved.\nBest score: " + str(best_correct) + "/" + str(total)
	else:
		feedback_label.text = "You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

	continue_button.visible = true
	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	result_status_label.visible = true
	if passed:
		result_status_label.text = "Status: Approved"
		result_status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		result_status_label.text = "Status: Failed"
		result_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))

func _on_repeat_pressed() -> void:
	content_vbox.visible = true
	check_button.visible = true
	_start_new_attempt()

func _on_back_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _exit_with_badge_popup(scene_path: String, is_back: bool) -> void:
	GameState.show_badge_popup_or_continue(
		self,
		"meet_classmates",
		Callable(self, "_change_scene_after_popup").bind(scene_path, is_back)
	)

func _change_scene_after_popup(scene_path: String, is_back: bool) -> void:
	GameState.change_scene_with_transition(scene_path, is_back)

func _load_fitted_image(path: String, max_size: Vector2i) -> Texture2D:
	var tex := GameState.load_texture_resource(path)
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return tex

	var source_w := img.get_width()
	var source_h := img.get_height()
	if source_w <= 0 or source_h <= 0:
		return tex

	var scale := minf(float(max_size.x) / float(source_w), float(max_size.y) / float(source_h))
	scale = minf(scale, 1.0)
	var target_w := maxi(int(round(float(source_w) * scale)), 1)
	var target_h := maxi(int(round(float(source_h) * scale)), 1)

	img.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


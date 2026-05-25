extends Control

const DATA_PATH := "res://data/meet_order_dialogue.json"
const PASS_RATIO := 0.70
const CHALLENGE_ID := "meet_order_dialogue"

const DropSlotScript = preload("res://scripts/DialogueDropSlot.gd")
const DragSentenceButtonScript = preload("res://scripts/DragSentenceButton.gd")
const BankDropAreaScript = preload("res://scripts/DialogueBankDropArea.gd")

var progress_label: Label
var prompt_label: Label
var feedback_label: Label
var screen_title_label: Label
var top_spacer: Control
var slots_box: VBoxContainer
var bank_title: Label
var bank_flow: FlowContainer
var bank_panel
var content_row: HBoxContainer
var check_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var result_status_label: Label

var dialogue_data: Dictionary = {}
var dialogues: Array = []
var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var finished: bool = false

var current_sentence_map: Dictionary = {}
var current_order_ids: Array[String] = []
var slot_assignments: Array[String] = []
var bank_ids: Array[String] = []
var slot_controls: Array = []

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("meet_classmates", "order_dialogue"))
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
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	screen_title_label = Label.new()
	screen_title_label.text = "Order the Dialogue"
	screen_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(screen_title_label, 36, true)
	root.add_child(screen_title_label)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 4)
	root.add_child(top_spacer)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 22, false)
	root.add_child(progress_label)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(0, 40)
	GameState.style_label(prompt_label, 22, true)
	root.add_child(prompt_label)

	content_row = HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 12)
	root.add_child(content_row)

	var sockets_panel := PanelContainer.new()
	sockets_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sockets_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sockets_panel.add_theme_stylebox_override("panel", _panel_style())
	content_row.add_child(sockets_panel)

	var sockets_margin := MarginContainer.new()
	sockets_margin.add_theme_constant_override("margin_left", 10)
	sockets_margin.add_theme_constant_override("margin_top", 10)
	sockets_margin.add_theme_constant_override("margin_right", 10)
	sockets_margin.add_theme_constant_override("margin_bottom", 10)
	sockets_panel.add_child(sockets_margin)

	slots_box = VBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 6)
	sockets_margin.add_child(slots_box)

	bank_panel = BankDropAreaScript.new()
	bank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_panel.custom_minimum_size = Vector2(470, 0)
	bank_panel.add_theme_stylebox_override("panel", _panel_style())
	bank_panel.sentence_returned.connect(_on_bank_sentence_returned)
	content_row.add_child(bank_panel)

	var bank_margin := MarginContainer.new()
	bank_margin.add_theme_constant_override("margin_left", 10)
	bank_margin.add_theme_constant_override("margin_top", 10)
	bank_margin.add_theme_constant_override("margin_right", 10)
	bank_margin.add_theme_constant_override("margin_bottom", 10)
	bank_panel.add_child(bank_margin)

	var bank_vbox := VBoxContainer.new()
	bank_vbox.add_theme_constant_override("separation", 8)
	bank_margin.add_child(bank_vbox)

	bank_title = Label.new()
	bank_title.text = "Sentence Bank (drag to sockets)"
	bank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(bank_title, 20, false)
	bank_vbox.add_child(bank_title)

	bank_flow = FlowContainer.new()
	bank_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_flow.add_theme_constant_override("h_separation", 8)
	bank_flow.add_theme_constant_override("v_separation", 8)
	bank_vbox.add_child(bank_flow)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 30)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
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

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	dialogue_data = parsed as Dictionary
	dialogues = dialogue_data.get("dialogues", [])

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	finished = false
	_show_dialogue()

func _show_dialogue() -> void:
	if dialogues.is_empty():
		progress_label.text = "Dialogue data missing"
		prompt_label.text = ""
		return
	if current_index >= dialogues.size():
		_finish_challenge()
		return

	answered_current = false
	screen_title_label.visible = true
	continue_button.disabled = true
	continue_button.text = "Continue"
	continue_button.visible = true
	check_button.disabled = false
	check_button.visible = true
	repeat_button.visible = false
	result_status_label.visible = false
	feedback_label.text = ""
	bank_title.text = "Sentence Bank (drag to sockets)"
	top_spacer.custom_minimum_size = Vector2(0, 4)
	content_row.visible = true
	slots_box.visible = true
	bank_panel.visible = true
	progress_label.add_theme_font_size_override("font_size", 22)
	progress_label.add_theme_constant_override("outline_size", 0)
	prompt_label.add_theme_font_size_override("font_size", 22)
	feedback_label.add_theme_font_size_override("font_size", 20)
	result_status_label.add_theme_font_size_override("font_size", 18)

	var dialogue: Dictionary = dialogues[current_index]
	var label := String(dialogue.get("label", "Dialogue"))
	progress_label.text = label + "  " + str(current_index + 1) + "/" + str(dialogues.size())
	prompt_label.text = "Drag each sentence to the correct socket."

	var blocks: Array = dialogue.get("blocks", [])
	current_sentence_map.clear()
	current_order_ids.clear()
	for i in range(blocks.size()):
		var sid := "s" + str(i)
		current_order_ids.append(sid)
		current_sentence_map[sid] = String(blocks[i])

	slot_assignments.clear()
	slot_assignments.resize(blocks.size())
	for i in range(slot_assignments.size()):
		slot_assignments[i] = ""

	bank_ids = current_order_ids.duplicate()
	bank_ids.shuffle()

	_render_slots()
	_render_bank()

func _render_slots() -> void:
	for child in slots_box.get_children():
		child.queue_free()
	slot_controls.clear()

	for i in range(slot_assignments.size()):
		var slot = DropSlotScript.new()
		slot.custom_minimum_size = Vector2(560, 52)
		slot.add_theme_stylebox_override("panel", _slot_style())
		slot.configure(i)
		slot.set_locked(answered_current)
		slot.sentence_dropped.connect(_on_slot_sentence_dropped)
		slot.sentence_cleared.connect(_on_slot_sentence_cleared)
		var sid := String(slot_assignments[i])
		if sid != "" and current_sentence_map.has(sid):
			slot.set_sentence(sid, str(i + 1) + ". " + String(current_sentence_map[sid]))
		else:
			slot.clear_sentence()
		slots_box.add_child(slot)
		slot_controls.append(slot)

func _render_bank() -> void:
	for child in bank_flow.get_children():
		child.queue_free()
	for sid_variant in bank_ids:
		var sid := String(sid_variant)
		if not current_sentence_map.has(sid):
			continue
		var chip = DragSentenceButtonScript.new()
		chip.setup(sid, String(current_sentence_map[sid]))
		chip.drag_enabled = not answered_current
		chip.custom_minimum_size = Vector2(222, 56)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.set_chip_style(_bank_chip_style())
		if chip.has_method("set_label_style"):
			chip.set_label_style(GameState.pretty_font, 20)
		bank_flow.add_child(chip)
	if bank_panel != null:
		bank_panel.set_locked(answered_current)

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

func _on_slot_sentence_dropped(slot_index: int, sentence_id: String) -> void:
	if answered_current:
		return
	if sentence_id == "":
		return
	if not current_sentence_map.has(sentence_id):
		return

	var existing := String(slot_assignments[slot_index])
	if existing != "":
		bank_ids.append(existing)

	for i in range(slot_assignments.size()):
		if String(slot_assignments[i]) == sentence_id:
			slot_assignments[i] = ""

	var bank_pos := bank_ids.find(sentence_id)
	if bank_pos >= 0:
		bank_ids.remove_at(bank_pos)

	slot_assignments[slot_index] = sentence_id
	_render_slots()
	_render_bank()

func _on_slot_sentence_cleared(slot_index: int) -> void:
	if answered_current:
		return
	if slot_index < 0 or slot_index >= slot_assignments.size():
		return
	var sid := String(slot_assignments[slot_index])
	if sid == "":
		return
	slot_assignments[slot_index] = ""
	bank_ids.append(sid)
	_render_slots()
	_render_bank()

func _on_bank_sentence_returned(sentence_id: String) -> void:
	if answered_current:
		return
	if sentence_id == "":
		return
	for i in range(slot_assignments.size()):
		if String(slot_assignments[i]) == sentence_id:
			slot_assignments[i] = ""
			if bank_ids.find(sentence_id) < 0:
				bank_ids.append(sentence_id)
			break
	_render_slots()
	_render_bank()

func _on_check_pressed() -> void:
	if answered_current:
		return
	for sid in slot_assignments:
		if String(sid) == "":
			feedback_label.text = "Complete all sockets first."
			return

	answered_current = true
	check_button.disabled = true
	continue_button.disabled = false

	var is_correct := true
	for i in range(current_order_ids.size()):
		if String(slot_assignments[i]) != String(current_order_ids[i]):
			is_correct = false
			break

	var dialogue: Dictionary = dialogues[current_index]
	if is_correct:
		correct_total += 1
		feedback_label.text = String(dialogue.get("correct_feedback", "Correct order!"))
	else:
		feedback_label.text = String(dialogue.get("incorrect_feedback", "Check the order again."))

	bank_title.text = "Sentence Bank"
	_render_slots()
	_render_bank()

func _on_continue_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_dialogue()

func _finish_challenge() -> void:
	finished = true
	var result := GameState.record_challenge_result(CHALLENGE_ID, correct_total, dialogues.size(), PASS_RATIO)
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
	var total := maxi(int(result.get("total_questions", dialogues.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	progress_label.text = "Challenge Complete"
	screen_title_label.visible = false
	progress_label.add_theme_font_size_override("font_size", 26)
	progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	progress_label.add_theme_constant_override("outline_size", 4)
	top_spacer.custom_minimum_size = Vector2(0, 112)
	prompt_label.custom_minimum_size = Vector2(0, 120)
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.text = "Order the dialogue from start to finish."
	content_row.visible = false
	check_button.visible = false
	feedback_label.custom_minimum_size = Vector2(0, 64)
	feedback_label.add_theme_font_size_override("font_size", 20)
	if passed:
		feedback_label.text = "Stamp progress saved.\nBest score: " + str(best_correct) + "/" + str(total)
	else:
		feedback_label.text = "You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	result_status_label.visible = true
	result_status_label.add_theme_font_size_override("font_size", 20)
	if passed:
		result_status_label.text = "Status: Approved"
		result_status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		result_status_label.text = "Status: Failed"
		result_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))

func _on_repeat_pressed() -> void:
	content_row.visible = true
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

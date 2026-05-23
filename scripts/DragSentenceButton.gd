extends Control

var sentence_id: String = ""
var sentence_text: String = ""
var drag_enabled: bool = true

var frame: PanelContainer
var text_label: Label
var drag_hint_panel: PanelContainer
var drag_hint_label: Label
var frame_style: StyleBoxFlat
var is_dragging_now: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_build_ui()
	_update_content()

func setup(id_value: String, text_value: String) -> void:
	sentence_id = id_value
	sentence_text = text_value
	if text_label != null:
		_update_content()

func set_chip_style(style_box: StyleBoxFlat) -> void:
	frame_style = style_box
	if frame != null and frame_style != null:
		frame.add_theme_stylebox_override("panel", frame_style)

func set_label_style(font: Font, font_size: int) -> void:
	if text_label == null:
		return
	text_label.add_theme_font_override("font", font)
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _get_drag_data(at_position: Vector2) -> Variant:
	if not drag_enabled:
		return null
	set_drag_preview(_build_drag_preview(at_position))
	return {"sentence_id": sentence_id}

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return false

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if drag_hint_panel != null and drag_enabled and not is_dragging_now:
			drag_hint_panel.visible = true
	elif what == NOTIFICATION_MOUSE_EXIT:
		if drag_hint_panel != null:
			drag_hint_panel.visible = false
	elif what == NOTIFICATION_DRAG_BEGIN:
		is_dragging_now = true
		if frame != null:
			frame.visible = false
		if drag_hint_panel != null:
			drag_hint_panel.visible = false
	elif what == NOTIFICATION_DRAG_END:
		is_dragging_now = false
		if not is_drag_successful() and frame != null:
			frame.visible = true

func _build_ui() -> void:
	if frame != null:
		return

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	frame = PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if frame_style != null:
		frame.add_theme_stylebox_override("panel", frame_style)
	root.add_child(frame)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	frame.add_child(margin)

	text_label = Label.new()
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(text_label)

	drag_hint_panel = PanelContainer.new()
	drag_hint_panel.visible = false
	drag_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_hint_panel.anchor_left = 0.5
	drag_hint_panel.anchor_right = 0.5
	drag_hint_panel.anchor_top = 0.0
	drag_hint_panel.anchor_bottom = 0.0
	drag_hint_panel.offset_left = -28
	drag_hint_panel.offset_right = 28
	drag_hint_panel.offset_top = -24
	drag_hint_panel.offset_bottom = -4
	drag_hint_panel.add_theme_stylebox_override("panel", _drag_hint_style())
	add_child(drag_hint_panel)

	drag_hint_label = Label.new()
	drag_hint_label.text = "drag"
	drag_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_hint_label.add_theme_font_size_override("font_size", 12)
	drag_hint_label.add_theme_color_override("font_color", Color(0.10, 0.10, 0.10))
	drag_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_hint_panel.add_child(drag_hint_label)

func _update_content() -> void:
	if text_label != null:
		text_label.text = sentence_text

func _build_drag_preview(grab_offset: Vector2) -> Control:
	var preview_root := Control.new()
	preview_root.custom_minimum_size = size + Vector2(32, 32)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.position = -grab_offset
	if frame_style != null:
		panel.add_theme_stylebox_override("panel", frame_style)
	preview_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var preview_label := Label.new()
	preview_label.text = sentence_text
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.add_theme_color_override("font_color", Color(1, 1, 1))
	if text_label != null:
		var theme_font := text_label.get_theme_font("font")
		if theme_font != null:
			preview_label.add_theme_font_override("font", theme_font)
		var theme_size := text_label.get_theme_font_size("font_size")
		if theme_size > 0:
			preview_label.add_theme_font_size_override("font_size", theme_size)
	margin.add_child(preview_label)

	return preview_root

func _drag_hint_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.95)
	sb.border_color = Color(0.88, 0.88, 0.88, 1)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	return sb

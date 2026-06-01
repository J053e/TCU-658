extends PanelContainer

signal sentence_dropped(slot_index: int, sentence_id: String)
signal sentence_cleared(slot_index: int)

var slot_index: int = -1
var sentence_id: String = ""
var sentence_text: String = ""
var locked: bool = false
var text_min_height: int = 46
var empty_text: String = "Drop sentence here"

var text_label: Label

func _ready() -> void:
	text_label = Label.new()
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.custom_minimum_size = Vector2(0, text_min_height)
	add_child(text_label)
	_update_text()

func set_text_min_height(value: int) -> void:
	text_min_height = maxi(value, 14)
	if text_label != null:
		text_label.custom_minimum_size = Vector2(0, text_min_height)

func configure(index_value: int) -> void:
	slot_index = index_value

func set_empty_text(value: String) -> void:
	empty_text = value
	if sentence_id == "":
		_update_text()

func set_locked(value: bool) -> void:
	locked = value

func set_sentence(id_value: String, text_value: String) -> void:
	sentence_id = id_value
	sentence_text = text_value
	_update_text()

func clear_sentence() -> void:
	sentence_id = ""
	sentence_text = ""
	_update_text()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if locked:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("sentence_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	emit_signal("sentence_dropped", slot_index, String(data.get("sentence_id", "")))

func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if sentence_id == "":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("sentence_cleared", slot_index)

func _update_text() -> void:
	if text_label == null:
		return
	if sentence_id == "":
		text_label.text = empty_text
	else:
		text_label.text = sentence_text

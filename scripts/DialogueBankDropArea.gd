extends PanelContainer

signal sentence_returned(sentence_id: String)

var locked: bool = false

func set_locked(value: bool) -> void:
	locked = value

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if locked:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("sentence_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	emit_signal("sentence_returned", String(data.get("sentence_id", "")))

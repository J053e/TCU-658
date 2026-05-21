extends Button

var sentence_id: String = ""
var sentence_text: String = ""
var drag_enabled: bool = true

func setup(id_value: String, text_value: String) -> void:
	sentence_id = id_value
	sentence_text = text_value
	text = text_value

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not drag_enabled:
		return null
	var data := {
		"sentence_id": sentence_id
	}
	var preview := Label.new()
	preview.text = sentence_text
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.custom_minimum_size = Vector2(300, 56)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_color_override("font_color", Color(1, 1, 1))
	set_drag_preview(preview)
	return data

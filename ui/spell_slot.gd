extends Control
class_name SpellSlot

## One box in the spell bar. Shows the shape you have to draw and the spell name.
## The box is dimmed while the spell can't be cast yet (see recast_delay in SpellData).

const SLOT_SIZE = Vector2(60, 50)

var spell: SpellData
var spell_caster: SpellCaster
var shape: PackedVector2Array = PackedVector2Array()
var highlight: float = 0.0
var is_waiting: bool = false

func setup(spell_data: SpellData, template: GestureTemplate, caster: SpellCaster):
	spell = spell_data
	spell_caster = caster
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if template:
		shape = make_shape(template)
	queue_redraw()

## Short flash when the spell was cast.
func light_up():
	highlight = 1.0

func _process(delta: float) -> void:
	var waiting_now = spell_caster.get_remaining_delay(spell) > 0
	if waiting_now != is_waiting || highlight > 0:
		is_waiting = waiting_now
		highlight = max(highlight - delta * 4.0, 0.0)
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.08, 0.7))
	if shape.size() >= 2:
		draw_polyline(shape, spell.color, 1.5, true)
	if is_waiting:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(Vector2.ZERO, size), spell.color.lerp(Color(1, 1, 1), highlight), false, 1.0 + highlight)
	draw_string(ThemeDB.fallback_font, Vector2(0, size.y - 3), spell.display_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, Color(1, 1, 1, 0.9))

## Template points are normalized (centred on 0, longest side = 1), so scale them to the box.
func make_shape(template: GestureTemplate):
	if template.points.size() != GestureRecognizer.NUM_POINTS:
		template.optimize_template()
	var result = PackedVector2Array()
	var middle = Vector2(SLOT_SIZE.x / 2, 18)
	var shape_size = 30.0
	for point in template.points:
		result.append(middle + point * shape_size)
	if template.is_closed_shape && template.points.size() > 0:
		result.append(middle + template.points[0] * shape_size)
	return result

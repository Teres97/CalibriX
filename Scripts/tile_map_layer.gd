extends TileMapLayer
@export var unit: Node2D

const ANIMATION_DURATION = 2.3
const DEFAULT_TILE_SOURCE_ID = 1
const HIGHLIGHT_TILE_SOURCE_ID = 5
const ANIMATED_TILE_SOURCE_ID = 10
const FINISHED_TILE_SOURCE_ID = 20

var last_hovered_cell: Vector2i = Vector2i(-999, -999)

func _process(delta):
	var mouse_world_pos = get_global_mouse_position()
	var local_pos = to_local(mouse_world_pos)
	var cell = local_to_map(local_pos)
	if cell != last_hovered_cell:
		# Снять подсветку с предыдущего
		if get_cell_source_id(last_hovered_cell) == HIGHLIGHT_TILE_SOURCE_ID:
			set_cell(last_hovered_cell, ANIMATED_TILE_SOURCE_ID, Vector2i(0, 0))
		# Подсветить текущий гекс
		if get_cell_source_id(cell) == ANIMATED_TILE_SOURCE_ID:
			set_cell(cell, HIGHLIGHT_TILE_SOURCE_ID, Vector2i(0, 0))
		last_hovered_cell = cell
		
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if unit.get_turn():
			var world_pos = get_global_mouse_position()
			var local_pos = to_local(world_pos)
			var cell = local_to_map(local_pos)
			if unit != null:
				if get_cell_source_id(cell) == HIGHLIGHT_TILE_SOURCE_ID:
					unit.move_unit_to_cell_parabola(cell)
				var other_unit = unit.get_unit_at_position(cell)
				if other_unit in unit.player_units:
					unit.selected_unit = other_unit
					unit.clear_highlight()
					unit.show_highlight(2)


func play_tile_animation_once(cell: Vector2i):
	# Заменяем на анимированный тайл (2.png)
	if get_cell_source_id(cell) == HIGHLIGHT_TILE_SOURCE_ID:
		set_cell(cell, ANIMATED_TILE_SOURCE_ID, Vector2i(0, 0))  # 1 — это ID AnimatedTile

		# Создаём таймер, чтобы вернуть обычный тайл после проигрывания
		var timer := Timer.new()
		timer.wait_time = ANIMATION_DURATION
		timer.one_shot = true
		add_child(timer)
		timer.start()

		# Когда таймер сработает — вернуть обычный тайл
		timer.timeout.connect(func():
			set_cell(cell, DEFAULT_TILE_SOURCE_ID, Vector2i(0, 0))
			timer.queue_free()
	)

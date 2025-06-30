extends Node2D

@onready var hex_map = $Node2D/TileMapLayer
@onready var bullfinch_scene = preload("res://Scenes/bullfinch.tscn")
@onready var lizard_black_scene = preload("res://Scenes/warrior_lizard_black.tscn")
@onready var lizard_green_scene = preload("res://Scenes/warrior_lizard_green.tscn")

var bullfinch_instance: Node2D
var lizard_green_instance: Node2D
var lizard_black_instance: Node2D

func _ready():
	var start_cell = Vector2i(-5, -1)
	bullfinch_instance = spawn_unit(bullfinch_scene,start_cell,0.25,20)
	start_cell = Vector2i(1, 0)
	lizard_black_instance = spawn_unit(lizard_black_scene,start_cell,0.15,20)
	start_cell = Vector2i(0, -1)
	lizard_green_instance = spawn_unit(lizard_green_scene,start_cell,0.15,20)
		
func spawn_unit(scene: PackedScene, cell: Vector2i, scale: float = 0.25, y_offset: float = 20.0) -> Node2D:
	var instance = scene.instantiate()
	instance.scale = Vector2(scale, scale)
	add_child(instance)

	var pos = hex_map.map_to_local(cell)
	instance.global_position = hex_map.to_global(pos) - Vector2(0, y_offset)
	return instance

	
func move_unit_to_cell(cell: Vector2i):
	var pos = hex_map.map_to_local(cell)
	var global_pos = hex_map.to_global(pos)
	var other_unit = get_unit_at_position(cell)
	if hex_map.get_cell_source_id(cell) < 23:
		print(hex_map.get_cell_source_id(cell))
		return
	await get_tree().create_timer(0.2).timeout
	var sprite := bullfinch_instance.get_node("AnimatedSprite2D")
	if sprite:
		sprite.play("bullfinch_fly")
	var tween = create_tween()
	tween.tween_property(bullfinch_instance, "global_position", global_pos- Vector2(0,20), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if sprite:
		sprite.play("idle")
	if other_unit != null:
		other_unit.hide()
		if sprite:
			sprite.play("bullfinch_explosion")
		# Если другой юнит есть — скрыть обоих через 2 секунды
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		add_child(timer)
		timer.start()

		timer.timeout.connect(func ():

			bullfinch_instance.queue_free()
			timer.queue_free()
		)
	hex_map.set_cell(cell, 24, Vector2i(0,0))

func get_unit_at_position(pos: Vector2i) -> Node2D:
	for child in get_children():
		if child is Node2D:
			var child_cell = hex_map.local_to_map(hex_map.to_local(child.global_position))
			if child_cell == pos:
				return child
	return null

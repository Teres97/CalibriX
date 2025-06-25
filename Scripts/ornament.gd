extends Sprite2D

func _ready():
	animate_loop()
	
func animate_loop() -> void:
	while true:
		var tween = create_tween()

		tween.tween_property(self, "rotation_degrees", rotation_degrees + 20, 10.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# 3. Разворот на 180° за 5 сек
		tween.tween_property(self, "rotation_degrees", rotation_degrees - 20, 10.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await  tween.finished

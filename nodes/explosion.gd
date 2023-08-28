extends Node2D

const EXPLOSION_SPEED: float = 1.0 # seconds
const LIFETIME: float = 3 # seconds
var timer: float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer >= EXPLOSION_SPEED:
		$Sprite.hide()
	else:
		$Sprite.frame = floor($Sprite.hframes * timer / EXPLOSION_SPEED)
	if timer > LIFETIME:
		get_parent().remove_child(self)

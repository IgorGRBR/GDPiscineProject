class_name SpriteTopDown

var sprite: Sprite2D = null
var td_rotation: int = 0
var frame: float = 0.0
var rad_rotation: float = 0.0

func _init(spr: Sprite2D):
	sprite = spr

const TOP_COS = cos(deg_to_rad(30))
const SIDE_COS = cos(deg_to_rad(60))
const RAD_30_DEG = deg_to_rad(30)
const RAD_45_DEG = deg_to_rad(45)
const WALKING_ANIMATION_SPEED = 0.1
const WALKING_SPEED_THRESHOLD = 0.1
func update_sprite(movement_vector: Vector2, dt: float):
	var movement_direction = movement_vector.normalized()
	var abs_movement_direction = movement_direction.abs()
	var dot: float = abs_movement_direction.dot(Vector2.DOWN)
	var diagonal = dot < TOP_COS and dot > SIDE_COS
	
	if movement_vector.length_squared() < WALKING_SPEED_THRESHOLD * WALKING_SPEED_THRESHOLD:
		sprite.frame_coords.x = 0
		rad_rotation = PI * td_rotation / 2 + (RAD_45_DEG * int(diagonal))
		return
	
	if !diagonal:
		td_rotation = 4 - roundi((2 * movement_direction.angle_to(Vector2.UP) / (PI)))
	else:
		td_rotation = 4 - roundi((2 * (RAD_30_DEG + movement_direction.angle_to(Vector2.UP)) / (PI)))
	td_rotation %= 4
	
	rad_rotation = PI * td_rotation / 2 + (RAD_45_DEG * int(diagonal))
	
	sprite.rotation = PI * td_rotation / 2
	sprite.frame_coords.y = 0 if not diagonal else 1
	frame += dt * WALKING_ANIMATION_SPEED * movement_vector.length()
	frame = fmod(frame, float(sprite.hframes))
	sprite.frame_coords.x = floori(frame)

class_name Actor
const TDSprite = preload("res://classes/tdsprite.gd")

var direction: Vector2 = Vector2.UP
var walk_speed: int = 48
var walk_acceleration: int = 8
var walk_friction: int = 1
var sprite: TDSprite
var body: CharacterBody2D

func _init(bd: CharacterBody2D, spr: TDSprite):
	sprite = spr
	body = bd
	
func physics_process(input_vector: Vector2, dt: float) -> bool:
	var collision = walk(input_vector, dt)
	sprite.update_sprite(body.velocity, dt)
	return collision

const WALKING_THRESHOLD = 64.0
func walk(input: Vector2, dt: float) -> bool:
	var target_vector: Vector2 = input * walk_speed
	var acceleration = 0.0
	var walking_threshold = 0.0
	if input.length_squared() > 0:
		acceleration = walk_acceleration
	else:
		acceleration = walk_friction
		target_vector = Vector2.ZERO
		walking_threshold = WALKING_THRESHOLD
	var acceleration_factor = 1.0 - pow(0.5, acceleration * dt)
	body.velocity = lerp(body.velocity, target_vector, acceleration_factor)
	if body.velocity.length_squared() < walking_threshold:
		body.velocity = Vector2.ZERO
	return body.move_and_slide()

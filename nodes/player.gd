extends CharacterBody2D
class_name PlayerNode

const TDSprite = preload("res://classes/tdsprite.gd")
const RateInterpolator = preload("res://classes/rateinterp.gd")
const Actor = preload("res://classes/actor.gd")
const CTimer = preload("res://classes/timer.gd")

var direction: Vector2 = Vector2.UP
@export_group("Player Properties")
@export_range(0, 256) var walk_speed: int = 48
@export_range(0, 4) var walk_acceleration: int = 8
@export_range(0, 4) var walk_friction: int = 1
@onready var camera_ref: Camera2D = $Camera
@onready var tdsprite = TDSprite.new($Sprite)
@onready var actor = Actor.new(self, tdsprite)
var rate_interp: RateInterpolator
var world_node: WorldNode
var alive = true
var death_timer: CTimer
const DEATH_TIMER = 3.0

func _ready():
	var physics_time: float = 1.0 / float(Engine.physics_ticks_per_second)
	rate_interp = RateInterpolator.new(position, physics_time)
	rate_interp.register_node(camera_ref)
	rate_interp.register_node($Sprite)
	actor.walk_speed = walk_speed
	actor.walk_acceleration = walk_acceleration
	actor.walk_friction = walk_friction
	world_node = find_parent("World")
	death_timer = CTimer.new(0.0, _game_over)

func _process(delta):
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())
	death_timer.update(delta)

func _physics_process(delta):
	if alive:
		var input_direction = Vector2(0, 0)
		input_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
		input_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
		var collision_happened = actor.physics_process(input_direction.normalized(), delta)
		if collision_happened:
			for i in range(get_slide_collision_count()):
				var collision: KinematicCollision2D = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider is Zombie:
					kill()
		rotate_ray(tdsprite.rad_rotation)
		interactions()
	rate_interp.set_position(position)
	# Not updating rate_interp here causes camera to jitter after each physics update for some reason
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())

func rotate_ray(rot: float):
	$InteractRay.rotation = rot

func set_player_position(pos: Vector2):
	position = pos

func kill():
	alive = false
	$Sprite.frame_coords.y = 2
	$Sprite.frame_coords.x = 0
	death_timer.timer = DEATH_TIMER

func _game_over():
	world_node.game_over()

func interactions():
	if Input.is_action_just_pressed("use") and $InteractRay.is_colliding():
		var col_object: Node = $InteractRay.get_collider()
		if col_object is CarNode:
			if col_object.enter_car(self):
				camera_ref.enabled = false
				get_parent().remove_child(self)
				world_node.player_node = col_object

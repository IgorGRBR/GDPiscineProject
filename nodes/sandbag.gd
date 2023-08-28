extends RigidBody2D
class_name Sandbag

const TDSprite = preload("res://classes/tdsprite.gd")
const RateInterpolator = preload("res://classes/rateinterp.gd")
const CTimer = preload("res://classes/timer.gd")

var standing = true
@onready var tdsprite = TDSprite.new($Sprite)
var ang_velocity = 0.0
var angle_direction = Vector2.UP
@export var dampening_force: float = 5
var rate_interp: RateInterpolator
var respawn_timer: CTimer
var initial_position = Vector2i.ZERO
const RESPAWN_TIME = 20.0 # seconds

func _ready():
	var physics_time: float = 1.0 / float(Engine.physics_ticks_per_second)
	rate_interp = RateInterpolator.new(position, physics_time)
	rate_interp.register_node($Sprite)
	respawn_timer = CTimer.new(0.0, init_sandbag)
	initial_position = position
	init_sandbag()

func init_sandbag():
	standing = true
	angle_direction = Vector2.UP
	ang_velocity = randf_range(-PI, PI)
	$Sprite.frame = 2
	position = initial_position

func _process(delta):
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())
	if not standing:
		var travel_coef = minf(linear_velocity.length(), 40.0) / 40.0
		if travel_coef > 0.1:
			angle_direction = angle_direction.rotated(travel_coef * ang_velocity * delta)
			tdsprite.update_sprite(angle_direction, delta)
	respawn_timer.update(delta)

func _physics_process(delta):
	apply_force(-linear_velocity * delta * 8)
	rate_interp.set_position(position)
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())

const HIT_VELOCITY_THRESHOLD = 100.0
func get_hit(velocity: Vector2, hit_normal: Vector2) -> float:
	if velocity.length_squared() > HIT_VELOCITY_THRESHOLD:
		if standing:
			$Particles.emitting = true
			respawn_timer.timer = RESPAWN_TIME
		standing = false
		var impact_force: Vector2 = hit_normal * \
			(velocity.dot(hit_normal) - dampening_force * 8)
		apply_force(impact_force)
	return dampening_force

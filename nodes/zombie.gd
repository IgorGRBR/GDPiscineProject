extends CharacterBody2D
class_name Zombie

const TDSprite = preload("res://classes/tdsprite.gd")
const RateInterpolator = preload("res://classes/rateinterp.gd")
const Actor = preload("res://classes/actor.gd")
const CTimer = preload("res://classes/timer.gd")

var direction: Vector2 = Vector2.UP
@export_group("Zombie Properties")
@export_range(0, 256) var walk_speed: int = 48
@export_range(0, 4) var walk_acceleration: int = 8
@export_range(0, 4) var walk_friction: int = 1
@export_range(1.0, 100.0) var max_health: float = 10.0
@onready var tdsprite = TDSprite.new($Sprite)
@onready var actor = Actor.new(self, tdsprite)
var rate_interp: RateInterpolator
var target: Node2D = null
var world_node: WorldNode
var alive = true
var health: float = max_health
var initial_position: Vector2
var respawn_timer: CTimer
const RESPAWN_TIME: float = 20.0
var original_texture: Texture2D
var original_texture_dimensions: Vector2i = Vector2i.ZERO
const FOLLOW_DISTANCE: float = 250.0

const CORPSE_TEXTURE = preload("res://sprites/zombie-corpse.png")

func _ready():
	var physics_time: float = 1.0 / float(Engine.physics_ticks_per_second)
	rate_interp = RateInterpolator.new(position, physics_time)
	rate_interp.register_node($Sprite)
	actor.walk_speed = walk_speed
	actor.walk_acceleration = walk_acceleration
	actor.walk_friction = walk_friction
	$Sprite.global_position = round($Sprite.global_position)
	world_node = find_parent("World")
	original_texture = $Sprite.texture
	original_texture_dimensions.x = $Sprite.hframes
	original_texture_dimensions.y = $Sprite.vframes
	initial_position = position
	respawn_timer = CTimer.new(0.0, init_zombie)
	init_zombie()

func init_zombie():
	alive = true
	position = initial_position
	set_target(world_node.player_node)
	$Sprite.texture = original_texture
	$Sprite.hframes = original_texture_dimensions.x
	$Sprite.vframes = original_texture_dimensions.y
	health = max_health
	collision_layer = 1

func _process(delta):
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())
	if health <= 0.0 and alive:
		$Sprite.texture = CORPSE_TEXTURE
		$Sprite.hframes = 1
		$Sprite.vframes = 1
		$Sprite.frame_coords = Vector2.ZERO
		velocity = Vector2.ZERO
		alive = false
		position = round(position)
		collision_layer = 2
		respawn_timer.timer = RESPAWN_TIME
		world_node.kill_count += 1
	respawn_timer.update(delta)

func set_target(t: Node2D):
	target = t

func damage(dmg: float):
	health -= dmg
	$Blood.emitting = true

func _physics_process(delta):
	if alive:
		var input_direction = Vector2(0, 0)
		set_target(world_node.player_node)
		if target\
			and (target.position - position).length_squared() <= FOLLOW_DISTANCE * FOLLOW_DISTANCE:
			input_direction = (target.position - position).normalized()
		actor.physics_process(input_direction.normalized(), delta)
	rate_interp.set_position(position)
	# Not updating rate_interp here causes camera to jitter after each physics update for some reason
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())

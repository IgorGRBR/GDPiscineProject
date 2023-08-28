extends CharacterBody2D
class_name CarNode

const TDSprite = preload("res://classes/tdsprite.gd")
const RateInterpolator = preload("res://classes/rateinterp.gd")
const Explosion = preload("res://nodes/explosion.tscn")

var direction: Vector2 = Vector2.UP
var speed: float = 0
@export_group("Car Properties")
@export_range(0, 256.0) var max_speed: float = 160
@export_range(0, 100.0) var acceleration: float = 30
@export_range(0, 100.0) var friction: float = 20
@export_range(0, PI) var turn_speed: float = PI/2
var sprite_rotation: int = 0
var sprite_frame: int = 0
var car_active: bool = false
var player: PlayerNode = null
var rate_interp: RateInterpolator
var gui_ref: GUINode
@onready var camera_ref: Camera2D = $Camera
@onready var tdsprite = TDSprite.new($Sprite)
@export_range(1.0, 1000.0) var health: float = 100
var world_node: WorldNode
var passenger: NPCNode = null

@export var car_texture: Texture2D = null
@export var car_bad_texture: Texture2D = null
@export var car_worse_texture: Texture2D = null

func _ready():
	var physics_time: float = 1.0 / float(Engine.physics_ticks_per_second)
	rate_interp = RateInterpolator.new(position, physics_time)
	rate_interp.register_node($Sprite)
	rate_interp.register_node($Camera)
	floor_block_on_wall = false
	gui_ref = get_tree().root.find_child("GUI", true, false)
	gui_ref.set_health_visibility(false)
	$CollisionShape/Smoke.emitting = false
	world_node = find_parent("World")
	$Sprite.texture = car_texture

func _process(delta):
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())
	if (car_active):
		update_camera_offset(delta)
		update_target_direction()

func _physics_process(delta):
	if player and Input.is_action_just_released("use"):
		car_active = true
	var gas_pedal = false
	var breaks = false
	var input_direction = 0
	if car_active:
		gas_pedal = Input.is_action_pressed("up")
		breaks = Input.is_action_pressed("down")
		input_direction = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
		try_leave_car()
		update_health()
	driving(gas_pedal, breaks, input_direction, delta)
	tdsprite.update_sprite(direction, delta)
	if (input_direction != 0):
		rotate_body_shape(tdsprite.rad_rotation)
		up_direction = Vector2.UP.rotated(tdsprite.rad_rotation)
	rate_interp.set_position(position)
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())
	try_to_explode()

func update_health():
	var int_hp = ceil(health)
	gui_ref.set_health(int_hp)
	if int_hp < 60 and car_bad_texture:
		$Sprite.texture = car_bad_texture
	if int_hp < 30 and car_worse_texture:
		$Sprite.texture = car_worse_texture
		$CollisionShape/Smoke.emitting = true

func update_target_direction():
	if passenger:
		var dir_vector = passenger.exit_area.position - position
		gui_ref.set_arrow_rotation(-dir_vector.angle_to(Vector2.UP))
	else:
		var npcs = world_node.npcs_node.get_children()
		if npcs.size() > 0:
			gui_ref.set_arrow_visibility(true)
			var npc = npcs[0]
			var dir_vector = npc.position - position
			gui_ref.set_arrow_rotation(-dir_vector.angle_to(Vector2.UP))
		else:
			gui_ref.set_arrow_visibility(false)

func try_to_explode():
	if health <= 0.0:
		var explosion = Explosion.instantiate()
		explosion.position = position
		get_parent().add_child(explosion)
		if car_active:
			gui_ref.set_health_visibility(false)
			player.kill()
			drop_player()
		get_parent().remove_child(self)

func driving(gas_pedal: bool, breaks: bool, turn_direction: int, dt: float):
	var turn_speed_baseline = signf(speed) * clampf(absf(speed), 0, 16) / 16
	direction = direction.rotated(turn_direction * turn_speed * dt * turn_speed_baseline)
	if gas_pedal:
		speed += acceleration * dt
	elif breaks:
		if speed < 0:
			speed -= (acceleration / 2) * dt
		else:
			speed -= (acceleration + friction) * dt
	else:
		speed -= friction * dt * signf(speed)
	speed = clampf(speed, -max_speed/2, max_speed)
	velocity = direction * speed
	var old_velocity = velocity
	var collision_happened = move_and_slide()
	# Decrease the speed after colliding with anything
	if collision_happened:
		var old_speed = speed
		for i in range(get_slide_collision_count()):
			var collision: KinematicCollision2D = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider is Sandbag:
				var slowdown = maxf(collider.get_hit(velocity, collision.get_normal()), 0.0)
				speed -= slowdown * signf(speed)
			elif collider is Zombie:
				speed -= 5 * signf(speed)
				collider.damage(absf(speed))
				collider.velocity = old_velocity
			else:
				if speed > 40:
					$Sparks.global_position = collision.get_position()
					$Sparks.emitting = true
				speed = sign(speed) * get_position_delta().length() / dt
		var speed_diff = old_speed - speed
		if speed_diff > 0.0:
			health -= speed_diff / 10
	velocity = direction * speed

const CAMERA_DISTANCE_MULTIPLIER = 0.4
func update_camera_offset(dt: float):
	var smoothing_factor = 1.0 - pow(0.5, dt * 8)
	camera_ref.offset = lerp(camera_ref.offset, direction * speed * CAMERA_DISTANCE_MULTIPLIER, smoothing_factor)

func rotate_body_shape(rot: float):
	$CollisionShape.rotation = rot
	$Sparks.direction = Vector2.UP.rotated(rot)

func enter_car(node: CharacterBody2D) -> bool:
	if node is PlayerNode:
		if player:
			return false
		player = node
		player.velocity = Vector2.ZERO
		camera_ref.enabled = true
		gui_ref.set_health_visibility(true)
		gui_ref.set_arrow_visibility(true)
		return true
	elif node is NPCNode:
		if passenger:
			return false
		passenger = node
		return true
	return false

func try_leave_car():
	if Input.is_action_just_pressed("use") and player:
		drop_player()

func drop_player():
	car_active = false
	camera_ref.enabled = false
	player.camera_ref.enabled = true
	player.position = $CollisionShape/ExitPoint.global_position
	get_parent().add_child(player)
	world_node.player_node = player
	player = null
	gui_ref.set_health_visibility(false)
	drop_passenger()

func drop_passenger():
	if passenger:
		passenger.position = $CollisionShape/ExitPoint2.global_position
		world_node.npcs_node.add_child(passenger)
		passenger = null

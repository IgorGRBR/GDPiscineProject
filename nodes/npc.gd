extends CharacterBody2D
class_name NPCNode

const TDSprite = preload("res://classes/tdsprite.gd")
const RateInterpolator = preload("res://classes/rateinterp.gd")
const Actor = preload("res://classes/actor.gd")

const NPC_TEXTURES: Array[Texture2D] = [
	preload("res://sprites/npc1.png"),
	preload("res://sprites/npc2.png"),
	preload("res://sprites/npc3.png"),
]

var direction: Vector2 = Vector2.UP
@export_group("NPC Properties")
@export_range(0, 256) var walk_speed: int = 48
@export_range(0, 4) var walk_acceleration: int = 8
@export_range(0, 4) var walk_friction: int = 1
@export_range(1.0, 100.0) var max_health: float = 10.0
@onready var tdsprite = TDSprite.new($Sprite)
@onready var actor = Actor.new(self, tdsprite)
var rate_interp: RateInterpolator
var target: Node2D = null
var world_node: WorldNode
const FOLLOW_DISTANCE: float = 120.0
var exit_area: NPCExitAreaNode = null
const EXIT_DISTANCE: float = 4.0

const CORPSE_TEXTURE = preload("res://sprites/zombie-corpse.png")

func _ready():
	var physics_time: float = 1.0 / float(Engine.physics_ticks_per_second)
	rate_interp = RateInterpolator.new(position, physics_time)
	rate_interp.register_node($Sprite)
	actor.walk_speed = walk_speed
	actor.walk_acceleration = walk_acceleration
	actor.walk_friction = walk_friction
	$Sprite.global_position = round($Sprite.global_position)
	world_node = find_parent("World") as WorldNode
	$Sprite.texture = NPC_TEXTURES[randi() % 3]
	collision_layer = 1

func on_spawn():
	var exit_nodes = world_node.npc_exits_node.get_children()
	exit_area = exit_nodes[randi() % exit_nodes.size()]

func _process(_delta):
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())

func set_target(t: Node2D):
	if t is CarNode:
		if t.car_active:
			target = t
	if t is NPCExitAreaNode:
		if t == exit_area:
			target = t

func rotate_ray(rot: float):
	$InteractRay.rotation = rot

func interactions():
	if $InteractRay.is_colliding():
		var col_object: Node = $InteractRay.get_collider()
		if col_object is CarNode:
			if col_object.car_active and col_object.enter_car(self):
				get_parent().remove_child(self)
				world_node.player_node = col_object

func _physics_process(delta):
	var input_direction = Vector2(0, 0)
	if not target or not (target is CarNode or target is NPCExitAreaNode):
		set_target(world_node.player_node)
	if target is CarNode:
		if target.car_active \
			and (target.position - position).length_squared() <= FOLLOW_DISTANCE * FOLLOW_DISTANCE:
			input_direction = (target.position - position).normalized()
			interactions()
		else:
			target = null
	elif target == exit_area:
		input_direction = (target.position - position).normalized()
		if (position - target.position).length_squared() < EXIT_DISTANCE * EXIT_DISTANCE:
			world_node.add_money(20)
			world_node.spawn_npc()
			get_parent().remove_child(self)
	actor.physics_process(input_direction.normalized(), delta)
	rotate_ray(tdsprite.rad_rotation)
	rate_interp.set_position(position)
	# Not updating rate_interp here causes camera to jitter after each physics update for some reason
	rate_interp.update_with_factor(Engine.get_physics_interpolation_fraction())

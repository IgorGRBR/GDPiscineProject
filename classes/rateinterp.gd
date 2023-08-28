class_name RateInterp

var nodes: Array[Node2D] = []
var old_position: Vector2
var current_position: Vector2
var update_time: float
var time_accumulator: float = 0.0

func _init(pos: Vector2, utime: float):
	old_position = pos
	current_position = pos
	update_time = utime

func register_node(node: Node2D):
	nodes.append(node)

func set_position(pos: Vector2):
	old_position = current_position
	current_position = pos
	time_accumulator = maxf(time_accumulator - update_time, 0)

func update(dt: float):
	time_accumulator += dt
	var gpos = lerp(old_position, current_position, time_accumulator / update_time)
	for node in nodes:
		node.global_position = gpos# - node.position

func update_with_factor(f: float):
	var gpos = lerp(old_position, current_position, f)
	for node in nodes:
		node.global_position = gpos#round(gpos)# - node.position

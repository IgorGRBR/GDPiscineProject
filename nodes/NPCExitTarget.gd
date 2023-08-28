extends Area2D
class_name NPCExitAreaNode

const CTimer = preload("res://classes/timer.gd")
var world_node: WorldNode

func _ready():
	world_node = find_parent("World")

func _on_body_entered(body):
	if body is NPCNode:
		if body.exit_area == self:
			body.set_target(self)
	elif body is CarNode:
		if body.passenger and body.passenger.exit_area == self:
			body.passenger.set_target(self)
			body.drop_passenger()

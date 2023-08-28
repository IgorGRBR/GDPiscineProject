extends Node2D
class_name WorldNode

var player_node: Node2D
var objects_node: Node
var zombies_node: Node
var npcs_node: Node
var spawn_positions_node: Node
var npc_exits_node: Node
var gui_node: GUINode
var money: int = 0
var kill_count: int = 0

const NPCNodeScene = preload("res://nodes/npc.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	player_node = find_child("Player")
	objects_node = find_child("Objects")
	zombies_node = find_child("Zombies")
	npcs_node = find_child("NPCS")
	npc_exits_node = find_child("NPCExits")
	npc_exits_node = find_child("NPCExits")
	spawn_positions_node = find_child("NPCSpawns")
	gui_node = find_child("GUI") as GUINode
	gui_node.set_money(money)
	spawn_npc()

func add_money(amount: int):
	money += amount
	gui_node.set_money(money)

func spawn_npc():
	var spawns = spawn_positions_node.get_children()
	var spawn = spawns[randi() % spawns.size()] as Node2D
	var npc = NPCNodeScene.instantiate()
	npc.position = spawn.position
	npcs_node.add_child(npc)
	npc.on_spawn()

func game_over():
	TaxiZGlobalData.set_stats(money, kill_count)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit()

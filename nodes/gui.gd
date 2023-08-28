extends Control
class_name GUINode

@onready var health_label = $MarginContainer/VBoxContainer/HealthContainer/Label
@onready var health_container = $MarginContainer/VBoxContainer/HealthContainer
@onready var money_container = $MarginContainer/VBoxContainer/MoneyContainer
@onready var money_label = $MarginContainer/VBoxContainer/MoneyContainer/Label
@onready var arrow = $Control/Arrow

func _ready():
	set_arrow_visibility(false)
	set_health_visibility(false)

func set_health(hp: int):
	health_label.text = str(hp) + "%"

func set_health_visibility(vis: bool):
	health_container.visible = vis

func set_arrow_rotation(rot: float):
	arrow.rotation = rot

func set_arrow_visibility(vis: bool):
	arrow.visible = vis

func set_money(mn: int):
	money_label.text = str(mn) + "$"

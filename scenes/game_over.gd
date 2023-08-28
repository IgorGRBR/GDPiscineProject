extends Node2D

func _ready():
	var str = "Money earned: %d$\nZombies killed: %d"
	var fstr = str % [TaxiZGlobalData.money, TaxiZGlobalData.kills]
	$VBoxContainer/Label.text = fstr

func _on_exit_button_pressed():
	get_tree().quit()

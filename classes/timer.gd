class_name CTimer

var timer: float
var timeout_callback: Callable

func _init(time: float, callback: Callable):
	timer = time
	timeout_callback = callback

func update(dt: float):
	if timer > 0.0:
		timer -= dt
		if timer <= 0.0:
			timeout_callback.call()


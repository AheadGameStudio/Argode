extends ArgodeViewBase
class_name ArgodeMessageWindow

func _init():
	await ready
	_after_ready_setup()

func _after_ready_setup():
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
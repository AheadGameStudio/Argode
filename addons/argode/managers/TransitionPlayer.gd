extends Node

signal transition_finished

enum TransitionType {
	NONE,
	FADE,
	DISSOLVE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN
}

var tween: Tween
var transition_map: Dictionary = {
	"none": TransitionType.NONE,
	"fade": TransitionType.FADE,
	"dissolve": TransitionType.DISSOLVE,
	"slide_left": TransitionType.SLIDE_LEFT,
	"slide_right": TransitionType.SLIDE_RIGHT,
	"slide_up": TransitionType.SLIDE_UP,
	"slide_down": TransitionType.SLIDE_DOWN
}

func _ready():
	print("🎬 TransitionPlayer initialized")

func play(target_node: Node, transition_name: String, duration: float = 0.5, reverse: bool = false):
	"""Play transition effect on target node"""
	if not target_node:
		push_warning("⚠️ TransitionPlayer: target_node is null")
		transition_finished.emit()
		return
	
	var transition_type = transition_map.get(transition_name.to_lower(), TransitionType.NONE)
	
	if transition_type == TransitionType.NONE:
		transition_finished.emit()
		return
	
	# Kill existing tween
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	match transition_type:
		TransitionType.FADE:
			_play_fade(target_node, duration, reverse)
		TransitionType.DISSOLVE:
			_play_dissolve(target_node, duration, reverse)
		TransitionType.SLIDE_LEFT:
			var screen_size = _get_screen_size()
			_play_slide(target_node, duration, Vector2(-screen_size.x, 0), reverse)
		TransitionType.SLIDE_RIGHT:
			var screen_size = _get_screen_size()
			_play_slide(target_node, duration, Vector2(screen_size.x, 0), reverse)
		TransitionType.SLIDE_UP:
			var screen_size = _get_screen_size()
			_play_slide(target_node, duration, Vector2(0, -screen_size.y), reverse)
		TransitionType.SLIDE_DOWN:
			var screen_size = _get_screen_size()
			_play_slide(target_node, duration, Vector2(0, screen_size.y), reverse)
	
	await tween.finished
	transition_finished.emit()

func _play_fade(node: Node, duration: float, reverse: bool):
	"""Fade in/out transition"""
	if not node.has_method("set_modulate"):
		push_warning("⚠️ TransitionPlayer: Node doesn't support modulate")
		return
	
	if reverse:  # Fade out
		node.modulate.a = 1.0
		tween.tween_property(node, "modulate:a", 0.0, duration)
	else:  # Fade in
		node.modulate.a = 0.0
		tween.tween_property(node, "modulate:a", 1.0, duration)

func _play_dissolve(node: Node, duration: float, reverse: bool):
	"""Dissolve transition using shader or fallback to fade"""
	# For now, use fade as fallback until custom shaders are implemented
	_play_fade(node, duration, reverse)

func _play_slide(node: Node, duration: float, offset: Vector2, reverse: bool):
	"""Slide transition"""
	if not node.has_method("set_position"):
		push_warning("⚠️ TransitionPlayer: Node doesn't support position")
		return
	
	var original_position = node.position
	
	if reverse:  # Slide out
		tween.tween_property(node, "position", original_position + offset, duration)
	else:  # Slide in
		node.position = original_position + offset
		tween.tween_property(node, "position", original_position, duration)

func fade_in(node: Node, duration: float = 0.5):
	"""Convenience method for fade in"""
	await play(node, "fade", duration, false)

func fade_out(node: Node, duration: float = 0.5):
	"""Convenience method for fade out"""
	await play(node, "fade", duration, true)

func slide_in_from_left(node: Node, duration: float = 0.5):
	"""Convenience method for slide in from left"""
	await play(node, "slide_left", duration, false)

func slide_out_to_right(node: Node, duration: float = 0.5):
	"""Convenience method for slide out to right"""
	await play(node, "slide_right", duration, true)

func get_available_transitions() -> Array[String]:
	"""Get list of available transition names"""
	return transition_map.keys()

func _get_screen_size() -> Vector2:
	"""Get screen size safely"""
	var viewport = get_viewport()
	if viewport:
		return viewport.get_visible_rect().size
	else:
		return Vector2(1152, 648)  # Default fallback size
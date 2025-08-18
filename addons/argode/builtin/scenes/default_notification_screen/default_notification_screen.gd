extends ArgodeViewBase
class_name ArgodeDefaultNotificationScreen

@export var notification_card_scene: PackedScene
var card_list:Array[Control] = []

# func _ready():
# 	add_notification_card("Welcome to Argode!")
# 	await get_tree().create_timer(1.0).timeout
# 	add_notification_card("Welcome to Argode!")
# 	await get_tree().create_timer(1.0).timeout
# 	add_notification_card("Welcome to Argode!")

func add_notification_card(message: String, icon:Texture=null):
	var card: Control = notification_card_scene.instantiate()
	
	var message_label = card.find_child("MessageLabel")
	if message_label:
		message_label.text = message

	var icon_texture = card.find_child("IconTexture")
	if icon_texture and icon != null:
		icon_texture.texture = icon
	card_list.append(card)
	add_child(card)
	set_card_position(card)

	var tween = _set_tween(card)
	tween.play()

func set_card_position(_card:Control):
	# card_list.find(_card)
	var padding = 10
	_card.position.y = _card.size.y * card_list.find(_card) + padding * card_list.find(_card)

func refresh_card_position():
	for i in range(card_list.size()):
		set_card_position(card_list[i])

func remove_card(_card:Control):
	card_list.erase(_card)
	refresh_card_position()
	_card.queue_free()

func _set_tween(card:Control) -> Tween:
	card.modulate.a = 0
	card.position.x = -card.size.x
	var _move_distance:float = 20
	
	var tween = get_tree().create_tween().bind_node(card)
	tween.tween_property(card, "modulate:a", 1, 0.3)
	tween.parallel()
	tween.tween_property(card, "position:x", card.position.x - _move_distance, 0.2)
	tween.tween_interval(3.0)
	tween.tween_property(card, "modulate:a", 0, 0.3)
	tween.parallel()
	tween.tween_property(card, "position:x", card.position.x + _move_distance, 0.2)
	tween.tween_callback(remove_card.bind(card))
	return tween

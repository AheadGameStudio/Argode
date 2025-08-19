extends RefCounted
class_name ArgodeLayerManager

var layers:Array[Dictionary] = [
	{ 
		"name": "GUI", 
		"z-index": 300 
	},
	{ 
		"name": "Character", 
		"z-index": 200 
	},
	{ 
		"name": "Background", 
		"z-index": 100 
	}
]

func _init():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ArgodeSystemLayer"
	ArgodeSystem.add_child(canvas_layer)
	for layer in layers:
		var layer_instance:Control = Control.new()
		layer_instance.name = layer["name"]
		# z-indexを設定
		layer_instance.z_index = layer["z-index"]
		#layer_instanceはアンカーもオフセットも画面全体に広げる
		layer_instance.anchor_left = 0
		layer_instance.anchor_right = 1
		layer_instance.anchor_top = 0
		layer_instance.anchor_bottom = 1
		layer_instance.offset_left = 0
		layer_instance.offset_right = 0
		layer_instance.offset_top = 0
		layer_instance.offset_bottom = 0
		# CanvasLayerに追加
		layer_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas_layer.add_child(layer_instance)

	ArgodeSystem.log("📚ArgodeLayerManager is ready")

## 指定された名前のレイヤーを取得
func get_layer(layer_name: String) -> Control:
	var system_layer = ArgodeSystem.get_node_or_null("ArgodeSystemLayer")
	if not system_layer:
		return null
	
	return system_layer.get_node_or_null(layer_name)

## GUIレイヤーを取得（便利メソッド）
func get_gui_layer() -> Control:
	return get_layer("GUI")

## キャラクターレイヤーを取得（便利メソッド）
func get_character_layer() -> Control:
	return get_layer("Character")

## 背景レイヤーを取得（便利メソッド）
func get_background_layer() -> Control:
	return get_layer("Background")
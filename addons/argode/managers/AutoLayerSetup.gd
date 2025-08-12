# AutoLayerSetup.gd
# Argode専用レイヤーの自動展開システム
@tool
extends Node
class_name AutoLayerSetup

## Argodeの標準3層レイヤー構造を自動で作成・設定します
## Character・Background・GUIは専用レイヤーとして自動展開

static func create_argode_layers(parent_scene: Node) -> Dictionary:
	"""Argodeの標準レイヤー構造を自動作成"""
	print("🏗️ Creating Argode standard layer structure...")
	
	var layer_map = {}
	
	# 1. BackgroundLayer（最下層）
	var background_layer = _create_layer("BackgroundLayer", parent_scene, 0)
	layer_map["background"] = background_layer
	
	# 2. CharacterLayer（中層）
	var character_layer = _create_layer("CharacterLayer", parent_scene, 100)
	layer_map["character"] = character_layer
	
	# 3. UILayer（最上層）- ArgodeScreen自身を使用
	if parent_scene is Control:
		layer_map["ui"] = parent_scene
		parent_scene.z_index = 200
		print("🗺️ UI layer set to parent scene with z_index: 200")
	else:
		var ui_layer = _create_layer("UILayer", parent_scene, 200)
		layer_map["ui"] = ui_layer
	
	print("✅ Argode layer structure created:", layer_map.keys())
	return layer_map

static func _create_layer(layer_name: String, parent: Node, z_index: int) -> Control:
	"""単一レイヤーを作成"""
	var layer = Control.new()
	layer.name = layer_name
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.z_index = z_index
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE  # マウスイベントを透過
	
	parent.add_child(layer)
	print("🗺️ Created layer:", layer_name, "with z_index:", z_index)
	
	return layer

static func setup_layer_hierarchy(scene: Node) -> Dictionary:
	"""既存のシーンにレイヤー階層を検証・設定"""
	var layers = {}
	
	# 既存レイヤーを検索
	var bg_layer = scene.find_child("BackgroundLayer", false, false)
	var char_layer = scene.find_child("CharacterLayer", false, false)  
	var ui_layer = scene.find_child("UILayer", false, false)
	
	# 不足しているレイヤーを自動作成
	if not bg_layer:
		bg_layer = _create_layer("BackgroundLayer", scene, 0)
	layers["background"] = bg_layer
	
	if not char_layer:
		char_layer = _create_layer("CharacterLayer", scene, 100)
	layers["character"] = char_layer
	
	# UILayerは通常、ArgodeScreen自身を使用
	if scene is Control:
		layers["ui"] = scene
		scene.z_index = 200
	elif ui_layer:
		layers["ui"] = ui_layer
		ui_layer.z_index = 200
	else:
		layers["ui"] = _create_layer("UILayer", scene, 200)
	
	return layers

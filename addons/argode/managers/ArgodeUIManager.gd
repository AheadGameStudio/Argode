extends RefCounted
class_name ArgodeUIManager

var ui_elements:Dictionary = {}
var layer_manager:ArgodeLayerManager
var gui_layer:Control
# 現在アクティブなUIのエイリアス
var active_ui_alias:String = ""

signal is_shown_ui(instance:Control)
signal is_hidden_ui(instance:Control)

func _init() -> void:
	# if ArgodeSystem.is_system_ready:
	layer_manager = ArgodeSystem.LayerManager
	gui_layer = layer_manager.get_gui_layer()
	ArgodeSystem.log("📚ArgodeUIManager is ready")

## UIの追加
func add_ui(path: String, alias:String ="", z_index:int = 0) -> void:
	"""
	Adds a UI instance to the manager.
	"""
	var ui_scene:PackedScene = load(path)
	var ui_instance = ui_scene.instantiate()
	if not ui_instance:
		ArgodeSystem.log("❌ Failed to load UI: " + path, 2)
		return
	
	if alias.is_empty():
		var _rnd_seed:int = rand_from_seed(Time.get_ticks_msec())[0] # シードを設定してランダム性を確保
		# もしエイリアスが設定されないなら被らないエイリアスを自動付与
		# ※ただ管理がしづらいと思うのでエイリアスの指定は推奨
		alias = "ui_" + ui_instance.name + "_" + str(_rnd_seed)

	if ui_instance is not Control:
		ArgodeSystem.log("❌ UI is not a Control: " + path, 2)
		return

	ui_elements[alias] = ui_instance
	ui_instance.z_index = z_index
	gui_layer.add_child(ui_instance)
	ArgodeSystem.log("📥 Added UI: " + path + " as " + alias)

## UIを削除。
## 完全にインスタンスごと解放するため、再度必要な場合はadd_uiが必要。
func delete_ui(alias:String) -> void:
	"""
	Frees the UI instance with the given alias.
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]
	ui_elements.erase(alias)
	ui_instance.queue_free()

## エイリアスで指定したUIのz-indexを変更
func change_z_index(alias:String, z_index:int) -> void:
	"""
	Changes the z-index of the UI instance with the given alias.
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]
	ui_instance.z_index = z_index

## UIの表示
func show_ui(alias:String) -> void:
	"""
	Shows the UI instance with the given alias.
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]

	ui_instance.show()

## UIの非表示
func hide_ui(alias:String) -> void:
	"""
	Hides the UI instance with the given alias.
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]
	ui_instance.hide()

## すべてのUIの辞書を取得
func get_all_ui() -> Dictionary:
	"""
	Returns all UI elements managed by the UI manager.
	"""
	return ui_elements

## 管理対象にそのエイリアスのUIが含まれるか
func has_ui(alias:String) -> bool:
	"""
	Checks if the UI instance with the given alias exists.
	"""
	return ui_elements.has(alias)

## 指定したエイリアスのUIを最前面に移動
func set_front(alias:String) -> void:
	"""
	Sets the UI instance with the given alias to the front of the GUI layer.
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]

	if ui_instance.get("is_sticky_front") and ui_instance.is_sticky_front:
		# is_sticky_frontがtrueの場合は処理をしない
		ArgodeSystem.log("ℹ️ UI '%s' is sticky front, skipping z-index adjustment." % alias)
		return

	# 指定されたUIをすべてのUIの最前面に移動
	# まずはすべての子要素のz_indexを1ずつ下げる
	for child in gui_layer.get_children():
		# is_sticky_frontがtrueの子要素はスキップ
		if child.get("is_sticky_front") and child.is_sticky_front:
			continue
		child.z_index -= 1
	# すべての子要素のz_indexを取得し、最も大きい値を取得
	var max_z_index = -1
	for child in gui_layer.get_children():
		if child.z_index > max_z_index:
			max_z_index = child.z_index
	# 指定されたUIのz_indexを最も大きい値の1つ上に設定
	ui_instance.z_index = max_z_index + 1


## 指定したUIを最背面に移動
func set_back(alias:String) -> void:
	"""
	Sets the UI instance with the given alias to the back of the GUI layer.
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]

	if ui_instance.get("is_sticky_front") and ui_instance.is_sticky_front:
		# is_sticky_frontがtrueの場合は処理をしない
		ArgodeSystem.log("ℹ️ UI '%s' is sticky front, skipping z-index adjustment." % alias)
		return

	# 指定されたUIをすべてのUIの最背面に移動
	# まずはすべての子要素のz_indexを1ずつ上げる
	for child in gui_layer.get_children():
		# is_sticky_backがtrueの子要素はスキップ
		if child.get("is_sticky_back") and child.is_sticky_back:
			continue
		child.z_index += 1
	# すべての子要素のz_indexを取得し、最も小さい値を取得
	var min_z_index = 1
	for child in gui_layer.get_children():
		if child.z_index < min_z_index:
			min_z_index = child.z_index
	# 指定されたUIのz_indexを最も小さい値の1つ下に設定
	ui_instance.z_index = min_z_index - 1

## 指定したUIを、その背面のUIと入れ替える
func bring_to_front(alias:String) -> void:
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]

	if ui_instance.get("is_sticky_front") and ui_instance.is_sticky_front:
		# is_sticky_frontがtrueの場合は処理をしない
		ArgodeSystem.log("ℹ️ UI '%s' is sticky front, skipping z-index adjustment." % alias)
		return
	
	# 指定されたUIの1個後ろのz_indexを保持するための変数
	# もし後ろがない場合に備え指定されたUIのz_indexを一時的に指定
	var behind_z_index = ui_instance.z_index
	# 指定されたUI要素の後ろにある要素のz_indexを取得
	for child in gui_layer.get_children():
		if child.z_index < ui_instance.z_index:
			behind_z_index = child.z_index
			# その要素のz_indexを1つ上げる
			child.z_index += 1
	# 後ろのUI要素のz_indexが、指定されたUIのz_index以下の場合は入れ替え
	if behind_z_index <= ui_instance.z_index:
		ui_instance.z_index = behind_z_index

func bring_to_back(alias:String) -> void:
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, 2)
		return
	var ui_instance = ui_elements[alias]

	if ui_instance.get("is_sticky_back") and ui_instance.is_sticky_back:
		# is_sticky_backがtrueの場合は処理をしない
		ArgodeSystem.log("ℹ️ UI '%s' is sticky back, skipping z-index adjustment." % alias)
		return

	# 指定されたUIの1個前のz_indexを保持するための変数
	# もし前がない場合に備え指定されたUIのz_indexを一時的に指定
	var front_z_index = ui_instance.z_index
	# 指定されたUI要素の前にある要素のz_indexを取得
	for child in gui_layer.get_children():
		if child.z_index > ui_instance.z_index:
			front_z_index = child.z_index
			# その要素のz_indexを1つ下げる
			child.z_index -= 1
	# 前のUI要素のz_indexが、指定されたUIのz_index以上の場合は入れ替え
	if front_z_index >= ui_instance.z_index:
		ui_instance.z_index = front_z_index

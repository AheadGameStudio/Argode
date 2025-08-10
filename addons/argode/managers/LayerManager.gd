# LayerManager.gd
# v2設計: レイヤーシステム管理（背景・キャラクター・UI層の制御）
extends Node
class_name LayerManager

# === シグナル ===
signal layer_changed(layer_name: String, content: Node)
signal background_changed(bg_path: String)
signal character_added(character_name: String, position: String)
signal character_removed(character_name: String)

# === レイヤー参照 ===
var background_layer: Control = null
var character_layer: Control = null 
var ui_layer: Control = null

# === 背景管理 ===
var current_background: TextureRect = null
var background_cache: Dictionary = {}

# === キャラクター管理 ===
var character_nodes: Dictionary = {}  # character_name -> TextureRect
var character_positions: Dictionary = {
	"left": Vector2(0.2, 1.0),
	"center": Vector2(0.5, 1.0), 
	"right": Vector2(0.8, 1.0),
	"far_left": Vector2(0.1, 1.0),
	"far_right": Vector2(0.9, 1.0)
}

# === Z-Order管理 ===
var layer_z_orders: Dictionary = {
	"background": 0,
	"character": 100,
	"ui": 200
}

func initialize_layers(bg_layer: Control, char_layer: Control, ui_layer_ref: Control):
	"""レイヤーシステムを初期化"""
	background_layer = bg_layer
	character_layer = char_layer
	ui_layer = ui_layer_ref
	
	# Z-Orderを設定
	if background_layer:
		background_layer.z_index = layer_z_orders["background"]
		print("🗺️ Background layer initialized with z_index:", layer_z_orders["background"])
	
	if character_layer:
		character_layer.z_index = layer_z_orders["character"] 
		print("🗺️ Character layer initialized with z_index:", layer_z_orders["character"])
	
	if ui_layer:
		ui_layer.z_index = layer_z_orders["ui"]
		print("🗺️ UI layer initialized with z_index:", layer_z_orders["ui"])
	
	print("✅ LayerManager: All layers initialized successfully")

# === 背景管理 ===

func change_background(bg_path: String, transition: String = "none") -> bool:
	"""背景を変更する（トランジション対応）"""
	if not background_layer:
		push_error("❌ LayerManager: Background layer not initialized")
		return false
	
	print("🖼️ LayerManager: Changing background to:", bg_path)
	
	# 新しい背景テクスチャを作成
	var new_bg = _create_background_node(bg_path)
	if not new_bg:
		push_error("❌ Failed to create background:", bg_path)
		return false
	
	# TransitionPlayerを使用してトランジション実行
	if transition != "none":
		var adv_system = get_node("/root/ArgodeSystem")
		var transition_player = adv_system.TransitionPlayer if adv_system else null
		if transition_player:
			print("🎬 LayerManager: Executing background transition:", transition)
			_execute_background_transition(new_bg, transition)
		else:
			push_warning("⚠️ TransitionPlayer not found, using immediate change")
			_set_background_immediately(new_bg)
	else:
		_set_background_immediately(new_bg)
	
	background_changed.emit(bg_path)
	return true

func _create_background_node(bg_path: String) -> TextureRect:
	"""背景ノードを作成"""
	# キャッシュから取得を試行
	if bg_path in background_cache:
		return background_cache[bg_path].duplicate()
	
	var texture = load(bg_path)
	if not texture:
		# フォールバック: 直接ファイルから読み込みを試行
		print("🔄 Trying direct file loading for:", bg_path)
		var image = Image.new()
		var file_path = bg_path.replace("res://", "")
		var load_result = image.load(file_path)
		if load_result == OK:
			texture = ImageTexture.new()
			texture.create_from_image(image)
			print("✅ Direct file loading successful:", bg_path)
		else:
			push_error("❌ Failed to load background texture:", bg_path)
			return null
	
	var bg_node = TextureRect.new()
	bg_node.texture = texture
	bg_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# キャッシュに保存
	background_cache[bg_path] = bg_node.duplicate()
	
	return bg_node

func _set_background_immediately(new_bg: TextureRect):
	"""背景を即座に変更"""
	if current_background:
		current_background.queue_free()
	
	background_layer.add_child(new_bg)
	current_background = new_bg

func _execute_background_transition(new_bg: TextureRect, transition: String):
	"""背景トランジションを実行"""
	# シンプルなフェード効果を実装
	if transition == "fade" or transition == "dissolve":
		# 新背景を透明で追加
		new_bg.modulate.a = 0.0
		background_layer.add_child(new_bg)
		
		# フェードインアニメーション
		var tween = create_tween()
		tween.set_parallel(true)
		
		# 古い背景をフェードアウト
		if current_background:
			tween.tween_property(current_background, "modulate:a", 0.0, 0.5)
		
		# 新背景をフェードイン
		tween.tween_property(new_bg, "modulate:a", 1.0, 0.5)
		
		await tween.finished
		
		# 古い背景を削除
		if current_background and current_background != new_bg:
			current_background.queue_free()
	else:
		# 即座に切り替え
		background_layer.add_child(new_bg)
		if current_background and current_background != new_bg:
			current_background.queue_free()
	
	current_background = new_bg

# === キャラクター管理 ===

func show_character(char_name: String, expression: String, position: String, transition: String = "none") -> bool:
	"""キャラクターを表示する"""
	if not character_layer:
		push_error("❌ LayerManager: Character layer not initialized")
		return false
	
	print("👤 LayerManager: Showing character:", char_name, "expression:", expression, "at:", position)
	
	# キャラクター定義を取得 (v2: ArgodeSystem経由)
	var adv_system = get_node("/root/ArgodeSystem")
	if not adv_system or not adv_system.CharDefs:
		push_error("❌ ArgodeSystem.CharDefs not found")
		return false
	
	var char_data = adv_system.CharDefs.get_character_definition(char_name)
	if not char_data:
		push_error("❌ Character not defined:", char_name)
		return false
	
	# キャラクターノードを作成
	var char_node = _create_character_node(char_name, char_data, expression, position)
	if not char_node:
		return false
	
	# 既存のキャラクターノードを削除
	if char_name in character_nodes:
		character_nodes[char_name].queue_free()
	
	# トランジション実行
	if transition != "none":
		_execute_character_transition(char_node, transition, true)
	else:
		character_layer.add_child(char_node)
	
	character_nodes[char_name] = char_node
	character_added.emit(char_name, position)
	return true

func hide_character(char_name: String, transition: String = "none") -> bool:
	"""キャラクターを非表示にする"""
	if char_name not in character_nodes:
		push_warning("⚠️ Character not shown:", char_name)
		return false
	
	print("👤 LayerManager: Hiding character:", char_name)
	
	var char_node = character_nodes[char_name]
	
	# トランジション実行
	if transition != "none":
		_execute_character_transition(char_node, transition, false)
	else:
		char_node.queue_free()
		character_nodes.erase(char_name)
	
	character_removed.emit(char_name)
	return true

func _create_character_node(char_name: String, char_data: Dictionary, expression: String, position: String) -> TextureRect:
	"""キャラクターノードを作成"""
	# 画像パスをImageDefinitionManagerから取得
	var image_path = ""
	var adv_system = get_node("/root/ArgodeSystem")
	if adv_system and adv_system.ImageDefs:
		# キャラクターIDから実際の名前を取得
		var actual_char_name = ""
		if char_name == "y":
			actual_char_name = "yuko"
		elif char_name == "s":
			actual_char_name = "saitos"
		else:
			actual_char_name = char_name
		
		# 「実際の名前 表情」で検索
		var image_key = actual_char_name + " " + expression
		image_path = adv_system.ImageDefs.get_image_path(image_key)
		print("🔍 ImageDefs lookup for '", image_key, "' (from char_id '", char_name, "'): ", image_path)
	
	# 定義が見つからない場合はデフォルトパス構築（実際の名前を使用）
	if image_path.is_empty():
		var actual_char_name = ""
		if char_name == "y":
			actual_char_name = "yuko"
		elif char_name == "s":
			actual_char_name = "saitos"
		else:
			actual_char_name = char_name
		
		image_path = "res://assets/images/characters/" + actual_char_name + "_" + expression + ".png"
		print("🔍 Using default character path: ", image_path)
	
	var texture = load(image_path)
	if not texture:
		# フォールバック: 直接ファイルから読み込みを試行
		print("🔄 Trying direct file loading for:", image_path)
		var image = Image.new()
		var file_path = image_path.replace("res://", "")
		var load_result = image.load(file_path)
		if load_result == OK:
			texture = ImageTexture.new()
			texture.create_from_image(image)
			print("✅ Direct file loading successful:", image_path)
		else:
			push_error("❌ Failed to load character image:", image_path)
			return null
	
	var char_node = TextureRect.new()
	char_node.texture = texture
	char_node.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	char_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 位置設定
	_set_character_position(char_node, position)
	
	return char_node

func _set_character_position(char_node: TextureRect, position: String):
	"""キャラクターの位置を設定"""
	if position not in character_positions:
		push_warning("⚠️ Unknown position:", position, "using center")
		position = "center"
	
	var pos_vector = character_positions[position]
	char_node.anchor_left = pos_vector.x - 0.1  # 幅調整
	char_node.anchor_right = pos_vector.x + 0.1
	char_node.anchor_top = 0.0
	char_node.anchor_bottom = pos_vector.y
	
	char_node.offset_left = 0
	char_node.offset_right = 0
	char_node.offset_top = 0
	char_node.offset_bottom = 0

func _execute_character_transition(char_node: TextureRect, transition: String, is_showing: bool):
	"""キャラクタートランジションを実行"""
	if transition == "fade" or transition == "dissolve":
		if is_showing:
			# フェードイン
			char_node.modulate.a = 0.0
			character_layer.add_child(char_node)
			
			var tween = create_tween()
			tween.tween_property(char_node, "modulate:a", 1.0, 0.3)
			await tween.finished
		else:
			# フェードアウト
			var tween = create_tween()
			tween.tween_property(char_node, "modulate:a", 0.0, 0.3)
			await tween.finished
			
			char_node.queue_free()
			character_nodes.erase(char_node.name)
	else:
		# 即座に表示/非表示
		if is_showing:
			character_layer.add_child(char_node)
		else:
			char_node.queue_free()
			character_nodes.erase(char_node.name)

# === ユーティリティ ===

func get_layer_info() -> Dictionary:
	"""デバッグ用レイヤー情報を取得"""
	return {
		"background_layer": background_layer != null,
		"character_layer": character_layer != null,
		"ui_layer": ui_layer != null,
		"current_background": current_background != null,
		"active_characters": character_nodes.keys(),
		"z_orders": layer_z_orders
	}

func clear_all_layers():
	"""全レイヤーをクリア"""
	if current_background:
		current_background.queue_free()
		current_background = null
	
	for char_name in character_nodes.keys():
		character_nodes[char_name].queue_free()
	
	character_nodes.clear()
	background_cache.clear()
	
	print("🧹 LayerManager: All layers cleared")
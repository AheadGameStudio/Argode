# ShaderEffectManager.gd
# Argode v2: シェーダーベース視覚効果管理システム
extends Node
class_name ShaderEffectManager

# === シグナル ===
signal effect_applied(target: Node, shader_name: String, params: Dictionary)
signal effect_removed(target: Node, shader_name: String)
signal effect_completed(target: Node, shader_name: String)

# === シェーダーキャッシュ ===
var shader_cache: Dictionary = {}
var shader_paths: Dictionary = {
	# スクリーンエフェクト
	"flash": "res://addons/argode/shaders/screen_effects/flash.gdshader",
	"fade": "res://addons/argode/shaders/screen_effects/fade.gdshader", 
	"tint": "res://addons/argode/shaders/screen_effects/tint.gdshader",
	"blur": "res://addons/argode/shaders/screen_effects/blur.gdshader",
	"wave": "res://addons/argode/shaders/screen_effects/wave.gdshader",
	"grayscale": "res://addons/argode/shaders/screen_effects/grayscale.gdshader",
	"sepia": "res://addons/argode/shaders/screen_effects/sepia.gdshader",
	
	# 特殊効果
	"pixelate": "res://addons/argode/shaders/screen_effects/pixelate.gdshader",
	"vignette": "res://addons/argode/shaders/screen_effects/vignette.gdshader",
	"chromatic": "res://addons/argode/shaders/screen_effects/chromatic.gdshader"
}

# === アクティブ効果管理 ===
var active_effects: Dictionary = {}  # target_node -> Array[EffectController]
var effect_id_counter: int = 0

func _ready():
	print("🎨 ShaderEffectManager initialized")

# === メイン効果適用API ===

func apply_screen_effect(shader_name: String, params: Dictionary, duration: float = 0.0) -> int:
	"""画面全体にシェーダー効果を適用"""
	var screen_overlay = _get_or_create_screen_overlay()
	if not screen_overlay:
		push_error("❌ Failed to create screen overlay")
		return -1
	
	return apply_effect(screen_overlay, shader_name, params, duration)

func apply_layer_effect(layer_node: Node, shader_name: String, params: Dictionary, duration: float = 0.0) -> int:
	"""特定レイヤーにシェーダー効果を適用"""
	if not layer_node:
		push_error("❌ Layer node is null")
		return -1
	
	return apply_effect(layer_node, shader_name, params, duration)

func apply_effect(target_node: Node, shader_name: String, params: Dictionary, duration: float = 0.0) -> int:
	"""指定ノードにシェーダー効果を適用"""
	if not target_node:
		push_error("❌ Target node is null")
		return -1
	
	if shader_name not in shader_paths:
		push_error("❌ Unknown shader: " + shader_name)
		return -1
	
	print("🎨 Applying shader effect: ", shader_name, " to ", target_node.name)
	
	# シェーダーを読み込み
	var shader = _load_shader(shader_name)
	if not shader:
		push_error("❌ Failed to load shader: " + shader_name)
		return -1
	
	# EffectControllerを作成
	var effect_id = _generate_effect_id()
	var controller = EffectController.new()
	controller.initialize(effect_id, target_node, shader, shader_name, params, duration)
	
	# 効果適用
	var success = controller.apply_effect()
	if not success:
		push_error("❌ Failed to apply effect: " + shader_name)
		return -1
	
	# アクティブ効果に追加
	if target_node not in active_effects:
		active_effects[target_node] = []
	active_effects[target_node].append(controller)
	
	# シグナル接続
	controller.effect_completed.connect(_on_effect_completed)
	
	# 持続時間がある場合、自動除去タイマー設定
	if duration > 0.0:
		controller.start_duration_timer()
	
	effect_applied.emit(target_node, shader_name, params)
	return effect_id

# === 効果除去API ===

func remove_effect(target_node: Node, effect_id: int) -> bool:
	"""指定効果を除去"""
	if target_node not in active_effects:
		return false
	
	var effects = active_effects[target_node]
	for i in range(effects.size()):
		var controller = effects[i]
		if controller.effect_id == effect_id:
			controller.remove_effect()
			effects.erase(controller)
			if effects.is_empty():
				active_effects.erase(target_node)
			effect_removed.emit(target_node, controller.shader_name)
			return true
	
	return false

func remove_all_effects(target_node: Node) -> bool:
	"""指定ノードの全効果を除去"""
	if target_node not in active_effects:
		return false
	
	var effects = active_effects[target_node]
	for controller in effects:
		controller.remove_effect()
		effect_removed.emit(target_node, controller.shader_name)
	
	active_effects.erase(target_node)
	return true

func clear_all_effects() -> void:
	"""全効果をクリア"""
	for target_node in active_effects.keys():
		remove_all_effects(target_node)

# === シェーダー管理 ===

func _load_shader(shader_name: String) -> Shader:
	"""シェーダーを読み込み（キャッシュ使用）"""
	if shader_name in shader_cache:
		return shader_cache[shader_name]
	
	var shader_path = shader_paths[shader_name]
	if not FileAccess.file_exists(shader_path):
		push_error("❌ Shader file not found: " + shader_path)
		return null
	
	var shader = load(shader_path) as Shader
	if not shader:
		push_error("❌ Failed to load shader: " + shader_path)
		return null
	
	shader_cache[shader_name] = shader
	print("✅ Shader loaded and cached: " + shader_name)
	return shader

func preload_shaders() -> void:
	"""よく使用するシェーダーを事前読み込み"""
	var common_shaders = ["flash", "fade", "tint", "blur"]
	for shader_name in common_shaders:
		_load_shader(shader_name)

# === 内部ヘルパー ===

func _get_or_create_screen_overlay() -> Control:
	"""スクリーン全体効果用のオーバーレイを取得/作成"""
	var overlay = get_tree().get_first_node_in_group("argode_screen_overlay")
	if overlay:
		return overlay
	
	# 新しいオーバーレイを作成（シェーダー効果のため白背景）
	overlay = ColorRect.new()
	overlay.name = "ArgodeScreenOverlay"
	overlay.color = Color.WHITE  # シェーダーが適用されるための基準色
	overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)  # 初期は透明
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 999  # UI層より上
	overlay.add_to_group("argode_screen_overlay")
	
	# メインシーンに追加
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(overlay)
		print("✅ Screen overlay created")
		return overlay
	else:
		push_error("❌ No current scene found for screen overlay")
		return null

func _generate_effect_id() -> int:
	"""効果IDを生成"""
	effect_id_counter += 1
	return effect_id_counter

func _on_effect_completed(controller: EffectController):
	"""効果完了時の処理"""
	var target_node = controller.target_node
	if target_node in active_effects:
		var effects = active_effects[target_node]
		effects.erase(controller)
		if effects.is_empty():
			active_effects.erase(target_node)
	
	effect_completed.emit(controller.target_node, controller.shader_name)
	print("✅ Effect completed: ", controller.shader_name)

# === デバッグ情報 ===

func get_active_effects_info() -> Dictionary:
	"""アクティブ効果の情報を取得"""
	var info = {}
	for target_node in active_effects.keys():
		var effects_info = []
		for controller in active_effects[target_node]:
			effects_info.append({
				"id": controller.effect_id,
				"shader": controller.shader_name,
				"duration": controller.duration,
				"remaining": controller.get_remaining_time()
			})
		info[target_node.name] = effects_info
	return info

func print_debug_info():
	"""デバッグ情報を出力"""
	print("🔍 ShaderEffectManager Debug Info:")
	print("  📋 Cached shaders: ", shader_cache.keys())
	print("  ✨ Active effects: ", get_active_effects_info())
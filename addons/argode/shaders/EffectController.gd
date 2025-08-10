# EffectController.gd  
# Argode v2: 個別のシェーダー効果制御クラス
extends RefCounted
class_name EffectController

# === シグナル ===
signal effect_completed(controller: EffectController)

# === 基本情報 ===
var effect_id: int
var target_node: Node
var shader: Shader
var shader_name: String
var parameters: Dictionary
var duration: float

# === 制御状態 ===
var is_active: bool = false
var material: ShaderMaterial
var original_material: Material
var duration_timer: Timer
var tween: Tween

func initialize(id: int, node: Node, shader_res: Shader, name: String, params: Dictionary, dur: float):
	"""EffectControllerを初期化"""
	effect_id = id
	target_node = node
	shader = shader_res
	shader_name = name
	parameters = params
	duration = dur

func apply_effect() -> bool:
	"""効果を適用"""
	if not target_node or not shader:
		push_error("❌ EffectController: Invalid target or shader")
		return false
	
	# 元のマテリアルを保存
	if target_node.has_method("get_material"):
		original_material = target_node.get_material()
	elif target_node.has_property("material"):
		original_material = target_node.material
	
	# シェーダーマテリアルを作成
	material = ShaderMaterial.new()
	material.shader = shader
	
	# パラメータを設定
	_apply_parameters()
	
	# ターゲットノードにマテリアルを設定
	var success = _set_material_to_target()
	if not success:
		push_error("❌ Failed to apply material to target")
		return false
	
	is_active = true
	print("✅ Effect applied: ", shader_name, " to ", target_node.name)
	return true

func remove_effect():
	"""効果を除去"""
	if not is_active:
		return
	
	# 元のマテリアルを復元
	_restore_original_material()
	
	# タイマー・Tweenをクリーンアップ
	_cleanup_controllers()
	
	is_active = false
	print("🗑️ Effect removed: ", shader_name, " from ", target_node.name)

func start_duration_timer():
	"""持続時間タイマーを開始"""
	if duration <= 0.0:
		return
	
	if not duration_timer:
		duration_timer = Timer.new()
		duration_timer.wait_time = duration
		duration_timer.one_shot = true
		duration_timer.timeout.connect(_on_duration_timeout)
		target_node.add_child(duration_timer)
	
	duration_timer.start()
	print("⏱️ Duration timer started: ", duration, "s for ", shader_name)

func update_parameter(param_name: String, value):
	"""パラメータを動的更新"""
	if not material or not is_active:
		return
	
	parameters[param_name] = value
	material.set_shader_parameter(param_name, value)

func animate_parameter(param_name: String, from_value, to_value, anim_duration: float, easing: Tween.EaseType = Tween.EASE_OUT):
	"""パラメータをアニメーション"""
	if not material or not is_active:
		return
	
	if tween:
		tween.kill()
	
	tween = target_node.create_tween()
	tween.set_ease(easing)
	
	# 開始値設定
	update_parameter(param_name, from_value)
	
	# アニメーション実行
	tween.tween_method(
		func(value): update_parameter(param_name, value),
		from_value,
		to_value,
		anim_duration
	)
	
	print("🎭 Animating parameter: ", param_name, " from ", from_value, " to ", to_value)

func get_remaining_time() -> float:
	"""残り時間を取得"""
	if duration_timer and not duration_timer.is_stopped():
		return duration_timer.time_left
	return 0.0

# === 内部メソッド ===

func _apply_parameters():
	"""パラメータをシェーダーに適用"""
	for param_name in parameters.keys():
		var value = parameters[param_name]
		
		# パラメータ名の変換（必要に応じて）
		var shader_param_name = _convert_parameter_name(param_name)
		
		# Godot 4.xでは直接set_shader_parameterを使用
		# 存在しないパラメータを設定してもエラーにならない
		material.set_shader_parameter(shader_param_name, value)
		print("🔧 Parameter set: ", shader_param_name, " = ", value)

func _convert_parameter_name(param_name: String) -> String:
	"""パラメータ名を変換（カスタムコマンド → シェーダー）"""
	var conversion_map = {
		# flash.gdshader用
		"flash_color": "flash_color",
		"flash_intensity": "flash_intensity", 
		"flash_time": "flash_time",
		
		# tint.gdshader用
		"tint_color": "tint_color",
		"tint_intensity": "tint_intensity",
		"blend_mode": "blend_mode",
		
		# blur.gdshader用
		"blur_amount": "blur_amount",
		"blur_direction": "blur_direction",
		"high_quality": "high_quality",
		
		# wave.gdshader用
		"wave_amplitude": "wave_amplitude",
		"wave_frequency": "wave_frequency",
		"wave_speed": "wave_speed",
		"wave_direction": "wave_direction",
		"time_offset": "time_offset"
	}
	
	return conversion_map.get(param_name, param_name)

func _set_material_to_target() -> bool:
	"""ターゲットノードにマテリアルを設定"""
	# CanvasItemの場合
	if target_node is CanvasItem:
		target_node.material = material
		return true
	
	# Controlの場合（一部のControlノード）
	if target_node is Control and target_node.has_method("set_material"):
		target_node.set_material(material)
		return true
	
	# TextureRectなど特定ノード
	if target_node.has_property("material"):
		target_node.material = material
		return true
	
	push_error("❌ Target node type not supported for shader effects: " + target_node.get_class())
	return false

func _restore_original_material():
	"""元のマテリアルを復元"""
	if not target_node:
		return
	
	if target_node is CanvasItem:
		target_node.material = original_material
	elif target_node is Control and target_node.has_method("set_material"):
		target_node.set_material(original_material)
	elif target_node.has_property("material"):
		target_node.material = original_material

func _cleanup_controllers():
	"""制御オブジェクトをクリーンアップ"""
	if duration_timer:
		duration_timer.queue_free()
		duration_timer = null
	
	if tween:
		tween.kill()
		tween = null

func _on_duration_timeout():
	"""持続時間タイマー完了時"""
	print("⏰ Duration timeout for effect: ", shader_name)
	
	# 画面オーバーレイの場合は完全に削除
	if target_node and target_node.is_in_group("argode_screen_overlay"):
		print("🗑️ Removing screen overlay after flash effect")
		target_node.queue_free()
	
	remove_effect()
	effect_completed.emit(self)
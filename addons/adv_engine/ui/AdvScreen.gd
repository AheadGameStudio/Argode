# AdvScreen.gd
# v2設計: UI基底クラス - call_screenで呼び出されるUIシーンが継承すべき高機能な基底クラス
extends Control
class_name AdvScreen

# === シグナル ===
signal screen_closed(return_value)
signal screen_ready()
signal screen_pre_close()

# === 画面管理プロパティ ===
var screen_name: String = ""
var is_screen_active: bool = false
var return_value: Variant = null
var screen_parameters: Dictionary = {}
var parent_screen: AdvScreen = null

# === AdvSystem統合 ===
var adv_system: Node = null

func _ready():
	screen_name = get_scene_file_path().get_file().get_basename() if get_scene_file_path() else name
	print("📱 AdvScreen initialized: ", screen_name)
	
	# AdvSystemへの参照を取得
	adv_system = get_node("/root/AdvSystem")
	if not adv_system:
		push_warning("⚠️ AdvScreen: AdvSystem not found")
	
	# 初期化完了を通知
	call_deferred("_emit_screen_ready")

func _emit_screen_ready():
	screen_ready.emit()
	on_screen_ready()

# === 仮想メソッド群（継承先でオーバーライド） ===

func on_screen_ready():
	"""画面の初期化完了時に呼び出される（継承先でオーバーライド）"""
	pass

func on_screen_shown(parameters: Dictionary = {}):
	"""画面が表示された時に呼び出される（継承先でオーバーライド）"""
	screen_parameters = parameters
	is_screen_active = true
	print("📱 Screen shown: ", screen_name, " with params: ", parameters)

func on_screen_hidden():
	"""画面が非表示になった時に呼び出される（継承先でオーバーライド）"""
	is_screen_active = false
	print("📱 Screen hidden: ", screen_name)

func on_screen_closing() -> bool:
	"""画面が閉じられる直前に呼び出される（継承先でオーバーライド）
	@return: falseを返すとクローズをキャンセル可能"""
	return true

# === スクリーン制御API ===

func show_screen(parameters: Dictionary = {}):
	"""画面を表示する"""
	visible = true
	on_screen_shown(parameters)

func hide_screen():
	"""画面を非表示にする"""
	visible = false
	on_screen_hidden()

func close_screen(return_val: Variant = null):
	"""画面を閉じる"""
	if not on_screen_closing():
		print("📱 Screen close cancelled by on_screen_closing(): ", screen_name)
		return
	
	screen_pre_close.emit()
	return_value = return_val
	is_screen_active = false
	
	# UIManagerに画面クローズを通知
	if adv_system and adv_system.UIManager:
		adv_system.UIManager.close_screen(self, return_val)
	
	screen_closed.emit(return_val)
	print("📱 Screen closed: ", screen_name, " with return value: ", return_val)

func call_screen(screen_path: String, parameters: Dictionary = {}) -> Variant:
	"""子画面を呼び出す（スクリーンスタック）"""
	if adv_system and adv_system.UIManager:
		return await adv_system.UIManager.call_screen(screen_path, parameters, self)
	else:
		push_error("❌ AdvScreen: Cannot call screen - UIManager not available")
		return null

# === シナリオ操作API ===

func jump_to(label_name: String):
	"""シナリオの指定ラベルにジャンプ"""
	if adv_system and adv_system.Player:
		adv_system.Player.play_from_label(label_name)
	else:
		push_error("❌ AdvScreen: Cannot jump - AdvScriptPlayer not available")

func call_label(label_name: String):
	"""シナリオの指定ラベルをcall（return可能）"""
	if adv_system and adv_system.Player:
		# call_stackに現在位置を積んでからジャンプ
		adv_system.Player.call_stack.append({"line": adv_system.Player.current_line_index, "screen": self})
		adv_system.Player.play_from_label(label_name)
	else:
		push_error("❌ AdvScreen: Cannot call label - AdvScriptPlayer not available")

func set_variable(var_name: String, value: Variant):
	"""シナリオ変数を設定"""
	if adv_system and adv_system.VariableManager:
		adv_system.VariableManager.global_vars[var_name] = value
		print("📊 Variable set from screen: ", var_name, " = ", value)
	else:
		push_error("❌ AdvScreen: Cannot set variable - VariableManager not available")

func get_variable(var_name: String) -> Variant:
	"""シナリオ変数を取得"""
	if adv_system and adv_system.VariableManager:
		return adv_system.VariableManager.global_vars.get(var_name, null)
	else:
		push_error("❌ AdvScreen: Cannot get variable - VariableManager not available")
		return null

# === ユーティリティ ===

func get_parameter(key: String, default_value: Variant = null) -> Variant:
	"""画面パラメータを取得"""
	return screen_parameters.get(key, default_value)

func has_parameter(key: String) -> bool:
	"""画面パラメータが存在するかチェック"""
	return key in screen_parameters

func get_screen_name() -> String:
	"""画面名を取得"""
	return screen_name

func is_active() -> bool:
	"""画面がアクティブかチェック"""
	return is_screen_active

# === デバッグ用 ===

func debug_info() -> Dictionary:
	"""デバッグ情報を取得"""
	return {
		"screen_name": screen_name,
		"is_active": is_screen_active,
		"parameters": screen_parameters,
		"return_value": return_value,
		"has_adv_system": adv_system != null
	}
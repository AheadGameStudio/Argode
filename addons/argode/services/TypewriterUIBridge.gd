extends RefCounted
class_name TypewriterUIBridge

## TypewriterUIBridge v1.2.0 Phase 2
## タイプライターとUI間の連携を管理

## === プロパティ ===

var target_canvas: Control = null
var target_window: Control = null
var character_name: String = ""

## === 基本API ===

static func create_bridge(canvas: Control, window: Control = null) -> TypewriterUIBridge:
	"""UIブリッジを作成"""
	var bridge = TypewriterUIBridge.new()
	bridge.target_canvas = canvas
	bridge.target_window = window
	
	ArgodeSystem.log_workflow("🌉 [Phase 2] UI Bridge created for canvas: %s" % canvas)
	return bridge

func set_character_name(name: String):
	"""キャラクター名を設定"""
	character_name = name
	
	# ウィンドウにキャラクター名表示
	if target_window and target_window.has_method("show_character_name"):
		target_window.show_character_name(name)

func update_text_display(text: String):
	"""テキスト表示を更新"""
	if not target_canvas:
		return
	
	# Canvasのcurrent_textを更新
	if target_canvas.has_property("current_text"):
		target_canvas.current_text = text
	
	# 再描画をトリガー
	if target_canvas.has_method("queue_redraw"):
		target_canvas.queue_redraw()

func clear_display():
	"""表示をクリア"""
	update_text_display("")

## === 内部ヘルパー ===

func is_valid() -> bool:
	"""ブリッジが有効かどうか"""
	return target_canvas != null

func get_canvas_size() -> Vector2:
	"""キャンバスサイズを取得"""
	if target_canvas and target_canvas.has_method("get_canvas_size"):
		return target_canvas.get_canvas_size()
	elif target_canvas and target_canvas.has_method("get_rect"):
		return target_canvas.get_rect().size
	
	return Vector2.ZERO

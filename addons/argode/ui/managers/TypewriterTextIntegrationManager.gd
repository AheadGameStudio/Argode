extends RefCounted
class_name TypewriterTextIntegrationManager

## TypewriterText統合管理システム
##
## TypewriterTextとRubyTextRendererの初期化・統合・管理を専門に行います。
## ArgodeScreenから分離され、タイプライター機能の責任を集約しています。

# TypewriterText参照
var typewriter: TypewriterText = null
var ruby_text_renderer: RubyTextRenderer = null

# 接続先のメッセージラベル
var message_label: RichTextLabel = null

# 親ノード（シグナル接続用）
var parent_node: Node = null

## 初期化
func initialize(target_message_label: RichTextLabel, target_parent: Node) -> bool:
	"""TypewriterText統合システムを初期化"""
	if not target_message_label:
		print("⚠️ TypewriterTextIntegrationManager: No message_label provided")
		return false
	
	if not target_parent:
		print("⚠️ TypewriterTextIntegrationManager: No parent node provided")
		return false
	
	message_label = target_message_label
	parent_node = target_parent
	
	_initialize_typewriter()
	_initialize_ruby_text_renderer()
	_connect_signals()
	
	print("📱 TypewriterTextIntegrationManager: Initialization complete")
	return true

## TypewriterText初期化
func _initialize_typewriter():
	"""TypewriterTextを初期化"""
	typewriter = TypewriterText.new()
	parent_node.add_child(typewriter)
	typewriter.setup_target(message_label)
	typewriter.skip_key_enabled = false
	
	print("📱 TypewriterTextIntegrationManager: TypewriterText initialized")

## RubyTextRenderer初期化
func _initialize_ruby_text_renderer():
	"""RubyTextRendererを初期化（複数Label方式のルビシステム）"""
	ruby_text_renderer = RubyTextRenderer.new()
	ruby_text_renderer.name = "RubyTextRenderer"
	
	# message_labelの親に追加してオーバーレイ
	if message_label.get_parent():
		message_label.get_parent().add_child(ruby_text_renderer)
		# message_labelと同じ位置・サイズに設定
		_sync_ruby_renderer_with_message_label()
	else:
		parent_node.add_child(ruby_text_renderer)
	
	print("📱 TypewriterTextIntegrationManager: RubyTextRenderer initialized")

## RubyTextRendererとメッセージラベルの同期
func _sync_ruby_renderer_with_message_label():
	"""RubyTextRendererをメッセージラベルと同じ位置・サイズに設定"""
	if not ruby_text_renderer or not message_label:
		return
	
	ruby_text_renderer.position = message_label.position
	ruby_text_renderer.size = message_label.size
	ruby_text_renderer.anchor_left = message_label.anchor_left
	ruby_text_renderer.anchor_top = message_label.anchor_top
	ruby_text_renderer.anchor_right = message_label.anchor_right
	ruby_text_renderer.anchor_bottom = message_label.anchor_bottom

## シグナル接続
func _connect_signals():
	"""TypewriterTextのシグナルを親ノードに接続"""
	if not typewriter or not parent_node:
		return
	
	# 親ノードが対応メソッドを持っている場合のみ接続
	if parent_node.has_method("_on_typewriter_started"):
		typewriter.typewriter_started.connect(parent_node._on_typewriter_started)
	
	if parent_node.has_method("_on_typewriter_finished"):
		typewriter.typewriter_finished.connect(parent_node._on_typewriter_finished)
	
	if parent_node.has_method("_on_typewriter_skipped"):
		typewriter.typewriter_skipped.connect(parent_node._on_typewriter_skipped)
	
	if parent_node.has_method("_on_character_typed"):
		typewriter.character_typed.connect(parent_node._on_character_typed)
	
	# RichTextLabelのリンククリック処理
	if message_label is RichTextLabel:
		message_label.bbcode_enabled = true
		if parent_node.has_method("_on_glossary_link_clicked"):
			message_label.meta_clicked.connect(parent_node._on_glossary_link_clicked)
		print("🔗 TypewriterTextIntegrationManager: Glossary link support enabled")
	
	print("📱 TypewriterTextIntegrationManager: Signals connected")

## TypewriterText操作API
func start_typing(text: String):
	"""テキストのタイプライター表示を開始"""
	if typewriter:
		typewriter.start_typing(text)

func skip_typing():
	"""タイプライター表示をスキップ"""
	if typewriter:
		typewriter.skip_typing()

func pause_typing():
	"""タイプライター表示を一時停止"""
	if typewriter:
		typewriter.pause_typing()

func resume_typing():
	"""タイプライター表示を再開"""
	if typewriter:
		typewriter.resume_typing()

func is_typing() -> bool:
	"""タイプライター表示中かどうか"""
	if typewriter:
		return typewriter.is_typing
	return false

func set_speed(characters_per_second: float):
	"""タイプライター速度を設定"""
	if typewriter:
		typewriter.characters_per_second = characters_per_second

## RubyTextRenderer操作API
func clear_ruby_display():
	"""ルビ表示をクリア"""
	if ruby_text_renderer:
		ruby_text_renderer.clear_display()

func setup_ruby_display(ruby_data: Array):
	"""ルビ表示を設定"""
	if ruby_text_renderer:
		ruby_text_renderer.setup_ruby_display(ruby_data)

## クリーンアップ
func cleanup():
	"""リソースのクリーンアップ"""
	if typewriter:
		typewriter.queue_free()
		typewriter = null
	
	if ruby_text_renderer:
		ruby_text_renderer.queue_free()
		ruby_text_renderer = null
	
	message_label = null
	parent_node = null
	
	print("📱 TypewriterTextIntegrationManager: Cleanup complete")

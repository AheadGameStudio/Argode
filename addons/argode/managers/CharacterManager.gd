extends Node

# v2: CharacterLayerベースの実装に移行
var character_sprites: Dictionary = {}

# v2: ArgodeSystem統合により、直接参照に変更
var transition_player  # TransitionPlayer
var variable_manager  # VariableManager - ArgodeSystemから設定される
var character_defs  # CharacterDefinitionManager - v2新機能
var layer_manager  # LayerManager - v2新機能

func _ready():
	print("👤 CharacterManager initialized (v2)")
	# v2: 参照はArgodeSystemの_setup_manager_references()で設定される
	
	# v2: LayerManagerのCharacterLayerを使用するため、独自コンテナ作成不要

func _ensure_character_container():
	"""v2: 廃止 - LayerManagerのCharacterLayerを使用します"""
	print("⚠️ _ensure_character_container is deprecated. Use LayerManager.character_layer instead.")

func show_character(char_id: String, expression: String, position: String, transition: String):
	print("🧍‍♀️ Showing: ", char_id, " (", expression, ") at ", position, " with ", transition)
	
	# v2: LayerManagerに処理を委譲
	if not layer_manager:
		push_error("❌ LayerManager not available")
		return
	
	await layer_manager.show_character(char_id, expression, position, transition)

func hide_character(char_id: String, transition: String):
	print("👻 Hiding: ", char_id, " with ", transition)
	
	# v2: LayerManagerに処理を委譲
	if not layer_manager:
		push_error("❌ LayerManager not available")
		return
	
	await layer_manager.hide_character(char_id, transition)

# v2: 古い背景処理は完全廃止 - LayerManagerを使用してください

func show_scene(scene_name: String, transition: String = ""):
	print("🎬 [DEPRECATED] CharacterManager.show_scene is deprecated. Use LayerManager.change_background instead")
	# LayerManagerに委譲
	if layer_manager:
		var bg_path = "res://assets/images/backgrounds/" + scene_name + ".png"
		await layer_manager.change_background(bg_path, transition)
		return
	
	print("❌ No LayerManager available for background handling")

func _load_character_image(sprite: Sprite2D, char_id: String, expression: String):
	"""v2: 廃止 - LayerManagerが画像処理を担当します"""
	print("⚠️ _load_character_image is deprecated. LayerManager handles character images.")

func _create_placeholder_texture(char_id: String) -> ImageTexture:
	"""v2: 廃止 - LayerManagerが画像処理を担当します"""
	print("⚠️ _create_placeholder_texture is deprecated. LayerManager handles character images.")
	return ImageTexture.new()
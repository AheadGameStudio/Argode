extends Node

@export var character_container: Node2D
var character_sprites: Dictionary = {}
var background_sprite: Sprite2D
# v2: AdvSystem統合により、直接参照に変更
var transition_player  # TransitionPlayer
var variable_manager  # VariableManager - AdvSystemから設定される
var character_defs  # CharacterDefinitionManager - v2新機能
var layer_manager  # LayerManager - v2新機能

func _ready():
	print("👤 CharacterManager initialized (v2)")
	# v2: 参照はAdvSystemの_setup_manager_references()で設定される
	
	# Create character container if not assigned
	if not character_container:
		character_container = Node2D.new()
		character_container.name = "CharacterContainer"
		# Add to main scene - we'll find the main scene node
		var main_scene = get_tree().current_scene
		if main_scene:
			main_scene.add_child(character_container)
			# Position container at screen center
			var viewport = get_viewport()
			if viewport:
				var screen_size = viewport.get_visible_rect().size
				character_container.position = Vector2(screen_size.x / 2, screen_size.y * 0.7)
				print("📦 Created character container at: ", character_container.position)
			print("📦 Created character container in main scene")
	
	# Create background sprite
	_setup_background()

func show_character(char_id: String, expression: String, position: String, transition: String):
	print("🧍‍♀️ Showing: ", char_id, " (", expression, ") at ", position, " with ", transition)
	
	# v2: CharacterDefinitionManagerから定義を取得を試行
	var char_data = null
	var display_name = char_id  # デフォルト表示名
	
	if character_defs and character_defs.has_character(char_id):
		# v2新式定義を使用
		var definition = character_defs.get_character_definition(char_id)
		display_name = definition.get("display_name", char_id)
		char_data = definition
		print("✅ v2 Character data loaded for: ", char_id, " -> ", display_name)
	elif variable_manager and variable_manager.character_defs.has(char_id):
		# v1互換のdefine文を使用
		char_data = variable_manager.get_character_data(char_id)
		if char_data and char_data.has("display_name"):
			display_name = char_data.display_name
		print("✅ v1 Character data loaded for: ", char_id, " -> ", display_name)
	else:
		# どちらの定義もない場合
		print("❌ Character data not found for: ", char_id)
		var v1_chars = variable_manager.character_defs.keys() if variable_manager else []
		var v2_chars = character_defs.get_all_character_ids() if character_defs else []
		print("❌ Available v1 characters: ", v1_chars)
		print("❌ Available v2 characters: ", v2_chars)
		return
	
	# Create or get existing sprite
	var sprite_key = char_id
	var sprite: Sprite2D
	
	if character_sprites.has(sprite_key):
		sprite = character_sprites[sprite_key]
	else:
		sprite = Sprite2D.new()
		sprite.name = char_id + "_sprite"
		character_container.add_child(sprite)
		character_sprites[sprite_key] = sprite
		print("🆕 Created new sprite for: ", char_id)
	
	# Set position (relative to character container)
	match position:
		"left":
			sprite.position = Vector2(-300, 0)
		"center":
			sprite.position = Vector2(0, 0)
		"right":
			sprite.position = Vector2(300, 0)
		_:
			sprite.position = Vector2(0, 0)
	
	print("📍 Sprite positioned at: ", sprite.position, " (container at: ", character_container.position, ")")
	
	# Load image (placeholder for now)
	_load_character_image(sprite, char_id, expression)
	
	# Show with transition
	if transition != "none" and transition_player:
		sprite.visible = true
		await transition_player.play(sprite, transition)
	else:
		sprite.visible = true
	
	print("✅ Character displayed: ", char_id, " with transition: ", transition)

func hide_character(char_id: String, transition: String):
	print("👻 Hiding: ", char_id, " with ", transition)
	
	var sprite_key = char_id
	if character_sprites.has(sprite_key):
		var sprite = character_sprites[sprite_key]
		
		# Hide with transition
		if transition != "none" and transition_player:
			# Play transition in reverse (hide)
			await transition_player.play(sprite, transition, 0.5, true)
			sprite.visible = false
		else:
			sprite.visible = false
		
		print("✅ Character hidden: ", char_id, " with transition: ", transition)
	else:
		print("⚠️ Character not found to hide: ", char_id)

func _setup_background():
	var main_scene = get_tree().current_scene
	if main_scene:
		background_sprite = Sprite2D.new()
		background_sprite.name = "BackgroundSprite"
		# Add background behind everything else
		main_scene.add_child(background_sprite)
		main_scene.move_child(background_sprite, 0)  # Move to back
		
		# Position background at screen center
		var viewport = get_viewport()
		if viewport:
			var screen_size = viewport.get_visible_rect().size
			background_sprite.position = Vector2(screen_size.x / 2, screen_size.y / 2)
			print("🖼️ Created background sprite at: ", background_sprite.position)

func show_scene(scene_name: String, transition: String):
	print("🏞️ Showing scene: ", scene_name, " with ", transition)
	
	if not background_sprite:
		_setup_background()
	
	# Try to load background image
	var image_path = "res://assets/images/backgrounds/" + scene_name + ".png"
	var texture = load(image_path)
	
	if texture:
		background_sprite.texture = texture
		print("🖼️ Loaded background: ", image_path)
	else:
		# Create a colored background as placeholder
		var placeholder = _create_background_placeholder(scene_name)
		background_sprite.texture = placeholder
		print("🎨 Using background placeholder for: ", scene_name)
	
	# Show with transition
	if transition != "none" and transition_player:
		print("🎬 Executing transition: ", transition)
		background_sprite.visible = true
		await transition_player.play(background_sprite, transition)
		print("✅ Transition completed: ", transition)
	else:
		print("📄 No transition specified or TransitionPlayer missing")
		background_sprite.visible = true
	
	# Debug information
	print("🔍 Background sprite debug:")
	print("  - Visible: ", background_sprite.visible)
	print("  - Position: ", background_sprite.position)
	print("  - Texture: ", background_sprite.texture != null)
	print("  - Parent: ", background_sprite.get_parent().name if background_sprite.get_parent() else "No parent")
	
	print("✅ Scene displayed: ", scene_name, " with transition: ", transition)

func _create_background_placeholder(scene_name: String) -> ImageTexture:
	var viewport = get_viewport()
	var screen_size = Vector2(1152, 648)  # Default size
	if viewport:
		screen_size = viewport.get_visible_rect().size
	
	var image = Image.create(int(screen_size.x), int(screen_size.y), false, Image.FORMAT_RGB8)
	
	# Different colors for different scenes
	var color: Color
	match scene_name:
		"classroom":
			color = Color.LIGHT_BLUE
		"corridor":
			color = Color.LIGHT_GRAY
		"park":
			color = Color.LIGHT_GREEN
		"home":
			color = Color.WHEAT
		_:
			color = Color.DARK_GRAY
	
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _load_character_image(sprite: Sprite2D, char_id: String, expression: String):
	# Try to load character image
	# Format: res://assets/images/characters/{char_id}_{expression}.png
	var image_path = "res://assets/images/characters/" + char_id + "_" + expression + ".png"
	
	var texture = load(image_path)
	if texture:
		sprite.texture = texture
		print("🖼️ Loaded image: ", image_path)
	else:
		# Create a colored rectangle as placeholder
		var placeholder = _create_placeholder_texture(char_id)
		sprite.texture = placeholder
		print("🎨 Using placeholder for: ", char_id)

func _create_placeholder_texture(char_id: String) -> ImageTexture:
	var image = Image.create(200, 300, false, Image.FORMAT_RGB8)
	
	# Different colors for different characters
	var color: Color
	match char_id:
		"y":
			color = Color.MAGENTA
		"s":
			color = Color.CYAN
		_:
			color = Color.WHITE
	
	# Fill with character color
	image.fill(color)
	
	# Add a border to make it more visible
	var border_color = Color.BLACK
	for x in range(image.get_width()):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, image.get_height() - 1, border_color)
	
	for y in range(image.get_height()):
		image.set_pixel(0, y, border_color)
		image.set_pixel(image.get_width() - 1, y, border_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
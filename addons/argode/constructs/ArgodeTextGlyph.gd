extends RefCounted
class_name ArgodeTextGlyph

## 1文字分のテキスト表示エンティティ
## 位置・色・スケール・エフェクトを個別管理

# 文字データ
var character: String = ""
var character_index: int = -1  # テキスト内での位置

# 座標情報
var base_position: Vector2 = Vector2.ZERO  # 基準位置
var current_position: Vector2 = Vector2.ZERO  # エフェクト適用後の位置
var offset_position: Vector2 = Vector2.ZERO  # 追加オフセット

# スケール情報
var base_scale: float = 1.0  # 基準スケール
var current_scale: float = 1.0  # エフェクト適用後のスケール

# 色情報
var base_color: Color = Color.WHITE  # 基準色
var current_color: Color = Color.WHITE  # エフェクト適用後の色

# 描画情報
var font: Font = null
var font_size: int = 20

# エフェクト管理
var effects: Array = []  # Array[ArgodeTextEffect] - 型注釈は実行時に解決

# 表示状態
var is_visible: bool = false
var appear_time: float = 0.0  # 表示開始時刻
var fade_alpha: float = 1.0  # フェード透明度

# デバッグ情報
var debug_id: String = ""

func _init(char: String = "", index: int = -1):
	character = char
	character_index = index
	current_position = base_position
	current_scale = base_scale
	current_color = base_color
	debug_id = "Glyph_%d_%s" % [index, char]

## エフェクトを追加
func add_effect(effect) -> void:  # ArgodeTextEffect
	if effect:
		effects.append(effect)
		ArgodeSystem.log("🎭 Added effect '%s' to glyph '%s'" % [effect.get_effect_name(), character])

## エフェクトを削除
func remove_effect(effect) -> void:  # ArgodeTextEffect
	if effect in effects:
		effects.erase(effect)
		ArgodeSystem.log("🎭 Removed effect '%s' from glyph '%s'" % [effect.get_effect_name(), character])

## 特定名のエフェクトを取得
func get_effect_by_name(effect_name: String):  # -> ArgodeTextEffect
	for effect in effects:
		if effect.get_effect_name() == effect_name:
			return effect
	return null

## すべてのエフェクトを更新
func update_effects(elapsed: float) -> void:
	var completed_effects = []
	
	for effect in effects:
		if effect.is_active:
			effect.update(self, elapsed)
			
			# 完了したエフェクトを記録
			if effect.is_effect_completed():
				completed_effects.append(effect)
	
	# 完了したエフェクトを削除
	for effect in completed_effects:
		remove_effect(effect)

## 表示状態を設定
func set_visible(visible: bool, current_time: float = 0.0) -> void:
	is_visible = visible
	if visible:
		appear_time = current_time
		# すべてのエフェクトを開始
		for effect in effects:
			effect.start_effect()

## 基準位置を設定
func set_base_position(pos: Vector2) -> void:
	base_position = pos
	current_position = pos + offset_position

## 現在位置を直接設定（エフェクト用）
func set_current_position(pos: Vector2) -> void:
	current_position = pos

## 基準色を設定
func set_base_color(color: Color) -> void:
	base_color = color
	current_color = color

## 基準スケールを設定
func set_base_scale(scale: float) -> void:
	base_scale = scale
	current_scale = scale

## フォント情報を設定
func set_font_info(new_font: Font, size: int) -> void:
	font = new_font
	font_size = size

## 最終描画色を取得（フェードα適用）
func get_final_color() -> Color:
	var final_color = current_color
	final_color.a *= fade_alpha
	return final_color

## デバッグ情報を出力
func debug_print() -> void:
	ArgodeSystem.log("🔤 TextGlyph Debug: %s (%s)" % [character, debug_id])
	ArgodeSystem.log("  - Index: %d" % character_index)
	ArgodeSystem.log("  - Visible: %s" % str(is_visible))
	ArgodeSystem.log("  - Position: %s -> %s" % [str(base_position), str(current_position)])
	ArgodeSystem.log("  - Scale: %.2f -> %.2f" % [base_scale, current_scale])
	ArgodeSystem.log("  - Color: %s -> %s" % [str(base_color), str(current_color)])
	ArgodeSystem.log("  - Effects: %d" % effects.size())
	for i in range(effects.size()):
		ArgodeSystem.log("    [%d] %s" % [i, effects[i].get_effect_name()])

## 描画用の完全な状態情報を取得
func get_render_info() -> Dictionary:
	return {
		"character": character,
		"position": current_position,
		"scale": current_scale,
		"color": get_final_color(),
		"font": font,
		"font_size": font_size,
		"visible": is_visible,
		"base_character_size": get_base_character_size()
	}

## 基本文字サイズを取得（中央基点計算用）
func get_base_character_size() -> Vector2:
	if font and font.has_method("get_string_size"):
		return font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	else:
		# フォールバック: 概算サイズ
		return Vector2(font_size * 0.6, font_size)

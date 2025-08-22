extends ArgodeCommandBase
class_name SetMessageAnimationCommand

func _ready():
	command_class_name = "SetMessageAnimationCommand"
	command_execute_name = "message_animation"
	is_define_command = true

## コマンド実行
func execute(args: Dictionary) -> void:
	# RGDパーサーから来る引数形式を解析
	# args = {"0": "clear"} または {"0": "add", "1": "slide", "2": "0.5", "3": "offset_y", "4": "-15", ...}
	
	var arg_array = []
	
	# "0", "1", "2"... の形式で順番に取得
	var i = 0
	while args.has(str(i)):
		arg_array.append(args[str(i)])
		i += 1
	
	# 最低限のチェック
	if arg_array.size() < 1:
		ArgodeSystem.log("⚠️ message_animation コマンドには最低1つの引数が必要です: action")
		return
	
	var action = arg_array[0].to_lower()  # clear, add, preset
	
	if action == "clear":
		_clear_animations()
		return
	elif action == "preset":
		if arg_array.size() < 2:
			ArgodeSystem.log("⚠️ message_animation preset には preset名が必要です")
			return
		_apply_preset(arg_array[1])
		return
	elif action == "add":
		if arg_array.size() < 2:
			ArgodeSystem.log("⚠️ message_animation add には効果タイプが必要です")
			return
		var animation_type = arg_array[1].to_lower()
		_add_animation_effect(animation_type, arg_array.slice(2))
		return
	else:
		ArgodeSystem.log("⚠️ 不明なアクション: %s (add, clear, preset のいずれかを指定してください)" % action)

## アニメーション効果を追加
func _add_animation_effect(effect_type: String, params: Array):
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		ArgodeSystem.log("⚠️ StatementManager が取得できません")
		return
	
	match effect_type:
		"fade":
			var duration = 0.3
			if params.size() > 0:
				duration = float(params[0])
			
			var effect_data = {
				"type": "fade",
				"duration": duration
			}
			statement_manager.add_message_animation_effect(effect_data)
			ArgodeSystem.log("✨ フェードイン効果を追加: 時間=%.2f秒" % duration)
		
		"slide":
			var duration = 0.4
			var offset_y = 0.0
			var offset_x = 0.0
			
			# パラメータ解析
			var i = 0
			while i < params.size():
				if i + 1 < params.size():
					var param_name = str(params[i]).to_lower()
					match param_name:
						"offset_y":
							offset_y = float(params[i + 1])
							i += 2
						"offset_x": 
							offset_x = float(params[i + 1])
							i += 2
						_:
							# 最初のパラメータはduration
							if i == 0:
								duration = float(params[i])
							i += 1
				else:
					i += 1
			
			# スライド効果を作成
			if offset_x != 0.0 or offset_y != 0.0:
				var effect_data = {
					"type": "slide",
					"duration": duration,
					"offset_x": offset_x,
					"offset_y": offset_y
				}
				statement_manager.add_message_animation_effect(effect_data)
				ArgodeSystem.log("📐 スライド効果を追加: 時間=%.2f秒, X軸オフセット=%.1f, Y軸オフセット=%.1f" % [duration, offset_x, offset_y])
			else:
				ArgodeSystem.log("⚠️ スライド効果にはoffset_xまたはoffset_yの指定が必要です")
		
		"scale":
			var duration = 0.25
			if params.size() > 0:
				duration = float(params[0])
			
			var effect_data = {
				"type": "scale",
				"duration": duration
			}
			statement_manager.add_message_animation_effect(effect_data)
			ArgodeSystem.log("🔍 スケール効果を追加: 時間=%.2f秒" % duration)
		
		_:
			ArgodeSystem.log("⚠️ 不明なアニメーション種類: %s (fade, slide, scale のいずれかを指定してください)" % effect_type)

## 全アニメーションをクリア
func _clear_animations():
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		ArgodeSystem.log("⚠️ StatementManager が取得できません")
		return
	
	statement_manager.clear_message_animations()
	ArgodeSystem.log("🔄 全メッセージアニメーション効果をクリアしました")

## プリセット適用
func _apply_preset(preset_name: String):
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		ArgodeSystem.log("⚠️ StatementManager が取得できません")
		return
	
	statement_manager.set_message_animation_preset(preset_name)
	ArgodeSystem.log("🎭 メッセージアニメーションプリセットを適用: %s" % preset_name)

## ヘルプ表示
func get_help_text() -> String:
	return """
message_animation コマンド - テキストアニメーション設定

使用法:
  message_animation add fade [duration]
    フェードイン効果を追加
    例: message_animation add fade 0.5

  message_animation add slide [duration] [offset_y value] [offset_x value]
    スライド効果を追加（X軸・Y軸両対応）
    例: message_animation add slide 0.5 offset_y -8 offset_x -2
    例: message_animation add slide 0.3 offset_y -10

  message_animation add scale [duration]
    スケール効果を追加
    例: message_animation add scale 0.25

  message_animation clear
    全アニメーション効果をクリア

  message_animation preset [preset_name]
    プリセット適用 (default, fast, dramatic, simple, none)
    例: message_animation preset dramatic

注意:
  - is_define_command として定義前に設定する必要があります
  - 複数のadd コマンドで複数の効果を組み合わせ可能
  - slideでは offset_x, offset_y のどちらか一方でも指定可能
"""

extends ArgodeDialogBase
class_name ArgodeDefaultChoiceDialog

@export_category("Theme Variation")
@export var choice_button_theme_variation: String = "ChoiceButton"

func _ready() -> void:
	super._ready()
	
	# 基底クラスのchoice_selectedシグナルをそのまま使用
	# （choice_selectedシグナルは基底クラスで定義済み）

## MenuCommandから呼び出される選択肢設定メソッド
func setup_choices(choices: Array[Dictionary]):
	"""MenuCommandから選択肢データを設定"""
	ArgodeSystem.log("🎯 DefaultChoiceDialog: Setting up %d choices" % choices.size())
	ArgodeSystem.log("🎯 DefaultChoiceDialog: Choice data structure: %s" % str(choices))
	
	# 基底クラスの汎用メソッドを使用
	setup_choice_buttons(choices, choice_button_theme_variation)
	
	ArgodeSystem.log("✅ DefaultChoiceDialog: Choice setup completed")

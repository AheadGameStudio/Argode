@tool
extends Resource
class_name RgdResource

## RGDスクリプトファイル用のカスタムリソースクラス

@export var content: String = ""

func _init():
    pass

func get_content() -> String:
    return content

func set_content(new_content: String):
    content = new_content
    emit_changed()
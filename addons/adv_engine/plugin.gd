@tool
extends EditorPlugin

# v2設計: 単一オートロード
const AUTOLOAD_ADV_SYSTEM = "AdvSystem"

# v1互換性: 既存のオートロードを削除する場合のリスト
const V1_AUTOLOADS = [
	"AdvScriptPlayer",
	"VariableManager", 
	"CharacterManager",
	"UIManager",
	"TransitionPlayer",
	"LabelRegistry"
]

func _enter_tree():
	print("🔧 Installing Ren' Gd ADV Engine v2...")
	
	# v1のオートロードがあれば削除
	_remove_v1_autoloads()
	
	# v2の単一オートロードを追加
	add_autoload_singleton(AUTOLOAD_ADV_SYSTEM, "res://addons/adv_engine/AdvSystem.gd")
	print("✅ AdvSystem autoload installed")

func _exit_tree():
	print("🗑️ Uninstalling Ren' Gd ADV Engine v2...")
	
	# v2オートロードを削除
	remove_autoload_singleton(AUTOLOAD_ADV_SYSTEM)
	
	# 念のため、v1オートロードも削除
	_remove_v1_autoloads()

func _remove_v1_autoloads():
	"""v1の古いオートロードを削除（マイグレーション対応）"""
	for autoload_name in V1_AUTOLOADS:
		remove_autoload_singleton(autoload_name)
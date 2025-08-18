# ArgodeLoadingScreen.gd
extends Control

class_name ArgodeLoadingScreen

## Argodeシステム初期化時のローディング画面
## 各レジストリの進捗状況を表示し、ユーザーに初期化の進行状況を知らせる

@onready var main_label: Label = $VBoxContainer/MainLabel
@onready var progress_label: Label = $VBoxContainer/ProgressLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var detail_label: Label = $VBoxContainer/DetailLabel

var current_registry: String = ""
var total_registries: int = 3
var completed_registries: int = 0

func _ready():
	# シーンツリーへの追加完了まで待機
	await _wait_for_tree_ready()
	
	# 初期状態の設定（安全なノード参照）
	_safe_set_label_text(main_label, "Argodeシステム初期化中...")
	_safe_set_label_text(progress_label, "準備中...")
	_safe_set_progress_bar_value(progress_bar, 0)
	_safe_set_label_text(detail_label, "")

## シーンツリーが準備完了まで安全に待機
func _wait_for_tree_ready():
	# シーンツリーが有効になるまで待機
	var max_attempts = 60  # 最大1秒待機（60フレーム）
	var attempts = 0
	
	while not get_tree() or not is_inside_tree():
		attempts += 1
		if attempts >= max_attempts:
			break  # タイムアウト
		await Engine.get_main_loop().process_frame
	
	# 追加のフレーム待機でノード参照を安定化
	if get_tree():
		await get_tree().process_frame
		await get_tree().process_frame

## ノードのnullチェックを行いながらテキストを設定
func _safe_set_label_text(label: Label, text: String):
	if label and is_instance_valid(label):
		label.text = text

## ノードのnullチェックを行いながらプログレスバーの値を設定
func _safe_set_progress_bar_value(bar: ProgressBar, value: float):
	if bar and is_instance_valid(bar):
		bar.value = value

## 安全な待機処理
func _safe_wait(duration: float):
	if get_tree() and is_inside_tree():
		await get_tree().create_timer(duration).timeout
	else:
		# フォールバック：フレーム単位での待機
		var frames = int(duration * 60)  # 60FPSを想定
		for i in frames:
			if Engine.get_main_loop():
				await Engine.get_main_loop().process_frame
			else:
				break  # メインループが無効な場合は中断

## レジストリ開始時の処理
func on_registry_started(registry_name: String):
	current_registry = registry_name
	_safe_set_label_text(main_label, "Argodeシステム初期化中...")
	_safe_set_label_text(detail_label, "%s を処理中..." % _get_registry_display_name(registry_name))

## レジストリ進捗更新時の処理
func on_registry_progress_updated(task_name: String, progress: float, total: int, current: int):
	var overall_progress = (float(completed_registries) + progress) / float(total_registries)
	_safe_set_progress_bar_value(progress_bar, overall_progress * 100)
	
	_safe_set_label_text(progress_label, "%s (%d/%d) - 全体: %.1f%%" % [
		task_name, 
		current, 
		total, 
		overall_progress * 100
	])

## レジストリ完了時の処理
func on_registry_completed(registry_name: String):
	completed_registries += 1
	var overall_progress = float(completed_registries) / float(total_registries)
	_safe_set_progress_bar_value(progress_bar, overall_progress * 100)
	
	if completed_registries >= total_registries:
		_safe_set_label_text(main_label, "初期化完了!")
		_safe_set_label_text(progress_label, "100%")
		_safe_set_label_text(detail_label, "ゲームを開始します...")
		
		# 少し待ってからローディング画面を閉じる
		await _safe_wait(1.0)
		_close_loading_screen()
	else:
		_safe_set_label_text(detail_label, "%s 完了" % _get_registry_display_name(registry_name))

## レジストリ名の表示用変換
func _get_registry_display_name(registry_name: String) -> String:
	match registry_name:
		"ArgodeCommandRegistry":
			return "コマンド登録"
		"ArgodeDefinitionRegistry":
			return "定義処理"
		"ArgodeLabelRegistry":
			return "ラベル検索"
		_:
			return registry_name

## ローディング画面を閉じる
func _close_loading_screen():
	# シーンツリーが有効かチェック
	if not get_tree() or not is_inside_tree():
		# 即座に削除
		queue_free.call_deferred()
		return
	
	# フェードアウトアニメーション
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		await tween.finished
	
	# 安全に削除
	queue_free.call_deferred()

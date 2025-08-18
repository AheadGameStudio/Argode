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

## 安全にシーンツリーを取得する
func _get_safe_tree():
	if not is_instance_valid(self):
		return null
	
	# is_inside_tree()をチェックしてからget_tree()を呼び出す
	if not is_inside_tree():
		return null
		
	return get_tree()

## ノードとツリーの基本的な安全性をチェックする
func _is_safe() -> bool:
	return is_instance_valid(self) and is_inside_tree()

## 安全でない場合は即座に終了する
func _check_safety_or_return() -> bool:
	if not _is_safe():
		return false
	return true

## 安全な待機処理
func _safe_wait(duration: float):
	if not _check_safety_or_return():
		return
	
	var tree = _get_safe_tree()
	if tree:
		await tree.create_timer(duration).timeout
	else:
		# フォールバック：Engine.get_main_loop()を使用
		var main_loop = Engine.get_main_loop()
		if main_loop:
			var frames = int(duration * 60)  # 60FPSを想定
			for i in frames:
				if not _is_safe():
					break
				await main_loop.process_frame

## レジストリ開始時の処理
func on_registry_started(registry_name: String):
	if not _check_safety_or_return():
		return
	
	current_registry = registry_name
	_safe_set_label_text(main_label, "Argodeシステム初期化中...")
	_safe_set_label_text(detail_label, "%s を処理中..." % _get_registry_display_name(registry_name))

## レジストリ進捗更新時の処理
func on_registry_progress_updated(task_name: String, progress: float, total: int, current: int):
	if not _check_safety_or_return():
		return
	
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
	if not _check_safety_or_return():
		return
	
	completed_registries += 1
	var overall_progress = float(completed_registries) / float(total_registries)
	_safe_set_progress_bar_value(progress_bar, overall_progress * 100)
	
	if completed_registries >= total_registries:
		_safe_set_label_text(main_label, "初期化完了!")
		_safe_set_label_text(progress_label, "100%")
		_safe_set_label_text(detail_label, "ゲームを開始します...")
		
		# 最終チェックしてからクローズ処理を実行
		if _is_safe():
			await _safe_wait(1.0)
			_close_loading_screen()
		else:
			# 安全でない場合は即座に終了
			if is_instance_valid(self):
				queue_free.call_deferred()
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
	if not _check_safety_or_return():
		if is_instance_valid(self):
			queue_free.call_deferred()
		return
	
	# フェードアウトアニメーション（短時間に変更）
	var tween = create_tween()
	if tween and _is_safe():
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		if is_instance_valid(tween):
			await tween.finished
	
	# 安全に削除（再度有効性をチェック）
	if is_instance_valid(self):
		queue_free.call_deferred()

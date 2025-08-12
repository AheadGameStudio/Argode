# AudioManager.gd
# オーディオ再生を管理するマネージャー
@tool
class_name AudioManager
extends Node

# === オーディオバス設定 ===
const BGM_BUS_NAME = "BGM"
const SE_BUS_NAME = "SE"
const MASTER_BUS_NAME = "Master"

# === オーディオプレイヤー ===
@export var bgm_player: AudioStreamPlayer
@export var se_container: Node  # SE用のAudioStreamPlayerを動的に作成する親ノード

# === 音量管理 ===
var master_volume: float = 1.0
var bgm_volume: float = 1.0
var se_volume: float = 1.0

# === BGM状態管理 ===
var current_bgm_path: String = ""
var current_bgm_resource: AudioStream = null
var is_bgm_looping: bool = true

# === SE管理 ===
var active_se_players: Dictionary = {}  # SE名 -> AudioStreamPlayer
var se_player_pool: Array[AudioStreamPlayer] = []  # 再利用可能なプレイヤー

# === Argodeシステム参照 ===
var audio_defs: AudioDefinitionManager  # オーディオ定義管理

# === シグナル ===
signal bgm_started(bgm_name: String)
signal bgm_stopped()
signal bgm_volume_changed(volume: float)
signal se_played(se_name: String)
signal se_volume_changed(volume: float)

func _ready():
	print("🎵 AudioManager initializing...")
	_setup_audio_buses()
	_setup_bgm_player()
	_setup_se_container()
	_setup_argode_references()
	print("✅ AudioManager ready")

func _setup_audio_buses():
	"""オーディオバスの設定"""
	print("🔊 Setting up audio buses...")
	
	# バスが存在するかチェック（エディタでの設定を推奨）
	var bgm_bus_index = AudioServer.get_bus_index(BGM_BUS_NAME)
	var se_bus_index = AudioServer.get_bus_index(SE_BUS_NAME)
	
	if bgm_bus_index == -1:
		print("⚠️ BGM bus not found. Please create '", BGM_BUS_NAME, "' bus in Audio settings")
	else:
		print("✅ BGM bus found at index:", bgm_bus_index)
	
	if se_bus_index == -1:
		print("⚠️ SE bus not found. Please create '", SE_BUS_NAME, "' bus in Audio settings")
	else:
		print("✅ SE bus found at index:", se_bus_index)

func _setup_bgm_player():
	"""BGMプレイヤーの設定"""
	if not bgm_player:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		add_child(bgm_player)
		print("🎵 Created BGM player")
	
	# BGMバスに接続
	var bgm_bus_index = AudioServer.get_bus_index(BGM_BUS_NAME)
	if bgm_bus_index != -1:
		bgm_player.bus = BGM_BUS_NAME
		print("🔗 BGM player connected to BGM bus")
	else:
		print("⚠️ Using Master bus for BGM (BGM bus not found)")
	
	# シグナル接続
	if not bgm_player.finished.is_connected(_on_bgm_finished):
		bgm_player.finished.connect(_on_bgm_finished)

func _setup_se_container():
	"""SEコンテナの設定"""
	if not se_container:
		se_container = Node.new()
		se_container.name = "SEContainer"
		add_child(se_container)
		print("🔊 Created SE container")

func _setup_argode_references():
	"""Argodeシステムの参照を設定"""
	var argode_system = get_node_or_null("/root/ArgodeSystem")
	if argode_system and "AudioDefs" in argode_system:
		audio_defs = argode_system.AudioDefs
		print("🔗 AudioDefs reference set")
	else:
		print("⚠️ AudioDefs not available")

# === BGM制御 ===
func play_bgm(audio_name: String, loop: bool = true, volume: float = 1.0, fade_in_duration: float = 0.0) -> bool:
	"""BGMを再生"""
	print("🎵 Playing BGM:", audio_name, "loop:", loop, "volume:", volume)
	
	var audio_path = _resolve_audio_path(audio_name, "bgm")
	if audio_path.is_empty():
		push_error("❌ BGM not found: " + audio_name)
		return false
	
	var audio_stream = _load_audio_stream(audio_path)
	if not audio_stream:
		push_error("❌ Failed to load BGM: " + audio_path)
		return false
	
	# 現在のBGMを停止
	if bgm_player.playing:
		bgm_player.stop()
	
	# 新しいBGMを設定
	bgm_player.stream = audio_stream
	current_bgm_path = audio_path
	current_bgm_resource = audio_stream
	is_bgm_looping = loop
	
	# ループ設定（AudioStreamOggVorbisの場合）
	if audio_stream is AudioStreamOggVorbis:
		audio_stream.loop = loop
	
	# 音量設定
	var final_volume = volume * bgm_volume * master_volume
	bgm_player.volume_db = _linear_to_db(final_volume)
	
	# フェードイン処理
	if fade_in_duration > 0.0:
		bgm_player.volume_db = -80.0  # 無音から開始
		bgm_player.play()
		_fade_bgm_volume(final_volume, fade_in_duration)
	else:
		bgm_player.play()
	
	print("✅ BGM started:", audio_name)
	bgm_started.emit(audio_name)
	return true

func stop_bgm(fade_out_duration: float = 0.0):
	"""BGMを停止"""
	print("🎵 Stopping BGM, fade_out:", fade_out_duration)
	
	if not bgm_player.playing:
		print("ℹ️ No BGM playing")
		return
	
	if fade_out_duration > 0.0:
		await _fade_bgm_volume(0.0, fade_out_duration)
		bgm_player.stop()
	else:
		bgm_player.stop()
	
	current_bgm_path = ""
	current_bgm_resource = null
	print("✅ BGM stopped")
	bgm_stopped.emit()

func set_bgm_volume(volume: float):
	"""BGM音量を設定 (0.0-1.0)"""
	bgm_volume = clamp(volume, 0.0, 1.0)
	
	if bgm_player.playing:
		var final_volume = bgm_volume * master_volume
		bgm_player.volume_db = _linear_to_db(final_volume)
	
	print("🔊 BGM volume set to:", bgm_volume)
	bgm_volume_changed.emit(bgm_volume)

# === SE制御 ===
func play_se(audio_name: String, volume: float = 1.0, pitch: float = 1.0) -> bool:
	"""SEを再生"""
	print("🔊 Playing SE:", audio_name, "volume:", volume, "pitch:", pitch)
	
	var audio_path = _resolve_audio_path(audio_name, "se")
	if audio_path.is_empty():
		push_error("❌ SE not found: " + audio_name)
		return false
	
	var audio_stream = _load_audio_stream(audio_path)
	if not audio_stream:
		push_error("❌ Failed to load SE: " + audio_path)
		return false
	
	# SEプレイヤーを取得または作成
	var se_player = _get_available_se_player()
	se_player.stream = audio_stream
	
	# 音量とピッチ設定
	var final_volume = volume * se_volume * master_volume
	se_player.volume_db = _linear_to_db(final_volume)
	se_player.pitch_scale = pitch
	
	# 再生
	se_player.play()
	
	# アクティブSEとして追跡
	active_se_players[audio_name] = se_player
	
	print("✅ SE started:", audio_name)
	se_played.emit(audio_name)
	return true

func stop_se(audio_name: String = ""):
	"""SEを停止"""
	if audio_name.is_empty():
		# 全SE停止
		print("🔊 Stopping all SE")
		for se_name in active_se_players.keys():
			var se_player = active_se_players[se_name]
			if se_player and se_player.playing:
				se_player.stop()
		active_se_players.clear()
	else:
		# 特定SE停止
		print("🔊 Stopping SE:", audio_name)
		if audio_name in active_se_players:
			var se_player = active_se_players[audio_name]
			if se_player and se_player.playing:
				se_player.stop()
			active_se_players.erase(audio_name)

func set_se_volume(volume: float):
	"""SE音量を設定 (0.0-1.0)"""
	se_volume = clamp(volume, 0.0, 1.0)
	
	# アクティブなSEプレイヤーの音量を更新
	for se_player in active_se_players.values():
		if se_player and se_player.playing:
			var final_volume = se_volume * master_volume
			se_player.volume_db = _linear_to_db(final_volume)
	
	print("🔊 SE volume set to:", se_volume)
	se_volume_changed.emit(se_volume)

# === マスター音量制御 ===
func set_master_volume(volume: float):
	"""マスター音量を設定 (0.0-1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	
	# 全てのオーディオの音量を更新
	if bgm_player.playing:
		set_bgm_volume(bgm_volume)  # 現在のBGM音量で更新
	
	for se_player in active_se_players.values():
		if se_player and se_player.playing:
			var final_volume = se_volume * master_volume
			se_player.volume_db = _linear_to_db(final_volume)
	
	print("🔊 Master volume set to:", master_volume)

# === 内部処理 ===
func _resolve_audio_path(audio_name: String, audio_type: String) -> String:
	"""オーディオファイルのパスを解決"""
	# AudioDefsから取得を試行
	if audio_defs and audio_defs.has_method("get_audio_path"):
		var resolved_path = audio_defs.get_audio_path(audio_name)
		if not resolved_path.is_empty():
			print("🔍 Audio resolved via AudioDefs:", audio_name, "->", resolved_path)
			return resolved_path
	
	# デフォルトパス構築
	var default_path = "res://assets/audios/" + audio_type + "/" + audio_name + ".ogg"
	if ResourceLoader.exists(default_path):
		print("🔍 Audio found at default path:", default_path)
		return default_path
	
	# .wav拡張子も試行
	var wav_path = "res://assets/audios/" + audio_type + "/" + audio_name + ".wav"
	if ResourceLoader.exists(wav_path):
		print("🔍 Audio found at WAV path:", wav_path)
		return wav_path
	
	print("❌ Audio not found:", audio_name, "in", audio_type)
	return ""

func _load_audio_stream(audio_path: String) -> AudioStream:
	"""オーディオストリームを読み込む"""
	var resource = ResourceLoader.load(audio_path)
	if resource is AudioStream:
		return resource as AudioStream
	else:
		push_error("❌ Invalid audio resource: " + audio_path)
		return null

func _get_available_se_player() -> AudioStreamPlayer:
	"""利用可能なSEプレイヤーを取得"""
	# プールから再利用可能なプレイヤーを探す
	for player in se_player_pool:
		if player and not player.playing:
			print("♻️ Reusing SE player from pool")
			return player
	
	# 新しいプレイヤーを作成
	var se_player = AudioStreamPlayer.new()
	se_player.name = "SEPlayer_" + str(se_player_pool.size())
	se_container.add_child(se_player)
	
	# SEバスに接続
	var se_bus_index = AudioServer.get_bus_index(SE_BUS_NAME)
	if se_bus_index != -1:
		se_player.bus = SE_BUS_NAME
	
	# プールに追加
	se_player_pool.append(se_player)
	print("🆕 Created new SE player:", se_player.name)
	
	return se_player

func _linear_to_db(linear_volume: float) -> float:
	"""リニア音量をdB値に変換"""
	if linear_volume <= 0.0:
		return -80.0  # 無音
	return 20.0 * log(linear_volume) / log(10.0)

func _fade_bgm_volume(target_volume: float, duration: float):
	"""BGM音量のフェード処理"""
	var current_volume = pow(10.0, bgm_player.volume_db / 20.0)  # dBからリニアに変換
	var tween = create_tween()
	
	tween.tween_method(
		func(volume: float):
			bgm_player.volume_db = _linear_to_db(volume),
		current_volume,
		target_volume,
		duration
	)
	
	await tween.finished

# === イベント処理 ===
func _on_bgm_finished():
	"""BGM再生終了時の処理"""
	print("🎵 BGM finished")
	if is_bgm_looping and current_bgm_resource:
		print("🔁 Restarting BGM loop")
		bgm_player.play()
	else:
		current_bgm_path = ""
		current_bgm_resource = null

# === デバッグ・情報取得 ===
func get_audio_info() -> Dictionary:
	"""現在のオーディオ状態を取得"""
	return {
		"bgm_playing": bgm_player.playing,
		"current_bgm": current_bgm_path,
		"bgm_volume": bgm_volume,
		"se_volume": se_volume,
		"master_volume": master_volume,
		"active_se_count": active_se_players.size(),
		"se_player_pool_size": se_player_pool.size()
	}

func list_active_audio():
	"""アクティブなオーディオをログ出力"""
	print("🎵 === Audio Status ===")
	print("BGM: ", current_bgm_path if bgm_player.playing else "None")
	print("BGM Volume: ", bgm_volume)
	print("SE Volume: ", se_volume)
	print("Master Volume: ", master_volume)
	print("Active SE: ", active_se_players.keys())
	print("SE Pool Size: ", se_player_pool.size())

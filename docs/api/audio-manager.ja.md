# AudioManager - 音声制御

AudioManagerは、Argodeシステムにおけるオーディオ（BGM・SE）の再生、停止、音量制御を担当するマネージャーです。

## 概要

AudioManagerを使用することで、GDScriptから直接音声ファイルの制御を行うことができます。シナリオスクリプトの`audio`コマンドとは別に、プログラム的な音声制御が可能です。

## AudioManagerへのアクセス

```gdscript
# ArgodeSystemを通じてAudioManagerにアクセス
var argode_system = get_node("/root/ArgodeSystem")
var audio_manager = argode_system.AudioManager
```

## BGM制御

### play_bgm()
BGMを再生します。

```gdscript
audio_manager.play_bgm(audio_name, loop, volume, fade_in_duration)
```

**パラメータ:**
- `audio_name` (String): 音声ファイル名（assets.rgdで定義された名前）
- `loop` (bool): ループ再生するか（デフォルト: true）
- `volume` (float): 音量（0.0-1.0、デフォルト: 1.0）
- `fade_in_duration` (float): フェードイン時間（秒、デフォルト: 0.0）

**例:**
```gdscript
# 基本的な再生
audio_manager.play_bgm("yoru_no_zattou")

# ループなしで音量80%で再生
audio_manager.play_bgm("bgm_peaceful", false, 0.8)

# 3秒のフェードインで再生
audio_manager.play_bgm("bgm_dramatic", true, 1.0, 3.0)
```

### stop_bgm()
BGMを停止します。

```gdscript
audio_manager.stop_bgm(fade_out_duration)
```

**パラメータ:**
- `fade_out_duration` (float): フェードアウト時間（秒、デフォルト: 0.0）

**例:**
```gdscript
# 即座に停止
audio_manager.stop_bgm()

# 2秒のフェードアウトで停止
audio_manager.stop_bgm(2.0)
```

### set_bgm_volume()
BGMの音量を調整します。

```gdscript
audio_manager.set_bgm_volume(volume)
```

**パラメータ:**
- `volume` (float): 音量（0.0-1.0）

## SE制御

### play_se()
効果音（SE）を再生します。

```gdscript
audio_manager.play_se(audio_name, volume, pitch)
```

**パラメータ:**
- `audio_name` (String): SE名（assets.rgdで定義された名前）
- `volume` (float): 音量（0.0-1.0、デフォルト: 1.0）
- `pitch` (float): ピッチ（0.5-2.0、デフォルト: 1.0）

**例:**
```gdscript
# 基本的なSE再生
audio_manager.play_se("keyword_ping")

# 音量80%で再生
audio_manager.play_se("door_open", 0.8)

# 音量70%、ピッチ1.2倍で再生
audio_manager.play_se("footsteps", 0.7, 1.2)
```

### stop_se()
SEを停止します。

```gdscript
audio_manager.stop_se(audio_name)
```

**パラメータ:**
- `audio_name` (String): 停止するSE名（空文字列の場合、全SEを停止）

**例:**
```gdscript
# 特定のSEを停止
audio_manager.stop_se("keyword_ping")

# 全てのSEを停止
audio_manager.stop_se()
```

### set_se_volume()
SEの音量を調整します。

```gdscript
audio_manager.set_se_volume(volume)
```

## マスター音量制御

### set_master_volume()
全体音量を調整します。

```gdscript
audio_manager.set_master_volume(volume)
```

**パラメータ:**
- `volume` (float): マスター音量（0.0-1.0）

## シグナル

AudioManagerは以下のシグナルを提供します：

- `bgm_started(bgm_name: String)` - BGM開始時
- `bgm_stopped()` - BGM停止時
- `bgm_volume_changed(volume: float)` - BGM音量変更時
- `se_played(se_name: String)` - SE再生時
- `se_volume_changed(volume: float)` - SE音量変更時

**シグナルの接続例:**
```gdscript
func _ready():
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    audio_manager.bgm_started.connect(_on_bgm_started)
    audio_manager.bgm_stopped.connect(_on_bgm_stopped)
    audio_manager.se_played.connect(_on_se_played)

func _on_bgm_started(bgm_name: String):
    print("BGM開始:", bgm_name)

func _on_bgm_stopped():
    print("BGM停止")

func _on_se_played(se_name: String):
    print("SE再生:", se_name)
```

## 実用例

### メニューUI での音声制御

```gdscript
extends Control

var audio_manager

func _ready():
    var argode_system = get_node("/root/ArgodeSystem")
    audio_manager = argode_system.AudioManager

func _on_button_pressed():
    """ボタンが押された時のSE再生"""
    audio_manager.play_se("keyword_ping", 0.5)

func _on_menu_opened():
    """メニューを開く時のBGM調整"""
    # 現在のBGMを一時的に音量を下げる
    audio_manager.set_bgm_volume(0.3)
    audio_manager.play_se("menu_open", 0.8)

func _on_menu_closed():
    """メニューを閉じる時のBGM復帰"""
    # BGM音量を元に戻す
    audio_manager.set_bgm_volume(1.0)
    audio_manager.play_se("menu_close", 0.8)
```

### ゲームシーン での BGM制御

```gdscript
extends Node

func _ready():
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # ゲーム開始時にBGMを再生
    audio_manager.play_bgm("yoru_no_zattou", true, 0.8)

func _on_battle_started():
    """戦闘開始時のBGM切り替え"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # 戦闘BGMに切り替え（1.5秒のフェードイン）
    audio_manager.play_bgm("bgm_tense", true, 1.0, 1.5)

func _on_battle_ended():
    """戦闘終了時のBGM復帰"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # 通常BGMに戻す（2秒のフェードイン）
    audio_manager.play_bgm("bgm_peaceful", true, 0.8, 2.0)
```

### 環境音の制御

```gdscript
extends Node

func _on_rain_started():
    """雨が降り始めた時"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # 雨音SEをループ再生（AudioStreamから直接制御する場合）
    audio_manager.play_se("rain_loop", 0.6)
    
    # BGM音量を下げて雰囲気を演出
    audio_manager.set_bgm_volume(0.4)

func _on_rain_stopped():
    """雨が止んだ時"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # 雨音を停止
    audio_manager.stop_se("rain_loop")
    
    # BGM音量を元に戻す
    audio_manager.set_bgm_volume(1.0)
```

## 注意事項

1. **音声ファイルの定義**: 使用する音声ファイルは事前に`assets.rgd`で定義されている必要があります。
2. **音量の範囲**: 音量は0.0-1.0の範囲で指定してください。
3. **SE の重複**: 同名のSEを連続再生すると、前の再生が停止されて新しい再生が開始されます。
4. **メモリ管理**: SEは自動的にプール管理され、使用後は再利用されます。

## 関連項目

- [Script Commands - audio](../script/audio-commands.md) - シナリオスクリプトでの音声コマンド
- [Audio Definitions](../getting-started/audio-setup.md) - 音声ファイルの定義方法
- [Managers Overview](./managers.md) - 他のマネージャーについて

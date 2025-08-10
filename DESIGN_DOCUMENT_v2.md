# **Ren'Py風ADVアドオン 設計書 v2**

Saitosさんと共に設計した、Godot Engineで動作するRen'Py風アドベンチャーゲームアドオンの最終設計書です。このドキュメントは、これまでの議論の集大成であり、**拡張性、柔軟性、そして開発者の利便性**を設計の中心に据えています。

## **1\. 📜 設計思想 (Design Philosophy)**

* 単一オートロードによるクリーンな設計:  
  このアドオンがグローバルスコープに追加するシングルトンは、AdvSystemただ一つです。他の全てのManagerはAdvSystemの子ノードとして管理され、Godotプロジェクトへの導入が極めてクリーンになります。  
* スクリプト中心の定義:  
  キャラクター、画像、アニメーション、サウンド、シェーダーといった、ゲームを構成するほぼ全てのアセット定義は、Ren'Pyと同様に\*\*.rgdスクリプト内の専用ステートメント\*\* (character, image, audio, shader) によって行われます。これにより、ライターはテキストエディタのみで多くの作業を完結できます。  
* 究極の拡張性 (Extensibility Framework):  
  このシステムの核心は、カスタムコマンドとカスタムインラインタグの完全なサポートにあります。エンジンが知らないコマンドやタグは、汎用的なシグナルとして発行されます。プログラマーは、このシグナルを待ち受けるだけで、ゲーム固有の機能を無限に追加できます。  
* 静的解析による予測プリロード:  
  AssetManagerは、ゲーム起動時に全スクリプトの分岐構造を解析して\*\*「制御フローグラフ」\*\*を構築します。実行時は、このグラフを基にプレイヤーの進行先を予測し、必要になるアセットだけを自動的にプリロード・アンロードすることで、パフォーマンスとメモリ効率を最大化します。  
* 柔軟なレイヤーアーキテクチャ:  
  システムは特定のシーン構造を強制しません。利用者は初期化時に、「背景」や「キャラクター」といった役割（ロール）に、自身のシーン内のどのCanvasLayerを割り当てるかをDictionaryで指定します。これにより、あらゆるプロジェクト構造に対応できます。  
* 高機能UIシステム (AdvScreen):  
  call\_screenで呼び出されるUIシーンは、高機能な基底クラス\*\*AdvScreen\*\*を継承します。このクラスは、UIから直接シナリオを操作したり、スクリーンを入れ子で呼び出したり（スクリーンスタック）するための、豊富なAPIを提供します。

## **2\. 📝 シナリオスクリプト仕様 (.rgd)**

### **定義ステートメント**

通常、スクリプトファイルの先頭で、ゲーム全体で使用するアセットやキャラクターを定義します。

\# キャラクター定義  
\# character \<ID\> \= Character("\<表示名\>", \<キーワード引数...\>)  
character y \= Character("優子", name\_color="\#c8ffc8", show\_callback="yuko\_mouth\_start", hide\_callback="yuko\_mouth\_stop", character\_callback="yuko\_lip\_sync", type\_speed\_cps=25.0)

\# 画像定義 (静止画)  
\# image \<タグ...\> \= "\<パス\>"  
image yuko happy \= "res://images/yuko\_happy.png"  
image bg school \= "res://bg/school.jpg"

\# 画像定義 (アニメーション)  
\# image \<タグ...\>:  
\#     "\<パス\>"  
\#     \<表示時間\>  
\#     ...  
\#     loop (オプション)  
image yuko idle:  
    "res://images/yuko\_idle\_1.png"  
    0.5  
    "res://images/yuko\_idle\_2.png"  
    0.5  
    loop

\# オーディオ定義 (エイリアス)  
\# audio \<エイリアス\> \= "\<パス\>"  
audio town\_bgm \= "res://bgm/town.ogg"  
audio door\_open \= "res://se/door\_open.wav"

\# シェーダー定義 (エイリアス)  
\# shader \<エイリアス\> \= "\<パス\>"  
shader sepia\_effect \= "res://shaders/sepia.gdshader"

### **基本コマンド**

エンジンに組み込まれた、最小限のコマンドセットです。

\# フロー制御  
label start  
jump start  
call subroutine  
return

\# 変数と条件分岐  
set score \= 100  
if score \>= 100 and has\_key:  
    \# ...  
elif score \>= 50:  
    \# ...  
else:  
    \# ...  
endif

\# 表示制御  
show yuko happy  
scene bg school

\# セリフ表示  
y "こんにちは、\[player\_name\]さん。{w=0.5}少しお待ちください。{p}"

\# 選択肢  
menu:  
    "選択肢1":  
        jump path\_a  
    "選択肢2":  
        pass \# 何もせず次に進む

### **拡張機能 (カスタムコマンドとタグ)**

上記以外のコマンドやタグは、すべて拡張機能として扱われます。

\# カスタムコマンドの例  
window "thought"  
camera\_shake 5 1.0  
set\_layer\_effect "character" "sepia\_effect" "{'strength': 0.8}"  
call\_screen "res://ui/MapSelect.tscn"

\# カスタムインラインタグの例  
y "地面が{shake}揺れている！"

### **構文の分離**

* **変数展開:** 角括弧 \[variable\_name\]  
* **インラインタグ:** 波括弧 {tag} または {tag=value}

## **3\. 🏛️ アーキテクチャと主要コンポーネント**

### **AdvSystem (唯一のオートロード)**

全てのアドオン機能を統括する唯一のシングルトン。他の全てのManagerを子ノードとして保持し、外部からの統一されたアクセスポイントを提供します。

\# adv\_system.gd  
extends Node

\# 各Managerへのパブリックな参照  
var Player: AdvScriptPlayer  
var AssetManager: AssetManager  
var SaveLoadManager: SaveLoadManager  
var LabelRegistry: LabelRegistry  
var ImageDefs: ImageDefinitionManager  
var CharDefs: CharacterDefinitionManager  
var AudioDefs: AudioDefinitionManager  
var ShaderDefs: ShaderDefinitionManager  
var UIManager: UIManager

\# レイヤーマッピング  
var layers: Dictionary \= {}

\# ゲームのメインシーンから呼び出される初期化関数  
func initialize\_game(layer\_map: Dictionary):  
    \# 1\. レイヤーをマッピング  
    self.layers \= layer\_map  
      
    \# 2\. 各定義をビルド  
    CharDefs.build\_definitions()  
    ImageDefs.build\_definitions()  
    AudioDefs.build\_definitions()  
    ShaderDefs.build\_definitions()  
      
    \# 3\. フローグラフをビルド  
    var errors \= LabelRegistry.build\_registry()  
    if not errors.is\_empty(): return false  
      
    AssetManager.build\_graph\_and\_associate\_assets()  
      
    return true

\# レイヤーを取得するための安全なインターフェース  
func get\_layer(role\_name: String) \-\> CanvasLayer:  
    return layers.get(role\_name, null)

### **AdvScreen (UI基底クラス)**

call\_screenで呼び出されるUIシーンが継承すべき、高機能な基底クラス。

\# AdvScreen.gd  
class\_name AdvScreen  
extends Control

signal screen\_closed(return\_value)

\# UIを閉じる  
func close\_screen(return\_value \= null) \-\> void:  
    \# ...

\# 別のスクリーンをスタックに積む  
async func call\_screen(scene\_path: String, args\_json: String \= "{}") \-\> Variant:  
    \# ...

\# シナリオのラベルにジャンプする  
func jump\_to\_label(label\_name: String) \-\> void:  
    \# ...

\# (その他、変数のget/setなど多数のヘルパー関数)

### **主要なManagerの責務**

* **AdvScriptPlayer:** スクリプトを1行ずつ実行し、コマンドを解釈して各Managerやカスタムコマンドシグナルに処理を振り分ける。  
* **LabelRegistry:** 全スクリプトからlabel定義を抽出し、グローバルなジャンプ先マップを構築する。  
* **\*DefinitionManager (Image/Char/Audio/Shader):** 各image等の定義ステートメントを解析し、その内容を保持する。  
* **AssetManager:** LabelRegistryと\*DefinitionManagerの情報から制御フローグラフを構築し、予測プリロードと動的アンロードを実行する。ロード状態をシグナルで通知する。  
* **UIManager:** メッセージウィンドウの表示、AdvScreenのライフサイクル管理、スクリーンスタックの管理を行う。  
* **CharacterManager:** showコマンドに応じて、ImageDefinitionManagerとAssetManagerと連携し、キャラクターの表示・アニメーションを行う。  
* **SaveLoadManager:** セーブ可能なオブジェクトを動的に登録できる、汎用的なセーブ・ロードフレームワークを提供する。

## **4\. 🚀 導入と利用フロー**

1. **オートロード設定:** プロジェクト設定でadv\_system.gdをAdvSystemという名前で登録する。  
2. **メインシーン構築:** ゲームのメインシーンに、必要なCanvasLayer（背景用、キャラクター用など）を自由に配置する。  
3. **初期化:** メインシーンの\_ready()で、レイヤーのマッピングDictionaryを作成し、AdvSystem.initialize\_game(layer\_map)を呼び出す。  
4. **ゲーム開始:** AdvSystem.Player.play\_from\_label("start")でシナリオを開始する。  
5. **カスタム機能の実装:** AdvSystem.Player.custom\_command\_requestedなどのシグナルをconnectし、ゲーム固有のロジックを実装する。
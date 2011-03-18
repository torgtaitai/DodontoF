
src_actionScriptディレクトリのソースコード概要

DodontoF.mxml
どどんとふの一番基点となるファイル。全ての処理がここから始まる。
setup()関数が最初に実行される初期化処理です。（applicationComplete参照）

DodontoF_Main.as
どどんとふのメインの処理を行うためのファイル。
グローバルなデータは大抵にここに保持されます。


〜Window.mxml、〜Window.as 系
各種画面を定義するファイル。
以下、具体例

・メインウィンドウ
常に画面に常駐するメインウィンドウについて

InitiativeWindow.mxml
イニシアティブウィンドウ

ChatWindow.mxml
チャットウィンドウ

DiceBox.mxml
ヴィジュアルダイスウィンドウ

ChatPalette.mxml
ChatPalette2.mxml
チャットパレット。ChatPalette.mxmlは現在未使用のため無視してOK。


・Add〜Windows.mxml ：追加系

AddCharacterWindow.as
キャラクター追加画面

AddMagicRangeDD4thWindow.mxml
魔法範囲（D&D4版晩）追加画面

AddMagicRangeWindow.mxml
魔法範囲追加画面

AddMagicTimerWindow.mxml
魔法タイマー追加画面

AddMapMarkerWindow.mxml
マップマーカー追加画面

AddMapMaskWindow.mxml
マップマスク追加画面

AddMemoWindow.mxml
メモ追加画面

AddMessageCardWindow.mxml
メッセージカード追加画面

AddStandingGraphicsWindow.mxml
立ち絵追加画面

・Change〜Windows.mxml ：変更系

ChangeCharacterWindow.as
キャラクター変更画面

ChangeFloorTileWindow.mxml
フロアタイル変更画面

ChangeMagicRangeDD4thWindow.as
魔法範囲（D&D4版）変更画面

ChangeMagicRangeWindow.mxml
魔法範囲変更画面

ChangeMagicTimerWindow.as
魔法タイマー変更画面

ChangeMapMarkerWindow.as
マップマーカー変更画面

ChangeMapMaskWindow.as
マップマスク変更画面

ChangeMapWindow.mxml
マップ変更画面

ChangeMemoWindow.as
メモ変更画面

ChangePlayRoomWindow.as
プレイルーム情報変更画面

ChangeStandingGraphicsWindow.as
立ち絵変更画面


・その他のWindow系

AlarmWindow.mxml
アラーム設定画面

CharacterWindow.mxml
キャラクター追加・変更画面のベースクラス

CardPreviewWindow.mxml
カード拡大表示画面

ChatFontWindow.mxml
チャットフォントサイズ・色変更画面

CommonPopupWindow.mxml
チャットやイニシアティブなどの画面のベースクラス

CreateMapEasyWindow.mxml
マップ簡易変更画面

CreatePlayRoomWindow.mxml
プレイルーム作成画面

CreateSmallImagesWindow.mxml
画像のサムネイル作成用画面。
通常運用では使用しないため無視してOK.

CutInMovieChangeWindow.as
カットイン追加画面

CutInMovieCreateWindow.mxml
カットイン変更画面

CutInMovieManageWindow.mxml
カットイン管理画面（ここから追加・変更画面を立ち上げる）

CutInWindow.mxml
カットイン画面

EditChatPaletteWindow.mxml
チャットパレット編集画面

EditReplayConfigWindow.mxml
リプレイエディターの環境設定画面

EditReplayWindow.mxml
リプレイエディター画面

FileUploadWindow.mxml
ファイルアップローダー（チャットウィンドウから設定する簡易版のこと）

GraveyardWindow.mxml
墓地画面

ImageManageWindow.mxml
画像削除画面


ImageUploadWindow.mxml
画像アップローダー画面

ImageUrlUploadWindow.mxml
画像URLアップローダー画面
現在は未サポートのため無視してOK。

InitCardWindow.mxml
カード初期化画面

InitiativeWindowEditor.mxml
イニシアティブウィンドウの値変更画面

InitiativeWindow_old.mxml
イニシアティブウィンドウの旧版。未使用のため無視してOK。

InputPlayRoomPasswordWindow.mxml
ログイン画面でのプレイルームパスワード入力画面。

InputTextWindow.mxml
画像タグ入力などで使う文字列入力を促すための汎用画面。

LoadMapWindow.mxml
マップのみのロード用画面

LoadWindow.mxml
ロード画面

LogWindow.mxml
デバッグ用のログ表示画面。
実運用では特に使用しないので無視してOK。

LoginWindow.mxml
ログイン画面

ReplayUploadWindow.mxml
リプレイ投稿画面

ResizableWindow.mxml
各種画面のベースクラス

SaveChatLogWindow.mxml
チャットログ保存画面

SaveMapWindow.mxml
マップのみセーブ画面

SaveWindow.mxml
セーブ画面

SecretDiceWindow.mxml
隠しダイスロール結果表示画面

SelectCardWindow.mxml
山札カード抜き取り用画面

StandingGraphicsManageWindow.mxml
立ち絵管理画面（ここから立ち絵の追加・変更・削除画面を起動する）

StockCharacterWindow.mxml
キャラクター追加時の最終ドロップ待ち用の保持画面

StockDiceSymbolWindow.mxml
ダイスシンボルの設置用画面

TagManagerWindow.mxml
画像タグ編集画面

VersionWindow.mxml
バージョン表示画面

VoteWindow.mxml
多数決投票機能用画面

WebCameraCaptureWindow.mxml
ウェブカメラ画像キャプチャー画面



以下は画面系以外のファイル。

Card.as
カードクラス

CardMount.as
山札クラス

CardPickup.as
カードのピックアップ（拡大表示）用クラス

CardTrushMount.as
捨て札クラス

CardZone.as
カード置き場クラス

Character.as
キャラクタークラス。
マップに配置するため MovablePiece（移動可能コマ）クラスの子クラスとなっている。


ChatEffecter.as
投票機能の投票結果表示に使う○×表示などの立ち絵にかぶせるエフェクト用のクラス

ChatMessageLogBox.mxml
チャットウィンドウのメイン・雑談の各チャンネル（ソース上ではこのタブ番号をchannelと呼んでいます）管理用のクラス。

ChatMessageTrader.as
チャットで発言を送信・表示するための管理クラス。
チャットウィンドウの補助用。
立ち絵の表示や各種エフェクトの処理はほとんどここで実施。

ChatSendData.as
チャットで送信受信するデータの管理用データクラス（構造体に近い）

Config.as
環境設定用のクラス。
表示メニューの現状値の保持とセーブ等の管理は全てこのクラス。

CustomSkin.as
各種ウィンドウや画面の背景に画像を表示するためのクラス。
現状未使用。（隠し機能として仮実装状態）

CutInBase.as
画像・動画、各種カットインのベースクラス。

CutInMovie.as
動画用カットインクラス

Dice.as
ビジュアルダイス用クラス。
ダイスのアニメーション関連は全てこのクラスで管理。
１ダイスが１インスタンスなのではなく、
このクラスで複数ダイスが全て配列として管理されている。

DiceInfo.as
ダイスの画像や乱数装置などの管理クラス。

DiceSymbol.as
ダイスシンボル用クラス。
マップに配置するためキャラクター等と同様にMovablePieceの子クラスとなっている。

DisplayPlayRoomInfo.mxml
プレイルーム情報表示画面用クラス

DodontoF.swf
ActionScriptコンパイル結果のSWFファイル

DodontoFTest.as
DodontoF_MainTest.as
DummySharedDataSender.as
動作テスト用のクラス。
実際には使用してないため無視してOK。

DodontoF_Ready.mxml
バージョン確認用のSWF作成用のソース。（ど＠えむサイトにて使用）
どどんとふ本体では使用してないため無視してOK。

FloorTile.as
フロアタイル用クラス
マップに配置するためキャラクター等と同様にMovablePieceの子クラスとなっている。

GuiInputSender.as
画面を操作して、サーバにデータを転送する際に値の正当性をチェックしたりするための SharedDataSender のラッパークラス。

ImageSelecter.mxml
キャラクターやマップ画像選択画面の画像選択部分のみを処理するためのファイル。
MXMLは画面の一部でもこうやってファイルとして抽出してTAGとして使用できるので便利だよね。
使用例はキャラクター追加画面(AddCharacterWindow)等を参照。

ImageSprite.as
キャラクター等の画像を管理するためのクラス。
内部でキャッシュを持ったり、縦横比率調整したり、意外と処理内容は多い。

ImageTag.as
画像タグ管理用クラス。
実質、ImageSelecterでタグ名一覧を表示するための管理クラス。

ImageUploadSetInfo.mxml
画像アップローダー画面の画像アップロード部分の処理用ファイル。
実際の処理については（ImageUploadWindow.mxml)を参照。

ImageUrlChanger.as
画像のURLでローカルファイル（アップロードした画像）はURLを全部そのまま表示しないで
 (local)/imageData.jpg
のように表示するためのURL変換クラス。
ちなみにこんな変換をするのは下手に画像アップローダーとして使用されることを恐れたため。
最近は杞憂だったかなぁ…とも思う。

InitiativedMovablePiece.as
マップに配置するコマは MovablePiece だが、この中でもイニシアティブ表に載るコマは
このクラスを継承する必要がある。

InitiativedPiece.as
マップに配置しないけどイニシアティブ表に載る場合はこのクラスを継承する必要がある。
MagicTimer以外にはこのパターンは無かった気がしますが。

Log.as
ログ表示用クラス。
実際の運用では使用しないため無視してOK。

MagicRange.as
魔法範囲クラス

MagicRangeDD4th.as
D&D4版魔法範囲クラス

MagicTimer.as
魔法タイマークラス

Map.as
マップクラス。
コマ（Piece）を配置したりするため処理が何気に多いクラス。

MapForTiny.as
洒落で作った簡易表示版どどんとふのためのマップクラス。
参照：http://www.dodontof.com/ja/dodontofnews/2009/166-aprilfool2010.html
実運用では特に使用しないので無視してok。

MapMarker.as
マップマーカー用クラス

MapMask.as
マップマスク用クラス

Memo.as
メモ用クラス

MersenneTwister.as
乱数（メルセンヌ・ツイスター）生成用クラス

Messages.as
サーバからのエラー応答メッセージ作成用のクラス。
一応多言語対応しようとしている足掻き。

MovablePiece.as
マップ上で動かせる各種コマの親クラス。
このクラスを継承さえすれば大体問題なく新しいコマが作れます。
まぁ便利！

NovelticMode.as
ノベルゲーム風表示モード用クラス

PNGEncoder.as
Webカメラでの画像キャプチャー時用画像ファイル変換クラス。

PaintablePreviewLoader.as
簡易マップ作成画面の塗りつぶしが出来るマップ用のクラス。

PaintablePreviewLoaderSquare.as
簡易マップ作成画面の塗りつぶしが出来るマップの、1マスを表すクラス。

Piece.as
マップ上で管理するコマ（Piece）のための基本クラス。クラスっていうかインターフェース。

PreviewLoader.as
画像をImageSelecterなどで選択してプレビューするためのプレビュー用表示クラス

Replay.as
リプレイ再生時の制御用クラス

ReplayEditor.as
リプレイ編集画面用の管理クラス

Resizer.as
可変ウィンドウのための便利クラス。
これは他の人のサイトからほぼ丸々パクって来たのですが、とても便利です。

RoundTimer.as
イニシアティブ（ラウンドタイマー）の管理用クラス

RubberBand.as
仮実装機能用クラス。
実際の運用では使用しないため無視してok。

SharedDataReceiver.as
サーバからのデータ受信を管理するためのクラス。

SharedDataReceiverDummy.as
上記クラスのテスト用のダミークラス。
実際の運用では使用しないため無視してok。

SharedDataSender.as
サーバへのデータ送信を管理するためのクラス。

SharedDataSenderDummy.as
上記クラスのテスト用のダミークラス。
実際の運用では使用しないため無視してok。

SharedDataSenderForGaeJava.as
上記クラスのGoogleApplecationEngine（GAE）用のクラス。
実際の運用では使用しないため無視してok。

StandingGraphics.as
立ち絵管理クラス。

Utils.as
その他雑多な処理のまとめクラス。

Voter.as
投稿機能管理用のクラス。

AllTests.mxml
動作検証用のテストソース。
実動作には使用していないので無視してOK.

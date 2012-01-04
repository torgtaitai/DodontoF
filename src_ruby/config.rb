#--*-coding:utf-8-*--
#CGIの環境設定用ファイル

#デバッグログ出力設定 trueで出力。falseで非出力(ただしエラー処理は常に出力されます。)
$debug = false


#サーバで許容できると思うログイン人数を記載。大体でいいです。
$aboutMaxLoginCount = 50


#CGIがクライアントへ通知を返す最大待機時間（秒）
#本CGIではAjaxで言うComet方式で実装されています（擬似的に、ですが）。
#つまりクライアントからの要求に即座に通知を返さず
#ここで指定される秒数までセーブファイルの変更を定期的にチェックして待ちます。
$refreshTimeout = 10

#サーバの一時チャットログの保存時間上限（秒）
#上記の $refreshTimeout よりも大きい必要があり、
#さらに言えば再接続後でも表示できるように十分な余裕が必要。
$oldMessageTimeout = 180

#セーブファイルの定期チェック時間（秒）
$refreshInterval = 0.5

#プレイルームの最大数
$saveDataMaxCount = 1000;

#ログイン画面で一括取得できる最大プレイルーム数
$playRoomGetRangeMax = 100

#墓場に保存されるキャラクターの最大数
$graveyardLimit = 30

#チャットの過去ログ大量保管を許可するかの設定
$IS_SAVE_LONG_CHAT_LOG = true

#チャットログ大量保管時の保管ライン数
$chatMessageDataLogAllLineMax = 500

#アップロード可能なファイルサイズの上限(MB)
$UPLOAD_IMAGE_MAX_SIZE = 10.0

#保持する画像の上限数(上限を超えた場合古いものから削除)
$UPLOAD_IMAGE_MAX_COUNT = 2000

#アップロード可能なリプレイデータのファイルサイズ上限(MB)
$UPLOAD_REPALY_DATA_MAX_SIZE = 5.0

#アップロード可能なファイルのファイルサイズ上限(MB)
$UPLOAD_FILE_MAX_SIZE = 10.0

#プレイルームデータ(saveData)の相対パス。
$SAVE_DATA_DIR = '.'

#ロックファイル作成先のチューニング用。nilなら $SAVE_DATA_DIR と同一になります。
$SAVE_DATA_LOCK_FILE_DIR = nil

#各画像(キャラクター・マップ)の保存パス
$imageUploadDir = "./imageUploadSpace"

#シナリオ読み込み機能用のマーカー文字列(変更してはいけません)
$imageUploadDirMarker = '###ROOM_LOCAL_SPACE###'

#削除対象から外す画像ディレクトリ名一覧
$protectImagePaths = []

#リプレイデータの保存パス
$replayDataUploadDir = "./replayDataUploadSpace"

#セーブデータの一時保存パス
$saveDataTempDir = "./saveDataTempSpace"

#ファイルアップローダーのパス
$fileUploadDir = "fileUploadSpace"

#ログイン画面に表示される「お知らせ」メッセージの定義ファイル名
$loginMessageFile = "loginMessage.html"

#古いセーブファイルの自動削除を行うかを判定するための基準経過時間(秒)
$oldSaveFileDelteSeconds = 180

#ログアウトと判定される応答途絶時間(秒)
#下記秒数以上ブラウザから応答が無い場合はログアウトしたと判定。
$loginTimeOut = $refreshTimeout * 1.5 + 10

#プレイルームを削除してもよい経過時間(秒)
$deletablePassedSeconds = 10

#ダイスボットの有効(true)、無効(false)の設定
$isDiceBotOn = true

#デバッグ用：メンテナンスモード起動用のパスワード。nilならメンテナンスモード無し
$mentenanceModePassword = nil

#デバッグ用：0以上の値を設定するとそのプレイルームへ自動的にログインします
# $autoLoginRoom = -1
# → この機能は削除されました。今後はURLの末尾に DodontoF.swf?loginRoom=1
# のように追記することで自動ログインできるようになります。

#ログイン時の「＊＊さんがログインしました」メッセージの表示（false:非表示）
#ログアウト時のメッセージも抑止
$isWelcomeMessageOn = true

#ダイスボットスクリプトへのパス -> B&C2では不要になりました。
# $diceBoxCgiUrl = "customBot.pl"

#セーブデータの管理方法(nil/"mysql")
# $dbType = nil
$dbType = nil

#MySQLを使用する場合のDB設定。
$databaseHostName = "localhost"
$databaseName = "databaseName"
$databaseUserName = "user"
$databasePassword = "password"

#サーバ更新中の場合はtrueへ。ログイン中のメンバーは遮断され、新規ログインもできなくなります。
$isMentenanceNow = false

#サーバの応答データをGZIP圧縮する場合の閾値(単位：byte)。 
# 0 を指定するとGZIP圧縮しなくなります。
$gzipTargetSize = 0;

#削除不可能なプレイルーム番号を指定
#たとえばプレイルーム0と1を削除できなくするなら
# $unremovablePlayRoomNumbers = [0, 1]
#となります。デフォルトは指定なし。
$unremovablePlayRoomNumbers = [0]

#上記と同様に、ロード不可の指定
$unloadablePlayRoomNumbers = [0]

#上記と同様に、パスワード設定不可の指定
$noPasswordPlayRoomNumbers = [0]

#FirstCGIを使用する場合にはtrueに設定。通常のCGIであればfalseのまま。
$isFirstCgi = false

#mod_rubyを使用する場合にはtrueに設定。通常のCGIであればfalseのまま。
$isModRuby = false

#画面に使用するスキン画像 nil なら指定無し
$skinImage = nil;

#マップ左上に性能管理を表示するかの指定。(参照：https://github.com/mrdoob/Hi-ReS-Stats）
$isPaformanceMonitor = false;

#画面の更新速度。nilなら従来通りFlexの初期固定値(30)のまま。
$fps = 60

#マップの横幅・縦幅として設定できる最大マス数
$mapMaxWidth = 150
$mapMaxHeigth = 150

#アップロード可能なシナリオデータの上限(MB)
$scenarioDataMaxSize = 100.0 


#--*-coding:utf-8-*--
#CGIの環境設定用ファイル

#デバッグログ出力設定 trueで出力。falseで非出力(ただしエラー処理は常に出力されます。)
$debug = false


#サーバで許容できると思うログイン人数を指定。大体でいいです。
#この人数以上になると、人数が多いと警告が表示されるようになります。
$aboutMaxLoginCount = 30

#サーバにログインする事のできる限界人数。
#この人数以上になると、ログインが全くできなくなります。
#制限しないなら -1 と指定ください。
# 例) $limitLoginCount = 100
#     $limitLoginCount = -1
$limitLoginCount = 100

#サーバCGIとクライアントFlashのバージョン一致確認用
$versionOnly = "Ver.1.40.08"
$versionDate = "2013/01/23"
$version = "#{$versionOnly}(#{$versionDate})"


#サーバがデータの更新をサーバ内で定期チェックして待つ最大待機時間（秒）
#再接続が連発する場合には数値を「減らして」下さい。 $refreshTimeout = 1 とかに。
$refreshTimeout = 2

#サーバの一時チャットログの保存時間上限（秒）
#上記の $refreshTimeout よりも大きい必要があり、
#さらに言えば再接続後でも表示できるように十分な余裕が必要。
$oldMessageTimeout = 180

#擬似Comet時のセーブファイル定期チェック時間（秒）
$refreshInterval = 0.5

#プレイルームの最大数
$saveDataMaxCount = 10

#ログイン画面で一括取得できる最大プレイルーム数
$playRoomGetRangeMax = 10

#墓場に保存されるキャラクターの最大数
$graveyardLimit = 30

#チャットの過去ログ大量保管を許可するかの設定
$IS_SAVE_LONG_CHAT_LOG = true

#チャットログ大量保管時の保管ライン数
$chatMessageDataLogAllLineMax = 500

#アップロード可能な画像ファイルのファイルサイズ上限(MB)
$UPLOAD_IMAGE_MAX_SIZE = 10.0

#保持する画像の上限数(上限を超えた場合古いものから削除)
$UPLOAD_IMAGE_MAX_COUNT = 2000

#アップロード可能なリプレイデータのファイルサイズ上限(MB)
$UPLOAD_REPALY_DATA_MAX_SIZE = 5.0

#アップロード可能な一時アップロードのファイルサイズ上限(MB)
$UPLOAD_FILE_MAX_SIZE = 10.0

#プレイルームデータ(saveData)の相対パス。
$SAVE_DATA_DIR = "../.."

#ロックファイル作成先のチューニング用。nilなら $SAVE_DATA_DIR と同一になります。
$SAVE_DATA_LOCK_FILE_DIR = nil

#各画像(キャラクター・マップ)の保存パス
$imageUploadDir = "../imageUploadSpace"

#イメージディレクトリを示すマーカー文字列
$localUploadDirMarker = '###IMAGE_UPLOADL_SPACE###'


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

#ログイン画面に表示される「更新履歴」の定義ファイル名
$loginMessageBaseFile = "loginMessageBase.html"

#古いセーブファイルの自動削除を行うかを判定するための基準経過時間(秒)
$oldSaveFileDelteSeconds = 180

#ログアウトと判定される応答途絶時間(秒)
#下記秒数以上ブラウザから応答が無い場合はログアウトしたと判定。
$loginTimeOut = $refreshTimeout * 1.5 + 10

#プレイルームを削除してもよい経過時間(秒)
$deletablePassedSeconds = 10

#ダイスボットの有効(true)、無効(false)の設定
$isDiceBotOn = true

#デバッグ用：メンテナンス用の管理用パスワード。nilなら指定なしでメンテナンスモードに移行できません。
#　設定している場合 DodontoF.swf?mode=admin　にアクセスすることで、「管理用パスワード」を入力できるようになります。
#　パスワードを正しく入力すると、パスワードの掛かった部屋でもログインし、内部の状況を確認する事ができます。
#パスワードは以下の様に指定します。
# $mentenanceModePassword = "pasuwaado"
$mentenanceModePassword = nil

#デバッグ用：0以上の値を設定するとそのプレイルームへ自動的にログインします
# $autoLoginRoom = -1
# → この機能は削除されました。今後はURLの末尾に DodontoF.swf?loginRoom=1
# のように追記することで自動ログインできるようになります。

#ログイン時の「＊＊さんがログインしました」メッセージの表示（false:非表示）
#ログアウト時のメッセージも抑止
$isWelcomeMessageOn = true

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

#ログイン状況を記録するファイル
$loginCountFile = File.join($SAVE_DATA_DIR, 'saveData', 'loginCount.txt')

#読み上げ機能の有効／無効(true/false)。サーバに負荷が掛かるので有効化は慎重に
#あ、あとPHP環境必須なんでその辺は頑張って下さい。
$canTalk = true

#差分記録方式で保存する保存件数
$recordMaxCount = 5

#通信方式を擬似Commet方式にするなら true に。
#サーバ応答時に即座にクライアントに返答するには falseに。
$isCommet = true

#擬似Commetを使わない場合のクライアント側での再読み込み待ち時間
$refreshIntervalForNotCommet = 2.0

#チャットの送信失敗時の再送上限回数。これを超えると送信失敗扱いになります。
$retryCountLimit = 3

#ログインしていられる最大時間。
# 1 以上の数値を指定するとその秒数経過でサーバからたたき出されます
#（開発環境用なので、通常は変更不要）
$loginTimeLimitSecond = 0

#簡易アップロード機能でアップロードしたファイルの保持時間（秒）
$uploadFileTimeLimitSeconds = (1 * 60 * 60)

#古いプレイルームを一括削除する時の指定日数（日である点に注意）
# 0 以下の値の場合、処理されません。
$removeOldPlayRoomLimitDays = 5

#キャラクターの情報を前回との差分レベルで管理する方式（Record方式と勝手に命名）
#コマの連続移動で移動したコマが手戻りする事がなくなり使いやすい反面、
#サーバの負荷が高くなります。
#運用負荷を見て、有効(true)無効（false)を切り替えて下さい。
$isUseRecord = true

#プレイルーム作成時に認証パスワードを要求するかどうかの指定。
#指定すると認証パスワードが合致しない限り新しい部屋を作製できません。
#指定方法は下記の通り。空白文字列だとパスワード無し。
# $createPlayRoomPassword="abc"
$createPlayRoomPassword = ""


#レンタルサーバではなく自前サーバ等でRubyスクリプトのインストールが可能な場合、
# gem install msgpack
#を実行し、下記の設定を
# $isMessagePackInstalled = true
#に変更してください。処理が早くなります。
$isMessagePackInstalled = false

#デフォルトで表示されるユーザー名
#配列なので、 ["abc", "def"] のように複数記述すると、どれかがランダムで表示されます。
#基本変更する必要はありません。誰得機能。
$defaultUserNames = ["ななしさん"]

#部屋削除時にパスワード入力が必要かどうかを設定します
# true ： パスワード必要、 false : パスワード不要。
$isPasswordNeedFroDeletePlayRoom = true

#ダイスボット一覧に表示するダイスボットの名前順序
#標準添付ののダイスボットで表示したくない物ははここから削除して下さい。
#
#独自のダイスボットのファイルを src_bcdice/diceBot に置いた場合は、
#そのダイスボットの名前をここに書いておけば任意の順序で表示できます。
#書いてない場合は末尾に並びます。
#
$diceBotOrder = <<____END_MARKER____
ダイスボット(指定無し)
アースドーン
アリアンロッド
アルスマギカ
ウィッチクエスト
ウォーハンマー
エルリック！
エムブリオマシン
カードランカー
カオスフレア
ガンドッグ
ガンドッグ・ゼロ
クトゥルフ
クトゥルフテック
ゲヘナ・アナスタシス
サタスペ
シノビガミ
シャドウラン
シャドウラン第４版
真空学園
真・女神転生TRPG　覚醒編
絶対隷奴
ソードワールド
ソードワールド2.0
ダークブレイズ
ダブルクロス2nd,3rd
墜落世界
デモンパラサイト
トーグ
特命転攻生
トンネルズ＆トロールズ
ナイトウィザード
ナイトメアハンター=ディープ
ネクロニカ
バトルテック
パラサイトブラッド
バルナ・クロニカ
ハンターズムーン
ピーカーブー
ファンタズムアドベンチャー
ブラッド・クルセイド
ペンドラゴン
マギカロギア
迷宮デイズ
迷宮キングダム
モノトーン・ミュージアム
りゅうたま
ルーンクエスト
六門世界2nd
ロールマスター
ワープス
比叡山炎上
無限のファンタジア
Chill
Eclipse Phase
NJSLYRBATTLE
____END_MARKER____

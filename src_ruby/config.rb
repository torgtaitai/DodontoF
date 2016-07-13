# -*- coding: utf-8 -*-
#CGIの環境設定用ファイル

#デバッグログ出力設定 trueで出力。falseで非出力(ただしエラー処理は常に出力されます。)
$debug = false

#ログファイル名
$logFileName = "log.txt"

#ログファイルサイズ。デフォルト10MB。
$logFileMaxSize = 10485760

#ログファイルの世代管理数
$logFileMaxCount = 1


#サーバで許容できると思うログイン人数を指定。大体でいいです。
#この人数以上になると、人数が多いと警告が表示されるようになります。
$aboutMaxLoginCount = 30

#サーバにログインする事のできる限界人数。
#この人数以上になると、ログインが全くできなくなります。
#制限しないなら -1 と指定ください。
# 例) $limitLoginCount = 100
#     $limitLoginCount = -1
$limitLoginCount = 100


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
#設定をはずすと処理が軽くなります。が、過去ログが殆ど残らなくなります。
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
$databaseHostName = "127.0.0.1"
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

#「全データロード」でアップロード可能なの上限(MB)
$allSaveDataMaxSize = 100.0 

#ログイン状況を記録するファイル
$loginCountFile = 'loginCount.txt'

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
#（通常は変更不要。想定以上の長時間ログインを避けたい場合に指定してください）
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
# [] と空の配列なら各言語のデフォルトに。基本変更する必要はありません。誰得機能。
$defaultUserNames = []

#部屋削除時にパスワード入力が必要かどうかを設定します
# true ： パスワード必要、 false : パスワード不要。
$isPasswordNeedFroDeletePlayRoom = true


#マップにペンで書き込める最大書き込み可能量。
#単位は線の本数。細かい直線は本数が増え、消しゴムでも書き込み量は増え続けます。
$drawLineCountLimit = 3000

#ログアウト時に飛ばされるURL
#空の場合はログインしていた DodontoF.swf をリロードしてログイン画面に戻ります。
$logoutUrl = ""

#多言語化対応 trueなら多言語有効化
#有効にするとログイン画面表示の際に多言語設定を languages ディレクトリから読み取るため、
#この処理の重さを嫌うのであれば false に設定し無効化してください。
$isMultilingualization = true

#外部画像URLの有効／無効を設定します。
# true で有効、false で無効になります。
$canUseExternalImageModeOn = false


#キャラクターコマにカーソルを合わせると表示される「その他」の情報の
#表示の1行最大文字数、最大行数を指定します。
# 0以下の値を指定すると指定なしの無限大となります。
#最初に横の最大文字数（最大の横幅）
$characterInfoToolTipMaxWidth = -1

#次に縦の最大文字数（最大行数）
$characterInfoToolTipMaxHeight = -1


#ログアウト時に他に人がいない場合、部屋の削除を質問するかどうかを設定（true:質問する、false:しない)
$isAskRemoveRoomWhenLogout = true

# プレイルーム名に「削除可」を含めることを禁止します（true：禁止、false：許可）。
# セッション終了後のプレイルーム放置対策の機能です。
$disallowRenamingPlayRoomAsDeletable = false

# src_bcdice/diceBot/ に置いてあるダイスボットを全て一覧に表示するかどうかの指定。
# false の場合は下記の $diceBotOrder に記載されていないダイスボットは一覧に表示されません。
# true の場合は全て表示されます（$diceBotOrderに記載されていないものは末尾に）
$isDisplayAllDice = true


#カード初期化時に表示するカードの名前順序
#ここに定義されていない場合は、文字列順になります。
$cardOrder = <<____CARD_END_MARKER____
トランプ
アマデウス:脅威カード
インセイン：狂気カード
ウィッチクエスト：ウィッチ・タロー
ウィッチクエスト：ストラクチャーカード
カードランカー
ガンメタル・ブレイズ：シチュエーションカード
ガンメタル・ブレイズ：シチュエーションカード(ラバーズストリート対応版)
上海退魔行：陰陽カード
深淵：運命カード
深淵：運命カード(夢魔の占い札対応版)
TORG：Drama Deck [English]
TORG：ドラマデッキ
トーキョーN◎VA：ニューロデッキ
花札
花札：どどんとふバージョン
ファー・ローズ・トゥ・ロード：地縁カード:光
ファー・ローズ・トゥ・ロード：地縁カード:森
ファー・ローズ・トゥ・ロード：地縁カード:氷
ファー・ローズ・トゥ・ロード：地縁カード:海
ファー・ローズ・トゥ・ロード：地縁カード:石
ファー・ローズ・トゥ・ロード：地縁カード:闇
ファー・ローズ・トゥ・ロード：霊縁カード:地
ファー・ローズ・トゥ・ロード：霊縁カード:歌
ファー・ローズ・トゥ・ロード：霊縁カード:水
ファー・ローズ・トゥ・ロード：霊縁カード:火
ファー・ローズ・トゥ・ロード：霊縁カード:風
ブレイド・オブ・アルカナ：タロット
マスカレイド・スタイル：アクト・カード 改定β版
ローズ・トゥ・ロード：タトゥーノ
Itras By：チャンスカード
Itras By：解決カード
Pathfinder：Harrow Deck
ランダムダンジョン・トランプ
____CARD_END_MARKER____


#ダイスボット一覧に表示するダイスボットの名前順序
#標準添付のダイスボットで表示したくない物ははここから削除して下さい。
#
#独自のダイスボットのファイルを src_bcdice/diceBot に置いた場合は、
#そのダイスボットの名前をここに書いておけば任意の順序で表示できます。
#書いてない場合は末尾に並びます。
#
$diceBotOrder = <<____END_MARKER____
ダイスボット(指定無し)
アースドーン
アースドーン3版
アースドーン4版
朱の孤塔のエアゲトラム
アマデウス
アリアンロッド
アルシャード
アルスマギカ
イサー・ウェン＝アー
インセイン
ウィッチクエスト
ウォーハンマー
ウタカゼ
詩片のアルセット
エクリプス・フェイズ
エリュシオン
エルリック！
エムブリオマシン
エンドブレイカー
央華封神RPG第三版
ガーデンオーダー
カードランカー
ガープス
ガープスフィルトウィズ
カオスフレア
片道勇者
神我狩
ガラコと破界の塔
艦これRPG
ガンドッグ
ガンドッグ・ゼロ
キルデスビジネス
クトゥルフ
クトゥルフ第7版
クトゥルフテック
グランクレスト
ゲイシャ・ガール・ウィズ・カタナ
ゲヘナ・アナスタシス
ゴリラTRPG
サタスペ
Shared†Fantasia
ジェームズ・ボンド007
紫縞のリヴラドール
シノビガミ
シャドウラン
シャドウラン第４版
少女展爛会
真空学園
真・女神転生TRPG　覚醒編
Standard RPG System
世界樹の迷宮SRS
絶対隷奴
ソードワールド
ソードワールド2.0
ダークブレイズ
ダンジョンズ＆ドラゴンズ
ダイス・オブ・ザ・デッド
ダブルクロス2nd,3rd
墜落世界
でたとこサーガ
デモンパラサイト
トーキョーＮ◎ＶＡ
トーグ
トーグ1.5版
特命転攻生
ドラクルージュ
トワイライト・ガンスモーク
トンネルズ＆トロールズ
ナイトウィザード
ナイトメアハンター=ディープ
鵺鏡
ネクロニカ
ハーンマスター
バトルテック
パラサイトブラッド
パラノイア
バルナ・クロニカ
ハンターズムーン
ピーカーブー
ビーストバインド トリニティ
ビギニングアイドル
ファンタズムアドベンチャー
フィルトウィズ
ブラッド・クルセイド
ブラッド・ムーン
フルメタル・パニック！
ブレイド・オブ・アルカナ
ペンドラゴン
蓬莱学園の冒険!!
マギカロギア
迷宮デイズ
迷宮キングダム
メタリックガーディアン
メタルヘッド
モノトーン・ミュージアム
ゆうやけこやけ
りゅうたま
ルーンクエスト
ログ・ホライズン
六門世界2nd
ロールマスター
ワースブレイド
ワープス
比叡山炎上
無限のファンタジア
Chill
Chill 3
NJSLYRBATTLE
Pathfinder
____END_MARKER____

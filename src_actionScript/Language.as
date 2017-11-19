//--*-coding:utf-8-*--
package {
    
    import mx.controls.Alert;
    import mx.utils.StringUtil;
    
	public class Language {
        
        [Bindable]
        static public var s:Object = new Object();
        
        static private var japaneseDefault:Object = new Object();
        
        //言語設定用。日本語なら"Japanese"、英語なら"English"
        static private var currentLanguage:String = "";
        static private var languageTable:Object = new Object();
        
        static private var isInitialized:Boolean = false;
        
        static public function setup():void {
            setJapanese();
            setLanguage("");
        }
        
        static public function setJapanese():void {
            var p:Object = new Object();
            p.language = "日本語";
            p.title = "どどんとふ";
            p.loginWindowTitle = "ログイン";
            p.selectLanguageMessage = "";
            p.yourName = "あなたのお名前（初回ログイン用）";
            p.createNewPlayRoom = "新規プレイルーム作成";
            p.deleteSelectedPlayRoom = "指定プレイルームを削除";
            p.playRoomNo = "プレイルームNo.";
            p.roomNo = "ルームNo.{0}";
            p.loginButton = "ログイン";
            p.extendButton = "＞＞拡張機能";
            p.hideExtendButton = "＜＜拡張機能を隠す";
            p.adminPassword = "管理用パスワード";
            p.sendMessageToAllRooms = "全部屋への一斉送信メッセージ";
            p.messageSender = "発言者：";
            p.administrator = "システム管理者";
            p.sendMessageToAllRoomsButton = "全部屋へ一斉発言";
            p.playRoomName = "プレイルーム名";
            p.gameSystem = "ゲームシステム";
            p.loginUserCount = "入室人数";
            p.loginPassword = "パスワード";
            p.canVisitTitle = "見学";
            p.updateTime = "最終更新時刻";
            p.currentLoginStatus = "現在のログイン状況：";
            p.deleteOldPlayRoom = "古いプレイルームを削除";
            p.editReplayData = "リプレイ編集";
            p.uploadReplayData = "リプレイ投稿";
            p.playReplayData = "リプレイ再生";
            p.anonymous = "ななしさん";
            p.passwordLocked = "有り";
            p.canVisit = "可";
            p.overCapacityError = "ログイン人数が限界です。\n　　【{0}】\n他のサーバをご利用ください。";
            p.overCapacityWarning = "ログイン人数が多くなってきました。【{0}】他のサーバの利用を検討ください";
            p.currentLoginCount = "現状：{0}人";
            p.maxLoginCount = "上限：{0}人";
            p.fileMenu = "ファイル";
            p.saveMenu = "セーブ";
            p.loadMenu = "ロード";
            p.saveAllDataMenu = "全データセーブ";
            p.loadAllSaveDataMenu = "全データロード(旧：シナリオデータ読み込み)";
            p.saveLogMenu = "チャットログ保存";
            p.startSessionRecordingMenu = "録画開始";
            p.stopSessionRecordingMenu = "録画終了";
            p.cancelSessionRecordingMenu = "録画キャンセル";
            p.logoutMenu = "ログアウト";
            p.displayMenu = "表示";
            p.displayWindowMenu = "ウィンドウ";
            p.isChatPaletteVisibleMenu = "チャットパレット表示";
            p.isCounterRemoconVisibleMenu = "カウンターリモコン表示";
            p.isChatVisibleMenu = "チャット表示";
            p.isDiceVisibleMenu = "ダイス表示";
            p.isInitiativeListVisibleMenu = "イニシアティブ表示";
            p.isResourceWindowVisibleMenu = "リソース表示";
            p.isStandingGraphicVisibleMenu = "立ち絵表示";
            p.isCutInVisibleMenu = "カットイン表示";
            p.isPositionVisibleMenu = "座標表示";
            p.isGridVisibleMenu = "マス目表示";
            p.isSnapMovablePieceMenu = "マス目にキャラクターを合わせる";
            p.isAdjustImageSizeMenu = "立ち絵のサイズを自動調整する";
            p.initWindowPositionMenu = "ウィンドウ配置初期化";
            p.initLocalSaveDataMenu = "表示状態初期化";
            p.pieceMenu = "コマ";
            p.addCharacterMenu = "キャラクター追加";
            p.addRangeMenu = "範囲追加";
            p.addMagicRangeMenu = "魔法範囲追加(D&D3版)";
            p.addMagicRangeDD4thMenu = "魔法範囲追加(D&D4版)";
            p.addLogHorizonRangeMenu = "ログホライズン用範囲";
            p.addMetallicGuardianDamageRangeMenu = "攻撃範囲(メタリックガーディアン)";
            p.addMagicTimerMenu = "魔法タイマー追加";
            p.createChitMenu = "チット作成";
            p.graveyardMenu = "墓場";
            p.characterWaitingRoomMenu = "キャラクター待合室";
            p.isRotateMarkerVisibleMenu = "回転マーカーを表示する";
            p.cardMenu = "カード";
            p.isCardPickUpVisibleMenu = "カードピックアップウィンドウ表示";
            p.isCardHandleLogVisibleMenu = "カード操作ログ表示";
            p.openInitCardWindowMenu = "カード配置の初期化";
            p.cleanCardMenu = "カードの全削除";
            p.mapMenu = "マップ";
            p.changeMapMenu = "マップ変更";
            p.changeFloorTileMenu = "フロアタイル変更モード";
            p.addMapMaskMenu = "マップマスク追加";
            p.createMapEasyMenu = "簡易マップ作成";
            p.saveMapMenu = "マップ状態保存";
            p.loadMapMenu = "マップ切り替え";
            p.imageMenu = "画像";
            p.imageFileUploaderMenu = "ファイルアップローダー";
            p.imageUrlUploaderMenu = "URLアップローダー";
            p.webcameraCaptureUploaderMenu = "WEBカメラ撮影";
            p.openImageTagManagerMenu = "タグ編集";
            p.deleteImageMenu = "画像削除";
            p.helpMenu = "ヘルプ";
            p.versionMenu = "バージョン";
            p.manualMenu = "マニュアル";
            p.tutorialReplayMenu = "チュートリアル動画";
            p.officialSiteMenu = "オフィシャルサイトへ";
            p.sharedMemo = "共有メモ";
            p.roomDisplay = "{0}：{1}名";
            p.handwrite = "手書き";
            p.replayPosition = "再生位置";
            p.replaySpeed = "早送り倍率";
            p.repeat = "繰り返し";
            p.logoutFromReplay = "戻る";
            p.resourceWindowTitle = "リソース";
            p.resourceName = "名称";
            p.resourceCount = "数";
            p.resourceCheck = "チェック";
            p.resourceOther = "その他";
            p.addResourceWindowTitle = "リソース追加";
            p.changeResourceWindowTitle = "リソース変更";
            p.deleteResourceQuestionWindoTitle = "削除確認";
            p.deleteResourceQuestion = "{0}\nを削除します。よろしいですか？";
            p.initiativeWindowTitle = "イニシアティブ表";
            p.initiativeWindowRoundFormat = "ラウンド：{0}／イニシアティブ：{1}";
            p.initiativeWindowBackButton = "戻る";
            p.initiativeWindowNextButton = "次へ";
            p.initiativeWindowInitButton = "戦闘開始";
            p.initiativeWindowConfigButton = "設定";
            p.initiativeWindowColumnTitleOrder = "順番";
            p.initiativeWindowColumnTitleInitiative = "イニシアティブ";
            p.initiativeWindowColumnTitleInitiativeModify = "修正値(イニシアティブ同値時比較用)";
            p.initiativeWindowColumnTitleCharacterName = "名前";
            p.initiativeWindowColumnTitleInfo = "その他";
            p.editButton = "変更";
            p.deleteButton = "削除";
            p.chatWindowTitle = "チャット";
            p.chatWindowSenderName = "名前";
            p.secretTalkButtonToolTip = "秘話機能有効化";
            p.sendChatToButtonToolTip = "送信先：（全員）以外ならその相手にだけ送信されます";
            p.sendChatMessage = "送信";
            p.saveChatLog = "ログ保存";
            p.chatMessageLabel = "発言";
            p.publicCard = "公開：";
            p.privateCard = "非公開：";
            p.closedCard = "完全非公開";
            p.cardTrushMount = "カード捨て札";
            p.cardMount = "カード山";
            p.cardMountCountDisplay = "山札:{0}枚";
            p.trushCardMountCountDisplay = "捨て札：{0}枚";
            p.createNewPlayRoomInfoText = "新規プレイルームを作成します。";
            p.createPassword = "認証パスワード";
            p.loginPasswordWithTips = "パスワード(空ならパスワード無し)";
            p.gameTypeWithTips = "ゲームシステム（自由入力も可）";
            p.defaultPlayRoomName = "仮プレイルーム（削除可能）";
            p.forVisitor = "見学用";
            p.canUseExternalImageConfig = "外部URLの許容";
            p.canUseExternalImage = "外部URL使用可";
            p.canNotUseExternalImage = "外部URL使用不可";
            p.canVisitConfig = "見学者の可否";
            p.canVisitSetting = "見学可";
            p.canNotVisitSetting = "見学不可";
            p.chatTabNameList = "使用するチャットのタブ";
            p.chatTabNameListInfo = "半角・全角スペースでタブ名を区切ってください。（例：「雑談　打ち合わせ　メモ用」）";
            p.viewStateInfo = "この部屋の表示設定。変更するとルーム内全員の設定が変更されます。";
            p.createButton = "作成";
            p.cancelButton = "キャンセル";
            p.passwordMismatch = "パスワードが違います";
            p.diceWindow = "ダイス";
            p.mainTabName = "メイン";
            p.smallTalkTabName = "雑談";
            p.visitorTabName = "見学用";
            p.diceBotHelpWindow = "ダイスボット解説";
            p.openDiceBotHelpTips = "ダイスボットのヘルプを別ウィンドウで表示します";
            p.botTableTips = "ダイスボット表追加・変更・削除";
            p.novelticModeTips = "シフトキー・Ctrlキーを押しながらのマウス操作でもログは隠れなくなります。";
            p.easyFileUploader = "簡易ファイルアップローダー";
            p.changeLogDisplayToNovelticMode = "ログ表示をノベルゲーム風表示へ切り替える";
            p.changeLogDisplayToNomalMode = "ログ表示をノベルゲーム風表示から通常ログに切り替える";
            p.hiddenLogAuto = "自動ログ隠し";
            p.deleteAllChatLog = "チャットログ全削除";
            p.deleteAllChatLogMessage = "全チャットログ削除が正常に終了しました。";
            p.chatFontConfig = "チャット文字設定";
            p.rollCallAndVote = "点呼／投票";
            p.cutInSetting = "カットイン設定";
            p.standingImageConfig = "立ち絵設定";
            p.sound = "音再生";
            p.soundOn = "音再生あり";
            p.soundOff = "音再生なし";
            p.sendWakeUpSound = "目覚ましアラーム送信";
            p.stopWakeUpSound = "目覚ましアラーム停止";
            p.talkTextOn = "テキスト読み上げあり";
            p.talkTextOff = "テキスト読み上げなし";
            p.allMember = "（全員）";
            p.loginMessage = "「{0}」がログインしました。";
            p.loadAllSaveDataSuccessfully = "全セーブデータ読み込みに成功しました。";
            p.searchMountAnnounce = "「{0}」が「{1}」の山札を参照しています。";
            p.searchTrushMountAnnounce = "「{0}」が「{1}」の捨て札を参照しています。";
            p.logoutMessage = "「{0}」がログアウトしました。";
            p.startRecordMessage = "「{0}」が録画を開始しました。";
            p.resumeRecordMessage = "「{0}」の録画を再開します。";
            p.stopRecordMessage = "「{0}」の録画が終了しました。";
            p.cancelRecordQuestion = "録画を取り消しますか？\n取り消すと今までの録画内容は削除されます。";
            p.cancelRecordQuestionTitle = "録画キャンセル確認";
            p.cancelRecordMessage = "「{0}」の録画をキャンセルしました。";
            p.diceOpenMessage = "「{0}」がダイスをオープンしました。出目は{1}({2}面ダイス)です。";
            p.changeCardSetOwnerMessage = "「{0}」が「{1}」のカード一式を受け取りました。";
            p.returnCardNoNameMessage = "「{0}」が「{1}」の捨て札からカードを引き戻しました。";
            p.returnCardWithNameMessage = "「{0}」が捨て札から「{1}」を引き戻しました。";
            p.alarmSendTo = "送信先";
            p.alarmSource = "効果音";
            p.alarmStartTime = "発動は";
            p.alarmStartSeconds = "秒後";
            p.executeButton = "実行";
            
            ///////////////////////////////////////////
            
            p.pauseTips = "一時停止";
            p.isInitWindowPositionWindow = "表示初期化確認";
            p.isInitWindowPosition = "ウィンドウ位置等の表示情報を初期化しますか？\n(初期化した場合再ログインが必要です)";
            p.initWindowPositionFinished = "保存していた表示情報を初期化しました。\nお手数ですが再度ログインし直してしてください。";
            p.loginUserList = "ログイン中メンバー一覧：";
            p.loginUserNameAndId = "{0}（ユーザーＩＤ：{1}）";
            p.diceBotTable = "ダイスボット表";
            p.addBotTableWindowTitle = "ダイスボット表追加";
            p.changeBotTableWindowTitle = "ダイスボット表変更";
            p.botTableCommandName = "コマンド名";
            p.botTableDiceText = "ダイス";
            p.botTableTitle = "表タイトル";
            p.botTableText = "表内容";
            p.botTableAddButton = "追加作成";
            p.botTableChangeButton = "変更";
            p.botTablePrintSampleButton = "サンプル表示";
            p.botTableSample = "表サンプル";
            p.botTableSampleText_2 = "2:「コマンド名」をチャットに入力することで、\\n表のロールができるようになります。\n";
            p.botTableSampleText_3 = "3:この例では「SAMPLE」と入力すれば\\n実行できるようになります。\n";
            p.botTableSampleText_4 = "4:表のフォーマットは\\nまさにここに書いてある通り、\n";
            p.botTableSampleText_5 = "5:　（数値）:（メッセージ）\n";
            p.botTableSampleText_6 = "6:になります。\n";
            p.botTableSampleText_7 = "7:「コマンド」をチャットで発言すると\\n「ダイス」に記載したダイスを元にランダム選択されます。\n";
            p.botTableSampleText_8 = "8:ダイス目に合致する値が表に無い場合は空文字になります。\n";
            p.botTableSampleText_9 = "9:悩むより一度追加してみるのが早いでしょう。\n";
            p.botTableSampleText_10 = "10:他の人も使える便利な表が出来たら\\n皆で共有してあげてくださいね！\n";
            p.botTableSampleText_11 = "11:そろそろ\\n書く事無くなってきましたね…\n";
            p.botTableSampleText_12 = "12:以上です。";
            p.ManageBotTableWindowTitle = "ダイスボット用表管理";
            p.addNewBotTable = "新規作成";
            p.copyBotTable = "コピー作成";
            p.changeBotTable = "変更";
            p.closeBotTable = "閉じる";
            p.deleteBotTableQuestionWindoTitle = "削除確認";
            p.deleteBotTableQuestion = "{0}({1})\nを削除します。よろしいですか？";
            p.addCharacterWindowTitle = "キャラクター追加";
            p.changeCharacterWindowTitle = "キャラクター変更";
            p.changeCharacterWindowButton = "変更";
            p.characterWindowImageSetting = "画像切替設定";
            p.addButton = "追加";
            p.changeStatusAliasEnable = "カウンターのチェック欄に名前を付ける";
            p.changeStatusAliasDisable = "カウンターのチェック欄に名前を付ける\n(カウンターにチェック欄が無いため現在設定できません)";
            p.characterImageUrlItem = "画像のURL";
            p.size = "サイズ";
            p.hideCharacterUnderMapMask = "マップマスクの下へ隠す\n(イニシアティブ表で非表示)";
            p.characterDataUrl = "参照URL";
            p.characterDataUrlTips = "設定すると、キャラクターの右クリックメニューから\n参照URLを開けるようになります。\nWEB上のキャラクターシートのURLを入力しておくと便利です";
            p.addChitWindowTitle = "チット作成";
            p.heightSize = "縦マス数";
            p.widthSize = "横マス数";
            p.explain = "説明";
            p.chit = "チット";
            p.imageSelecterOpenButton = "画像変更";
            p.tagName = "タグ名";
            p.secretImage = "隠し画像";
            p.reverseImage = "反";
            p.reverseImageTips = "左右反転";
            p.tagInSelectedImage = "選択画像に含まれるタグ";
            p.secretImagePasswordInputWindowTitle = "隠し画像用パスワード入力";
            p.secretImagePasswordInputMessage = "パスワードを入力することで、隠し画像を表示することができます";
            p.secretImagePasswordInput = "パスワード入力";
            p.magicRange3rd = "魔法範囲";
            p.magicRangeDD4th = "魔法範囲D&D4版";
            p.addMagicRangeDD3rdWindowTitle = "魔法範囲追加";
            p.changeMagicRangeDD3rdWindowTitle = "魔法範囲変更";
            p.addMagicRangeDD4thWindowTitle = "魔法範囲追加(D&D4版)";
            p.changeMagicRangeDD4thWindowTitle = "魔法範囲変更(D&D4版)";
            p.magicRangeName = "名前";
            p.magicRangeType = "範囲種別";
            p.magicRangeRadius = "範囲(マス)";
            p.magicRangeColor = "色";
            p.magicRangeTimeRange = "持続時間";
            p.isShowOnInitiativeWindow = "イニシアティブ表に表示する";
            p.magicRangeFeets = "半径(5ft.単位)";
            p.changeButton = "変更";
            p.magicRangeTypeCircle = "円";
            p.magicRangeTypeCorn1 = "円錐型(右上)";
            p.magicRangeTypeCorn2 = "円錐型(右)";
            p.magicRangeTypeCorn3 = "円錐型(右下)";
            p.magicRangeTypeCorn4 = "円錐型(下)";
            p.magicRangeTypeCorn5 = "円錐型(左下)";
            p.magicRangeTypeCorn6 = "円錐型(左)";
            p.magicRangeTypeCorn7 = "円錐型(左上)";
            p.magicRangeTypeCorn8 = "円錐型(上)";
            p.magicRangeTypeSquare = "四角";
            p.closeBurstDD4th = "爆発";
            p.blastDD4th = "噴射";
            p.magicRangeRestRound = "魔法範囲 残り：{0}ラウンド";
            p.changeMagicRangeRightMenu = "魔法範囲の変更";
            p.addMagicRangeRightMenu = "魔法範囲の削除";
            p.cutInWindowTitle = "カットイン：{0}";
            p.addCutInWindowTitle = "カットイン作成";
            p.changeCutInWindowTitle = "カットイン変更";
            p.cutInTitle = "カットインタイトル";
            p.cutInImageSourceLabel = "画像／動画ファイル";
            p.cutInImageSourceTips = "指定可能なファイル形式は jpg,gif,png,swf,flv\nそしてYoutubeへのURLです。";
            p.cutInDisplaySecondsLabel = "表示時間[秒]";
            p.cutInDisplaySecondsTips = "0で無限。flvなら再生が完了した時点でも閉じます";
            p.cutInVolumeLabel = "音声ボリューム";
            p.cutInMatchWithChatTail = "チャット末尾で起動";
            p.cutInMatchWithChatTailTips = "チャットの行末尾がカットインタイトルと一致した場合にカットインを発動するかの指定\n例えばカットインタイトルを「 → 失敗」とするとダイス結果に対してカットインを発動させることができるようになります。";
            p.cutInBgm = "BGM(空欄ならBGM無し)";
            p.cutInBgmLoop = "無限ループ";
            p.cutInPosition = "表示位置";
            p.cutInPositionTips = "カットインの表示位置を指定します。";
            p.cutInPositionLeftUp = "左上";
            p.cutInPositionRightUp = "右上";
            p.cutInPositionUp = "上";
            p.cutInPositionCenter = "中央";
            p.cutInPositionRight = "右";
            p.cutInPositionLeft = "左";
            p.cutInSizeWidth = "横";
            p.cutInSizeHeight = "縦";
            p.cutInSizeDot = "ドット(0なら自動設定)";
            p.cutInTagLabel = "カットインタグ名(空欄なら指定無し)";
            p.cutInTagTips = "カットインタグ名が同一のカットインが表示されている場合は、既存のカットインを先に閉じて新しいカットインが表示されます。\nカットインタグ名が空欄（指定無し）の場合には常に新しいカットインが生成されます。";
            p.cutInPreview = "プレビュー(自分のみ)";
            p.cutInYoutubeUrlTips = "YoutubeのURL指定時には「ルーム」ボタンから「プレイルーム情報変更」で外部URLを使用可にしてください";
            p.cutInInputTitleWarning = "タイトルを入力してください";
            p.cutInInputImageSourceWarning = "画像／動画ファイル名を入力してください";
            
            p.discardMessage = "{0}がカードを捨てました。";
            p.discardMessageWithCardName = "{0}が「{1}」を捨てました。";
            p.returnCardMessage = "{0}がカードを山札に戻しました。";
            p.returnCardMessageWithCardName = "{0}が「{1}」を山札に戻しました。";
            p.openCardMessage = "{0}がカードを公開しました。「{1}」";
            p.changeCardOwnerMessage = "{0}が「{1}」のカードを受け取りました。";
            p.changeCardOwnerToAnyoneMessage = "{0}が「{1}」へカードを渡しました。";
            p.cardOwnerIsNotYouMessage = "カードの所持者ではないため操作できません。";
            p.openMessageCardMessage = "{0}がカードを開きました。";
            p.drawCardAndOpenMessage = "{0}が「{1}」の山札からカードを引いて公開しました。「{2}」";
            p.drawCardAndOpenMessageSeparactor = "」「";
            p.drawCardMessage = "{0}が「{1}」の山札からカードを引きました。";
            p.drawCardSecretMessage = "{0}が「{1}」の山札からカードを伏せたまま引きました。";
            
            p.changeDiceSymbolNumber = "ダイス目を{0}に";
            p.checkRoomNumberWarning = "ルームNo.は0〜{0}の値を設定してください。";
            p.checkMapHeightWarning = "縦マス数の入力値が不正です。1〜{0}の整数を入力してください。";
            p.checkMapWidthWarning = "横マス数の入力値が不正です。1〜{0}の整数を入力してください。";
            p.checkDD3rdRadiusWarning = "半径の入力値が不正です。1〜{0}の整数で5の倍数を入力してください。";
            p.checkDD4thRadiusWarning = "半径の入力値が不正です。1〜{0}の整数を入力してください。";
            p.rangeOverWarning = "射程の入力値が不正です。0〜{0}の整数を入力してください。";
                                                            
            p.magicTimerRestRound = "魔法タイマー 残り：{0}ラウンド";
            p.magicTimerDeleteQuestion = "魔法タイマー「{0}」を削除してもよろしいですか？";
            p.rollCallResult = "準備完了！（{0}/{1}）";
            p.voteResultAgree = "賛成。（{0}/{1}）";
            p.voteResultDisagree = "反対。（{0}/{1}）";
            p.voteTotalResult = "投票結果　賛成：{0}、反対：{1}";
            p.checkLoginCount = "このサーバへのログイン回数が{0}回 になりました！\rそろそろ自前サーバの構築はいかがでしょうか！？";
            p.counterRemoconCounterNameWarning = "カウンター値に「{0}」は存在しません";
            p.replaySetting = "グリッド表示{0}、座標文字{1}、ダイス表示{2}、立ち絵調整{3}、音再生{4}";
            p.deletePlayRoomPasswordMessage = "部屋 [ No.{0} ] を削除します。パスワードを入力してください。";
            p.deleteReplayDataQuestion = "タイトル：{0}\nのリプレイデータを削除します。よろしいですか？";
            p.invalidDiceBotText = "{0}のチャットメッセージに不正なダイスロール結果が検出されました。\n{1}";
            p.diceSymbolToolTips = "[{0}]のダイス\n";

            p.noSmallImageDir = "サムネイル画像格納用ディレクトリ「{0}」がありません。マニュアルの「設置方法」の「imageUploadSpace/smallImages」についての記載を参照しディレクトリの作成を実施して下さい。";
            p.canNotLoginBecauseMentenanceNow = "現在メンテナンス作業中のためログインすることが出来ません。しばらくお待ち下さい。";
            p.canNotRefreshBecauseMentenanceNow = "メンテナンス作業が発生したためサーバ接続が途絶しました。\nしばらく待ったうえで、再度ログインしてください。";
            //
            p.dragMeForFloorTile = "ドラッグ＆ドロップするとマップにタイルを貼り付けることが出来ます。";
            p.dragMeForChit = "チットを配置したいところにドラッグしてください";
            p.unremovablePlayRoomNumber = "指定されたプレイルームはシステム管理者によって削除不可に指定されています。";
            p.unloadablePlayRoomNumber = "このプレイルームはシステム管理者によってロード不可に指定されています。ロードを行いたい場合は他のプレイルームを作成してください。";
            p.noPasswordPlayRoomNumber = "このプレイルームはシステム管理者によってパスワード設定不可に指定されています。\nパスワードは空にしてください。";
            p.loginTimeLimitHasComes = "ログイン時間の上限（{0}秒）が経過しました。サーバとの接続を切断します。";
            p.loginTimeLimitWarning = "このサーバでは{0}以上ログインすると接続が切断されます。";
            p.noEmptyPlayRoom = "空きプレイルームが見つかりませんでした";
            p.errorPassword = "パスワードが間違っています。";
            
            p.saveDataFilter = "セーブデータ(*.{0})";
            p.allSaveDataFilter = "全セーブデータ(*.{0})";
            p.standingGraphicDuplicateError = "キャラクター名：{0}、状態：{1}、はすでに登録済みの立ち絵が存在します。";
            p.ON = "あり";
            p.OFF = "なし";
            p.closeButton = "閉じる";
            p.cardZoneTitle = "{0}の手札置き場";
            p.saveDataNameNotMatched = "{0}ではないため開けません。";
            p.xTimes = "{0}回目";
            
            
            // Card.as
            p.card = "カード";
            p.openCardForMe = "カードを自分だけが見る（非公開）";
            p.openCardEveryone = "カードを全員に見せる（公開）";
            p.closeCard = "カードを伏せる（非公開）";
            p.changeCardOwnerToMe = "カードを自分の管理へ";
            p.writeCardTextToChat = "カードテキストをチャットに引用";
            p.giveCard = "カード譲渡";
            p.deleteCard = "カード削除";
            p.changeCard = "カード変更";
            p.copyCard = "カード複製";
            p.dumpCard = "カード捨て";
            p.returnToCardMount = "カードを山札に戻す";
            p.upSideCard = "正位置";
            p.downSideCard = "逆位置";
            p.yourAreNotCardOwner = "カードの所持者ではないため公開できません。";
            // CardMount.as
            p.drawCardForMe = "カードを引く：非公開で自分だけ";
            p.drawCardForEveryone = "カードを引く：全員に公開する";
            p.drawCardClosed = "カードを引く：全員に非公開で";
            p.drawCardMany = "カードをN枚引く";
            p.selectCardFromMount = "山からカードを選び出す";
            p.shuffleOnlyMountCards = "山札をシャッフルする";
            p.shuffleMountAnnounce = "「{0}」が「{1}」の山札をシャッフルしました。";
            // CardTrushMount.as
            p.returnMountTopCardToField = "一番上のカードを場に戻す";
            p.shuffleTrushCardsAndToMount = "捨て札を山札に積んでシャッフルする";
            p.moveTrushCardsToMountWithoutShuffle = "捨て札をそのまま山札に積んで、シャッフルしない";
            p.selectCardFromTrushMount = "山からカードを選び出す";
            // CardZone.as
            p.cardZone = "カード置き場";
            p.changeCardZoneOwnerToMe = "手札置き場を自分の管理へ";
            p.deleteCardZone = "手札置き場の削除";
            // RandomDungeonCardMount.as
            p.randomDungeonCardMount = "ランダムダンジョン用カード山";
            // RandomDungeonCardTrushMount.as
            p.randomDungeonCardTrushMount = "ランダムダンジョン用カード捨て札";
            p.moveOnlyAceCardToMountForSetupDungeonTile = "Aのみ山に戻して次のダンジョンタイルを準備する";
            // SelectTrushCardWindow.as
            p.selectTrushCard = "捨て札カード選択";
            p.selectTrushCardInfo = "捨て札のカードは以下の通り。抜き取りたいカードをドラッグしてカード置き場にドロップしてください。";
            // AddMessageCardWindow.mxml
            p.addMessageCardWindow = "メッセージカード追加画面";
            p.changeMessageCardWindow = "メッセージカード変更画面";
            p.cardBack = "背面:";
            p.toAnonymous = "ななしさん へ";
            p.message = "メッセージ:";
            p.sampleMessage = "サンプルメッセージ";
            p.addMessageCard = "メッセージカードの追加";
            p.changeMessageCard = "メッセージカードの変更";
            p.changingMessageCardMessage = "「{0}」がメッセージカードを変更しています。";
            p.changeMessageCardMessage = "「{0}」がメッセージカードを変更しました";
            p.faceSide = "表面";
            p.backSide = "裏面";
            
            // CardPickUpWindow.mxml
            p.cardPickup = "カードピックアップ";
            // DrawCardWindow.mxml
            p.drawCardCount = "引く枚数:";
            p.howToDraw = "引き方:";
            p.howToDrawDrawCardForMe = "非公開で自分だけ";
            p.howToDrawDrawCardForEveryone = "全員に公開する";
            p.howToDrawDrawCardClosed = "全員に非公開で";
            p.drawCard = "カードを引く";
            // InitCardWindow.mxml
            p.initCardWindow = "カード初期化画面";
            p.trump = "トランプ";
            p.deckCouunt = "デッキ個数:";
            p.jorkerCount = "ジョーカー枚数:";
            p.randomDungeonTrump = "ランダムダンジョン用トランプ（アリアンロッド等）";
            p.cardCountIncludeAce = "Aを含めた枚数:";
            p.initWithShuffle = "シャッフルして初期配置へ";
            p.cardInitQuestion = "カード初期化確認";
            p.cardInitQuestionMessage = "現在使用しているカードは全て破棄されます。\nよろしいですか？";
            p.checkCardAllDelete = "カード削除確認";
            p.checkCardAllDeleteMessage = "全てのカードを破棄します\nよろしいですか？";
            // SelectCardWindow.mxml
            p.selectCard = "カード選択";
            p.selectCardMessage = "山札のカードは以下の通り。抜き取りたいカードをドラッグしてマップにドロップしてください。";
            
            // ChangeMetallicGuardianDamageRangeWindow.as
            p.changeMetallicGuardianDamageRangeWindowTitle = "攻撃範囲変更";
            // MetallicGuardianDamageRange.as
            p.metallicGuardianAtackRange = "メタリックガーディアン攻撃範囲";
            p.changeAtackRange = "攻撃範囲の変更";
            p.deleteAtackRange = "攻撃範囲の削除";
            p.rotationRight = "右回転";
            p.rotationLeft = "左回転";
            // AddMetallicGuardianDamageRangeWindow.mxml
            p.addAatackRange = "攻撃範囲追加";
            p.atackRangeName = "名前:";
            p.maxRange = "最大射程:";
            p.minRange = "最小射程:";
            p.color = "色:";
            
            //LogHorizonRange
            p.logHorizonRange = "ログホライズン用範囲";
            p.name = "名前";
            p.range = "射程";
            
            
            // Character.as
            p.character = "キャラクター";
            p.changeCharacter = "キャラクターの変更";
            p.deleteCharacter = "キャラクターの削除";
            p.cloneCharacter = "キャラクターの複製";
            p.openCharacterDataUrl = "データ参照先URLを開く";
            // CharacterWaitingRoomWindow.mxml
            p.characterWaitingRoom = "キャラクター待合室";
            p.characterWaitingRoomTips = "マップのキャラクターを待合室に置いたり、置いたキャラクターをマップに戻すことが出来ます。";
            // StockCharacterWindow.mxml
            p.stockCharacterWindow = "キャラクター置き場";
            p.manyCreateCheck = "複数作成";
            p.menyNumber = "連番：";
            
            
            // ChangeStandingGraphicsWindow.as
            p.changeStandingGraphics = "立ち絵変更";
            // AddStandingGraphicsWindow.mxml
            p.addStandingGraphics = "立ち絵追加";
            p.standingGraphicsTips = "下記で設定した「キャラクター名」「状態」でチャットで発言すると立ち絵が表示されます。";
            p.standingGraphicsCharacterName = "キャラクター名";
            p.standingGraphicsImageFileName = "画像ファイル名(jpg,gif,png,swf)";
            p.standingGraphicPosition = "表示位置（1：左端、12：右端）";
            p.loading = "ロード中・・・";
            // StandingGraphicsManageWindow.mxml
            p.standingGraphic = "立ち絵設定";
            p.standingGraphicNameColumn = "名前";
            p.standingGraphicStateColumn = "状態";
            p.standingGraphicPositionColumn = "位置";
            p.standingGraphicImageFile = "画像／動画ファイル";
            p.selectStandingImage = "立ち絵を選択してください。";
            p.characterName = "キャラクター名：";
            p.standingGraphicState = "状態：";
            p.imageFileName = "画像ファイル名：";
            p.deleteStandingGraphicStateQuestion = "上記の立ち絵を削除してよろしいですか？";
            p.deleteStandingGraphicStateQuestionTitle = "立ち絵削除確認";
            p.pleaseSelectStandinggraphic = "立ち絵を選択してください。";
            
            
            // ChangeMemoWindow.as
            p.changeSharedMemoWindowTitle = "共有メモ変更";
            // Memo.as
            p.changeSharedMemo = "共有メモの変更";
            p.deleteSharedMemo = "共有メモの削除";
            // AddMemoWindow.mxml
            p.addMemoTab = "タブ追加";
            p.memo = "メモ:";
            
            
            // ChangeFloorTileWindow.mxml
            p.changeFloorTile = "フロアタイル変更";
            p.imageUrl = "画像のURL";
            // FloorTile.as
            p.floorTile = "フロアタイル";
            p.fixFlexFloorTile = "タイルの固定／固定解除";
            p.rotation180 = "180度回転";
            p.deleteFloorTile = "フロアタイルの削除";
            p.creating = "作成中…";
            
            
            // ChangeMapMarkerWindow.as
            p.changeMapMarkerWindowTitle = "マップマーカー変更";
            // ChangeMapMaskWindow.as
            p.changeMapMaskWindowTitle = "マスク変更";
            // Map.as
            p.addMapMarkerMenue = "マップマーカー追加";
            p.addDiceSymbolMenu = "ダイスシンボル追加";
            p.addCardZoneMenu = "手札置き場の作成";
            p.addMessageCardMenu = "メッセージカードの追加";
            // MapMarker.as
            p.mapMarker = "マップマーカー";
            p.changeMapMarker = "マップマーカーの変更";
            p.deleteMapMarker = "マップマーカーの削除";
            // MapMask.as
            p.mapMask = "マップマスク";
            p.changeMapMask = "マップマスクの変更";
            p.fixMapMask = "マップマスクの固定";
            p.deleteMapMask = "マップマスクの削除";
            // AddMapMarkerWindow.mxml
            p.addMapMarker = "マーカー作成";
            p.mapMarkerHeightSize = "高さ:";
            p.mapMarkerWidthSize = "幅:";
            p.mapMarkerColor = "背景色:";
            p.mapMarkerPaint = "塗りつぶす";
            p.mapMarkerFix = "マーカー固定";

            // AddMapMaskWindow.mxml
            p.addMapMask = "マスク作成";
            p.mapMaskName = "名前:";
            p.mapMaskHeight = "高さ:";
            p.mapMaskWidth = "幅:";
            p.mapMaskAlpha = "透過度:";
            // ChangeMapWindow.mxml
            p.changeMap = "マップ変更";
            p.mapImageUrl = "画像のURL";
            p.changeToBrankMap = "白地図にする";
            p.mapHeight = "縦:";
            p.mapWidth = "横:";
            p.mapLinePositionColor = "マス目・座標文字の色:";
            p.mapGridGap = "マス目間隔:";
            p.mapGridOdded = "マスを交互に";
            p.mapSet = "設定";
            // DrawMapWindow.mxml
            p.handPaintTips = "Altで直線\nShiftで一定角\nCtrlでマス目端点";
            p.handPaintColor = "色:";
            p.handPaintUndo = "取り消し（アンドゥ）";
            p.handPaintRedo = "取り消しの取り消し（リドゥ）";
            p.handLineWeight = "太さ:";
            p.handPaintToImage = "確定";
            p.handPaintToImageToolTip = "手書き線を画像として保存します。\n描き込み量を削減し軽くなりますが、\n確定後はアンドゥができなくなります";
            p.handPaintDeleteAll = "全削除";
            p.handPaintDrawTooMuch = "描き込み量：大量！";
            p.handPaintDrawMuch = "描き込み量：多い";
            p.handPaintDrawMuchNomal = "描き込み量：普通";
            p.handPaintDrawMuchLittle = "描き込み量：軽い";
            p.handPaintDrawPointPercent = "(%1ポイント)";
            p.handPaintDrawTooMuchWarning = "書き込み量が上限です。「全削除」して下さい";
            p.deleteHandPaint = "マップ描消去";
            p.deleteHandPaintQuestion = "マップの全描き込みを削除してよいですか？";
            // LoadMapWindow.mxml
            p.changeMapState = "マップ切り替え";
            p.changeMapStateInfo = "マップとマップマスクを差し替えて、マップを切り替えます";
            p.executeChangeMapState = "切り替え実行";
            // SaveMapWindow.mxml
            p.saveMapStateTitle = "マップ状態保存";
            p.saveMapStateNow = "マップ状態保存準備中……";
            p.saveMapState = "マップ状態保存";
            p.saveMapStateFinished = "マップ保存準備完了";
            // CreateMapEasyWindow.mxml
            p.createMapEasyWindow = "簡易マップ作成";
            p.createMapEasyColor = "色:";
            p.createMapLineWeight = "ペン太さ:";
            p.pencil = "鉛筆";
            p.eraser = "消しゴム";
            p.spoit = "スポイト";
            p.createMapEasyExecuteButton = "決定";
            // PaintablePreviewLoader.as
            p.getSpointColor = "色取得（スポイト）";
            
            
            // Dice.as
            p.diceTotal = "ダイス合計：";
            p.deleteDice = "ダイスの削除";
            
            p.secretDice = "シークレットダイス";
            p.secretDiceResult = "隠しダイスロール結果";
            p.openSecretDiceResult = "結果公開";
            p.deleteSecretDiceResult = "削除";
            
            // DiceSymbol.as
            p.diceSymbol = "ダイスシンボル";
            p.openDiceSymbol = "ダイス目を公開する";
            p.rollDiceSymbol = "ダイスを振る";
            p.changeDiceNumberOver10 = "ダイス目を10以上に";
            p.hideDiceSymbol = "ダイスを隠す";
            p.deleteDiceSymbol = "ダイスの削除";
            p.diceSymbolPrivateMode = "非公開：";
            p.changeDiceSimboleNumber = "「{0}」のダイスシンボルの値が変更されました。";
            
            // StockDiceSymbolWindow.mxml
            p.createDiceSymbol = "ダイスシンボル生成";
            p.diceSymbomNumber = "ダイス目:";
            p.diceSymbomType = "ダイス種別:";
            p.putDiceSymbolSecret = "ダイス目を隠して置く";
            p.white = "白";
            p.black = "黒";
            
            
            // CutInMovie.as
            p.loadImageErrorMessage = "指定画像が読み出せませんでした。";
            // ManageCutInMovieWindow.mxml
            p.cutIn = "カットイン";
            p.sendButton = "送信";
            p.previewButton = "プレビュー(自分のみ)";
            p.executeCutInWhenChatTailMatched = "末尾発動：チャット末尾がタイトル一致なら発動";
            p.cutInTitle = "タイトル";
            p.cutInImageFileName = "画像／動画ファイル名";
            p.cutInSecond = "秒";
            p.pleaseSelectCutIn = "カットインを選択してください。";
            p.deleteCutInMovieQuestion = "上記のカットイン動画を削除してよろしいですか？";
            p.deleteCutInMovieQuestionTitle = "カットイン削除確認";
            
            // Replay.as
            p.playRecordDataFileFormat = "プレイ録画データ(*.rec)";
            p.loadingReplayData = "録画データロード中……";
            p.startReplayRecording = "リプレイ録画を再生します。";
            p.stopReplayRecording = "リプレイ再生を終了します。";
            // EditReplayConfigWindow.mxml
            p.editReplayConfig = "リプレイ環境設定";
            p.isDisplayGridOnReplay = "マス目を表示する";
            p.isDisplayPositionOnReplay = "座標文字を表示する";
            p.isVisualDiceOnReplay = "ビジュアルダイスを表示する";
            p.isStandingGraphicsOnReplay = "立ち絵を自動調整する";
            p.chatWindowBackgroundColorOnReplay = "チャットウィンドウ背景色:";
            p.chatBackgroundColorOnReplay = "チャット背景色設定";
            p.setConfigOnReplay = "設定";
            // EditReplayWindow.mxml
            p.editReplayDataWindow = "リプレイデータ編集画面";
            p.loadReplayData = "ロード";
            p.saveReplayData = "セーブ";
            p.saveReplayDataByHtmlStyle = "セーブ(HTML形式)";
            p.editReplayDataLog = "ログ編集";
            p.replayDataType = "データ種別";
            p.replayDataDetail = "詳細";
            p.setReplayConfig = "環境設定";
            p.copyReplayData = "コピー";
            p.moveReplayDataUp = "↑";
            p.moveReplayDataDown = "↓";
            p.insertReplayDataByLoad = "挿入ロード";
            p.undoReplayDataDelete = "削除取消";
            p.bulkChangeReplayDataImage = "画像一括編集";
            p.replayDataInfo = "概要";
            p.replayDataImageFileName = "画像ファイル名";
            p.replayEditCharacterName = "キャラ:";
            p.replayEditStandingGraphic = "立ち絵:";
            p.replayEditCutIn = "カットイン:";
            p.replayEditMapImage = "マップ画像:";
            p.replayEditCharacterOrCardData = "キャラクター・カード";
            p.replayEditRandData = "ラウンド進行";
            p.replayEditEffectData = "立ち絵・カットイン";
            p.replayEditChatData = "チャット";
            p.replayEditMapData = "マップ情報";
            p.replayEditConfigData = "リプレイ再生時設定";
            // ReplayUploadWindow.mxml
            p.replayUploadWindowTitle = "リプレイ録画データ投稿所";
            p.replayUploadWindowWelcomeMessage1 = "リプレイ録画データ投稿所へようこそ！ここではあなたのリプレイデータの投稿が可能です。";
            p.replayUploadWindowWelcomeMessage2 = "カッコいい・恥ずかしい・うれしかったそんなプレイが録画できましたら";
            p.replayUploadWindowWelcomeMessage3 = "サクっと投稿してみましょう！";
            p.replayUploadTitle = "タイトル";
            p.replayUploadPlayButton = "再生";
            p.replayUploadPlayUrl = "再生URL";
            p.replayUploadPlayUrlInfo = "このURLでリプレイを直接再生することが出来ます。\n他の人にリプレイを見せる場合に手軽でオススメです。";
            p.replayUploadMessage = "リプレイデータの投稿は以下から";
            p.selectUploadReplayData = "投稿リプレイデータ選択";
            p.uploadReplayData = "投稿（リプレイデータアップロード）";
            p.uploadReplayDataResult = "実行結果：";
            p.deleteUploadedReplayDataQuestion = "リプレイデータ削除確認";
            p.replayDataFileFormat = "リプレイデータ(*.rec)";
            p.pleaseInputReplayDataTitle = "タイトルを入力してください。";
            p.uploading = "アップロード中……";
            
            
            // MagicTimer.as
            p.magicTimer = "魔法タイマー";
            p.deleteQuestionTitle = "削除確認";
            // ChangeMagicTimerWindow.as
            p.changeMagicTimer = "魔法タイマー変更";
            // AddMagicTimerWindow.mxml
            p.addMagicTimer = "魔法タイマー追加";
            p.magicTimerName = "名前:";
            p.magicTimerTime = "持続時間:";
            p.magicTimerRound = "ラウンド";
            p.magicTimerStartRound = "効果開始ラウンド:";
            p.magicTimerStartInitiative = "効果開始イニシアティブ:";
            p.magicTimerInfo = "その他:";
            
            
            // ChangePlayRoomWindow.as
            p.changePlayRoom = "プレイルーム変更";
            // CreatePlayRoomWindow.mxml
            p.useExternalImageTips = "外部画像の許可を行うと画像指定時に外部URLが使用出来るようになります。指定していない場合に外部URLを画像に使用すると×マークに指し換わります。";
            p.canVisitTips = "見学可にすると、パスワード有りでも見学者ならログインできるようになります。見学者はチャットの「見学用」タブでの発言のみが許可され、名前は「（名前）＠見学」になります。チャット発言意外の、マップやキャラ等の操作は一切できません。";
            p.playRoomNameTips = "プレイルーム名を設定しない場合、仮使用とみなして削除されます。\n正式に利用する場合には正しく名前をつけましょう。";
            // DisplayPlayRoomInfo.mxml
            p.displayPlayRoomInfo = "プレイルーム情報表示";
            p.changePlayRoomInfo = "プレイルーム情報変更";
            // InputPlayRoomPasswordWindow.mxml
            p.isLoginCheck = "ログインチェック";
            p.areYouVisitorQuestion = "参加者ですか？見学者ですか？:";
            p.visitorTips = "見学者はチャットの「見学用」タブでの発言のみが許可され、発言時の名前は「名前＠見学」になります。マップやキャラ等の操作は一切できません。";
            p.playMember = "参加者";
            p.visitor = "見学者";
            p.loginPasswordForPlayMember = "ログインパスワード:";
            
            
            // SaveAllDataWindow.as
            p.allSaveData = "全データセーブ";
            p.saveDataTips = "画像等の全データをファイルとして保存します。";
            p.saveDataTips2 = "このファイルを使って別サーバへ移行することも可能です！";
            p.saveFileReady = "ファイル準備完了";
            // SaveLoadLocalFile.as
            p.canNotOpenSaveDataBecauseInvalid = "セーブデータが不正なため開けませんでした";
            // SaveChatLogWindow.mxml
            p.saveChatLog = "ログ保存";
            p.saveChatLogForHtml = "HTMLとして保存";
            p.saveChatLogForText = "テキストとして保存";
            p.saveChatLogAllTabs = "[ 全タブ ]";
            
            // SaveWindow.mxml
            p.save = "セーブ";
            p.saveInfomation = "サーバのデータをファイルとして保存します。";
            p.initSaveData = "データ取得";
            p.saveSaveData = "ファイル保存";
            p.saveDataSetting = "サーバデータ取得中...しばらくお待ち下さい...";
            p.saveDataReady = "セーブ(ファイル保存)準備完了";
            p.nowSaving = "保存中…";
            p.whenDownloadDoNotBeginWarning = "ダウンロードが始まらない場合はキャンセルを押してください";
            
            
            // LoadWindow.mxml
            p.load = "ロード";
            p.loadAllSaveData = "全データをロードする（現在のデータは全て破棄されます）";
            p.loadAPartOfSaveData = "一部データのみをロードする";
            p.loadMapData = "マップを変更する";
            p.loadAPartOfSaveDataInfomationForMapObject = "以下は現状に該当データを追加します（現在のデータは保持されます）";
            p.magicRangeBoth = "魔法範囲";
            p.standingGraphics = "立ち絵";
            
            // Voter.as
            p.allReady = "全員準備完了しましたっ！";
            p.beginVote = "点呼開始！";
            p.beginRollCall = "投票を開始しました：";
            p.preshOkWhenReady = "準備が出来たらOKを押してください";
            p.vote = "点呼";
            p.rollCall = "投票";
            // VoteWindow.mxml
            p.rollCallAndVoteWindow = "点呼／投票画面";
            p.votePersonCount = "対象人数:";
            p.voteQuestion = "投票用質問：";
            p.youNeedMorePersenForrollCarll = "点呼を実施するには少なくとももう一人参加者が必要です。";
            
            
            // ChatPalette2.mxml
            p.chatPallet = "チャットパレット";
            p.chatPalletEdit = "編集";
            p.chatPalletSave = "セーブ";
            p.chatPalletLoad = "ロード";
            p.chatPalletAddTab = "タブ追加";
            p.chatPalletDeleteTab = "タブ削除";
            p.chatPalletUndo = "削除戻し";
            p.chatPalletInputSample1 = "チャットパレット入力例：";
            p.chatPalletInputSample2 = "2d6+1 ダイスロール";
            p.chatPalletInputSample3 = "１ｄ２０＋{敏捷}＋｛格闘＠2｝　格闘！";
            p.chatPalletInputSample4 = "//敏捷=10";
            p.chatPalletInputSample5 = "//格闘＝１";
            p.chatPalletName = "名前：";
            p.chatPalletColorTips = "指定文字色が白（FFFFFF）の場合はチャットウィンドウの文字色で発言します。";
            p.chatPalletNameTips = "名前が空欄の場合、チャットウィンドウの名前で発言します";
            p.chatPalletTabName = "タブ名：";
            p.chatPalletSendButton = "送信";
            p.chatPalletSaveData = "チャットパレットセーブデータ";
            
            // ChatWindow.mxml
            p.channerCoundIsEmptyErrorMessage = "チャンネル数が0で設定されています。正しいチャンネル設定を行ってください";
            p.sendChatErrorMessage = "チャット送信エラー";
            p.visitorNameSaffix = "＠見学";
            p.diceBotCustomInfomation = "==【{0}専用】=======================\n";
            p.alarmMessage = "[アラーム発生：{0}]:";
            p.alarmMessageSecond = ":{0}秒後";
            p.needFlashPlayerOverVer10ErrorMessage = "この機能を使用するにはFlashPlayerのバージョン10以上が必要です。";
            p.chatLog = "チャットログ";
            p.nomalChatLogDisplayMode = "通常のチャットログ表示モード";
            p.novelticChatDisplayMode = "ノベルゲーム風表示モード";
            p.changeChatLogDisplayModeQuestion = "{0}に切り替えますか？\n(切り替えには時間がかかります。";
            p.changeChatLogDisplayModeQuestionTitle = "チャット表示切替確認";
            p.visitorMode = "見学モード";
            p.deleteAllChatLogDeleteQuestionTitle = "チャットログ削除確認";
            p.deleteAllChatLogDeleteQuestion = "チャットログを全て削除します。よろしいですか？";
            p.deleteAllChatLogDeleteQuestionTitle2 = "再確認";
            p.deleteAllChatLogDeleteQuestion2 = "削除したログは復旧できませんが、本当によろしいですか？";
            // SendChatMessageFailedWindow.mxml
            p.retrySendFailedMessage = "送信失敗チャットの再送";
            p.resend = "再送";
            p.sendChatErrorCountMessage = "送信エラー[{0}]";
            // EditChatPaletteWindow.mxml
            p.eitChatPaletteWindow = "チャットパレット編集画面";
            p.chatPaletteText = "チャットパレット文字列:";
            p.chatPaletteEditButton = "編集";
            p.howToUseChatPallet_1 = "チャットパレットの使い方：\n";
            p.howToUseChatPallet_2 = "登録したいメッセージをここに入力しましょう。\n";
            p.howToUseChatPallet_3 = "1行1メッセージに対応します。\n";
            p.howToUseChatPallet_4 = "文中に\n";
            p.howToUseChatPallet_5 = "//予約語＝値\n";
            p.howToUseChatPallet_6 = "と書いておくと、｛予約語｝という記述で文字と値の差し替えが出来ます。\n";
            p.howToUseChatPallet_7 = "キャラクターの能力値やスキルの管理に便利かと思います。\n";
            p.howToUseChatPallet_8 = "予約語の宣言は文中どこでも構いません（他のタブには影響しません）。\n";
            p.howToUseChatPallet_9 = " // や = や {} といった記号や数値は全角・半角どちらでもOKです。\n";
            p.howToUseChatPallet_10 = "｛予約語｝にはイニシアティブ表のカウンター値を指定することもできます。\n";
            p.howToUseChatPallet_11 = "その場合、チャットパレットの「名前」を元に参照するキャラクターが決まります。\n";
            p.howToUseChatPallet_12 = "「名前」が空の場合はチャットウィンドウの「名前」を参照します。";
            
            
            // ImageManageWindow.mxml
            p.imageManageWindow = "画像管理";
            p.selectDeleteImage = "削除する画像を選択してください。";
            p.selectDeleteImageTips = "上の一覧から削除したい画像を選択してください。選択すると背景色が変わります";
            p.deleteImage = "選択した画像を削除";
            p.deleting = "削除中・・・";
            p.deleteResultLoading = "結果受信中・・・";
            // ImageUploadSetInfo.mxml
            p.uploadImageFormat = "対応画像:JPEG/GIF/PNG/SWF";
            p.secretImagePassword = "隠し画像パスワード設定";
            p.addedTags = "付与するタグ（半角・全角スペースで区切り）：";
            p.addedTagsTips = "タグ名に 縦nn横mm を記述することでマップ変更時に自動的にそのサイズが指定されます。";
            p.imageUploaderSecretPasswordInfo = "隠し画像用パスワード（空文字場合は誰でも参照可能）\nこのパスワードは管理・通信上暗号化されません。\n他者に参照される恐れがあるため、重要なパスワードの利用は避け\n簡易な文字を利用してください。";
            p.secreteImagePasswordInput = "隠し画像用パスワード入力";
            p.inputPassword = "パスワード入力";
            p.passworded = "パスワードあり";
            p.nopassword = "パスワードなし";
            p.uploadPrivate = "専用";
            p.uploadPublic = "全体";
            p.uploadPrivateToolTips = "アップロードした画像はこの部屋でのみ参照できるようになります";
            p.uploadPublicToolTips = "アップロードした画像は全ての部屋で参照できるようになります";
            // ImageUploadWindow.mxml
            p.imageUploader = "画像／動画アップローダ";
            p.selectUploadTargetImage = "アップロード対象画像選択";
            p.uploadImage = "アップロード";
            p.executeResult = "実行結果：";
            p.uploadImageIsNotSelected = "アップロード画像未選択";
            p.uploadImageFlashPlayerVersionWarningMessage = "選択画像の表示にはFlash Player10以上が必要です。<br><i><a href='http://www.adobe.com/shockwave/download/index.cgi?Lang=Japanese&P1_Prod_Version=ShockwaveFlash'>Flash Player最新版のダウンロードはこちらから。</a></i>";
            p.imageFIleFormat = "画像／動画データ(*.jpg;*.jpeg;*.gif;*.png;*.swf;*.flv)";
            p.canUploadSeletedImage = "選択画像のアップロード可能";
            p.selectedFileName = "選択ファイル名：";
            p.nowUploading = "アップロード実行中...";
            p.loadImageFileErrorMessage = "画像の読み込みでエラーが発生しました。";
            p.imageFileUploadingProgress = "アップロード実行中...({0}/{1})";
            
            // Chit.as
            p.Chit = "チット";
            p.deleteChit = "チットの削除";
            p.cloneChit = "チットの複製";
            // DodontoF_Main.as
            p.nowYouAreRecordingErrorMessage = "録画中です。ログアウトするには録画を終了してください。";
            p.logoutQuestionTitle = "ログアウト確認";
            p.logoutQuestion = "ログアウトしてよろしいですか？";
            p.deleteWhenLogout = "ログアウト時に部屋を削除する";
            p.returnToLoginWindow = "ログイン画面に戻る";
            p.returnToLoginWindowQuestion = "リプレイ再生を止め、ログイン画面に戻りますか？";
            // GuiInputSender.as
            p.inputNameError = "名前を入力してください。";
            p.inputImageFileUrlError = "イメージ画像のURLを入力してください。";
            p.sizeError = "サイズの入力値が不正です。1〜10の整数を入力してください。";
            p.counterValueError = "カウンター値が不正です。";
            p.statusAliasNameError = "ステータスエイリアスが不正です。";
            p.widthInvalidError = "幅が不正な値です。";
            p.heightInvalidError = "高さが不正な値です。";
            p.positionXYsmallerError = "設置X,Y座標が0未満の値になっています。";
            p.inputMessageError = "メッセージを入力してください。";
            p.noMagirRangeError = "魔法範囲種別を選択してください。";
            p.noColorErro = "色を選択してください";
            p.noImageUrlError = "イメージ画像のURLを入力してください。";
            p.invalidTimeRangeError = "持続時間の値範囲が不正です。1以上の値を入力してください。";
            p.noCharacterIdWantToRessurectError = "復活させたいキャラクターのＩＤを入力してください。";
            p.noSpeackerNameError = "発言者を入力してください。";
            p.noPlayRoomError = "プレイルーム名は必ず入力してください";
            // ImageTag.as
            p.allTag = "（全て）";
            p.noselectTag = "（未選択）";
            p.characterImageTag = "キャラクター画像";
            p.mapImageTag = "マップ画像";
            p.floorTileImageTag = "フロアタイル画像";
            p.standingGraphicTag = "立ち絵";
            p.monsterImageTag = "モンスター";
            // MessageBaloon.as
            p.period = "。";
            p.comma = "、";
            p.success = "成功";
            p.failed = "失敗";
            // MovablePiece.as
            p.movablePiece = "コマ基本クラス";
            // SharedDataReceiver.as
            p.connectToServerSuccessfully = "サーバとの再接続に成功しました。";
            p.deleteInvalidDataAutomatically = "不正なデータが含まれていたため自動削除しました。";
            // SharedDataSender.as
            p.loadAllSaveDataError = "全セーブデータ読み込み時にエラーが発生しました：";
            p.connectToServerErrorAndReconnect = "サーバとの接続でエラーが発生しました。再接続します。";
            p.reconnectingToServer = "再接続中……";
            p.generating = "(作成中・・・)";
            p.characterNameDuplicate = "\"{0}\"という名前のキャラクターはすでに存在するため追加に失敗しました。";
            p.sendChatAllRoomSuccess = "成功\r送信した部屋：";
            p.sendChatAllRoomFailed = "送信失敗";
            p.refreshStopedError = "サーバとの接続が切断されました。操作を行う事は出来ません";
            // ChangeCounterRemoconWindow.mxml
            p.changeCounterRemoconWindow = "カウンターリモコンエディター";
            p.buttonName = "ボタン名:";
            p.addHp = "HP増加";
            p.counterRemoconCounterName = "カウンター名\{1\}:";
            p.counterRemoconCounterNameTips = "イニシアティブは「#INI」で指定できます。\nリソースウィンドの名前を指定することも可能。";
            p.counterRemoconModifyValue = "修正値\{2\}:";
            p.counterRemoconModifyOperatorTips = "現状値に加減算するか、値を差し替えるかを選択できます。";
            p.counterRemoconModifyValueTips = "設定可能な書式\n （空）　：任意の値を後から指定\n 数値　：指定した値\n 「xDy+n」形式：ダイスロール結果（例：２ｄ６＋１、D66、D66s(値入れ替え)）";
            p.counterRemoconDisplayMessage = "表示メッセージ:";
            p.counterRemoconDisplayMessageDefault = "\{0\}の\{1\}を\{2\}した";
            p.counterRemoconDisplayMessageTips = "使用可能な置換文字：\n\{0\}：キャラクター名\n\{1\}：カウンター名\n\{2\}：修正値\n\{3\}：修正値絶対値（＋−無し）\n\{4\}：変更結果";
            p.sample = "例:";
            p.setting = "設定";
            // ChangeStatusAliasWindow.mxml
            p.changeStatusAliasWindow = "イニシアティブ表のチェックボックスへの名前付与画面";
            p.headerName = "ヘッダー名";
            p.checkBoxName = "チェックボックスへの名前";
            // ChatFontWindow.mxml
            p.chatFontWindow = "チャット文字設定";
            p.chatFontColor = "文字色:";
            p.chatFontColorSetting = "チャット文字色設定";
            p.chatFontBackgroundColor = "背景色:";
            p.chatFontBackgroundColorSetting = "チャット背景色設定";
            p.chatFontSize = "文字サイズ:";
            p.chatFontSizeTips = "チャット文字サイズ";
            p.chatFontTimeFormat = "フォーマット:";
            p.chatFontTimeFormatInfo = "「時：分」表示";
            p.chatFontDisplayOtherChannel = "別タブメッセージ:";
            p.chatFontDisplayOtherChannelInfo = "表示する";
            p.chatChannelColored = "タブの色:";
            p.chatChannelColoredInfo = "色分けする";
            p.chatFontInputSample = "入力例:";
            p.chatFontOutputSample = "出力例：";
            p.chatFontSetting = "設定";
            p.chatFontSampleName = "なまえ";
            
            
            // CheckLoginCountWindow.mxml
            p.howDoYouMakeYoruServer = "自前サーバはいかがでしょうか？";
            p.yesIMakeMyServer = "YES(設定方法について是非教えて下さい)";
            p.noIhaveNotInterestInMyServer = "NO(またの機会に願いします)";
            // CounterRemocon.mxml
            p.saveCounterRemoconButton = "セーブ";
            p.loadCounterRemoconButton = "ロード";
            p.addCounterRemoconButton = "ボタン追加";
            p.counterRemoconSampleTitle_1 = "1D6ダメージ";
            p.counterRemoconSampleInfo_1 = "{0}に{3}のダメージ！{4}";
            p.counterRemoconSampleTitle_2 = "HP回復";
            p.counterRemoconSampleInfo_2 = "{0}の{1}を{3}回復{4}";
            p.counterRemoconSampleTitle_3 = "イニシロール";
            p.counterRemoconSampleInfo_3 = "{0}のイニシアティブを{2}へ";
            p.counterRemoconSampleTitle_4 = "夢を渡す";
            p.counterRemoconSampleCounterName_4 = "夢";
            p.counterRemoconSampleInfo_5 = "{0}に夢を渡しました{4}";
            p.counterRemoconSaveData = "カウンターリモコンセーブデータ";
            p.counterRemocon = "カウンター リモコン";
            p.changeCounterRemoconButton = "ボタンの変更";
            p.deleteCounterRemoconButton = "ボタンの削除";
            p.cloneCounterRemoconButton = "ボタンの複製";
            p.moveLeftCounterRemoconButton = "ボタンを【←左　　】へ";
            p.moveRightCounterRemoconButton = "ボタンを【　　右→】へ";
            p.toOthersCounterRemoconButton = "その他のキャラ";
            p.initiativeValue = "イニシアティブ値";
            p.counterRemoconExecuteResultFormat = "（{0}：{1}->{2}）";
            // CreateSmallImagesWindow.mxml
            p.login = "ログイン";
            p.getData = "データ取得";
            p.progressiveInfo = "進行度を示す . が止まったら「アップロード」ボタンを押してください。 . 一つが１ファイルです。\n";
            p.createSmallImagesCountPlan = "サムネイル作成対象件数（予定） : ";
            p.createSmallImagesFinished = "全画像のサムネイル作成が完了しました。お疲れ様でした。\n";
            p.createSmallImages_1 = "この件数が0件なら全て完了です。\n0でなくても何らかの理由で実施できない場合もあります。\n大体0件になればOKと考えておいてください。\n\n";
            p.createSmallImages_2 = "まずは「データ取得」ボタンを押してください。処理が重い場合がありますのでご注意ください。\n";
            p.createSmallImages_3 = "\nアップロード中。　上記と同様に進行度を . で示しています。\n通常は上記と同じ数の.が表示されます。\n進行が停止したら処理完了です。お疲れ様でした。\n";
            // DodontoF.mxml
            p.replayButton = "再生";
            // FileUploadWindow.mxml
            p.easyFileUploader = "簡易ファイルアップローダー";
            p.easyFileUploaderInfo_1 = "ファイルをアップロードできます。";
            p.easyFileUploaderInfo_2 = "アップロードすると、ファイルのURLがチャットに発言されるので、";
            p.easyFileUploaderInfo_3 = "そのリンクからみんなでファイルをダウンロードすることができます。";
            p.easyFileUploaderInfo_4 = "アップロードしたファイルは1時間経つと自動的に削除されます。";
            p.executeFileUpload = "アップロード実行";
            p.executeFileUploadResult = "実行結果：";
            p.allUploadableFileTypes = "全サポートファイル種別";
            p.imageFileType = "画像";
            p.textFileType = "文書";
            p.compressedFileType = "圧縮ファイル";
            p.movieSoundFileType = "動画・音声";
            p.oterFileType = "その他";
            p.executeFileUploadInishedMessage = "{0}がファイルをアップロードしました\r  ファイル名：{1}\r  URL:{2}";
            // GraveyardWindow.mxml
            p.graveyard = "墓場";
            p.graveyardCharacterName = "名前:";
            p.ressurect = "復活";
            p.clearGraveyard = "墓地を空にする";
            // InitiativeWindow.mxml
            p.deleteSelectedCharacter = "対象の削除";
            // InputTextWindow.mxml
            p.input = "入力";
            // LoginWindow.mxml
            p.loginUser = "ログインユーザー：";
            p.versionMismuch = "どどんとふの更新データが正しく読み込めませんでした。\n　１．今開いているページを一度閉じて、再度開き直してください。\n　２．それでもダメな場合、ブラウザのキャッシュをクリアしてみてください。\n　３．それでもダメな場合、サーバーのファイルが正しく転送されているか再度確認してください。\n\n以下、技術的な情報：\nサーババージョン　　：{0}\nクライアントバージョン：{1}\n";
            p.loginRoomStates = "No. {0} ： {1} 人";
            p.nobadyLogined = "誰もログインしていません";
            p.loginStatus = "ログイン状況\n";
            p.removePlayRoomQuestion = "{0}を削除しますか？";
            p.removePlayRoomQuestionTitle = "削除確認";
            p.deleteWhenUserExistQuestion = "No.{0}にログインしているユーザーがまだいるようです。\n削除してよいですか？";
            p.deletePlayRoom = "部屋削除";
            p.deleteOldPlayRoomBulkQuestion = "一括削除確認";
            p.deleteOldPlayRoomBulkQuestionTitle = "日以上前の、古いプレイルームの一括削除を行います。\nよろしいですか？";
            p.replayRoom = "リプレイルーム";
            // SetInitiativeInfoWindow.mxml
            p.setInitiativeInfoWindow = "イニシアティブ表設定";
            p.inputerCounterNames = "カウンターに使用するパラメータ名をスペース区切りで入力してください";
            p.inputerCounterNamesInfo_1 = "先頭に ＊（全角・半角どちらでも可）を付けて記述するとチェック欄になります。";
            p.inputerCounterNamesInfo_2 = "（最小）＜カウンター名＜（最大）で上下限を指定。「？」を指定すると個別に設定可能。";

            p.inputerCounterNamesInfo_3 = "　　　例）　-15<HP<?　?<MP<99　AC　侵食率　ポシビリティ　*毒　＊転倒";
            p.inputerCounterNamesInfo_4 = "(注)この設定は同一プレイルームの全員に影響します。";
            p.counterNamelist = "カウンター名一覧:";
            //p.initiativeWindowFontSize = "イニシアティブ表フォントサイズ:";
            //p.initiativeWindowFontSizeTips = "(注)この設定は他のプレイヤーに影響は無く、あなたの画面にだけ反映されます。";
            p.initiativeColumnMaxFormat = "最大{0}";
            p.initiativeColumnMinFormat = "最小{0}";
            
            // TagManagerWindow.mxml
            p.tagManagerWindowTitle = "画像タグ名管理";
            p.saveTagManagedSetting = "変更内容を保存";
            p.doYouLeaveHereWithNoSavingQuestion = "「変更内容を保存」を実施していません。\n現在の変更内容を破棄しますがよろしいですか？";
            p.doYouLeaveHereWithNoSavingQuestionTitle = "確認";
            // VersionWindow.mxml
            p.version = "バージョン";
            // WebCameraCaptureWindow.mxml
            p.webCameraCaptureWindowTitle = "WEBカメラ撮影";
            p.webCameraCaptureInfos_1 = "WEBカメラで撮影した画像をキャラクター画像として直接アップロードできます。";
            p.webCameraCaptureInfos_2 = "お手持ちのフィギュアやイラストの取り込みにご利用ください。";
            p.capture = "撮影";
            p.uploadCaptureImage = "アップロード";
            p.capturing = "撮影中...";
            p.cameraNotFound = "カメラが検出できません";
            p.uploadCapturedImageQuestion = "この画像をアップロードしますか？";
            p.cancel = "取消";
            p.captureImageUploading = "転送中・・・";
            p.captureImageUploadResult = "転送結果：";
            p.captureImageUploadResultFailed = "失敗";
            p.youNeedInstallMsgPack = "MsgPackがインストールされていません。サーバで\ngem install msgpack\nを実行して必要なライブラリを追加してください。";
            
            p.MotionEffectToolTip = "立ち絵に揺れなどのエフェクトをかけられます";
            p.MotionEffectNone = "エフェクト無し";
            p.MotionEffectZoom = "拡大・縮小";
            p.MotionEffectShake = "車両";
            p.MotionEffectWalk = "歩行";
            p.cutinSortMoveable = "並べ替え許可";
            p.cutinSortMoveableTip = "リストをドラッグして順番を入れ替え可能になります";
            
            p.lineHeight = "行間の高さ";
            p.fontSize = "フォントサイズ";
            p.changeFontSize = "フォントサイズ変更";
            p.changeFontSizeText = "どどんとふ全体のフォントサイズを変更します";
            p.defaultText = "デフォルト";
            p.invalidFileNameExtension = "ファイル名 \"{0}\" は拡張子が不正です";
            p.commandNameAlreadyExist = "そのコマンド名は既に使用されています。";
            p.commandNameIsNotExist = "そのコマンド名は存在しません。";
            p.commandNameCanUseOnlyAlphabetAndNumber = "コマンド名には英数字のみ使用できます";
            p.commandNameIsEmpty = "コマンド名が空です";
            p.tableFormatIsInvalid = "{0}行目の表記({1})は「数字:文字列」になっていません。";
            p.changeCommandNameFaild = "コマンド名の変更に失敗しました（ファイル移動でエラーが発生しました）";
            
            
            japaneseDefault = p;
            languageTable[""] = japaneseDefault;
        }
        
        
        static private var keywordFormat:RegExp = /^###Language:(.+)###$/;
        
        static public function getKeywordText(message:String):String {
            
            var matchResult:Object = keywordFormat.exec(message);
            if( matchResult == null ) {
                return message;
            }
            
            var keybase:String = matchResult[1];
            
            var args:Array = keybase.split(/\t/);
            var key:String = args.shift();
            
            var str:String = Language.s[key];
            if( str == null ) {
                return key;
            }
            
            return getText(str, args);
        }
        
        
        static public function text(key:String, ...args):String {
            var str:String = Language.s[key];
            if( str == null ) {
                Log.loggingError("Language.s." + str + "is NOT exist!!!!!!!!!");
                return key;
            }
            
            return getText(str, args);
        }
        
        static private function getText(str:String, args:Array):String {
            var result:String = StringUtil.substitute(str,
                                  args[0], args[1], args[2], args[3], args[4], 
                                  args[5], args[6], args[7], args[8], args[9]);
            return result;
        }
        
        
        static public function initLanguage(languageInfos:Object):String {
            if( languageInfos == null ){
                return "";
            }
            
            for(var name:Object in languageInfos) {
                var info:Object = languageInfos[name];
                if( name == "Japanese" ) {
                    name = "";
                }
                
                languageTable[name] = info;
            }
            
            // checkJapanese();
            
            return checkLanguageNames();
        }
        
        /*
        static private function checkJapanese():void {
            
            if( DodontoF_Main.getInstance().isInvisibleMode() ) { return; }
            
            var japanese:Object = languageTable[""];
            if( japanese == null ) {
                Log.logging("japanese is null");
                return;
            }
            
            for(var key:String in japaneseDefault) {
                if( japaneseDefault[key] != japanese[key] ) {
                    Log.loggingTest("\rkey : " + key
                                     + "\r"+ japaneseDefault[key]
                                     + "\r" + japanese[key])
                }
            }
        }
         */
        
        
        static private function checkLanguageNames():String {
            
            var names:Array = Utils.getKeys(languageTable);
            var langNames:Array = new Array();
            
            for each(var name:String in names) {
                if( name == "" ) {
                    continue;
                }
                var langName:String = languageTable[name].language;
                var duplicate:Array = getDuplicateLangage(langNames, langName);
                if( duplicate != null ) {
                    var message:String = "";
                    message += "[" + langName + "] is duplicated ! please check \r";
                    message += "  language/" + duplicate[1] + ".txt\r";
                    message += "  language/" + name + ".txt\r";
                    message += "and delete old file.";
                    return message;
                }
                
                langNames.push( [langName, name] );
            }
            
            return "";
        }
        
        static private function getDuplicateLangage(array:Array, name:String):Array {
            for each(var item:Array in array) {
                var itemName:String = item[0];
                if( itemName == name ) {
                    return item;
                }
            }
            return null;
        }
        
        
        //言語設定
        static public function setLanguage(lang:String):String {
            if( lang == null ) {
                return "";
            }
            
            lang = lang.replace('-', '');
            
            var beforeLang:String = currentLanguage;
            var beforeKeys:Array = Utils.getKeys(s, diceBotLangPrefix);
            
            currentLanguage = lang;
            Log.logging("language", currentLanguage);
            
            s = languageTable[currentLanguage];
            
            var result:String = checkDiff(beforeLang, currentLanguage, beforeKeys);
            
            DodontoF_Main.getInstance().getDodontoF().initMenu();
            
            return result;
        }
        
        static public var diceBotLangPrefix:String = "DiceBotName_";
        
        static private function checkDiff(beforeLang:String, afterLang:String,
                                   beforeKeys:Array):String {
            
            if( ! isInitialized ) {
                isInitialized = true;
                return "";
            }
            
            var afterKeys:Array = Utils.getKeys(s, diceBotLangPrefix);
            
            var diffString:String = Utils.getHashDiff(beforeKeys, afterKeys);
            if( diffString == "" ) {
                return "";
            }
            
            
            
            var message:String = "Server directory \"language\" files has problem. please change language file.\r\r";
            
            if( beforeLang != "" || currentLanguage != "" ) {
                message += StringUtil.substitute("Language data has different,\rbefore:{0}\rafter:{1}\r\r",
                                                 beforeLang, currentLanguage);
            }
            
            message += diffString;
            return message;
        }
        
        //言語取得
        static public function getLanguage():String {
            return currentLanguage;
        }
        
        static public function getDataProvider():Array {
            var result:Array = new Array();
            
            var names:Array = Utils.getKeys(languageTable);
            
            for each(var name:String in names){
                var label:String = languageTable[name].language;
                result.push( {label:label, data:name} );
            }
            
            return result;
        }
        
        static public function getLangageTypes():Array {
            var types:Array = Utils.getKeys(languageTable);
            return types;
        }
        
    }
    
}

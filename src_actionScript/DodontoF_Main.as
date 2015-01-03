//--*-coding:utf-8-*--
package {
    
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import mx.core.UIComponent;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.net.FileReference;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.navigateToURL;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.setTimeout;
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.core.IFlexDisplayObject;
    import mx.managers.BrowserManager;
    import mx.utils.StringUtil;
    
    
	public class DodontoF_Main extends UIComponent {
        
        private var playRoomName:String = "";
        private var playRoomPassword:String = "";
        static private var defaultChatChannelNames:Array = [publicChatChannelName, Language.s.smallTalkTabName];
        private var chatChannelNames:Array = Utils.clone(defaultChatChannelNames);
        private var canVisitValue:Boolean = false;
        private var logoutUrl:String = "";

        
        public function setCommet(b:Boolean):void {
            sender.setCommet(b);
        }
        
        
        public function getPlayRoomName():String {
            return Utils.clone(playRoomName);
        }
        
        public function getPlayRoomPassword():String {
            return Utils.clone(playRoomPassword);
        }
        
        public function getPlayRoomNumber():int {
            return sender.getRoomNumber();
        }
        
        public function setPlayRoomPassword(pass:String):void {
            playRoomPassword = pass;
            Log.logging("setPlayRoomPassword pass", pass);
        }
        
        public function getChatChannelNames():Array {
            return Utils.clone(chatChannelNames);
        }
        
        public function getChatChannelName(index:int):String {
            return chatChannelNames[index];
        }
        
        public function canVisit():Boolean {
            return canVisitValue;
        }
        
        
        private var serverViewStateInfo:Object = null;
        private var isServerViewStateNotInitialized:Boolean = true;
        
        public function setPlayRoomInfo(local_playRoomName:String,
                                        local_chatChannelNames:Array,
                                        local_canUseExternalImageMode:Boolean,
                                        local_canVisit:Boolean,
                                        backgroundImage:String,
                                        gameType:String,
                                        info:Object):void {
            Log.logging("setPlayRoomInfo begin");
            
            if( local_playRoomName == "" ) {
                Log.logging("local_playRoomName is empty");
                return;
            }
            
            playRoomName = local_playRoomName;
            //playRoomPassword = local_password;
            setUseExternalImage( local_canUseExternalImageMode );
            canVisitValue = local_canVisit;
            
            setDiceBotGameType(gameType);
            setChatChannelNames(local_chatChannelNames);
            
            
            if( info == null ) {
                info = new Object();
            }
            
            initServerViewStateInfo();
            
            Log.logging("serverViewStateInfo.key", serverViewStateInfo.key);
            Log.logging("info.key", info.key);
            Log.logging("isServerViewStateNotInitialized", isServerViewStateNotInitialized );
            
            if( (serverViewStateInfo.key != info.key) ||
                isServerViewStateNotInitialized ) {
                Log.logging("serverViewStateInfo.key is diff info.key");
                setViewState(serverViewStateInfo, info);
                isServerViewStateNotInitialized = false;
            }
            
            Config.getInstance().setBackgroundImage( backgroundImage );
        }
        
        private function setDiceBotGameType(gameType:String):void {
            if( chatWindow == null ) {
                return;
            }
            if( gameType == null ) {
                return;
            }
            if( gameType == "" ) {
                return;
            }
            
            chatWindow.setDiceBotGameType(gameType);
            Log.logging("setGame", gameType);
        }
        
        private function setViewState(serverViewStateInfo:Object, info:Object):void {
            Log.logging("has diff! info.key", info.key);
            Log.logging("serverViewStateInfo.key", serverViewStateInfo.key);
            try {
                serverViewStateInfo = info;
                if( serverViewStateInfo == null ) {
                    serverViewStateInfo = new Object();
                }
                
                Config.getInstance().loadViewStateInfo(serverViewStateInfo);
                Config.getInstance().saveInfo(serverViewStateInfo_saveKey, serverViewStateInfo);
            } catch(e:Error) {
                Log.loggingException("DodontoF_Main.loadViewStateInfo()", e);
            }
        }
        
        private var serverViewStateInfo_saveKey:String = "serverViewStateInfo_saveKey";
        
        private function initServerViewStateInfo():void {
            Log.logging("initServerViewStateInfo begin");
            
            if( serverViewStateInfo != null ) {
                Log.logging("serverViewStateInfo is NOT null", serverViewStateInfo);
                return;
                
            }
            
            Log.logging("serverViewStateInfo is null");
            
            serverViewStateInfo = Config.getInstance().loadInfo(serverViewStateInfo_saveKey);
            Log.logging("serverViewStateInfo from loadInfo", serverViewStateInfo);
            
            if( serverViewStateInfo == null ) {
                serverViewStateInfo = new Object();
            }
        }
        
        
        public function getServerViewStateInfo():Object {
            initServerViewStateInfo();
            return serverViewStateInfo;
        }
        
        private function setChatChannelNames(names:Array):void {
            chatChannelNames = names;
            
            if( chatChannelNames == null ) {
                chatChannelNames = defaultChatChannelNames;
            }
            
            if( chatWindow != null ) {
                chatWindow.setChannelNames( getChatChannelNames() );
            }
        }
        
        public function get publicChatChannelName():String {
            return DodontoF_Main.publicChatChannelName;
        }
        static public function get publicChatChannelName():String {
            return Language.s.mainTabName;
        }
        
        private var visiterMode:Boolean = false;
        public function isVisiterMode():Boolean {
            return visiterMode;
        }
        
        public function setVisiterMode(b:Boolean):void {
            visiterMode = b;
            Log.logging("DodontoF_Main.setVisiterMode visiterMode", visiterMode);
            
            if( chatWindow != null ) {
                chatWindow.changeWindowStyle();
            }
        }
        
        public function setEffects(effects:Array):void {
            var tmpCutInInfos:Array = new Array();
            var tmpStandingGraphicInfos:Array =  new Array();
            
            for(var i:int = 0 ; i < effects.length ; i++) {
                var effect:Object = effects[i];
                if( effect.type == StandingGraphics.getTypeStatic() ) {
                    tmpStandingGraphicInfos.push(effect);
                } else {
                    tmpCutInInfos.push(effect);
                }
            }
            
            CutInBase.setCutInInfos(tmpCutInInfos);
            StandingGraphicsManageWindow.standingGraphicInfos = tmpStandingGraphicInfos;
            
            chatWindow.setStandingGraphics(StandingGraphicsManageWindow.standingGraphicInfos);
        }
        
        
        private static var staticThis:DodontoF_Main;
        private var thisObj:DodontoF_Main;
        protected var dodontoF:DodontoF;
        private var sender:SharedDataSender;
        private var guiInputSender:GuiInputSender = new GuiInputSender();
        private var map:Map;
        private var roundTimer:RoundTimer = new RoundTimer();
        
        
        public function setDodontoF(dodontoF_:DodontoF):void {
            dodontoF = dodontoF_;
            staticThis = this;
        }
        
        public function getDodontoF():DodontoF {
            return dodontoF;
        }
        
        public static function getInstance():DodontoF_Main {
            return staticThis;
        }
        
        public function setUniqueId(uniqueId_:String):void {
            this.sender.setUniqueId(uniqueId_);
        }
        
        public function setRefreshTimeout(refreshTimeout:Number):void {
            this.sender.setRefreshTimeout(refreshTimeout);
        }
        
        public function setRefreshInterval(value:Number):void {
            this.sender.setRefreshInterval(value);
        }
        
        public function getScreenWidth():int {
            return dodontoF.getScreenWidth();
        }
        
        public function getScreenHeight():int {
            return dodontoF.getScreenHeight();
        }
        
        /*
		// コンポーネントのサイズを設定する
		protected override function measure():void {
			measuredWidth = badge.x + badge.width;
			measuredHeight = reflection.y + reflection.height;
		}
        */
        
        //////////////////////////////////////////
        
        public function getGuiInputSender():GuiInputSender {
            return guiInputSender;
        }
        
        public function getRoundTimer():RoundTimer {
            return roundTimer;
        }
        
        public function getMap():Map {
            return map;
        }
        
		public function DodontoF_Main() {
        }
        
        protected function newSharedDataSender():SharedDataSender {
            /*
            if( isGoogleWave() ) {
                return new SharedDataSenderForGoogleWave();
            }
            */
            /*
            if( Config.isGaeJava() ) {
                return new SharedDataSenderForGaeJava();
            }
            */
            return new SharedDataSender();
        }
        
        /*
        public function isGoogleWave():Boolean {
            return isMode('GoogleWave');
        }
        */
        
        public function isRails():Boolean {
            return isMode('Rails');
        }
        
        public function isMySqlMode():Boolean {
            if( COMPILE::isMySql ) {
                var isMySql:Boolean = ( ! isMode('filedb') );
                return isMySql;
            }
            
            return isMode('mysql');
        }
        
        public function isSQLiteMode():Boolean {
            return isMode('sqlite');
        }
        
        public function isMySqlKaiMode():Boolean {
            return isMode('mysqlkai');
        }
        
        public function isErrorLogMode():Boolean {
            return isMode('errorLog');
        }
        
        public function isTuningLogMode():Boolean {
            return isMode('tuningLog');
        }
        
        public function isDebugLogMode():Boolean {
            return isMode('debugLog');
        }
        
        public function isCreateSmallImages():Boolean {
            return (getParams('createSmallImage') == "on" );
        }
        
        public function getStandingGraphicLayer():UIComponent {
            return dodontoF.getStandingGraphicLayer();
        }
        
        public function init():void {
            try {
                Log.logging("init start.");
                
                sender = newSharedDataSender();
                
                thisObj = this;
                
                map = new Map();
                
                Log.logging("map init.");
                map.init(this);
                
                Log.logging("init sender.");
                sender.setMap(map);
                
                Log.logging("init character.");
                MovablePiece.setSharedDataSender(sender);
                guiInputSender.setSender(sender);
                
                Log.logging("init RoundTimer.");
                roundTimer.setSender( sender );
                roundTimer.setReciever( sender.getReciever() );
                
                Log.logging("init sessionRecorder.");
                initSessionRecord();
                
                Log.logging("init end.");
                
            } catch(e:Error) {
                Log.loggingException("DodontoF_Main.DodontoF_Main()", e);
            }
        }
        
        public function loadAllSaveData():void {
            getGuiInputSender().getSender().loadAllSaveData();
        }
        
        
        public function initAfterLanguageSet():void {
            map.initContextMenu();
        }
        
        
        public function login():void {
            if( isReplayEditMode() ) {
                DodontoF.popup(EditReplayWindow, true);
                return;
            }
            
            if( isCreateSmallImages() ) {
                DodontoF.popup(CreateSmallImagesWindow, true);
                return;
            }
            
            DodontoF.popup(LoginWindow, true);
        }
        
        public function logout():void {
            if( RecordHistory.getInstance().isRecording() ) {
                Alert.show(Language.s.nowYouAreRecordingErrorMessage);
                return;
            }
            
            Utils.askByAlert(Language.s.logoutQuestionTitle, Language.s.logoutQuestion, 
                             function():void { thisObj.logoutExecute() });
        }
        
        public function logoutFromReplay():void {
            Utils.askByAlert(Language.s.returnToLoginWindow, Language.s.returnToLoginWindowQuestion, 
                             function():void { thisObj.logoutExecute() });
        }
        
        public function logoutExecute():void {
            stopSessionRecording();
            
            if( isWelcomeMessageOn ) {
                chatWindow.sendSystemMessage(Language.s.logoutMessage);
            }
            
            var url:String = logoutUrl;
            if((url == null) || (url == "")) {
                //ログアウト先の指定が無いなら、今のＵＲＬに再ログイン
                url = Utils.getOwnRawUrl();;
                url = url.replace(/loginRoom=\d+\&?/, '');
                url = url.replace(/\?$/, '');
                url = url.replace(/\&$/, '');
            }
            
            var request:URLRequest = new URLRequest( url );
            navigateToURL( request, "_self" );
        }
            
        public function setLogoutUrl(url:String):void {
            logoutUrl = url;
        }
        
        
        public function startSessionRecording(isResume:Boolean):void {
            if( isResume ) {
                chatWindow.sendSystemMessage(Language.s.resumeRecordMessage);
            } else {
                chatWindow.sendSystemMessage(Language.s.startRecordMessage);
            }
            
            var sender:SharedDataSender = getGuiInputSender().getSender();
            sender.startSessionRecording();
        }
        
        public function stopSessionRecording(action:Function = null):void {
            if( ! RecordHistory.getInstance().stopRecord() ) {
                return;
            }
            
            var history:Array = RecordHistory.getInstance().getHistory();
            
            var saveFileBaseName:String = "DodontoF_PlayRecord_";
            saveHistory(history, saveFileBaseName);
        }
        
        private var fileReferenceForSessionRecording:FileReference = new FileReference();
        
        private function initSessionRecord():void {
            fileReferenceForSessionRecording.addEventListener(Event.COMPLETE, function(event:Event):void {
                    clearHistory();
                    chatWindow.sendSystemMessage(Language.s.stopRecordMessage);
                });
        }
        
        private function clearHistory():void {
            RecordHistory.getInstance().clearHistory(dodontoF);
        }
        
        public function saveHistory(history:Array, baseName:String):void {
            var dateString:String = DodontoF_Main.getDateString();
            var saveFileName:String = baseName + dateString + ".rec";
            
            var historyString:String = Utils.getJsonString(history);
            fileReferenceForSessionRecording.save(historyString, saveFileName);
        }
        
        
        public function cancelSessionRecording():void {
            
            var reciever:SharedDataReceiver = getGuiInputSender().getSender().getReciever();
            
            Utils.askByAlert(Language.s.cancelRecordQuestionTitle,
                             Language.s.cancelRecordQuestion,
                             function():void {
                                 clearHistory();
                                 chatWindow.sendSystemMessage(Language.s.cancelRecordMessage);
                             });
        }
        
        
        public function start(isStart:Boolean):void {
            Log.logging("DodontoF_Main start begin");
            
            dodontoF.startWindows();
            
            Log.logging("DodontoF_Main setEvents");
            setEvents();
            Log.logging("DodontoF_Main setEvents　End");
            if( isStart ) {
                startRefresh();
            }
            
            Log.logging("DodontoF_Main start end");
        }
        
        private function startRefresh():void {
            
            Utils.timer(3, function():void { 
                    Log.loggingTuning("DodontoF_Main startRefresh begin");
                    sender.startRefresh();
                    Log.loggingTuning("DodontoF_Main startRefresh end");
                });
        }
        
        private function setEvents():void {
            map.setEvents();
        }
        
        public function zoom(isZoom:Boolean):void {
            map.zoom(isZoom);
        }
        
        public function setCardPickUpWindow(window:IFlexDisplayObject, eventName:String):void {
            window.visible = false;
            cardPickUpWindow = window as CardPickUpWindow;
            cardPickUpWindow.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        private var cardPickUpWindow:CardPickUpWindow = null;
        
        public function displayCardPickUp(card:Card):void {
            if( cardPickUpWindow == null ) {
                return;
            }
            cardPickUpWindow.displayCardPickUp(card);
        }
        
        public function hideCardPickUp():void {
            if( cardPickUpWindow == null ) {
                return;
            }
            cardPickUpWindow.hideCardPickUp();
        }
        
        public function setCardPickUpVisible(b:Boolean):void {
            if( cardPickUpWindow == null ) {
                return;
            }
            cardPickUpWindow..setVisibleState(b);
        }
        
        private var isCardHandleLogVisible:Boolean = true;
        
        public function setCardHandleLogVisible(b:Boolean):void {
            isCardHandleLogVisible = b;
        }
        
        public function getCardHandleLogVisible():Boolean {
            return isCardHandleLogVisible;
        }
        
        
        public function getUniqueId():String {
            return sender.getUniqueId();
        }
        
        public function getStrictlyUniqueId():String {
            return sender.getStrictlyUniqueId();
        }
        
        public function clearCards():void {
            sender.clearCards();
        }
        
        private  function getShffledIndexs(max:int):Array {
            return shuffle(getIndexs(max));
        }
        
        private  function getIndexs(max:int):Array {
            var indexs:Array = new Array();
            for(var i:int = 0 ; i < max ; i++) {
                indexs.push(i);
            }
            return indexs
        }
        
        private  function shuffle(arr:Array):Array {
            var l:int = arr.length;
            var newArr:Array = arr;
            
            while(l){
                var m:int = Math.floor(Math.random()*l);
                var n:int = newArr[--l];
                newArr[l] = newArr[m];
                newArr[m] = n;
            }
            
            return newArr;
        }
        
        
        private function getZeroPaddingString(number:Number, size:uint):String {
            var str:String = number.toString(10);
            while (str.length < size) {
                str = "0" + str;
            }
            return str;
        }
        
        private var isReplayModeOn:Boolean = false;
        
        public function isReplayMode():Boolean {
            return isReplayModeOn;
        }
        
        public function replayFromSessionRecord():void {
            setReplayMode();
            getReplay().replayFromSessionRecord();
        }
        
        public function editReplayData():void {
            var window:EditReplayWindow = DodontoF.popup(EditReplayWindow, true) as EditReplayWindow;
            window.loadReplayData();
        }
        
        private function setReplayMode():void {
            isReplayModeOn = true;
            
            diceBox.height = 0;
            diceBox.visible = false;
            
            chatWindow.nameBox.width = 0;
            chatWindow.nameBox.visible = false;
            
            dodontoF.mainMenuBody.width = 0;
            dodontoF.mainMenuBody.visible = false;
            dodontoF.speedBox.percentWidth = 100;
            dodontoF.speedBox.visible = true;
            
            chatWindow.nameBox.height = 0;
            chatWindow.chatControlBox.height = 0;
            chatWindow.publicChatChannelBox.percentHeight = 100;
            
            var isReplayMode:Boolean = true;
            var chatFontSizeForReplayMode:int = 30;//40;
            chatWindow.setChatFontSize(chatFontSizeForReplayMode, isReplayMode);
            
            //setChatChannelNames( [DodontoF_Main.publicChatChannelName] );
        }
        
        
        public function setReplaySpeed(speed:Number):void {
            getReplay().setReplaySpeed(speed);
        }
        
        public function clearForReplay():void {
            getChatWindow().clearForReplay();
            sender.clearLastUpdateTimes();
            sender.getReciever().clearChatLastWrittenTime();
            roundTimer.clearForReplay();
        }
        
        public function changeReplayPoint(point:int):void {
            getReplay().changeReplayPoint(point);
        }
        
        
        private var initiativeWindow:InitiativeWindow;
        
        public function setInitiativeWindow(window:IFlexDisplayObject, eventName:String):void {
            initiativeWindow = window as InitiativeWindow;
            initiativeWindow.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function getInitiativeWindow():InitiativeWindow {
            return initiativeWindow;
        }
        
        private var chatWindow:ChatWindow;
        
        public function setChatWindow(window:IFlexDisplayObject, eventName:String):void {
            chatWindow = window as ChatWindow;
            chatWindow.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function getChatWindow():ChatWindow {
            return chatWindow;
        }
        
        private var chatPalette:ResizableWindow;
        
        public function getChatPaletteWindow():ChatPalette2 {
            return chatPalette as ChatPalette2;
        }
        
        public function setChatPaletteWindow(window:IFlexDisplayObject, eventName:String):void {
            chatPalette = window as ResizableWindow;
            chatPalette.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function setChatPaletteVisible(v:Boolean):void {
            chatPalette.setVisibleState(v);
        }
        
        
        private var counterRemocon:CounterRemocon;
        
        public function setButtonWindow(window:IFlexDisplayObject, eventName:String):void {
            counterRemocon = window as CounterRemocon;
            counterRemocon.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function setCounterRemoconVisible(v:Boolean):void {
            counterRemocon.setVisibleState(v);
        }
        
        
        private var resourceWindow:ResourceWindow;
        
        public function setResourceWindow(window:IFlexDisplayObject, eventName:String):void {
            resourceWindow = window as ResourceWindow;
            resourceWindow.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function setResourceWindowVisible(v:Boolean):void {
            resourceWindow.setVisibleState(v);
        }
        
        
        private var diceBox:DiceBox;
        
        public function setDiceWindow(window:IFlexDisplayObject, eventName:String):void {
            diceBox = window as DiceBox;
            diceBox.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function getDiceBox():DiceBox {
            return diceBox;
        }
        
        public function getDiceBoxWidth():Number {
            return diceBox.width;
        }
        
        static public function zeroPaddingNumber(value:int, count:int = 2):String {
            var result:String = String(value);
            while (result.length < count) {
                result = "0" + result;
            }
            return result;
        }
        
        static public function getDateString():String {
            var date:Date = new Date();
            
            var dateString:String
            = StringUtil.substitute("{0}{1}{2}_{3}{4}{5}", 
                                    zeroPaddingNumber(date.fullYear, 4),
                                    zeroPaddingNumber(date.month + 1),
                                    zeroPaddingNumber(date.date),
                                    zeroPaddingNumber(date.hours),
                                    zeroPaddingNumber(date.minutes),
                                    zeroPaddingNumber(date.seconds));
            
            return dateString;
        }
        
        private function getWindowInfoSaveData(window:IFlexDisplayObject):Object {
            var windowInfo:Object = new Object();
            
            windowInfo.visible = window.visible;
            windowInfo.x = window.x;
            windowInfo.y = window.y;
            windowInfo.width = window.width;
            windowInfo.height = window.height;
            
            return windowInfo;
        }
        
        public function setDiceBoxVisible(v:Boolean):void {
            diceBox.setVisibleState(v);
        }
        
        
        public function replayFromDataUrl(url:String):void {
            setReplayMode();
            
            var textLoader:URLLoader = new URLLoader();
            textLoader.dataFormat = URLLoaderDataFormat.TEXT;//URLLoaderDataFormat.BINARY;
			textLoader.addEventListener(Event.COMPLETE, replayFromDataUrlOnComplete);
            
            
			var urlRequest:URLRequest = new URLRequest(url);
            //URL呼び出しデータのキャッシュを回避するには以下の2行が必須
            var header:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
            urlRequest.requestHeaders.push(header);
            textLoader.load(urlRequest);
        }
        
        private function replayFromDataUrlOnComplete(event:Event):void {
            var textLoader:URLLoader = event.currentTarget as URLLoader;
            var dataString:String = textLoader.data;
            //Alert.show(dataString);
            //getReplay().playReplayFromDataString( dataString );
            
            setTimeout(function():void {
                    getReplay().playReplayFromDataString( dataString );
                }, 3 * 1000);
		}

        public function pauseAndPlay():void {
            getReplay().pauseAndPlay();
        }
        
        private var replay:Replay = null;
        
        public function getReplay():Replay {
            if( replay != null ) {
                return replay;
            }
            
            replay = new Replay();
            replay.setSender(sender);
            
            return replay;
        }
        
        public function addRestChatSendDataForReplay(chatSendData:ChatSendData):void {
            getReplay().addRestChatSendDataForReplay(chatSendData);
        }
        
        public function getGlobalZoomRate():Number {
            var zoomRate:String = getParams('zoomRate') as String;
            if( zoomRate == null ) {
                return 1;
            }
            
            return parseFloat(zoomRate);
        }
        
        public function isReplayEditMode():Boolean {
            return ( getParams('isReplayEditMode') == "true" );
        }
        
        public function isReplayer():Boolean {
            return COMPILE::isReplayer;
        }
        
        public function getReplayDataUrl():String {
            var url:String = getParams('replay');
            return url
        }
        
        public function getReplayStartPosition():int {
            return parseInt( getParams('replayStartPosition') );
        }
        
        // URLで
        // DodontoF.swf?loginRoom=1
        //のようにログインする部屋番号を指定。値が指定されていない場合は-1を返す
        public function getLoginRoom():int {
            var value:String = getParams('loginRoom') as String;
            if( value == null ) {
                return -1;
            }
            
            return parseInt( value );
        }
        
        
        public function isMode(targetMode:String):Boolean {
            var modeString:String = getParams("mode");
            if( modeString == null ) {
                return false;
            }
            
            var modes:Array = modeString.split(/,/);
            
            for(var i:int = 0 ; i < modes.length ; i++) {
                var mode:String = modes[i];
                if( mode == targetMode ) {
                    return true;
                }
            }
            
            return false;
        }
        
        public function getParams(key:String):String {
            return dodontoF.parameters[key];
        }
        
        
        private var diceBotInfos:Array = new Array();
        
        public function getDiceBotInfosResult(obj:Object):void {
            var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(obj);
            setDiceBotInfos( jsonData );
        }
        
        public function setDiceBotInfos(jsonData:Object):void {
            Log.logging("setDiceBotInfos Begin");
            
            var infos:Array = jsonData as Array;
            
            if( infos == null ) {
                Log.logging("infos is NULL");
                return;
            }
            
            diceBotInfos = infos;
            
            if( chatWindow == null ) {
                return;
            }
            
            chatWindow.setDiceBotInfos(diceBotInfos);
            
            Log.logging("setDiceBotInfos End");
        }
        
        public function getDiceBotInfos():Array {
            return Utils.clone(diceBotInfos);
        }
        
        public function getDiceBotName(gameType:String):String {
            if( gameType == "diceBot" ) {
                gameType = "DiceBot";
            }
            
            var localGameName:String = Utils.getDiceBotLanguageName(gameType);
            if( localGameName != null ) {
                return localGameName;
            }
                
            
            for each(var info:Object in diceBotInfos) {
                if( info['gameType'] != gameType ) {
                    continue;
                }
                
                return info['name'];
            }
            
            return gameType;
        }
        
        
        public function initWindowPosition():void {
            initiativeWindow.setInitPositionDefault();
            chatWindow.setInitPositionDefault();
            chatPalette.setInitPositionDefault();
            diceBox.setInitPositionDefault();
            
            cardPickUpWindow.setInitPositionDefault();
        }
        
        
        private var canUseExternalImageMode:Boolean = false;
        
        public function setUseExternalImage(b:Boolean):void {
            if( Config.canUseExternalImageModeOn ) {
                canUseExternalImageMode = b;
            }
        }
        
        public function canUseExternalImage():Boolean {
            if( ! Config.canUseExternalImageModeOn ) {
                return false;
            }
            
            return canUseExternalImageMode;
        }
        
        
        public function setCanUseExternalImageModeOn( b:Boolean ):void {
            Config.canUseExternalImageModeOn = b;
        }
        
        private var isMentenanceModeOn:Boolean = false;
        private var isWelcomeMessageOn:Boolean = true;
        
        public function setMentenanceModeOn(b:Boolean):void {
            isMentenanceModeOn = b;
            
            if( isMentenanceModeOn ) {
                dodontoF.mentenanceModeButton.visible = true;
                dodontoF.mentenanceModeButton.width = 80;
            }
            dodontoF.mentenanceModeButton.selected = isMentenanceModeOn;
        }
        
        public function getMentenanceModeOn():Boolean {
            return isMentenanceModeOn;
        }
        
        public function setWelcomeMessageOn(b:Boolean):void {
            isWelcomeMessageOn = b;
        }
        
        private var loginTimeLimitSecond:int = 0;
        
        public function setLoginTimeLimitSecond(time:int):void {
            loginTimeLimitSecond = time;
        }
        
        public function getLoginTimeLimitSecond():int {
            return loginTimeLimitSecond;
        }
        
        public function getLoginTimeLimitSecondMessage():String {
            if( loginTimeLimitSecond <= 0 ) {
                return null;
            }
            
            return Messages.getMessage("loginTimeLimitWarning",
                                       [Utils.getTimeText(loginTimeLimitSecond)]);
        }
        
        public function initForFirstRefresh():void {
            getGuiInputSender().getSender().getDiceBotInfos();
            chatWindow.initForFirstRefresh(isWelcomeMessageOn);
            
            dodontoF.findMainMenuItem("pass_display").enabled = true;
            
            checkRecording();
        }

        private function checkRecording():void {
            
            if( ! RecordHistory.getInstance().isHaveHistory() ) {
                return;
            }
            
            dodontoF.startSessionRecording(true);
        }
        
        
        
        private var localReplayMode:Boolean = false;
        public function isLocalReplayMode():Boolean {
            return localReplayMode;
        }
        public function setLocalReplayMode(b:Boolean):void {
            localReplayMode = b;
        }
        
        public function getMenuXml():Array {
            var menuXml:Array = getMenuXmlDefault();
            return Utils.clone(menuXml);
        }
        
        
        private function getMenuXmlDefault():Array {
            return [
    {label:Language.s.fileMenu, data:"pass_file",
     children: [
        {label:Language.s.saveMenu, data:"save"},
        {label:Language.s.loadMenu, data:"load"},
        {type:"separator"},
        {label:Language.s.saveAllDataMenu, data:"saveAllData"},
        {label:Language.s.loadAllSaveDataMenu, data:"loadAllSaveData"},
        {type:"separator"},
        {label:Language.s.saveLogMenu, data:"saveLog"},
        {type:"separator"},
        {label:Language.s.startSessionRecordingMenu, data:"startSessionRecording", enabled:"true"},
        {label:Language.s.stopSessionRecordingMenu, data:"stopSessionRecording", enabled:"false"},
        {label:Language.s.cancelSessionRecordingMenu, data:"cancelSessionRecording", enabled:"false"},
        {type:"separator"},
        {label:Language.s.logoutMenu, data:"logout", enabled:"true"},
                ]},

    {label:Language.s.displayMenu, data:"pass_display", enabled:"true",
     children: [
                {label:Language.s.displayWindowMenu, data:"pass_displayWindow", enabled:"true",
                        children: [
                                   {label:Language.s.isChatVisibleMenu, data:"isChatVisible", type:"check", toggled:true},
                                   {label:Language.s.isDiceVisibleMenu, data:"isDiceVisible", type:"check", toggled:true},
                                   {label:Language.s.isInitiativeListVisibleMenu, data:"isInitiativeListVisible", type:"check", toggled:true},
                                   {label:Language.s.isResourceWindowVisibleMenu, data:"isResourceWindowVisible", type:"check", toggled:false},
                                   {type:"separator"},
                                   {label:Language.s.isChatPaletteVisibleMenu, data:"isChatPaletteVisible", type:"check", toggled:false},
                                   {label:Language.s.isCounterRemoconVisibleMenu, data:"isCounterRemoconVisible", type:"check", toggled:false}]},
        {type:"separator"},
        
        {label:Language.s.isStandingGraphicVisibleMenu, data:"isStandingGraphicVisible", type:"check", toggled:true},
        {label:Language.s.isCutInVisibleMenu, data:"isCutInVisible", type:"check", toggled:true},
        {type:"separator"},
        
        {label:Language.s.isPositionVisibleMenu, data:"isPositionVisible", type:"check", toggled:true},
        {label:Language.s.isGridVisibleMenu, data:"isGridVisible", type:"check", toggled:true},
        {type:"separator"},
        
        {label:Language.s.isSnapMovablePieceMenu, data:"isSnapMovablePiece", type:"check", toggled:true},
        {label:Language.s.isAdjustImageSizeMenu, data:"isAdjustImageSize", type:"check", toggled:Config.isAdjustImageSizeDefault()},
        {type:"separator"},
        
        {label:Language.s.changeFontSize, data:"changeFontSize"},
        {type:"separator"},
        
        {label:Language.s.initWindowPositionMenu, data:"initWindowPosition"},
        {label:Language.s.initLocalSaveDataMenu, data:"initLocalSaveData"}
        
                ]},
    
    {label:Language.s.pieceMenu, data:"pass_piece",
     children: [
        {label:Language.s.addCharacterMenu, data:"addCharacter"},
        {label:Language.s.addRangeMenu, data:"pass_range",
                children: [
                           {label:Language.s.addMagicRangeMenu, data:"addMagicRange"},
                           {label:Language.s.addMagicRangeDD4thMenu, data:"addMagicRangeDD4th"},
                           {label:Language.s.addLogHorizonRangeMenu, data:"addLogHorizonRange"},
                           {label:Language.s.addMetallicGuardianDamageRangeMenu, data:"addMetallicGuardianDamageRange"},
                           ]},
        {label:Language.s.addMagicTimerMenu, data:"addMagicTimer"},
        {type:"separator"},
        {label:Language.s.createChitMenu, data:"createChit"},
        {type:"separator"},
        {label:Language.s.graveyardMenu, data:"graveyard"},
        {label:Language.s.characterWaitingRoomMenu, data:"characterWaitingRoom"},
        {type:"separator"},
        {label:Language.s.isRotateMarkerVisibleMenu, data:"isRotateMarkerVisible", type:"check", toggled:true},
                ]},
    
    {label:Language.s.cardMenu, data:"pass_card",
     children: [
        {label:Language.s.isCardPickUpVisibleMenu, data:"isCardPickUpVisible", type:"check", toggled:false},
        {label:Language.s.isCardHandleLogVisibleMenu, data:"isCardHandleLogVisible", type:"check", toggled:true},
        {type:"separator"},
        {label:Language.s.openInitCardWindowMenu, data:"openInitCardWindow"},
        {type:"separator"},
        {label:Language.s.cleanCardMenu, data:"cleanCard"}
                ]},
    
    {label:Language.s.mapMenu, data:"pass_map",
     children: [
        {label:Language.s.changeMapMenu, data:"changeMap"},
        {label:Language.s.changeFloorTileMenu, data:"changeFloorTile"},
        {label:Language.s.addMapMaskMenu, data:"addMapMask"},
        {label:Language.s.createMapEasyMenu, data:"createMapEasy"},
        {type:"separator"},
        {label:Language.s.saveMapMenu, data:"saveMap"},
        {label:Language.s.loadMapMenu, data:"loadMap"},
                ]},
    {label:Language.s.imageMenu, data:"pass_image",
     children: [
        {label:Language.s.imageFileUploaderMenu, data:"imageFileUploader"},
        {label:Language.s.webcameraCaptureUploaderMenu, data:"webcameraCaptureUploader"},
        {type:"separator"},
        {label:Language.s.openImageTagManagerMenu, data:"openImageTagManager"},
        {label:Language.s.deleteImageMenu, data:"deleteImage"}
                ]},
    
    {label:Language.s.helpMenu, data:"pass_help",
            children: [
                       {label:Language.s.versionMenu, data:"version"},
                       {label:Language.s.manualMenu, data:"manual"},
                       {label:Language.s.tutorialReplayMenu, data:"tutorialReplay"},
                       {label:Language.s.officialSiteMenu, data:"officialSite"}
                       ]
            }
    
    /*
    ,
    {label:"LOG", data:"pass_log", 
     children: [
        {label:"initLogWindow", data:"initLogWindow"}, 
        {type:"separator"}, 
        {label:"debugLog", data:"debugLog"}, 
        {label:"tuningLog", data:"tuningLog"}, 
        {label:"errorLog", data:"errorLog"}, 
        {label:"fatalErrorLog", data:"fatalErrorLog"} 
                ]} 
    */
                    ];
        }
	}
    
}

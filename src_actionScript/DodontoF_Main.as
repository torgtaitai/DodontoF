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
    import mx.collections.ArrayCollection;
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.core.IFlexDisplayObject;
    import mx.managers.BrowserManager;
    import mx.utils.StringUtil;
    
    
	public class DodontoF_Main extends UIComponent {
        
        [Bindable] public var standingGraphicInfos:ArrayCollection = new ArrayCollection();
        
        /*
        [Bindable] public var visibleDirectionLayer:Boolean = false;
        
        public function setVisibleDirectionLayer(b:Boolean):void {
            visibleDirectionLayer = b;
        }
        */
        
        
        private var playRoomName:String = "";
        private var playRoomPassword:String = "";
        static private var defaultChatChannelNames:Array = [publicChatChannelName, "雑談"];
        private var chatChannelNames:Array = Utils.clone(defaultChatChannelNames);
        private var canVisitValue:Boolean = false;
        
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
            canUseExternalImageMode = local_canUseExternalImageMode;
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
            return "メイン";
        }
        
        private var visiterMode:Boolean = false;
        public function isVisiterMode():Boolean {
            return visiterMode;
        }
        
        public function setVisiterMode(b:Boolean):void {
            visiterMode = b;
            Log.logging("DodontoF_Main.setVisiterMode visiterMode", visiterMode);
            
            if( chatWindow != null ) {
                chatWindow.changeVisiterMode();
            }
        }
        
        public function setEffects(effects:ArrayCollection):void {
            var tmpCutInInfos:ArrayCollection = new ArrayCollection();
            var tmpStandingGraphicInfos:ArrayCollection =  new ArrayCollection();
            
            for(var i:int = 0 ; i < effects.length ; i++) {
                var effect:Object = effects[i];
                if( effect.type == StandingGraphics.getTypeStatic() ) {
                    tmpStandingGraphicInfos.addItem(effect);
                } else {
                    tmpCutInInfos.addItem(effect);
                }
            }
            
            CutInBase.setCutInInfos(tmpCutInInfos);
            standingGraphicInfos = tmpStandingGraphicInfos;
            
            chatWindow.setStandingGraphics(standingGraphicInfos);
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
                
                initForTiny();
                
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
                
                Log.logging("init end.");
                
            } catch(e:Error) {
                Log.loggingException("DodontoF_Main.DodontoF_Main()", e);
            }
        }
        
        public function setStockCharacterWindow(window:StockCharacterWindow):void {
            if( ! isTinyMode() ) {
                return;
            }
            
            hideForTiny(window.isMany);
        }
        
        public function setCharacterWindow(characterWindow:CharacterWindow):void {
            if( ! isTinyMode() ) {
                return;
            }
            
            hideForTiny(characterWindow.otherInfos);
            hideForTiny(characterWindow.characterSizeBox);
            characterWindow.height = 400;
        }
        
        public function initWindowForTiny():void {
            if( ! isTinyMode() ) {
                return;
            }
            
            initiativeWindow.visible = false;
            
            hideForTiny(chatWindow.diceBotGameType);
            hideForTiny(chatWindow.secretTalkButton);
            hideForTiny(chatWindow.sendButtonBox);
            hideForTiny(chatWindow.voteImage);
            hideForTiny(chatWindow.sendSoundButton);
            hideForTiny(chatWindow.novelticModeButton);
            
            chatPalette.visible = false;
            
            diceBox.visible = false;
            diceBox.width = 0;
        }
        
        private function initForTiny():void {
            if( ! isTinyMode() ) {
                menuXml = getMenuXmlDefault();
                map = new Map();
                return;
            }
            
            menuXml = getMenuXmlTiny();
            map = new MapForTiny();
            
            hideForTiny(dodontoF.zoomInButton);
            hideForTiny(dodontoF.zoomOutButton);
            hideForTiny(dodontoF.sharedMemo);
            ChatWindow.setDiceBotOn( false );
            
            hideForTiny(dodontoF.graveyard);
        }
        
        private function hideForTiny(comp:UIComponent):void {
            comp.visible = false;
            comp.width = 0;
            comp.height = 0;
            comp.enabled = false;
        }
        

        public function uploadScenarioData():void {
            getGuiInputSender().getSender().uploadScenarioData();
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
            if( isSessionRecording() ) {
                Alert.show("録画中です。ログアウトするには録画を終了してください。");
                return;
            }
            
            Utils.askByAlert("ログアウト確認", "ログアウトしてよろしいですか？", 
                             function():void { thisObj.logoutExecute() });
        }
        
        public function logoutExecute():void {
            stopSessionRecording();
            
            if( isWelcomeMessageOn ) {
                chatWindow.sendSystemMessage("がログアウトしました。");
            }
            
            //今のＵＲＬに再ログイン
            var url:String = Utils.getOwnRawUrl();;
            url = url.replace(/loginRoom=\d+\&?/, '');
            url = url.replace(/\?$/, '');
            url = url.replace(/\&$/, '');
            var currentUrl:URLRequest = new URLRequest( url );
            navigateToURL( currentUrl, "_self" );
        }
        
        public function isSessionRecording():Boolean {
            return getGuiInputSender().getSender().getReciever().isSessionRecording();
        }
        
        public function startSessionRecording():void {
            chatWindow.sendSystemMessage("が録画を開始しました。");
            var sender:SharedDataSender = getGuiInputSender().getSender();
            sender.startSessionRecording();
        }
        
        public function stopSessionRecording():void {
            var reciever:SharedDataReceiver = getGuiInputSender().getSender().getReciever();
            if( ! reciever.stopHistory() ) {
                return;
            }
            
            var history:Array = reciever.getHistory();
            
            var saveFileBaseName:String = "DodontoF_PlayRecord_";
            saveHistory(history, saveFileBaseName);
            
            chatWindow.sendSystemMessage("の録画が終了しました。");
        }
        
        private var fileReferenceForSessionRecording:FileReference = new FileReference();
        
        public function saveHistory(history:Array, baseName:String):void {
            var dateString:String = DodontoF_Main.getDateString();
            var saveFileName:String = baseName + dateString + ".rec";
            
            var historyString:String = Utils.getJsonString(history);
            fileReferenceForSessionRecording.save(historyString, saveFileName);
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
        
        public function setRulerMode():void {
            map.setRulerMode();
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
        
        private var buttonBox:ButtonBox;
        
        public function setButtonWindow(window:IFlexDisplayObject, eventName:String):void {
            buttonBox = window as ButtonBox;
            buttonBox.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function setButtonBoxVisible(v:Boolean):void {
            buttonBox.setVisibleState(v);
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
            if( isTinyMode() ) {
                return 0;
            }
            
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
        
        //無効な場合は-1を返す
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
            
            for each(var info:Object in diceBotInfos) {
                    if( info['gameType'] == gameType ) {
                        return info["name"];
                    }
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
        
        
        private var canUseExternalImageMode:Boolean = false
        
        public function setUseExternalImage(b:Boolean):void {
            canUseExternalImageMode = b;
        }
        
        public function canUseExternalImage():Boolean {
            return canUseExternalImageMode;
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
        }
        
        private var localReplayMode:Boolean = false;
        public function isLocalReplayMode():Boolean {
            return localReplayMode;
        }
        public function setLocalReplayMode(b:Boolean):void {
            localReplayMode = b;
        }
        
        public function isTinyMode():Boolean {
            return isMode("tiny");
        }
        
        private var menuXml:Array;
        
        public function getMenuXml():Array {
            return Utils.clone(menuXml);
        }
        
        private function getMenuXmlTiny():Array {
            return [
                    {label:"ファイル", data:"pass",
                            children: [
                                       {label:"チャットログ保存", data:"saveLog"},
                                       {label:"録画開始", data:"startSessionRecording", enabled:"true"},
                                       {label:"録画終了", data:"stopSessionRecording", enabled:"false"},
                                       {label:"ログアウト", data:"logout", enabled:"true"},
                                       ]},
                    
                    {label:"表示", data:"pass_display", enabled:"true",
                            children: [
                                       {label:"立ち絵のサイズを自動調整する", data:"isAdjustImageSize", type:"check", toggled:Config.isAdjustImageSizeDefault()},
                                       {type:"separator"},
                                       {label:"背景変更", data:"changeMap"},
                                       ]},
                    
                    {label:"画像", data:"pass",
                            children: [
                                       {label:"ファイルアップローダー", data:"imageFileUploader"},
                                       {label:"タグ編集", data:"openImageTagManager"},
                                       {label:"画像削除", data:"deleteImage"}
                                       ]},
                    ];            
        }
        
        private function getMenuXmlDefault():Array {
            return [
    {label:"ファイル", data:"pass",
     children: [
        {label:"セーブ", data:"save"},
        {label:"ロード", data:"load"},
        {type:"separator"},
        {label:"全データセーブ", data:"saveScenarioData"},
        {label:"全データロード(旧：シナリオデータ読み込み)", data:"uploadScenarioData"},
        {type:"separator"},
        {label:"チャットログ保存", data:"saveLog"},
        {label:"録画開始", data:"startSessionRecording", enabled:"true"},
        {label:"録画終了", data:"stopSessionRecording", enabled:"false"},
        {type:"separator"},
        {label:"ログアウト", data:"logout", enabled:"true"},
                ]},

    {label:"表示", data:"pass_display", enabled:"true",
     children: [
        {label:"チャットパレット表示", data:"isChatPaletteVisible", type:"check", toggled:false},
        {label:"カウンターリモコン表示", data:"isButtonBoxVisible", type:"check", toggled:false},
        {type:"separator"},
        
        {label:"チャット表示", data:"isChatVisible", type:"check", toggled:true},
        {label:"ダイス表示", data:"isDiceVisible", type:"check", toggled:true},
        {label:"イニシアティブ表示", data:"isInitiativeListVisible", type:"check", toggled:true},
        {type:"separator"},
        
        {label:"立ち絵表示", data:"isStandingGraphicVisible", type:"check", toggled:true},
        {label:"カットイン表示", data:"isCutInVisible", type:"check", toggled:true},
        {type:"separator"},
        
        {label:"座標表示", data:"isPositionVisible", type:"check", toggled:true},
        {label:"マス目表示", data:"isGridVisible", type:"check", toggled:true},
        {type:"separator"},
        
        {label:"マス目にキャラクターを合わせる", data:"isSnapMovablePiece", type:"check", toggled:true},
        {label:"立ち絵のサイズを自動調整する", data:"isAdjustImageSize", type:"check", toggled:Config.isAdjustImageSizeDefault()},
        {type:"separator"},
        
        {label:"ウィンドウ配置初期化", data:"initWindowPosition"},
        {label:"表示状態初期化", data:"initLocalSaveData"}
        
                ]},
    
    {label:"コマ", data:"pass",
     children: [
        {label:"キャラクター追加", data:"addCharacter"},
        {label:"魔法範囲追加(D&D3版)", data:"addMagicRange"},
        {label:"魔法範囲追加(D&D4版)", data:"addMagicRangeDD4th"},
        {label:"魔法タイマー追加", data:"addMagicTimer"},
        {type:"separator"},
        {label:"チット作成", data:"createChit"},
        {type:"separator"},
        {label:"墓場", data:"graveyard"},
        {label:"キャラクター待合室", data:"characterWaitingRoom"},
        {type:"separator"},
        {label:"回転マーカーを表示する", data:"isRotateMarkerVisible", type:"check", toggled:true},
                ]},
    
    {label:"カード", data:"pass_card",
     children: [
        {label:"カードピックアップウィンドウ表示", data:"isCardPickUpVisible", type:"check", toggled:false},
        {type:"separator"},
        {label:"カード配置の初期化", data:"openInitCardWindow"},
        {type:"separator"},
        {label:"カードの全削除", data:"cleanCard"}
                ]},
    
    {label:"マップ", data:"pass",
     children: [
        {label:"マップ変更", data:"changeMap"},
        {label:"フロアタイル変更モード", data:"changeFloorTile"},
        {label:"マップマスク追加", data:"addMapMask"},
        {label:"簡易マップ作成", data:"createMapEasy"},
        {type:"separator"},
        {label:"マップ状態保存", data:"saveMap"},
        {label:"マップ切り替え", data:"loadMap"},
                ]},
    {label:"画像", data:"pass",
     children: [
        {label:"ファイルアップローダー", data:"imageFileUploader"},
        //{label:"URLアップローダー", data:"imageUrlUploader"},
        {label:"WEBカメラ撮影", data:"webcameraCaptureUploader"},
        {type:"separator"},
        {label:"タグ編集", data:"openImageTagManager"},
        {label:"画像削除", data:"deleteImage"}
                ]},
    
    {label:"ヘルプ", data:"pass",
            children: [
                       {label:"バージョン", data:"version"},
                       {label:"マニュアル", data:"manual"},
                       {label:"チュートリアル動画", data:"tutorialReplay"},
                       {label:"オフィシャルサイトへ", data:"officialSite"}
                       ]
            }
    
    /*
    ,
    {label:"ログ", data:"pass", 
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

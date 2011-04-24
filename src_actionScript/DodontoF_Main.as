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
    import flash.system.Capabilities;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.setTimeout;
    import mx.collections.ArrayCollection;
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.core.IFlexDisplayObject;
    import mx.events.CloseEvent;
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
        
        public function getPlayRoomName():String {
            return Utils.clone(playRoomName);
        }
        
        public function getPlayRoomPassword():String {
            return Utils.clone(playRoomPassword);
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
        
        public function setPlayRoomInfo(local_playRoomName:String,
                                        local_chatChannelNames:Array,
                                        local_canUseExternalImageMode:Boolean,
                                        local_canVisit:Boolean):void {
            if( local_playRoomName == "" ) {
                return;
            }
            
            playRoomName = local_playRoomName;
            //playRoomPassword = local_password;
            canUseExternalImageMode = local_canUseExternalImageMode;
            canVisitValue = local_canVisit;
            
            setChatChannelNames(local_chatChannelNames);
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
        
        public function setRefreshTimeout(refreshTimeout:int):void {
            this.sender.setRefreshTimeout(refreshTimeout);
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
            if( Config.isGaeJava() ) {
                return new SharedDataSenderForGaeJava();
            }
            return new SharedDataSender();
        }
        
        /*
        public function isGoogleWave():Boolean {
            return isMode('GoogleWave');
        }
        */
        
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
            hideForTiny(characterWindow.characterImageUrlItem);
            hideForTiny(characterWindow.underNameBox);
            hideForTiny(characterWindow.characterSizeBox);
            hideForTiny(characterWindow.hideCheckBox);
            characterWindow.height = 400;
            characterWindow.inputBox.height = 80;
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
            
            var result:Alert = Alert.show("ログアウトしてよろしいですか？", "ログアウト確認", 
                                          Alert.OK | Alert.CANCEL, null, 
                                          function(e : CloseEvent) : void {
                                              if (e.detail == Alert.OK) {
                                                  thisObj.logoutExecute();
                                              }});
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
            return DodontoF_Main.getInstance().getGuiInputSender().getSender().getReciever().isSessionRecording();
        }
        
        public function startSessionRecording():void {
            chatWindow.sendSystemMessage("が録画を開始しました。");
            var sender:SharedDataSender = DodontoF_Main.getInstance().getGuiInputSender().getSender();
            sender.startSessionRecording();
        }
        
        public function stopSessionRecording():void {
            var reciever:SharedDataReceiver = DodontoF_Main.getInstance().getGuiInputSender().getSender().getReciever();
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
            Log.logging("DodontoF_Main setEvents");
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
            Log.logging("setEventsWheel");
            setEventsWheel();
            
            Log.logging("this addEventListener MOUSE_DOWN");
            this.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    //deckStateManager.stopAllDrag();
                });
            
            Log.logging("map.setEvents() calling...");
            map.setEvents();
        }
        
        private function zoomCheck(isZoom:Boolean, mouseX:int, mouseY:int):void {
            if( map.getCardLayer().visible && 
                map.getCardLayer().hitTestPoint(mouseX, mouseY) ) {
                map.zoomCardLayer(isZoom);
            } else {
                map.zoom(isZoom);
            }
        }
        
        private function setEventsWheel():void {
            var mapWheelEvent:Function = function (event:MouseEvent):void {
                var isZoom:Boolean = (event.delta > 0);
                map.zoom(isZoom);
            };
            map.getView().addEventListener(MouseEvent.MOUSE_WHEEL, mapWheelEvent);
            
            var cardWheelEvent:Function = function (event:MouseEvent):void {
                var isZoom:Boolean = (event.delta > 0);
                map.zoomCardLayer(isZoom);
            };
            map.getCardLayer().addEventListener(MouseEvent.MOUSE_WHEEL, cardWheelEvent);
        }
        
        public function zoom(isZoom:Boolean):void {
            zoomCheck(isZoom, 0, 0);
        }
        
        
        private var cardPreviewWindow:CardPreviewWindow = null;
        
        private function getCardPreviewWindow():CardPreviewWindow {
            if( cardPreviewWindow == null ) {
                cardPreviewWindow = DodontoF.popup(CardPreviewWindow, false) as CardPreviewWindow;
            }
            
            return cardPreviewWindow;
        }
        
        public function displayCardPreview(card:Card):void {
            getCardPreviewWindow().displayCardPreview(card);
        }
        
        public function hideCardPreview():void {
            getCardPreviewWindow().hideCardPreview();
        }
        
        public function setVisibleCardPreview(b:Boolean):void {
            if( ! b ) {
                if( cardPreviewWindow == null ) {
                    return;
                }
            }
            
            getCardPreviewWindow().setVisibleState(b);
        }
        
        public function setRulerMode():void {
            map.setRulerMode();
        }
        
        static public function getFlashVersion():int {
            var fullVersionString:String = flash.system.Capabilities.version
            Log.loggingTuning(fullVersionString, "fullVersionString"); //output MAC 9,0,115,0
            
            var versionNoString:String = fullVersionString.split(" ")[1].split(",")[0];
            Log.loggingTuning(versionNoString, "versionNoString"); //9
            
            var version:int = parseInt(versionNoString);
            Log.loggingTuning("version", version); //9
            
            return version;
        }
        
        static public function isFileRefecenseLoadMethodSupportVersion():Boolean {
            var version:int = getFlashVersion();
            
            if ( version < 10) {
                return false;
            }
            return true;
        }
        
        public function getUniqueId():String {
            return sender.getUniqueId();
        }
        
        public function clearCards():void {
            sender.clearCards();
        }
        public function initCards(cardTypes:Array):void {
            sender.initCards(cardTypes);
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
            chatWindow.chatMessageLogBox.percentHeight = 100;
            
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
        
        public function setChatPaletteWindow(window:IFlexDisplayObject, eventName:String):void {
            chatPalette = window as ResizableWindow;
            chatPalette.setChangeVisibleEvent( function(visible:Boolean):void {
                    dodontoF.changeMainMenuToggle(eventName, visible);
                });
        }
        
        public function setChatPaletteVisible(v:Boolean):void {
            chatPalette.setVisibleState(v);
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
        
        public function addRestChatMessageForReplay(messageData:Object):void {
            getReplay().addRestChatMessageForReplay(messageData);
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
        
        public function setDiceBotInfos(info:Array):void {
            diceBotInfos = info;
        }
        
        public function getDiceBotInfos():Array {
            return Utils.clone(diceBotInfos);
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
            }
            dodontoF.mentenanceModeButton.selected = isMentenanceModeOn;
        }
        
        public function getMentenanceModeOn():Boolean {
            return isMentenanceModeOn;
        }
        
        public function setWelcomeMessageOn(b:Boolean):void {
            isWelcomeMessageOn = b;
        }
        
        public function initForFirstRefresh():void {
            chatWindow.initForFirstRefresh(isWelcomeMessageOn);
            Config.getInstance().loadViewStateInfo();
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
        {label:"チャットログ保存", data:"saveLog"},
        {label:"録画開始", data:"startSessionRecording", enabled:"true"},
        {label:"録画終了", data:"stopSessionRecording", enabled:"false"},
        {label:"ログアウト", data:"logout", enabled:"true"},
                ]},

    {label:"表示", data:"pass_display", enabled:"true",
     children: [
        {label:"表示状態初期化", data:"initLocalSaveData"},
        {type:"separator"},
        {label:"マス目にキャラクターを合わせる", data:"isSnapMovablePiece", type:"check", toggled:true},
        {label:"立ち絵のサイズを自動調整する", data:"isAdjustImageSize", type:"check", toggled:Config.isAdjustImageSizeDefault()},
        {type:"separator"},
        {label:"チャット表示", data:"isChatVisible", type:"check", toggled:true},
        {label:"ダイス表示", data:"isDiceVisible", type:"check", toggled:true},
        {label:"イニシアティブ表示", data:"isInitiativeListVisible", type:"check", toggled:true},
        {label:"チャットパレット表示", data:"isChatPaletteVisible", type:"check", toggled:false},
        
        {label:"カード表示", data:"isCardVisible", type:"check", toggled:false},
        {label:"立ち絵表示", data:"isStandingGraphicVisible", type:"check", toggled:true},
        {label:"マップ表示", data:"isMapVisible", type:"check", toggled:true},
        {label:"座標表示", data:"isPositionVisible", type:"check", toggled:true},
        {label:"マップのマス目表示", data:"isGridVisible", type:"check", toggled:true}
        //{label:"キャラクターの向き表示", data:"isDirectionVisible", type:"check", toggled:false}
                ]},
    
    {label:"コマ", data:"pass",
     children: [
        {label:"キャラクター追加", data:"addCharacter"},
        {label:"魔法範囲追加(D&D3版)", data:"addMagicRange"},
        {label:"魔法範囲追加(D&D4版)", data:"addMagicRangeDD4th"},
        {label:"魔法タイマー追加", data:"addMagicTimer"},
        {label:"墓場", data:"graveyard"},
        /*
        {type:"separator"},
        {label:"キャラクター待合室", data:"characterWaitingRoom"},
        */
                ]},
    
    {label:"カード", data:"pass",
     children: [
        {label:"カード初期化画面を開く", data:"openInitCardWindow"}
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
            },
    
    /*
    ,{label:"ログ", data:"pass", 
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

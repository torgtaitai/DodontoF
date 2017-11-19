//--*-coding:utf-8-*--

package {
    import flash.net.SharedObject;
    import flash.net.URLRequest;
    import mx.controls.Alert;
    import flash.events.MouseEvent;
    
    public class Config {
        static private var thisObj:Config = new Config();
        static private var saveDataKey:String = "DodontoF_LocalSaveData";
        
        static public function getInstance():Config {
            return thisObj;
        }
        
        private var version:String = "Ver.1.48.32.1(2017/11/19)";
        
        public function getVersion():String {
            return version;
        }
                
        private var localUrlPrefix:String = null;
        
        public function Config() {
        }
        
        
        private function getPlayRoomNumber():int {
            var playRoomNumber:int =  + DodontoF_Main.getInstance().getPlayRoomNumber();
            return playRoomNumber;
        }
        
        private function getSaveData(isGlobal:Boolean):SharedObject {
            
            var key:String = saveDataKey;
            
            if( ! isGlobal ) {
                key +=  "_" + getPlayRoomNumber();
            }
            
            return SharedObject.getLocal(key);
        }
        
        
        private var mouseEvent:MouseEvent;
        public function setMouseEvent(event:MouseEvent):void {
            mouseEvent = event;
        }
        
        private var isSnapMovablePiece:Boolean= true;
        
        public function setSnapMovablePiece(b:Boolean):void {
            isSnapMovablePiece = b;
            saveViewStateInfo();
        }
        
        public function isSnapMovablePieceMode():Boolean {
            if( mouseEvent != null ) {
                if( mouseEvent.altKey ) {
                    return false;
                }
            }
            return isSnapMovablePiece;
        }
        
        static public function isAdjustImageSizeDefault():Boolean {
            return true;
        }
        
        private var isAdjustImageSize:Boolean = isAdjustImageSizeDefault();
        
        public function setAdjustImageSizeMode(b:Boolean):void {
            isAdjustImageSize = b;
            saveViewStateInfo();
        }
        
        public function isAdjustImageSizeMode():Boolean {
            return isAdjustImageSize;
        }
        
        
        public function getDodontoFServerCgiUrl():String {
            var cgiUrl:String = "DodontoFServer.rb";
            
            if( DodontoF_Main.getInstance().isMySqlKaiMode() ) {
                cgiUrl = "DodontoFServerMySqlKai.rb";
            }
            
            if( DodontoF_Main.getInstance().isMySqlMode() ) {
                cgiUrl = "DodontoFServerMySql.rb";
            }
            
            cgiUrl = getUrlString(cgiUrl);
            
            return cgiUrl;
        }
        
        public function getImageUploaderUrl():String {
            return getDodontoFServerCgiUrl();
        }
        
        public function getUrlString(url:String):String {
            if( url == null ) {
                return url;
            }
            
            if( url == "" ) {
                return url;
            }
            
            url = changeUrlByUploadDirInfo(url);
            
            if(localUrlPrefix != null) {
                if( url.search(localUrlPrefix) == 0 ) {
                    return url;
                }
            }
            
            if( url.search('https?://') == 0 ) {
                url = Utils.getLocalImageUrl(url);
                return url;
            }
            
            if(localUrlPrefix != null) {
                url = localUrlPrefix + url;
            }
            
            return url;
        }
        
        private var skinImageUrl:String;
        
        public function setSkinImageUrl(url:String):void {
            skinImageUrl = getUrlString(url);
        }
        
        public function getSkinImageUrl():String {
            Log.logging("getSkinImageUrl skinImageUrl", skinImageUrl);
            return skinImageUrl;
        }
        
        public function getOriginalUrlString(url:String):String {
            if(localUrlPrefix == null) {
                return url;
            }
            
            if( url == null) {
                return url;
            }
            
            return url.replace(localUrlPrefix, '');
        }
        
        public function getFileImageUrl():String {
            return getUrlString("image/film.png");
        }
        
        
        private var fontSizeSaveKey:String = "fontSize";
        public function saveFontInfo():void {
            var info:Object = {"size": fontSize};
            var isGlobal:Boolean = true;
            saveInfo(fontSizeSaveKey, info, isGlobal);
        }
        
        public function loadFontInfo():void {
            var isGlobal:Boolean = true;
            var info:Object = loadInfo(fontSizeSaveKey, isGlobal);
            if( info == null || info.size == null ) {
                return;
            }
            
            if( fontSize == info.size ) {
                return;
            }
            
            setFontSize( info.size );
        }
        
        public function saveInfo(key:String, info:Object, isGlobal:Boolean = false):void {
            var saveData:SharedObject = getSaveData(isGlobal);
            saveData.data[key] = info
            saveData.flush();
        }
        
        private var tinyModePrefix:String = "tinyMode:";
        
        public function loadInfo(key:String, isGlobal:Boolean = false):Object {
            
            //リプレイモードでは常にデフォルト構成に
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                return null;
            }
            
            var saveData:SharedObject = getSaveData(isGlobal);
            var info:Object = saveData.data[key];
            return info;
        }
        
        public function setToDefaultInfo():void {
            var saveData:SharedObject = getSaveData(false);
            saveData.clear();
            saveData.flush();
            
            saveData = getSaveData(true);
            saveData.clear();
            saveData.flush();
        }
        
        
        private var saveInfoKeyNameForViewState:String = "ViewState";
        
        /*
         * サーバのセーブデータの方が新しくて書き換えが行われる場合には戻り値は true
         */
        public function checkViewStateKey(key:String):Boolean {
            if( key == null ) {
                return false;
            }
            
            var info:Object = loadInfo( saveInfoKeyNameForViewState );
            
            if( info != null ) {
                if( info.key == key ) {
                    Log.logging("セーブデータのキー（書き込み時間）は同一。ってことは以前部屋設定してから変えていない。そのためサーバの設定は反映せずにスルー。");
                    return false;
                }
            }
            
            Log.logging("セーブデータのキー（書き込み時間）が今までと異なるなら、これまでの表示状態は破棄");
            var newInfo:Object = new Object();
            newInfo.key = key;
            saveInfo(saveInfoKeyNameForViewState, newInfo);
            
            return true;
        }
        
        
        private var loginSaveDataKey:String = "loginInfo";
        
        public function loadLoginInfo():Object {
            return Config.getInstance().loadInfo(loginSaveDataKey);
        }
        
        public function saveLoginInfo(loginInfo:Object):void {
            saveInfo(loginSaveDataKey, loginInfo);
        }
        
        
        public function loadInfoForResiableWindow(key:String):Object {
            var info:Object = loadInfo( saveInfoKeyNameForViewState );
            if( info == null ) {
                info = new Object();
            }
            
            return info[key];
        }
        
        public function loadViewStateInfo(serverInfo:Object):void {
            if( serverInfo == null ) {
                serverInfo = new Object();
            }
            
            Log.logging("serverInfo", serverInfo);
            var key:String = serverInfo.key;
            
            var isUseServer:Boolean = checkViewStateKey(key);
            
            var info:Object = loadInfo( saveInfoKeyNameForViewState );
            if( info == null ) {
                info = new Object();
            }
            
            loadToggleState( serverInfo, info, "isSnapMovablePiece",
                             function(v:Boolean):void {isSnapMovablePiece = v} );
            loadToggleState( serverInfo, info, "isAdjustImageSize",
                             function(v:Boolean):void {isAdjustImageSize = v} );
            loadToggleState( serverInfo, info, "isStandingGraphicVisible",
                             getDodontoFM().getChatWindow().setStandingGraphicsDisplayState );
            loadToggleState( serverInfo, info, "isCutInVisible",
                             setCutInDisplayState );
            loadToggleState( serverInfo, info, "isPositionVisible",
                             getDodontoFM().getMap().setVisibleGridPositionLayer );
            loadToggleState( serverInfo, info, "isGridVisible",
                             getDodontoFM().getMap().setVisibleGridLayer );
            loadToggleState( serverInfo, info, "isRotateMarkerVisible",
                             Rotater.setGlobalVisible );
            loadToggleState( serverInfo, info, "isCardHandleLogVisible",
                             getDodontoFM().setCardHandleLogVisible);
            
            if( isUseServer ) {
                loadToggleStateForRisizableWindow(serverInfo, "isChatPaletteVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isButtonBoxVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isChatVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isDiceVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isCardPickUpVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isInitiativeListVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isResourceWindowVisible");
                loadToggleStateForRisizableWindow(serverInfo, "isCounterRemoconVisible");
            }
            
            Log.logging("loadViewStateInfo info", info);
            
            saveViewStateInfo();
        }
        
        private var isCutInVisible:Boolean = true;
        public function setCutInDisplayState(b:Boolean):void {
            isCutInVisible = b;
        }
        
        public function getCutInDisplayState():Boolean {
            return isCutInVisible;
        }
            
        private function loadToggleStateForRisizableWindow(serverInfo:Object, menuName:String):void {
            Log.logging("loadToggleStateForRisizableWindow menuName", menuName);
            
            var dummyInfo:Object = new Object();
            loadToggleState(serverInfo, dummyInfo, menuName, function(toggled:Boolean):void {
                    thisObj.getDodontoF().selectMenuByManuName(menuName, toggled);
                });
        }
        
        private function loadToggleState(serverInfo:Object, info:Object, key:String,
                                         action:Function):void {
            Log.logging("loadToggleState key", key);
            
            var fullKey:String =  getMenuSateSaveKey(key);
            var toggleStateObj:Object = info[fullKey];
            
            if( toggleStateObj == null ) {
                toggleStateObj = serverInfo[key];
                Log.logging("server value", toggleStateObj);
            }
            
            if( toggleStateObj == null ) {
                Log.logging("this is NULL.");
                return;
            }
            
            var toggleState:Boolean = toggleStateObj as Boolean;
            
            action(toggleState);
            getDodontoF().changeMainMenuToggle(key, toggleState);
        }
        
        private function getDodontoF():DodontoF {
            return DodontoF_Main.getInstance().getDodontoF();
        }
        
        private function getDodontoFM():DodontoF_Main {
            return DodontoF_Main.getInstance();
        }
        
        private function getMenuSateSaveKey(key:String):String {
            return "MainMenuSate:" + key;
        }
        
        private function saveMainManuStateToInfo(info:Object, key:String):void {
            var fullKey:String =  getMenuSateSaveKey(key);
            info[ fullKey ] = getDodontoF().getMainMenuToggle(key);
        }
        
        public function saveViewStateInfo():void {
            var info:Object = loadInfo( saveInfoKeyNameForViewState );
            if( info == null ) {
                info = new Object();
            }
            
            saveMainManuStateToInfo(info, "isSnapMovablePiece");
            saveMainManuStateToInfo(info, "isAdjustImageSize");
            saveMainManuStateToInfo(info, "isStandingGraphicVisible");
            saveMainManuStateToInfo(info, "isCutInVisible");
            saveMainManuStateToInfo(info, "isPositionVisible");
            saveMainManuStateToInfo(info, "isGridVisible");
            saveMainManuStateToInfo(info, "isCardHandleLogVisible");
            
            saveInfo(saveInfoKeyNameForViewState, info);
        }
        
        public function saveInfoForResiableWindow(key:String, value:Object):void {
            var info:Object = loadInfo( saveInfoKeyNameForViewState );
            if( info == null ) {
                info = new Object();
            }
            info[key] = value;
            saveInfo(saveInfoKeyNameForViewState, info);
        }
        
        
        private var novelticModeInfoKey:String = "novelticModeInfo";
        
        public function loadNovelticMode():Object {
            var info:Object = loadInfo(novelticModeInfoKey);
            return info;
        }
        
        public function isNovelticModeOn():Boolean {
            var info:Object = loadNovelticMode();
            if( info == null ) {
                return false;
            }
            
            return info.isNovelticMode;
        }
        
        public function saveNovelticMode(isNovelticMode:Boolean):void {
            var info:Object = {
                "isNovelticMode" : isNovelticMode
            };
            
            saveInfo(novelticModeInfoKey, info);
        }
        
        public function getTransparentImage():String {
            var url:String = "image/transparent.gif";
            url = getUrlString(url);
            return url;
        }
        
        private var paletteCountParTab:int = 20;
        public function getPaletteCountParTab():int {
            return paletteCountParTab;
        }
        
        
        public function getGraveyardLimit():int {
            return 10;
        }
        
        [Bindable]
            static public var windowAlpha:Number = 0.85;
        
        
        private var imageUploadDirInfo:Object = {};
        
        public function setImageUploadDirInfo(info:Object):void {
            imageUploadDirInfo = info;
        }
        
        private function changeUrlByUploadDirInfo(url:String):String {
            Log.logging("Config.changeUrlByUploadDirInfo Begin url", url);
            
            Log.logging("imageUploadDirInfo", imageUploadDirInfo);
            
            for(var marker:String in imageUploadDirInfo) {
                Log.logging("marker", marker);
                var dir:String = imageUploadDirInfo[marker];
                url = url.replace(marker, dir);
            }
            
            Log.logging("Config.changeUrlByUploadDirInfo End url", url);
            return url;
        }
        
        
        private var backgroundImage:String = null;
        
        public function getBackgroundImage():String {
            return backgroundImage;
        }
        
        public function setBackgroundImage(imageUrl:String):void {
            if( imageUrl == null ) {
                return;
            }
            
            backgroundImage = imageUrl;
            
            Log.logging("setBackImage imageUrl", imageUrl);
            imageUrl = getUrlString(imageUrl);
            Log.logging("setBackImage changed imageUrl", imageUrl);
            
            DodontoF_Main.getInstance().getDodontoF().setStyle("backgroundImage", imageUrl);
        }
        
        
        public function isGameType(target:String):Boolean {
            var gameType:String = ChatWindow.getInstance().diceBotGameType.selectedItem.gameType;
            return (target == gameType);
        }
        
        public function isHaveZeroDice(maxNumber:int):Boolean {
            if( maxNumber == 6 ) {
                return true;
            }
            if( maxNumber == 20 ) {
                return true;
            }
            return false;
        }
        
        public function isInitialRefresh():Boolean {
            return DodontoF_Main.getInstance().getGuiInputSender().getSender().getReciever()
                .isInitialRefresh();
        }
        
        public static function setFontSize(size:int):void {
            fontSize = size;
            buttonFontSize = fontSize + 5;
            Utils.setToolTipStyle(fontSize);
        }
        
        [Bindable]
        static public var fontSize:int = 10;
        
        [Bindable]
        static public var buttonFontSize:int = 15;
        
        
        [Bindable]
        static public var canUseExternalImageModeOn:Boolean = false;
        
        
        
        private var characterInfoToolTipMaxWidth:int = 50;
        private var characterInfoToolTipMaxHeight:int = 20;
        
        public function setCharacterInfoToolTipMax(maxInfo:Array):void {
            if( maxInfo == null ) {
                return;
            }
            
            characterInfoToolTipMaxWidth = parseInt(maxInfo[0]);
            characterInfoToolTipMaxHeight= parseInt(maxInfo[1]);
        }
        
        public function getToolTipMessage(piece:InitiativedPiece):String {
            var toolTipMessage:String = "";
            
            toolTipMessage += "[" + piece.getName() + "]";
            
            var addInfos:Array = piece.getAdditionalInfos();
            toolTipMessage += addInfos.join("\n");
            toolTipMessage += "\n";
            toolTipMessage += piece.getInfo();
            
            toolTipMessage = cutToolTip(toolTipMessage);
            
            return toolTipMessage;
        }
        
        private function cutToolTip(message:String):String {
            var result:Array = new Array();
            
            var lines:Array = message.split("\r");
            for(var i:int ; i < lines.length ; i++) {
                
                if( characterInfoToolTipMaxHeight > 0 ) {
                    if( i >= characterInfoToolTipMaxHeight ) {
                        break;
                    }
                }
                
                var line:String = lines[i];
                
                if( characterInfoToolTipMaxWidth > 0 ) {
                    line = line.substring(0, characterInfoToolTipMaxWidth);
                }
                
                result.push(line);
            }
            
            var resultString:String = result.join("\n");
            return resultString;
        }
        
        static public function get defaultImageUrl():String {
            return "./image/defaultImageSet/pawn/pawnBlack.png";
        }
        
        
        private var configParams:Object = {
            isAskRemoveRoomWhenLogout: true,
            canUploadImageOnPublic: true,
            wordChecker: {},
            dummy:false
        };
        
        public function set isAskRemoveRoomWhenLogout(b:Boolean):void {
            configParams.isAskRemoveRoomWhenLogout = b;
        }
        
        public function get isAskRemoveRoomWhenLogout():Boolean {
            return configParams.isAskRemoveRoomWhenLogout;
        }
        
        
        public function set canUploadImageOnPublic(b:Boolean):void {
            configParams.canUploadImageOnPublic = b;
        }
        
        public function get canUploadImageOnPublic():Boolean {
            return configParams.canUploadImageOnPublic;
        }
        
        
        public function setWordChecker(obj:Object):void {
            configParams.wordChecker = obj;
        }
        
        public function getWordChecker(key:String):Object {
            if( configParams.wordChecker == null ) {
                return new Object();
            }
            
            var info:Object = configParams.wordChecker[key];
            if( info == null ) {
                return new Object();
            }
            
            return info;
        }
        
    }
}

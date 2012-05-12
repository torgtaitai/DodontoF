//--*-coding:utf-8-*--

package {
    import flash.net.SharedObject;
    import flash.net.URLRequest;
    import mx.controls.Alert;
    
    public class Config {
        static private var thisObj:Config = new Config();
        static private var saveDataKey:String = "DodontoF_LocalSaveData";
        
        static public function getInstance():Config {
            return thisObj;
        }
        
        private var version:String = "Ver.1.36.13(2012/05/12)";
        
        public function getVersion():String {
            return version;
        }
                
        private var localUrlPrefix:String = null;
        
        public function Config() {
            /*
            if( DodontoF_Main.getInstance().isGoogleWave() ){
                localUrlPrefix = "http://www.dodontof.com/DodontoF_New/";
            }
            */
            
            if( isGaeJava() ){
                return;
            }
            
        }
        
        static public function isGaeJava():Boolean {
            return COMPILE::isGaeJava;
        }
        
        static public function isGaeRuby():Boolean {
            return COMPILE::isGaeRuby;
        }
        
        static public function isRails():Boolean {
            return DodontoF_Main.getInstance().isRails();
        }
        
        public function setServerUrl(url:String):void {
            //localUrlPrefix = "http://www.dodontof.com/DodontoF/";
            localUrlPrefix = url;
        }
        
        public function isAdobeAir():Boolean {
            return COMPILE::isAir;
        }
        
        
        private function getPlayRoomNumber():int {
            var playRoomNumber:int =  + DodontoF_Main.getInstance().getPlayRoomNumber();
            return playRoomNumber;
        }
        
        private function getSaveData():SharedObject {
            return SharedObject.getLocal(saveDataKey + "_" + getPlayRoomNumber());
        }
        
        private var isSnapMovablePiece:Boolean= true;
        
        public function setSnapMovablePiece(b:Boolean):void {
            isSnapMovablePiece = b;
            saveViewStateInfo();
        }
        
        public function isSnapMovablePieceMode():Boolean {
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
            if( isGaeRuby() ) {
                return "/dodontof";
            }
            
            if( isRails() ) {
                return "/command/any.json";
            }
            
            var cgiUrl:String = "DodontoFServer.rb";
            
            if( DodontoF_Main.getInstance().isMySqlMode() ) {
                cgiUrl = "DodontoFServerMySql.rb";
            }
            
            cgiUrl = getUrlString(cgiUrl);
            
            return cgiUrl;
        }
        
        public function getImageUploaderUrl():String {
            if( isGaeRuby() ) {
                return "/imageUploader";
            }
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
        
        public function saveInfo(key:String, info:Object):void {
            if( DodontoF_Main.getInstance().isTinyMode() ) {
                key = tinyModePrefix + key;
            }
            
            var saveData:SharedObject = getSaveData();
            saveData.data[key] = info
            saveData.flush();
        }
        
        private var tinyModePrefix:String = "tinyMode:";
        
        public function loadInfo(key:String):Object {
            
            if( DodontoF_Main.getInstance().isTinyMode() ) {
                key = tinyModePrefix + key;
            }
            
            //リプレイモードでは常にデフォルト構成に
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                return null;
            }
            
            var saveData:SharedObject = getSaveData();
            var info:Object = saveData.data[key];
            return info;
        }
        
        public function setToDefaultInfo():void {
            var saveData:SharedObject = getSaveData();
            saveData.clear();
            saveData.flush();
        }
        
        private var saveInfoKeyNameForViewState:String = "ViewState";
        
        public function setViewStateKey(key:String):void {
            if( key == null ) {
                return;
            }
            
            var info:Object = loadInfo( getSaveInfoKeyNameForViewState() );
            Log.logging("info", info);
            if( info != null ) {
                if( info.key == key ) {
                    return;
                }
            }
            
            //キーが今までと異なるなら、コレまでの表示状態は破棄
            var newInfo:Object = new Object();
            saveInfo(getSaveInfoKeyNameForViewState(), newInfo);
        }
        
        public function getSaveInfoKeyNameForViewState():String {
            return saveInfoKeyNameForViewState;
        }
        
        
        private var loginSaveDataKey:String = "loginInfo";
        
        public function loadLoginInfo():Object {
            return Config.getInstance().loadInfo(loginSaveDataKey);
        }
        
        public function saveLoginInfo(loginInfo:Object):void {
            saveInfo(loginSaveDataKey, loginInfo);
        }
        
        
        public function loadInfoForResiableWindow(key:String):Object {
            var info:Object = loadInfo( getSaveInfoKeyNameForViewState() );
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
            Log.logging("loadViewStateInfo key", key);
            setViewStateKey(key);
            
            var info:Object = loadInfo( getSaveInfoKeyNameForViewState() );
            if( info == null ) {
                info = new Object();
            }
            Log.logging("local info", info);
            
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
            
            loadToggleStateForRisizableWindow(serverInfo, "isChatPaletteVisible");
            loadToggleStateForRisizableWindow(serverInfo, "isChatVisible");
            loadToggleStateForRisizableWindow(serverInfo, "isDiceVisible");
            loadToggleStateForRisizableWindow(serverInfo, "isCardPickUpVisible");
            loadToggleStateForRisizableWindow(serverInfo, "isInitiativeListVisible");

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
            
            Log.logging("local value", toggleStateObj);
            
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
            info[ getMenuSateSaveKey(key) ] = getDodontoF().getMainMenuToggle(key);
        }
        
        public function saveViewStateInfo():void {
            var info:Object = loadInfo( getSaveInfoKeyNameForViewState() );
            if( info == null ) {
                info = new Object();
            }
            
            saveMainManuStateToInfo(info, "isSnapMovablePiece");
            saveMainManuStateToInfo(info, "isAdjustImageSize");
            saveMainManuStateToInfo(info, "isStandingGraphicVisible");
            saveMainManuStateToInfo(info, "isCutInVisible");
            saveMainManuStateToInfo(info, "isPositionVisible");
            saveMainManuStateToInfo(info, "isGridVisible");
            
            Log.logging("saveViewStateInfo info", info);
            
            saveInfo(getSaveInfoKeyNameForViewState(), info);
        }
        
        public function saveInfoForResiableWindow(key:String, value:Object):void {
            var info:Object = loadInfo( getSaveInfoKeyNameForViewState() );
            if( info == null ) {
                info = new Object();
            }
            info[key] = value;
            saveInfo(getSaveInfoKeyNameForViewState(), info);
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
        
        
    }
}

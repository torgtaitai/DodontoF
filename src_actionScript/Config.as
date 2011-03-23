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
        
        private var version:String = "Ver.1.30.01(2011/03/23)";
        
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
        
        public function setServerUrl(url:String):void {
            //localUrlPrefix = "http://www.dodontof.com/DodontoF/";
            localUrlPrefix = url;
        }
        
        public function isAdobeAir():Boolean {
            return COMPILE::isAir;
        }
        
        
        private function getSaveData():SharedObject {
            return SharedObject.getLocal(saveDataKey);
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
        
        public function getImageDataUploaderUrl():String {
            return getUrlString("imageUploader.rb");
        }
        
        private var diceBotCgiUrl:String = "customBot.pl";
        
        public function setDiceBotCgiUrl(url:String):void {
            if( url != null ) {
                diceBotCgiUrl = url
            }
            
            diceBotCgiUrl = getUrlString(diceBotCgiUrl);
        }
        
        public function getDiceBotCgiUrl():String {
            return diceBotCgiUrl;
        }
        
        public function getUrlString(url:String):String {
            if( url == null ) {
                return url;
            }
            
            if( url == "" ) {
                return url;
            }
            
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
        
        public function getSaveInfoKeyNameForViewState():String {
            return "ViewState";
        }
        
        
        public function loadViewStateInfo():void {
            var info:Object = loadInfo(getSaveInfoKeyNameForViewState());
            
            if( info == null ) {
                return;
            }
            
            loadToggleState( info, "isSnapMovablePiece", function(v:Boolean):void {isSnapMovablePiece = v} );
            loadToggleState( info, "isAdjustImageSize", function(v:Boolean):void {isAdjustImageSize = v} );
            loadToggleState( info, "isCardVisible", getDodontoFM().getMap().setVisibleCardLayer );
            loadToggleState( info, "isStandingGraphicVisible", getDodontoFM().getChatWindow().setStandingGraphicsDisplayState );
            loadToggleState( info, "isMapVisible", getDodontoFM().getMap().setVisible );
            loadToggleState( info, "isPositionVisible", getDodontoFM().getMap().setVisibleGridPositionLayer );
            loadToggleState( info, "isGridVisible", getDodontoFM().getMap().setVisibleGridLayer );
            //loadToggleState( info, "isDirectionVisible", getDodontoFM().setVisibleDirectionLayer );
        }
        
        private function loadToggleState(info:Object, key:String, function_:Function):void {
            var fullKey:String =  getMenuSateSaveKey(key);
            var toggleState:Boolean = info[fullKey];
            
            function_.call(null, toggleState);
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
            var info:Object = {};
            
            saveMainManuStateToInfo(info, "isSnapMovablePiece");
            saveMainManuStateToInfo(info, "isAdjustImageSize");
            saveMainManuStateToInfo(info, "isCardVisible");
            saveMainManuStateToInfo(info, "isStandingGraphicVisible");
            saveMainManuStateToInfo(info, "isMapVisible");
            saveMainManuStateToInfo(info, "isPositionVisible");
            saveMainManuStateToInfo(info, "isGridVisible");
            //saveMainManuStateToInfo(info, "isDirectionVisible");
            
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
        
        public function getGraveyardLimit():int {
            return 10;
        }
    }
}

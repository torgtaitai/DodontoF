//--*-coding:utf-8-*--

package {
    
    public class RecordHistory {
        
        private var history:Array = new Array();
        private var isHistoryOn:Boolean = false;
        
        static private var self:RecordHistory;
        
        static public function getInstance():RecordHistory {
            if( self == null ) {
                self = new RecordHistory();
            }
            return self;
        }
        
        public function isRecording():Boolean {
            return isHistoryOn;
        }
        
        
        public function stopRecord():Boolean {
            if( ! isHistoryOn ) {
                return false;
            }
            
            return true;
        }
        
        public function getHistory():Array {
            return history;
        }
        
        
        public function addHistory(jsonData_original:Object):void {
            
            if( ! isHistoryOn ) {
                return;
            }
            
            Log.logging("addHistory jsonData", jsonData);
            
            var jsonData:Object = Utils.clone(jsonData_original);
            
            delete jsonData.loginUserInfo;
            delete jsonData.refreshIndex;
            delete jsonData.lastUpdateTimes;
            
            Log.logging("history jsonData", jsonData);
            
            if( ! hasKey(jsonData) ) {
                Log.logging("jsonData has NO key.");
                return;
            }
            
            Log.logging("jsonData has key, so push history!!");
            pushHistory(jsonData);
        }
        
        private function hasKey(params:Object):Boolean {
            for(var key: String in params){
                return true;
            }
            return false;
        }
        
        
        private var historySaveKey:String = "history";
        
        public function startRecord():void {
            initHistory();
        }
        
        public function initHistory():void {
            
            history = getHistoryCache();
            
            if( history == null ) {
                history = new Array();
            }
            
            isHistoryOn = true;
        }
        
        private function getHistoryCache():Array {
            try {
                return Config.getInstance().loadInfo(historySaveKey) as Array;
            } catch (e:Error) {
            }
            
            return null;
        }
        
        private function pushHistory(jsonData:Object):void {
            
            history.push(jsonData);
            
            try {
                Config.getInstance().saveInfo(historySaveKey, history);
            } catch (e:Error) {
            }
        }
        
        public function clearHistory(dodontoF:DodontoF):void {
            stopRecord();
            
            history = new Array();
            Config.getInstance().saveInfo(historySaveKey, []);
            isHistoryOn = false;
            
            dodontoF.setMenuSessionRecording(false);
        }
        
        public function isHaveHistory():Boolean {
            var cache:Array = getHistoryCache();
            if( cache == null ) {
                return false;
            }
            if( cache.length == 0 ) {
                return false;
            }
            
            return true;
        }
}
}

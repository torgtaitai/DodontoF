//--*-coding:utf-8-*--
package {
	public class ReplayEditor {
        private var history:Array = new Array();
        
        public function setHistory(history_:Array):void {
            history = history_;
        }
        
        public function getHistory():Array {
            return history;
        }
        
        public function startEdit():void {
            var newHistory:Array = new Array();
            this.chatMessageDataLastWrittenTime = -1;
            
            for(var i:int = 0 ; i < history.length ; i++) {
                var jsonData:Object = history[i];
                editHistoryJsonData(jsonData, newHistory);
            }
            
            history = newHistory;
        }
        
        public function editHistoryJsonData(jsonData:Object, newHistory:Array):void {
            editHistoryJsonData_Chat(jsonData, newHistory);
            
            pushJsonDataUnlessNull( jsonData, "characters", newHistory );
            pushJsonDataUnlessNull( jsonData, "roundTimeData", newHistory );
            pushJsonDataUnlessNull( jsonData, "mapData", newHistory );
            pushJsonDataUnlessNull( jsonData, "effects", newHistory );
            pushJsonDataUnlessNull( jsonData, "replayConfig", newHistory );
        }
        
        private function pushJsonDataUnlessNull(jsonData:Object, key:String, newHistory:Array):void {
            if( jsonData[key] == null ) {
                return;
            }
            
            var newJsonData:Object = getNewJsonData();
            newJsonData[key] = jsonData[key];
            newHistory.push( newJsonData );
        }
        
        private function getNewJsonData():Object {
            var newJsonData:Object = new Object();
            return newJsonData;
        }
        
        private var chatMessageDataLastWrittenTime:Number = 0;
        
        public function editHistoryJsonData_Chat(jsonData:Object, newHistory:Array):void {
            if( ! jsonData.chatMessageDataLog ) {
                return;
            }
            
            var lastWrittenTime:Number = this.chatMessageDataLastWrittenTime;
            for(var i:int = 0 ; i < jsonData.chatMessageDataLog.length ; i++) {
                var chatMessageData:Object = jsonData.chatMessageDataLog[i];
                
                var channel:int = chatMessageData['channel'];
                /*
                if( Replay.isIgnoreChannel(channel) ) {
                    continue;
                }
                */
                
                var writtenTime:Number = chatMessageData[0];
                if( writtenTime <= this.chatMessageDataLastWrittenTime ) {
                    continue;
                }
                
                lastWrittenTime = writtenTime;
                
                var newJsonData:Object = getNewJsonData();
                newJsonData.chatMessageDataLog = new Array();
                newJsonData.chatMessageDataLog.push( chatMessageData );
                newHistory.push(newJsonData);
            }
            this.chatMessageDataLastWrittenTime = lastWrittenTime;
        }
    }
}

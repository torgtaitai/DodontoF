//--*-coding:utf-8-*--

package {
    
    import com.adobe.serialization.json.JSON;
    import flash.events.Event;
    import flash.net.URLLoader;
    import mx.controls.Alert;
    
    public class SharedDataReceiverDummy extends SharedDataReceiver {
        
        private var refreshedCount:int = 0;
        
        public function getRefreshedCount():int {
            return refreshedCount;
        }
        
        public function init():void {
            refreshedCount = 0;
        }
        
        override protected function refreshNext():void {
            refreshedCount++;
            //do NOT refresh next.
        }
    }
}


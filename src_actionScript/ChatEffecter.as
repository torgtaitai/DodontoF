//--*-coding:utf-8-*--

package {
    
    import com.adobe.serialization.json.JSON;
    
    public class ChatEffecter {
        
        private var marker:String = "";
        
        public function ChatEffecter(marker_:String):void {
            marker = marker_;
        }
        
        private function getMarkString():String {
            return "###" + marker + "###";
        }
        
        public function getSendMessage(params:Object):String {
            var paramsString:String = JSON.encode(params);
            return (getMarkString() + paramsString);
        }
        
        public function isChatEffect(message:String):Boolean {
            return ( message.indexOf( getMarkString() ) == 0 );
        }
        
        public function getParams(message:String):Object {
            var params:Object = null;
            
            if( ! isChatEffect(message) ) {
                return params;
            }
            
            var paramsString:String = message.substring( getMarkString().length );
            try {
                params = JSON.decode(paramsString);
            } catch (error:Error) {
            }
            
            return params;
        }
    }
    
}


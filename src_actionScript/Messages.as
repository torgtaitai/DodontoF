//--*-coding:utf-8-*--

package {
    
    import mx.controls.Alert;
    import mx.utils.StringUtil;
    
    public class Messages {
        
        static private var instance:Messages;
        
        
        static public function getInstance():Messages {
            if( instance == null ) {
                instance = new Messages();
            }
            
            return instance;
        }
        
        static public function getMessageFromWarningInfo(warning:Object):String {
            if( warning == null ) {
                return "";
            }
            
            var key:String = warning["key"];
            var params:Array = warning["params"];
            
            return getMessage(key, params);
            
        }
        
        static public function getMessage(key:String, params:Array = null):String {
            if( params == null ) {
                params = [];
            }
            
            return Language.text(key, params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9]);
        }
        
        private var messageBaseList:Object = 
{

        }
        
    }
}

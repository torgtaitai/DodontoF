//--*-coding:utf-8-*--

package {
    import flash.text.TextField;
    import mx.utils.StringUtil;
    import mx.managers.PopUpManager;
    import flash.utils.ByteArray;
    
    
    public class Log {
        
        private static var debugText:TextField = new TextField();
        
        private static var debug:int = 4;
        private static var tuning:int = 2;
        private static var error:int = 1;
        private static var fatalError:int = 0;
        
        private static var logLevel:int = error; //
        
        private static var self:Log;
        
        public static function setDebug():void {
            logLevel = debug;
        }
        public static function setTuning():void {
            logLevel = tuning;
        }
        public static function setError():void {
            logLevel = error;
        }
        public static function setFatalError():void {
            logLevel = fatalError;
        }
        
        public static function init():void {
            if( logLevel == 0 ) {
                return;
            }
            
            logging("initialized");
        }
        
        public static function loggingException(methodName:String, error:Error):void {
            Log.loggingError("error in " + methodName, error.message);
            Log.loggingError("exception : " + error);
            Log.loggingError("stackTrace : " + error.getStackTrace());
        }
        
        public static function loggingExceptionDebug(methodName:String, error:Error):void {
            Log.logging("error in " + methodName, error.message);
            Log.logging("exception", "" + error);
            Log.logging("stackTrace", error.getStackTrace());
        }
        
        public static function logging(text:String, obj:Object = "noLogPrint"):void {
            loggingByLevel(text, debug, obj);
        }
        
        public static function loggingTuning(text:String, obj:Object = "noLogPrint"):void {
            loggingByLevel(text, tuning, obj);
        }
        
        public static function loggingError(text:String, obj:Object = "noLogPrint"):void {
            loggingByLevel(text, error, obj);
        }
        
        
        
        public static function loggingFatalError(text:String, obj:Object = "noLogPrint"):void {
            loggingByLevel(text, fatalError, obj);
        }
        
        static private var noLogPrintTag:String = "noLogPrint";
        
        public static function loggingErrorOnStatus(text:String, obj:Object = "noLogPrint"):void {
            var isOnStatus:Boolean = true;
            loggingByLevel(text, fatalError, obj, isOnStatus);
        }
        
        private static var logWindow:LogWindow;
        
        public static function initLogWindow():void {
            if( logWindow == null ) {
                logWindow = DodontoF.popup(LogWindow, false) as LogWindow;
                return;
            }
            
            PopUpManager.removePopUp( logWindow );
            logWindow = null;
        }
        
        private static function getDateString():String {
            var now:Date = new Date();
            var dateString:String = StringUtil.substitute("{0}/{1}/{2} {3}:{4}:{5}.{6}", 
                                                          now.fullYear,
                                                          now.month,
                                                          now.date,
                                                          now.hours,
                                                          now.minutes,
                                                          now.seconds,
                                                          now.milliseconds);
                return dateString;
        }
        
        public static function loggingByLevel(text:String, level:int, obj:Object = null, isOnStatus:Boolean = false):void {
            if( logLevel < level ) {
                return;
            }
            
            var objText:String = getObjectString(obj);
            
            if( objText != noLogPrintTag ) {
                text = text + " : " + objText;
            }
            
            var logText:String = "[" + getDateString() + "]" + text + "\n";
            logAny(logText);
            
            if( logWindow != null ) {
                //debugText.appendText( logText );
                logWindow.textArea.text += logText;
            }
            
            
            if( logLevel > error ) {
                return;
            }
            
            if( ChatWindow.getInstance() == null ) {
                return;
            }
            
            if( isOnStatus ) {
                ChatWindow.getInstance().status = text;
                return;
            }
            
            //var logMessage:String = ("Log[" + level + "]:" + text);
            var logMessage:String = text;
            
            printSystemLog(logMessage, ChatWindow.getInstance().lastChatChannel);
            
            if( logLevel <= fatalError ) {
                printSystemLog(logMessage, ChatWindow.getInstance().publicChatChannel);
            }
        }
        
        static public function getObjectString(obj:Object):String {
            var objText:String = obj as String;
            if( objText != null ) {
                return objText;
            }
            
            var data:ChatSendData = obj as ChatSendData;
            if( data != null ) {
                return data.toString();
            }
            
            var bytes:ByteArray = obj as ByteArray;
            if( bytes != null ) {
                return bytes.toString();
            }
            
            return Utils.getJsonString(obj);
        }
        
        static public function printSystemLogPublic(logMessage:String):void {
            printSystemLog(logMessage, ChatWindow.getInstance().publicChatChannel);
        }
        
        static private function printSystemLog(message:String, channel:int):void {
            channel = ChatWindow.getInstance().changeChatChannelNumberForSystemLog(channel);
            
            var name:String = Language.s.title;
            var color:String = "00AA00";
            var time:Number = (new Date().getTime() / 1000);
            
            var data:ChatSendData = new ChatSendData(channel, message, name);
            data.setColorString(color);
            data.setSendToOwnself();
            
            ChatWindow.getInstance()
                .addMessageToChatLog(data,
                                     time,
                                     "logger");
        }
        
    }
}

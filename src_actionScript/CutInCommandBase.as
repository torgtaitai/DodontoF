//--*-coding:utf-8-*--

package {

    public class CutInCommandBase extends CutInBase {
        
        public function sendCommand(params:Object = null):void {
            var commandText:String = getCutInMessage(params);
            ChatWindow.getInstance().sendChatMessage_public(commandText);
        }
        
        override protected function getMarkString():String {
            return "###CutInCommand:" + getCommand() + "###";
        }
        
        
        //継承先で実装して下さい。
        protected function getCommand():String {
            return "Base";
        }
        
        
        override protected function getPrintMessageText(params:Object):String {
            return null;
        }
        
        override protected function executeEffect(params:Object):void {
            Log.loggingTuning("CutInCommandBase.executeEffect Begin");
            try {
                executeCommand(params);
            } catch (error:Error) {
                Log.loggingException("CutInCommandBase.executeEffect", error);
            }
            Log.loggingTuning("CutInCommandBase.executeEffect End");
        }
        
        
        //継承先で実装して下さい。
        protected function executeCommand(params:Object):void {
        }
        
        
    }
}

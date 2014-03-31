//--*-coding:utf-8-*--

package {

    //カットイン機能を流用してコマンドを流し込むための機能。
    //内容については各種継承先の実例 CutInCommandRollVisualDice.as 等を参照してください。
    public class CutInCommandBase extends CutInBase {
        
        public function sendCommand(params:Object = null):void {
            var message:String = getCutInMessage(params);
            
            var window:ChatWindow = ChatWindow.getInstance();
            var isCheckDiceRoll:Boolean = false;
            window.sendChatMessage(window.publicChatChannel, message, isCheckDiceRoll);
        }
        
        public static function getBeginMarker():String {
            return "###CutInCommand:"
        }
        
        public function getMark():String {
            return getMarkString();
        }
        
        override protected function getMarkString():String {
            return getBeginMarker() + getCommand() + "###";
        }
        
        //カットインが非表示の場合でも「カットインを流用したコマンド機能」（このクラスのこと）
        //は有効にするためにオーバーライド。継承先でも変更しないで下さい。
        override protected function isCutInDisable():Boolean {
            return false;
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

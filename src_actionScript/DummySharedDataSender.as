//--*-coding:utf-8-*--

package {
    
    public class DummySharedDataSender extends SharedDataSender {
        
        private var sendParamString:String = "";
        private var roundTimer:RoundTimer;
        
        public function setRoundTimer(roundTimer_:RoundTimer):void {
            roundTimer = roundTimer_;
        }
        
        public override function sendCommandData(paramsString:String,
                                         callBack:Function = null,
                                         callBackForError:Function = null):void {
            Log.logging("sendCommandData Dummy");
            sendParamString = paramsString;
        }
        
        public function clear():void {
            sendParamString = "";
        }
        
        public function getSendParamString():String {
            return sendParamString;
        }
        
        override public function sendRoundTimeData(round:int, initiative:Number):void {
            roundTimer.setTime(round, initiative);
        }
    }
}

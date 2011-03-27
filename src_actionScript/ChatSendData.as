//--*-coding:utf-8-*--

package {
    
    import mx.controls.ComboBox;
    import mx.controls.Alert;
    
    public class ChatSendData {
        
        private var color:int = -1;
        private var name:String;
        private var state:String;
        private var sendto:String;
        private var message:String = "";
        private var channel:int = 0;
        
        private var isDiceRollResultFlag:Boolean = false;
        
        static private var tailReturn:RegExp = /\r+$/;
        
        public function ChatSendData(channel_:int,
                                     message_:String,
                                     name_:String = null, 
                                     state_:String = null,
                                     sendto_:String = null):void {
            channel = channel_;
            setMessage(message_);
            
            name = name_;
            state = state_;
            sendto = sendto_;
        }
        
        public function replaceMessage(before:*, after:Object):void {
            message = message.replace(before, after);
        }
        
        public function setMessage(m:String):void {
            message = m;
            replaceMessage(tailReturn, '');
        }
        
        public function setColor(color_:int):void {
            color = color_;
        }
            
        public function setColorString(color_:String):void {
            if( color_ != null ) {
                color = parseInt( "0x" + color_ );
            }
        }
        
        public function getColor():String {
            if(( color == -1 ) || (color == 0xFFFFFF)) {
                return getChatWindw().getChatFontColor();
            }
            
            return Utils.getColorString(color);
        }
        
        public function getName():String {
            var nameString:String = getValue(name, getChatWindw().getChatCharacterName());
            return nameString;
        }
        
        public function getState():String {
            return getValue(state, getComboBoxText(getChatWindw().standingGraphicsStates));
        }
        
        public function getSendto():String {
            return getValue(sendto, getComboBoxText(getChatWindw().sendto));
        }
        
        private function getValue(param1:String, param2:String):String {
            if( (param1 != null) && (param1 != "") ) {
                return param1;
            }
            if( (param2 != null) && (param2 != "") ) {
                return param2;
            }
            
            return "";
        }
        
        public function getMessage():String {
            return message;
        }
        
        public function getChannel():int {
            return channel;
        }
        
        public function setDiceRollResult():void {
            isDiceRollResultFlag = true;
        }
        
        public function isDiceRollResult():Boolean {
            return isDiceRollResultFlag;
        }
        
        private function getChatWindw():ChatWindow {
            return ChatWindow.getInstance();
        }
        
        private function getComboBoxText(combobox:ComboBox):String {
            return Utils.getComboBoxText(combobox);
        }
        
    }
    
}

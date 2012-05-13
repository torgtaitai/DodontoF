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
        private var isSendToOwnself:Boolean = false;
        
        private var randomSeed:int = 0;
        private var gameType:String = null;
        private var callBack:Function = null;
        
        private var isDiceRollResultFlag:Boolean = false;
        
        private var retryCount:int = 0;
        static private var retryCountLimit:int = 3;
        
        static public function setRetryCountLimit(limit:int):void {
            retryCountLimit = limit;
        }
        
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
        
        public function setNameAndState(nameAndState:String):void {
            var params:Array = nameAndState.split("\t");
            name = params[0];
            state = params[1];
        }
        
        public function setNameFromChatWindow():void {
            name = getValue(name, getChatWindw().getChatCharacterName());
        }
        
        
        private var isStateEmpty:Boolean = false;
        
        public function getNameAndState():String {
            return getNameOnly() + "\t" + getState();
        }
        
        public function getNameOnly():String {
            return name;
        }
        
        public function setStateEmpty():void {
            isStateEmpty = true;
        }
        
        public function getState():String {
            if( isStateEmpty ) {
                return "";
            }
            
            return getValue(state, getComboBoxText(getChatWindw().standingGraphicsStates));
        }
        
        public function setSendto(to:String):void {
            sendto = to;
        }
        
        public function setSendtoFromChatWindow():void {
            sendto = getValue(sendto, getComboBoxText(getChatWindw().sendtoBox));
        }
        
        public function getSendto():String {
            return sendto;
        }
        
        private function getValue(param1:String, param2:String = ""):String {
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
        
        public function setChannel(c:int):void {
            this.channel = c;
        }
        
        public function getChannel():int {
            return this.channel;
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
        
        
        public function setDiceBotData(seed:int, type:String, callBack_:Function):void {
            randomSeed = seed;
            gameType = type;
            callBack = callBack_;
        }
        
        public function getRandSeed():int {
            return randomSeed;
        }
        
        public function getGameType():String {
            return gameType;
        }
        
        public function isDiceRoll():Boolean {
            return (gameType != null);
        }
        
        public function getCallBack():Function {
            return callBack;
        }
        
        public function isFirstSend():Boolean {
            return (retryCount == 0);
        }
        
        public function isInRetryLimit():Boolean {
            return (retryCount <= retryCountLimit);
        }
        
        public function inclimentRetryCount():void {
            retryCount++;
        }
        
        public function clearRetryCount():void {
            retryCount = 0;
        }
        
        public function setSendToOwnself():void {
            isSendToOwnself = true;
        }
        
        public function getStrictlyUniqueId(sender:SharedDataSender):String {
            if( isSendToOwnself ) {
                return "dummy";
            }
            
            return sender.getStrictlyUniqueId();
        }
        
    }
    
}

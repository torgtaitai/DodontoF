//--*-coding:utf-8-*--

package {
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import mx.events.FlexEvent;
    import mx.controls.Text;
    import mx.controls.TextArea;
    import mx.controls.Image;
    import mx.containers.HBox;
    import mx.controls.Button;
    import mx.controls.Alert;
    import mx.events.CloseEvent;
    import mx.utils.StringUtil;
    
    public class ChatMessageTrader {
        
        private var cutInList:Array = new Array();
        private var chatWindow:ChatWindow;
        //private var addMessageLines:String = "";
        
        private var localMessageUniqueId:String = "localMessageUniqueId";
        private var systemMessageSenderName:String = Language.s.title;
        private var systemMessageColor:String = "00AA00";
        private var thisObj:ChatMessageTrader;
        private var guiInputSender:GuiInputSender;
        
        private var voter:Voter;
        
        
        public function ChatMessageTrader(chatWindow_:ChatWindow) {
            thisObj = this;
            
            guiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            chatWindow = chatWindow_;
            cutInList = [new CutInCommandRollVisualDice(),
                         new CutInMovie(), 
                         new CutInCommandGetDiceBotInfos()];
            
            voter  = new Voter(chatWindow);
        }
        
        
        private var diceCheckRegExp:RegExp = /^\s*ダイス合計[：:]\s*\d+\s*[\(\（]/;
        
        //ダイスロール結果を手入力で不正入力していないかのチェック
        private function checkInvalidDiceRoll(chatMessage:String,
                                           isDiceRollResult:Boolean):Boolean {
            //正当なダイスロール結果ならチェック無し
            if( isDiceRollResult ) {
                return false;
            }
            
            var checkResult:Object = diceCheckRegExp.exec(chatMessage);
            if( checkResult == null ) {
                return false;
            }
            
            chatWindow.sendSystemMessage(Language.s.invalidDiceBotText, [chatMessage]);
            return true;
        }
        
        
        public function sendMessage(data:ChatSendData):void {
            Log.logging("ChatMessageTrader.sendMessage Begin data", data);
            
            //不正なダイスロールならここで終了
            if( checkInvalidDiceRoll(data.getMessage(), data.isDiceRollResult()) ) {
                return;
            }
            
            data.setNameFromChatWindow();
            data.setSendtoFromChatWindow();
            
            try{
                addMessageToChatLogWhenSendMessage(data);
                guiInputSender.sendChatMessage(data);
            } catch(error:Error) {
                this.status = error.message;
            }
        }
        
        private function addMessageToChatLogWhenSendMessage(data:ChatSendData):void {
            if( data.isDiceRoll() ) {
                return;
            }
            
            if( ! data.isFirstSend() ) {
                return;
            }
            
            var time:Number = (new Date().getTime() / 1000);
            var isReplayChatMessage:Boolean = false;
            addMessageToChatLog(data, time, localMessageUniqueId, isReplayChatMessage);
        }
        
        
        public function addLocalMessage(message:String):void {

            var data:ChatSendData = new ChatSendData(ChatWindow.getInstance().publicChatChannel,
                                                     message,
                                                     systemMessageSenderName);
            data.setColorString(systemMessageColor);
            data.setStateEmpty();
            
            addMessageToChatLog(data, 0, "dummy");
        }
        
        public function sendSystemMessage(messageBase:String,
                                          args:Array = null, strictlyUniqueId:String = null):void {
            if( args == null ) {
                args = [];
            }
            
            var isRoomResult:Boolean = true;
            var message:String = "";
            
            var channel:int = chatWindow.publicChatChannel;
            channel = chatWindow.changeChatChannelNumberForSystemLog(channel);
            
            var data:ChatSendData = new ChatSendData(channel, message, systemMessageSenderName);
            data.setColorString(systemMessageColor);
            data.setStateEmpty();
            
            var name:String = chatWindow.getChatCharacterName();
            data.setMessage(name);
            name = data.getMessage();
            
            message = StringUtil.substitute(messageBase, name,
                                            args[0], args[1], args[2], args[3], args[4], 
                                            args[5], args[6], args[7], args[8], args[9]);
            
            data.setMessage(message);
            data.setSendToOwnself();
            if( strictlyUniqueId != null ) {
                data.setStrictlyUniqueId(strictlyUniqueId);
            }
            
            guiInputSender.sendChatMessage(data);
        }
        
        public function addMessageToChatLog(data:ChatSendData,
                                            time:Number,
                                            chatSenderUniqueId:String,
                                            isReplayChatMessage:Boolean = false):void {
            addMessageToChatLogParts(data,
                                     time,
                                     chatSenderUniqueId,
                                     isReplayChatMessage);
            printAddedMessageToChatMessageLog();
        }
        
        private function isOwnStrictlyUniqueId(targetId:String):Boolean {
            return guiInputSender.getSender().isOwnStrictlyUniqueId(targetId);
        }
        
        private function isPrintableMessageOnSecretMessage(chatSenderUniqueId:String, sendto:String):Boolean {
            Log.logging("ChatMessageTrader.isPrintableMessageOnSecretMessage Begin");
            
            Log.logging("chatSenderUniqueId", chatSenderUniqueId);
            Log.logging("localMessageUniqueId", localMessageUniqueId);
            
            if( chatSenderUniqueId == localMessageUniqueId ) {
                Log.logging("送信者が自分なら表示可能");
                return true;
            }
            
            if( ! Utils.isValidSendTo(sendto) ) {
                Log.logging("秘話指定無しなので表示可能");
                return true;
            }
            
            if( isOwnStrictlyUniqueId(sendto) ) {
                Log.logging("秘話指定先が自分なら表示可能");
                return true;
            }
            
            if( guiInputSender.getSender().getReciever().isFirstChatRefresh() ) {
                Log.logging("初回ロード時は秘話の宛先指定を緩く判定。");
                Log.logging("接続事のユニークID（strictlyUniqueId)ではなく、ブラウザキャッシュのユニークID（uniqueId)でマッチングを確認");
                
                if( guiInputSender.getSender().isOwnUniqueIdByStrictlyId(sendto) ) {
                    Log.logging("秘話指定先は自分（同一のブラウザ）宛なので表示可能");
                    return true;
                }
                if( guiInputSender.getSender().isOwnUniqueIdByStrictlyId(chatSenderUniqueId) ) {
                    Log.logging("秘話送付元は自分（同一のブラウザ）なので表示可能");
                    return true;
                }
            }
            
            Log.logging("残念、表示不能です。");
            return false;
        }
        
        private function isOwnMessage(senderName:String, chatSenderUniqueId:String):Boolean {
            //初回読み込みタイミングなら常に全メッセージ表示
            if( guiInputSender.getSender().getReciever().isFirstChatRefresh() ) {
                return false;
            }
            
            if( senderName == systemMessageSenderName ) {
                return false;
            }
            
            if( senderName == "" ) {
                return false;
            }
            
            
            return ( isOwnStrictlyUniqueId( chatSenderUniqueId ) );
        }
        
        
        //関数の戻り値は「リプレイログに保存できる、正しいメッセージかどうか」を示します。
        //このため、自分自身の発言は画面に表示する処理を行いませんがtrueとみなします。
        public function addMessageToChatLogParts(chatSendData:ChatSendData,
                                                 time:Number,
                                                 chatSenderUniqueId:String,
                                                 isReplayChatMessage:Boolean = false
                                                 ):Boolean {
            Log.logging("addMessageToChatLog called");
            
            var senderName:String = chatSendData.getNameAndState();
            var color:String = chatSendData.getColor();
            var sendto:String = chatSendData.getSendto();
            var sendtoName:String = chatSendData.getSendtoName();
            var chatMessage:String = chatSendData.getMessage();
            var channel:int = chatSendData.getChannel();
            
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                if( ! isReplayChatMessage ) {
                    Log.logging("it's replay log.");
                    pushToReplayChatLog(time, chatSenderUniqueId, chatSendData);
                    return true;
                }
            } else {
                //リプレイモード以外（通常プレイ時）に自分の発言が戻ってきた場合は表示無し
                if( isOwnMessage(senderName, chatSenderUniqueId) ) {
                    Log.logging("it's own message");
                    //でも自分の発言は正しい発言なのでtrue
                    return true;
                }
            }
            
            //カード操作時のログを残さない指定の場合、表示なしだが発言は正しいので true
            if( isInvisibleChatHandleLog(chatSenderUniqueId) ) {
                Log.logging("it's card  log. and config is set NOT record card");
                return true;
            }
            
            if( ! isPrintableMessageOnSecretMessage(chatSenderUniqueId, sendto) ) {
                //指定外のユーザーのためログ表示無し
                Log.logging("it's NOT printable message");
                return false;
            }
            
            
            var effectResult:Object = checkEffect(channel, chatMessage, senderName);
            
            chatMessage = effectResult.chatMessage;
            chatMessage = Language.getKeywordText(chatMessage);
            
            senderName = effectResult.senderName;
            if( chatMessage == null ) {
                Log.logging("effectResult.chatMessage is null");
                return false;
            }
            
            senderName = escapeHtml(senderName);
            chatMessage = escapeHtml(chatMessage);
            
            if( isReplayChatMessage ) {
                separator = "：<br>";
            }
            
            var messageLine:String = getChatMessageForPrintHtml(chatMessage, senderName, color,
                                                                time, chatWindow.getDisplayTime(), sendto, sendtoName);
            addPrintBuffer(channel, messageLine);
            
            chatWindow.playAddMessageSound(senderName);
            chatWindow.setUserNames(senderName);
            
            Log.logging("addMessageToChatLog end");
            return true;
        }
        
        public function getChatMessageForPrintHtml(chatMessage:String, 
                                                   senderName:String, 
                                                   color:String,
                                                   time:Number,
                                                   isDisplayTime:Boolean,
                                                   sendto:String = "",
                                                   sendtoName:String = ""):String {
            var messageLine:String = 
                "<font color='#" + color + "'>"
                + "<b>"
                + senderName
                + getSendtoName(sendto, sendtoName)
                + "</b>"
                + separator
                + chatMessage + "</font>";
            
            if( isDisplayTime ) {
                messageLine = Utils.getTimeTextForChat(time) + messageLine;
            }
            
            return messageLine;
        }
        
        
        private function addPrintBuffer(channel:int, message:String):void {
            var count:int = chatWindow.chatChannelCount;
            
            for(var i:int = 0 ; i < count ; i++) {
                
                var text:String = getChatMessage(message, i, channel);
                
                if( text == null ) {
                    continue;
                }
                
                chatWindow.getChatChannle(i).addBuffer(text);
            }
        }
        
        private function getChatMessage(message:String,
                                        targetChannel:int, sendChannel:int):String {
            if(targetChannel == sendChannel) {
                return message;
            }
            
            if( ! chatWindow.isDisplayOtherChannelMode() ) {
                return null;
            }
            
            var tabName:String = chatWindow.getChatChannle(sendChannel).getDefaultLabel();
            return getChatMessageOtherChannel(message, tabName);
        }
            
        static public function getChatMessageOtherChannel(message:String,
                                                          tabName:String):String {
            message = ( otherChannelPrefix + '<i>[' + tabName + "]" +message + '</i>');
            return message;
        }
        
        static public function get otherChannelPrefix():String {
            return "　　　　　";
        }
        
        private function isInvisibleChatHandleLog(chatSenderUniqueId:String):Boolean {
            if( chatSenderUniqueId != Card.cardLogStrictlyUniqueId ) {
                return false;
            }
            
            return ( ! DodontoF_Main.getInstance().getCardHandleLogVisible() );
        }
        
        private function pushToReplayChatLog(time:Number, uniqueId:String, chatSendData:ChatSendData):void {
            chatSendData.setParams('time', time);
            chatSendData.setParams('uniqueId', uniqueId);
            DodontoF_Main.getInstance().addRestChatSendDataForReplay(chatSendData);
        }
        
        static private var separator:String = "：";
        
        static public function getChatMessageSeparator():String {
            return separator;
        }
        
        
        private function getSendtoName(sendto:String, sendtoName:String):String {
            if( ! Utils.isValidSendTo(sendto) ) {
                return "";
            }

            if( sendtoName == null || sendtoName == "" ) {
                sendtoName = DodontoF_Main.getInstance().getDodontoF().getUserNameByUniqueId(sendto);
            }
            
            return " -> " + sendtoName;
        }
        
        public static function escapeHtml(htmlString:String):String {
            htmlString = htmlString.replace(/&/g, "&amp;");
            htmlString = htmlString.replace(/</g, "&lt;");
            htmlString = htmlString.replace(/>/g, "&gt;");
            htmlString = htmlString.replace(/(http[^\s　]+)/, "<u><a href='$1' target='_blank'>$1</a></u>");
            return htmlString;
        }
        
        public function vote():void {
            voter.execute();
        }
        
        private function getEffectable(channel:int):Boolean {
            
            if( guiInputSender.getSender().getReciever().isFirstChatRefresh() ) {
                return false;
            }
            
            if( channel != ChatWindow.getInstance().publicChatChannel ) {
                return false;
            }
            
            return true;
        }
        
        private function checkEffect(channel:int, chatMessage:String, senderName:String):Object {
            Log.logging("checkEffect Begin");
            
            var result:Object = {
                "chatMessage" : chatMessage, 
                "senderName"  : senderName
            };
            
            var effectable:Boolean = getEffectable(channel);
            
            result.chatMessage = checkCutInEffect(result.chatMessage, effectable);
            Log.logging("result.chatMessage", result.chatMessage);
            
            if( result.chatMessage == null ) {
                Log.logging("checkEffect End, chatMessage is null, result", result);
                return result;
            }
            
            if( effectable && chatWindow.isToMyAlarm( result.chatMessage ) ) {
                chatWindow.playSound( result.chatMessage );
            }
            
            var filterImageInfos:Array = new Array();
            result.chatMessage = voter.received( result.chatMessage, effectable, filterImageInfos );
            
            var printResult:Object
                = chatWindow.printStandingGraphics(senderName,
                                                   result.chatMessage,
                                                   effectable,
                                                   filterImageInfos);
            
            if( printResult != null ) {
                result.senderName = printResult.senderName;
                result.chatMessage = printResult.chatMessage;
            }
            
            Log.logging("checkEffect End, result", result);
            return result;
        }
        
        private function checkCutInEffect(chatMessage:String,
                                          effectable:Boolean):String {
            
            for(var i:int = 0 ; i < cutInList.length ; i++) {
                Log.logging("cutInList i", i);
                Log.logging("match target chatMessage", chatMessage);
                
                var cutIn:CutInBase = cutInList[i];
                var matchResult:Object = cutIn.matchCutIn(chatMessage);
                if( matchResult.resultData == null ) {
                    Log.logging("ChatMessageTrader.checkEffect matchResult.resultData == null");
                    continue;
                }
                
                Log.logging("matched matchResult", matchResult);
                
                cutIn = Utils.newSameClassInstance(cutIn) as CutInBase;
                
                cutIn.setEffectable(effectable);
                chatMessage = cutIn.effect( matchResult.resultData.chatMessage );
            }
            
            Log.logging("checkCutInEffect result", chatMessage);
            
            return chatMessage;
        }
        
        private function getFaildMessageTextArea(message:String):TextArea {
            var text:TextArea = new TextArea();
            text.htmlText = message;
            
            text.percentWidth = 100;
            text.height = 25;
            text.editable = false;
            
            text.setStyle("paddingTop", 0);
            text.setStyle("paddingBottom", 0);
            text.setStyle("horizontalGap", 0);
            text.setStyle("verticalGap", 0);
            text.setStyle("leading", 0);
            
            return text;
        }
        
        private function getImageId():String {
            return "loadingImage";
        }
        
        private function getChatMarkerImage(imageUrl:String):String {
            var imageSize:int = chatWindow.getChatFontSize();
            
            return '<img src="' + imageUrl + '" '
                + 'vspace="0" hspace="2" '
                + 'id="' + getImageId() + '" '
                + 'width="' + imageSize + '" '
                + 'height="' + imageSize + '" '
                + '>';
        }
        
        public function printAddedMessageToChatMessageLog():void {
            chatWindow.eachChatChannel_with_index(function(chatChannel:ChatMessageLogBox, channel:int):void {
                    
                    var isAdded:Boolean = chatWindow.addChatLogText(channel);
                    if( ! isAdded ) {
                        return;
                    }
                    
                    var isScrollFoced:Boolean = chatWindow.isScrollPositionBottom(channel);
                    chatWindow.scrollChatMessageLogIfPositionIsLast(channel, isScrollFoced);
                });
        }
        
    }
}

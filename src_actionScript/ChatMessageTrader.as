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
    
    public class ChatMessageTrader {
        
        private var cutInList:Array = new Array();
        private var chatWindow:ChatWindow;
        //private var addMessageLines:String = "";
        
        private var localMessageUniqueId:String = "localMessageUniqueId";
        private var systemMessageSenderName:String = "どどんとふ";
        private var systemMessageColor:String = "00AA00";
        private var thisObj:ChatMessageTrader;
        private var guiInputSender:GuiInputSender;
        
        private var voter:Voter;
        
        
        public function ChatMessageTrader(chatWindow_:ChatWindow) {
            thisObj = this;
            
            guiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            chatWindow = chatWindow_;
            cutInList = [new CutInCommandRollVisualDice(), new CutInMovie(), new CutInCommandGetDiceBotInfos()];
            
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
            
            chatWindow.sendSystemMessage("のチャットメッセージに不正なダイスロール結果が検出されました。\n"
                                         + chatMessage + "");
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
        
        public function sendSystemMessage(messageBase:String, isPrintName:Boolean = true):void {
            var isRoomResult:Boolean = true;
            var message:String = "";
            
            var channel:int = chatWindow.publicChatChannel;
            channel = chatWindow.changeChatChannelNumberForSystemLog(channel);
            
            var data:ChatSendData = new ChatSendData(channel, message, systemMessageSenderName);
            data.setColorString(systemMessageColor);
            data.setStateEmpty();
            
            if( isPrintName ) {
                var name:String = chatWindow.getChatCharacterName();
                message += "「" + name + "」";
                data.setMessage(message);
                message = data.getMessage();
            }
            message += messageBase;
            
            data.setMessage(message);
            data.setSendToOwnself();
            
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
            
            if( ! isValidSendTo(sendto) ) {
                Log.logging("秘話指定無しなので表示可能");
                return true;
            }
            
            if( isOwnStrictlyUniqueId(sendto) ) {
                Log.logging("秘話指定先が自分なら表示可能");
                return true;
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
            var chatMessage:String = chatSendData.getMessage();
            var channel:int = chatSendData.getChannel();

            
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                if( ! isReplayChatMessage ) {
                    var messageData:Object = [channel, senderName, chatMessage, color, time, chatSenderUniqueId];
                    DodontoF_Main.getInstance().addRestChatMessageForReplay(messageData);
                    Log.logging("it's replay log.");
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
            
            if( ! isPrintableMessageOnSecretMessage(chatSenderUniqueId, sendto) ) {
                //指定外のユーザーのためログ表示無し
                Log.logging("it's NOT printable message");
                return false;
            }
            
            
            var effectResult:Object = checkEffect(channel, chatMessage, senderName);
            chatMessage = effectResult.chatMessage;
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
                                                                time, chatWindow.getDisplayTime(), sendto);
            chatWindow.getChatChannle(channel).addBuffer(messageLine, time);
            
            //printUpdateDateString(time);
            chatWindow.playAddMessageSound(senderName);
            chatWindow.setUserNames(senderName);
            
            Log.logging("addMessageToChatLog end");
            return true;
        }
        
        static private var separator:String = "：";
        
        static public function getChatMessageSeparator():String {
            return separator;
        }
        
        
        public function getChatMessageForPrintHtml(chatMessage:String, 
                                                   senderName:String, 
                                                   color:String,
                                                   time:Number,
                                                   isDisplayTime:Boolean,
                                                   sendto:String = ""):String {
            var messageLine:String = 
                "<font color='#" + color + "'>"
                + "<b>"
                + senderName
                + getSendtoName(sendto)
                + "</b>"
                + separator
                + chatMessage + "</font>";
            
            if( isDisplayTime ) {
                messageLine = Utils.getTimeTextForChat(time) + messageLine;
            }
            
            return messageLine;
        }
        
        static public function isValidSendTo(sendto:String):Boolean {
            return ((sendto != null) && (sendto != ""));
        }
        
        private function getSendtoName(sendto:String):String {
            if( ! isValidSendTo(sendto) ) {
                return "";
            }
            
            return " -> " + DodontoF_Main.getInstance().getDodontoF().getUserNameByUniqueId(sendto);
        }
        
        public static function escapeHtml(htmlString:String):String {
            //htmlString = htmlString.replace(/\"/g, "&quot;"); //"
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
            var result:Object = {
                "chatMessage" : chatMessage, 
                "senderName"  : senderName
            };
            
            var effectable:Boolean = getEffectable(channel);
            
            result.chatMessage = checkCutInEffect(result.chatMessage, effectable);
            
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
                
                cutIn.setEffectable(effectable);
                chatMessage = cutIn.effect( matchResult.resultData.chatMessage );
                //break;
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

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
        
        private var loadingLimitSeconds:int = 15;
        
        private var voter:Voter;
        
        
        public function ChatMessageTrader(chatWindow_:ChatWindow) {
            thisObj = this;
            
            chatWindow = chatWindow_;
            cutInList = [new CutInMovie()];//, new CutInImage()];
            
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
        
        private var sendMessageIndex:int = 0;
        
        public function sendMessage(chatSendData:ChatSendData):void {
            
            var name:String = chatSendData.getName() + "\t" + chatSendData.getState();
            var color:String = chatSendData.getColor();
            var sendto:String = chatSendData.getSendto();
            var chatMessage:String = chatSendData.getMessage();
            var channel:int = chatSendData.getChannel();
            
            
            //不正なダイスロールならここで終了
            if( checkInvalidDiceRoll(chatMessage, chatSendData.isDiceRollResult()) ) {
                return;
            }
            
            var messageIndex:int = sendMessageIndex++;
            
            try{
                var time:Number = 0; //(new Date().getTime() / 1000);
                var isReplayChatMessage:Boolean = false;
                addMessageToChatLog(channel, name, chatMessage, color, time, localMessageUniqueId,
                                    isReplayChatMessage, sendto, messageIndex);
                
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                guiInputSender.sendChatMessage(name, chatMessage, color, messageIndex, sendto,
                                               DodontoF_Main.getInstance().getChatWindow().getSelectedChatChannleIndex());
            } catch(error:Error) {
                this.status = error.message;
            }
        }
        
        
        public function addLocalMessage(message:String):void {
            addMessageToChatLog(ChatWindow.getInstance().publicChatChannel, systemMessageSenderName, message, systemMessageColor, 0, "dummy");
        }
        
        public function sendSystemMessage(messageBase:String, isPrintName:Boolean = true):void {
            var isRoomResult:Boolean = true;
            var message:String = "";
            
            var channel:int = ChatWindow.getInstance().publicChatChannel;
            channel = ChatWindow.getInstance().changeChatChannelNumberForSystemLog(channel);
            
            if( isPrintName ) {
                var data:ChatSendData = new ChatSendData(channel, "");
                message += "「" + data.getName() + "」";
                data.setMessage(message);
                message = data.getMessage();
            }
            message += messageBase;
            
            var messageIndexTmp:int = -1;
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.sendChatMessage(systemMessageSenderName, message, systemMessageColor, messageIndexTmp,
                                           null, channel);
        }
        
        public function addMessageToChatLog(channel:int,
                                            senderName:String,
                                            chatMessage:String,
                                            color:String,
                                            time:Number,
                                            chatSenderUniqueId:String,
                                            isReplayChatMessage:Boolean = false,
                                            sendto:String = null,
                                            messageIndex:int = -1):void {
            addMessageToChatLogParts(channel,
                                     senderName,
                                     chatMessage,
                                     color,
                                     time,
                                     chatSenderUniqueId,
                                     messageIndex,
                                     sendto,
                                     isReplayChatMessage);
            printAddedMessageToChatMessageLog();
        }
        
        private function getOwnUniqueId():String {
            return DodontoF_Main.getInstance().getGuiInputSender().getSender().getUniqueId();
        }
        
        private function isPrintableMessageOnSecretMessage(chatSenderUniqueId:String, sendto:String):Boolean {
            
            if( chatSenderUniqueId == localMessageUniqueId ) {
                //"送信者が自分なら表示可能"
                return true;
            }
            
            if( ! isValidSendTo(sendto) ) {
                //秘話指定無しなので表示可能
                return true;
            }
            
            if( sendto == getOwnUniqueId() ) {
                //秘話指定先が自分なら表示可能
                return true;
            }
            
            return false;
        }
        
        public function addMessageToChatLogParts(channel:int,
                                                 senderName:String,
                                                 chatMessage:String,
                                                 color:String,
                                                 time:Number,
                                                 chatSenderUniqueId:String,
                                                 messageIndex:int = -1,
                                                 sendto:String = null,
                                                 isReplayChatMessage:Boolean = false
                                                 ):Boolean {
            Log.logging("addMessageToChatLog called");
            
            //自分の発言が戻ってきた場合は表示無し
            if( (senderName != systemMessageSenderName) && (senderName != "") ) {
                if( getOwnUniqueId() == chatSenderUniqueId ) {
                    Log.logging("it's own message");
                    return false;
                }
            }
            
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                if( ! isReplayChatMessage ) {
                    var messageData:Object = [channel, senderName, chatMessage, color, time, chatSenderUniqueId];
                    DodontoF_Main.getInstance().addRestChatMessageForReplay(messageData);
                    Log.logging("it's replay log.");
                    return false;
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
            var separator:String = "：";
            
            if( isReplayChatMessage ) {
                separator = "：<br>";
            }
            
            var messageLine:String = 
                "<font color='#" + color + "'>"
                + "<b>"
                + senderName
                + getSendtoName(sendto)
                + "</b>"
                + separator
                + chatMessage + "</font>";
            
            chatWindow.getChatChannle(channel).addBuffer(messageLine, time);
            
            //printUpdateDateString(time);
            chatWindow.playAddMessageSound(senderName);
            chatWindow.setUserNames(senderName);
            
            Log.logging("addMessageToChatLog end");
            return true;
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
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
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
            
            
            if( effectable && chatWindow.isToMyAlarm( chatMessage ) ) {
                chatWindow.playSound(chatMessage);
            }
            
            var filterImageInfos:Array = new Array();
            result.chatMessage = voter.received( chatMessage, effectable, filterImageInfos );
            
            var printResult:Object = chatWindow.printStandingGraphics(senderName,
                                                                      result.chatMessage,
                                                                      effectable,
                                                                      filterImageInfos);
            
            if( printResult != null ) {
                result.senderName = printResult.senderName;
                result.chatMessage = printResult.chatMessage;
            }
            
            for(var i:int = 0 ; i < cutInList.length ; i++) {
                var cutIn:CutInBase = cutInList[i];
                var matchResult:Object = cutIn.matchCutIn(chatMessage);
                if( matchResult.resultData == null ) {
                    continue;
                }
                
                cutIn.setSoundOn( chatWindow.isSoundOnMode() );
                cutIn.setEffectable(effectable);
                result.chatMessage = cutIn.effect( matchResult.resultData.chatMessage );
            }
            
            return result;
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

//--*-coding:utf-8-*--

package {
    
    import mx.core.UIComponent;
    import flash.events.MouseEvent;
    import mx.containers.Box;
    import mx.controls.Text;
    import mx.controls.Alert;
    
    public class NovelticMode {
        
        private var chatWindow:ChatWindow = null;
        private var isNovelticMode:Boolean = false;
        private var defaultChatLogHeight:int = 50;
        
        private static var chatLogLayer:UIComponent = null;
        private static var thisObj:NovelticMode;
        
        public static function addEventListenerOfMouseOverForChatLogLayer(_chatLogLayer:UIComponent):void {
            chatLogLayer = _chatLogLayer;
            chatLogLayer.visible = true;
            
            chatLogLayer.addEventListener( MouseEvent.ROLL_OVER, function(event:MouseEvent):void {
                    changeLogInvisible(event);
                });
            /*
            chatLogLayer.addEventListener( MouseEvent.ROLL_OUT, function(event:MouseEvent):void {
                    thisObj.changeLogVisible();
                });
            */
            
        }
        
        public function init():void {
            if( Config.getInstance().isNovelticModeOn() ) {
                changeNovelticMode(true);
            }
            changeButtonStates();
        }
        
        public function setLogVisible(event:MouseEvent, visible:Boolean):void {
            if( visible ) {
                changeLogVisible();
            } else {
                changeLogInvisible(event);
            }
        }
        
        public function changeLogVisible():void {
            if( ! isNovelticMode ) {
                return;
            }
            
            chatLogLayer.visible = true;
        }
        
        public function changeLogInvisible(event:MouseEvent):void {
            NovelticMode.changeLogInvisible(event);
        }
        
        public static function changeLogInvisible(event:MouseEvent):void {
            var chatWindowLocal:ChatWindow = DodontoF_Main.getInstance().getChatWindow();
            
            if( ! chatWindowLocal.isHideNovelticWindow.selected ) {
                return;
            }
            
            if( event.shiftKey ){
                return;
            }
            if( event.ctrlKey ){
                return;
            }
            
            chatLogLayer.visible = false;
        }
        
        
        public function NovelticMode(chatWindow_:ChatWindow):void {
            thisObj = this;
            chatWindow = chatWindow_;
        }
        
        public function isNovelticModeOn():Boolean {
            return isNovelticMode;
        }
        
        public function scrollChatMessageLogIfPositionIsLast(isForceScroll:Boolean):void {
            textLogBox.validateNow();
            chatWindow.scrollChatBox(textLogBox, isForceScroll);
        }
        
        
        public function changeButtonStates():void {
            chatWindow.isHideNovelticWindow.visible = isNovelticMode;
            chatWindow.isHideNovelticWindow.width = ( isNovelticMode ? 80 : 0);
            chatWindow.novelticModeButton.toolTip = ( isNovelticMode ?
                                                      "ログ表示をノベルゲーム風表示から通常ログに切り替える" :
                                                      "ログ表示をノベルゲーム風表示へ切り替える");
        }
        
        private var textLogBox:Box = new Box();
        private var isTextBoxInited:Boolean = false;
        
        public function addChatMessageLog(text:Text):void {
            textLogBox.addChild(text);
        }
        
        private function addTextToTextBox():void {
            var chatMessageLogList:Array = chatWindow.getChatMessageLogList();
            
            for(var i:int ; i < chatMessageLogList.length ; i++) {
                var text:Text = chatMessageLogList[i] as Text;
                try {
                    chatWindow.chatMessageLogBox.removeChild( text );
                    textLogBox.addChild(text);
                } catch (e:Error) {
                }
            }
        }
        
        private function removeTextFromTextBox():void {
            var chatMessageLogList:Array = chatWindow.getChatMessageLogList();
            for(var i:int = 0 ; i < chatMessageLogList.length ; i++) {
                var text:Text = chatMessageLogList[i] as Text;
                try {
                    textLogBox.removeChild(text);
                    chatWindow.chatMessageLogBox.addNewTextBlock( text, true );
                }catch(e:Error) {
                }
            }
        }
        
        private function setTextBoxPosition():void {
            textLogBox.x = chatWindow.x;
            textLogBox.y = 0;
            textLogBox.width = chatWindow.width;
            
            textLogBox.height = (chatWindow.y - 36);
        }
        
        public function resizeAndMoveWindow():void {
            if( ! isNovelticMode ) {
                return;
            }
            
            setTextBoxPosition();
        }
        
        public function setChatBackgroundColor(color:String):void {
            textLogBox.setStyle('backgroundColor', '0x' + color);
        }
        
        public function saveInfo():void {
            Config.getInstance().saveNovelticMode(isNovelticMode);
        }
        
        public function wheelEvent(event:MouseEvent):void {
            if( ! isNovelticMode ) {
                return;
            }
            
            ChatWindow.wheelScrollComponent(textLogBox, event);
        }
        
        public function changeNovelticMode(isInit:Boolean = false):void {
            chatWindow.novelticModeButton.enabled = false;
            
            isNovelticMode = ( ! isNovelticMode );
            
            if( ! isTextBoxInited ) {
                isTextBoxInited = true;
                chatLogLayer.addChild( textLogBox );
                setChatBackgroundColor('FFFFFF');
            }
            
            if( isNovelticMode ) {
                var compressHeight:int = chatWindow.chatMessageLogBox.height - 2;
                compressForNovelticMode(true, compressHeight, isInit);
                try {
                    addTextToTextBox();
                    setChatMessageLogBoxAlpha( textLogBox, 0.8 );
                    setTextBoxPosition();
                }catch(e:Error){
                    Log.loggingException("NovelticMode.changeNovelticMode", e);
                }
                
                textLogBox.visible = true;
            } else {
                textLogBox.visible = false;
                
                setChatMessageLogBoxAlpha( textLogBox, 1 );
                removeTextFromTextBox();
                
                compressForNovelticMode(false, defaultChatLogHeight, isInit);
            }
            
            changeButtonStates();
            
            chatWindow.scrollChatMessageLogIfPositionIsLast(ChatWindow.getInstance().publicChatChannel, true);
            chatWindow.novelticModeButton.enabled = true;
            
            saveInfo();
        }
        
        private function compressForNovelticMode(isCompress:Boolean, compressHeight:int, isInit:Boolean):void {
            try {
                chatWindow.setChatChannelVisible(ChatWindow.getInstance().publicChatChannel, ( ! isCompress ));
                if( isCompress ) {
                    chatWindow.selectChatChannel(ChatWindow.getInstance().lastChatChannel);
                }
                chatWindow.validateNow();
            } catch (e:Error) {
            }
            Log.loggingError("isCompress:" + isCompress);
            //textLogBox.visible = true;
            return;
            ////////////////////////////////
            var rate:int = (isCompress ? -1 : 1);
            
            if( ! isInit ) {
                chatWindow.height += (compressHeight * rate);
                chatWindow.y += (compressHeight * rate * -1);
                
                chatWindow.getStandingGraphics().shiftAllImagesYPosition( (compressHeight * rate * -1) );
            }
            
            chatWindow.validateNow();
            chatWindow.chatMessageLogBoxDivder.moveDivider(0, compressHeight * rate);
            chatWindow.chatMessageLogBox.visible = ( ! isCompress );
        }
        
        private function setChatMessageLogBoxAlpha(textLogBox:Box, alpha:Number):void {
            textLogBox.alpha = alpha;
            textLogBox.setStyle('backgroundAlpha', alpha);
        }
        
        
    }
}


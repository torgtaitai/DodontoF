//--*-coding:utf-8-*--

package {
    import mx.controls.CheckBox;
    
    public class ChangePlayRoomWindow extends CreatePlayRoomWindow {
        import mx.managers.PopUpManager;
        
        private var backgroundImage:String;
        private var playRoomNameOriginal:String = "";
        
        public function setPlayRoomInfo(name:String,
                                        password:String,
                                        chatChannelNames:Array,
                                        canUseExternalImage:Boolean,
                                        canVisitValue:Boolean,
                                        backgroundImage_:String):void {
            this.validateNow();
            
            playRoomNameOriginal = name;
            playRoomName.text = name;
            playRoomPassword.text = password;
            
            if( canUseExternalImage ) {
                canUseExternalImageRadioGroup.selectedValue = "canUseExternalImage";
            }
            
            if( canVisitValue ) {
                canVisitRadioGroup.selectedValue = "canVisit";
                changeVisitMode(true);
                chatChannelNames.pop();
            }
            
            chatChannelNames.shift();
            chatChannelNamesText.text = chatChannelNames.join("　");
            
            backgroundImage = backgroundImage_;
        }
        
        override protected function init():void {
            super.init();
            
            title=Language.s.changePlayRoom;
            executeButton.label = Language.s.changeButton;
        }
        
        override protected function initViewStateInfos():void {
            super.initViewStateInfos();
            
            var serverViewStateInfo:Object = DodontoF_Main.getInstance().getServerViewStateInfo();
            
            for each(var info:Object in menuInfos) {
                    var checkBox:CheckBox = info.checkBox;
                    
                    var obj:Object = serverViewStateInfo[ info.data ];
                    if( obj == null ) {
                        continue;
                    }
                    
                    var b:Boolean = obj as Boolean;
                    checkBox.selected = b;
                }
        }
        
        // プレイルーム情報の変更を実行する
        override protected function execute():void {
            try {
                var chatChannelNames:Array = getChatChannelNames();
                
                executeButton.enabled = false;
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                guiInputSender.changePlayRoom(playRoomNameOriginal,
                                              playRoomName.text,
                                              playRoomPassword.text,
                                              chatChannelNames,
                                              canUseExternalImage.selected,
                                              canVisit.selected,
                                              backgroundImage,
                                              getGameType(),
                                              getViewStates(),
                                              playRoomIndex,
                                              executeResult);
            } catch(error:Error) {
                this.status = error.message;
                executeButton.enabled = true;
            }
            
        }
        
    }
}


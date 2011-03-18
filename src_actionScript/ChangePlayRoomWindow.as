//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class ChangePlayRoomWindow extends CreatePlayRoomWindow {
        import mx.managers.PopUpManager;
        
        //private static var character:Character;
        /*
        public static function setCharacter(character_:Character):void {
            character = character_;
        }
        */
        
        public function setPlayRoomInfo(name:String,
                                        password:String,
                                        chatChannelNames:Array,
                                        canUseExternalImage:Boolean,
                                        canVisitValue:Boolean):void {
            this.validateNow();
            
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
            
        }
        
        override protected function init():void {
            super.init();
            
            title="プレイルーム変更";
            executeButton.label = "変更";
        }
        
        
        override protected function execute():void {
            try {
                var chatChannelNames:Array = getChatChannelNames();
                
                executeButton.enabled = false;
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                guiInputSender.changePlayRoom(playRoomName.text,
                                              playRoomPassword.text,
                                              chatChannelNames,
                                              canUseExternalImage.selected,
                                              canVisit.selected,
                                              playRoomIndex,
                                              executeResult);
            } catch(error:Error) {
                this.status = error.message;
            }
            
        }
        
    }
}


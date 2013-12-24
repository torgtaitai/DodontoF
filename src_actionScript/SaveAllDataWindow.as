//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class SaveAllDataWindow extends SaveWindow {
        
        override protected function setup():void {
            this.title = Language.s.allSaveData;
            
            loadingMessage.text = Language.s.saveDataTips;
            
            var height:int = 25;
            this.height += height;
            loadingMessageBox.height += height;
            loadingMessage2.height = height;
            loadingMessage2.visible = true;
            loadingMessage2.text = Language.s.saveDataTips2;
            
            super.setup();
        }
        
        override protected function executeServerSave():void {
            var data:Object = DodontoF_Main.getInstance().getChatPaletteWindow().getSaveData();
            var chatPaletteData:String = Utils.getJsonString(data);
            Log.logging("chatPaletteData", chatPaletteData);
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.saveAllData(chatPaletteData, this.resultFuction);
        }
        
        override protected function getReadyMessage():String {
            return Language.s.saveFileReady;
        }
        
    }
}
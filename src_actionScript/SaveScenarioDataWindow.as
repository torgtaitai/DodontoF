//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class SaveScenarioDataWindow extends SaveWindow {
        
        override protected function executeServerSave():void {
            this.title = "シナリオファイル保存";
            
            var chatPaletteSaveData:String = DodontoF_Main.getInstance().getChatPaletteWindow().getSaveData();
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.saveScenario(chatPaletteSaveData, this.resultFuction);
        }
        
        override protected function getReadyMessage():String {
            return "シナリオファイル準備完了";
        }
        
    }
}
//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class SaveAllDataWindow extends SaveWindow {
        
        override protected function setup():void {
            this.title = "全データセーブ";
            
            loadingMessage.text = "画像等の全データをファイルとして保存します。";
            
            var height:int = 25;
            this.height += height;
            loadingMessageBox.height += height;
            loadingMessage2.height = height;
            loadingMessage2.visible = true;
            loadingMessage2.text = "このファイルを使って別サーバへ移行することも可能です！";
            
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
            return "ファイル準備完了";
        }
        
    }
}
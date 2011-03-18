//--*-coding:utf-8-*--

package {
    public class ChangeMemoWindow extends AddMemoWindow {
        import mx.managers.PopUpManager;
        
        private var memo:Memo;
        
        public function setMemo(m:Memo):void {
            memo = m;
        }
        
        protected override function init():void {
            title = "共有メモ変更";
            executeButton.label = "変更";
            
            message.text = memo.getMessage();
        }
        
        override public function execute():void {
            changeMemo();
        }
        
        private function changeMemo():void {
            try{
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                memo.setMessage( message.text );
                guiInputSender.getSender().changeCharacter( memo.getJsonData() );
                
                PopUpManager.removePopUp(this);
            } catch(error:Error) {
                this.status = error.message;
            }
        }
    }
}



//--*-coding:utf-8-*--

package {
    public class ChangeMemoWindow extends AddMemoWindow {
        import mx.managers.PopUpManager;
        
        private var memo:Memo;
        
        public function setMemo(m:Memo):void {
            memo = m;
        }
        
        /**
         * Windowの初期化処理
         */
        override protected function setup():void {
            title = "共有メモ変更";
            executeButton.label = "変更";
            
            message.text = memo.getMessage();
        }
        
        override public function execute():void {
            try{
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                memo.setMessage( message.text );
                memo.loadViewImage();
                guiInputSender.getSender().changeCharacter( memo.getJsonData() );
                
                memo.updateByOwn();
                
                PopUpManager.removePopUp(this);
            } catch(error:Error) {
                this.status = error.message;
            }
        }
    }
}



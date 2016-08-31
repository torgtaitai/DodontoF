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
            title = Language.s.changeSharedMemoWindowTitle;
            executeButton.label = Language.s.changeButton;
            
            setMessage(memo.getMessage());
        }
        
        private function setMessage(text:String):void {
            var messageList:Array = getMessageList(text);
            
            for(var i:int = 0 ; i < messageList.length ; i++) {
                var text:String = messageList[i];
                addTab(text);
            }
            
            tabs.selectedIndex = 0;
        }
        
        override public function execute():void {
            try{
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                memo.setMessage( getMessageText() );
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



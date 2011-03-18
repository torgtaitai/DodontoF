//--*-coding:utf-8-*--

package {
    public class ChangeStatusMarkerWindow extends AddStatusMarkerWindow {
        
        import mx.managers.PopUpManager;
        
        private var statusMarker:StatusMarker;
        
        public function setStatusMarker(marker_:StatusMarker):void {
            statusMarker = marker_;
        }
        
        protected override function init():void {
            title = "状態マーカー変更";
            executeButton.label = "変更";
            
            message.text = statusMarker.getMessage();
        }
        
        override public function execute():void {
            changeStatusMarker();
        }
        
        private function changeStatusMarker():void {
            try{
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                
                statusMarker.setMessage( message.text );
                statusMarker.loadViewImage();
                
                guiInputSender.getSender().changeCharacter( statusMarker.getJsonData() );
                PopUpManager.removePopUp(this);
            } catch(error:Error) {
                this.status = error.message;
            }
        }
    }
}



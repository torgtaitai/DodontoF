//--*-coding:utf-8-*--

package {
    
    public class ChangeMessageCardWindow extends AddMessageCardWindow {
        
        /**
         * Windowの初期化処理
         */
        override protected function setup():void {
            super.setup();
            
            this.title = Language.s.changeMessageCardWindow
            executeButton.label = Language.s.changeMessageCard;
            
            Utils.sendSystemMessage(Language.s.changingMessageCardMessage);
        }
        
        
        private var card:Card;
        
        public function setCard(_card:Card):void {
            card = _card;
            
            imageName.text = getText( card.getImageName() );
            imageNameBack.text = getText( card.getImageNameBack() );
            
            initPreview();
        }
        
        private function getText(textOriginal:String):String {
            
            var text:String = textOriginal.replace(/\r/g, "<br>")
            
            var messageReg:RegExp = /\>(.*)\</m;
            var result:Object = messageReg.exec(text);
            
            if( result == null ) {
                return textOriginal;
            }
            
            var message:String = result[1];
            message = message.replace(/<br>/g, "\r");
            
            return message;
        }
        
        
        /** 
         * カード変更処理
         */
        override public function execute():void {
            var imageNameText:String = getHtml( imageNameSize.value, imageName.text );
            var imageNameBackText:String = getHtml( imageNameBackSize.value, imageNameBack.text );
            
            card.setImageName( imageNameText );
            card.setImageNameBack( imageNameBackText );
            
            DodontoF_Main.getInstance().getGuiInputSender().getSender()
                .changeCharacter( card.getJsonData() );
            
            card.updateRefresh();
            Utils.sendSystemMessage(Language.s.changeMessageCardMessage);
            
            closeAction();
        }
        
    }
}


//--*-coding:utf-8-*--

package {
    public class CardPickup extends Card {
        
        public function CardPickup(params:Object) {
            super(params);
        }
        
        private var card:Card = null;
        
        public function setCard(card_:Card):void {
            card = card_;
            setTitleVisible(card.getTitleVisible());
            update( card.getJsonDataForPreview() );
        }
        
        override public function getWidth():int {
            return card.getWidth();
        }
        
        override public function getHeight():int {
            return card.getHeight();
        }
        
        override public function getTitleText():String {
            if( card == null ) {
                return "";
            }
            
            return card.getTitleText();
        }
    }
}

//--*-coding:utf-8-*--

package {
    public class CardPickUp extends Card {
        
        public function CardPickUp(params:Object) {
            super(params);
        }
        
        private var card:Card = null;
        
        public function setCard(card_:Card):void {
            card = card_;
            
            roundColor = card.getRoundColor();
            setTitleVisible(card.isTitleVisible());
            
            update( card.getJsonDataForPreview() );
        }
        
        /** 
         * カードの拡大率指定
         */
        public function setRate(rate:Number):void {
            view.scaleX = rate;
            view.scaleY = rate;
        }
        
        private var roundColor:int;
        override public function getRoundColor():int {
            return roundColor;
        }

        override public function getWidth():int {
            return card.getWidth();
        }
        
        override public function getHeight():int {
            return card.getHeight();
        }
        
        override public function getMountName():String {
            if( card == null ) {
                return "CardPickUp";
            }
            
            return card.getMountName();
        }
       
        override public function getTitleText():String {
            if( card == null ) {
                return "";
            }
            
            return card.getTitleText();
        }
        
        override protected function canRotate():Boolean {
            return false;
        }
        
        override protected function canDoubleClick():Boolean {
            return false;
        }
        
        
    }
}

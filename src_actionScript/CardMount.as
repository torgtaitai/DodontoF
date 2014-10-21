//--*-coding:utf-8-*--

package {
    
    import flash.events.MouseEvent;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.TextFieldAutoSize;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.geom.Point;
    import mx.controls.Text;
    import mx.controls.Label;
    import mx.managers.PopUpManager;
    import mx.containers.Box;
    import mx.effects.Glow;
    
    public class CardMount extends Card {
        
        public static function getTypeStatic():String {
            return "CardMount";
        }
        
        override public function isTrashable():Boolean {
            return false;
        }
        
        override public function getType():String {
            return getTypeStatic();
        }

        override public function getTypeName():String {
            return Language.s.cardMount;
        }
        
        public function getCardCount():int {
            return this.cardCount;
        }
        
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x_:int,
                                           y_:int):Object {
            var characterJsonData:Object = Card.getJsonData(imageName_, imageNameBack_, x_, y_);
            
            characterJsonData.type = getTypeStatic();
            characterJsonData.cardCount = 0;
            
            return characterJsonData;
        }
        
        override public function getJsonData():Object {
            var characterJsonData:Object = super.getJsonData();
            
            characterJsonData.type = getTypeStatic();
            characterJsonData.cardCount = this.cardCount;
            
            return characterJsonData;
        }
        
        private var cardCount:int = 0;
        
        public function CardMount(params:Object) {
            super(params);
        }
        
        override protected function setParams(params:Object):void {
            this.cardCount = params.cardCount;
            
            super.setParams(params);
        }
        
        override public function getRoundColor():int {
            return 0xEEEEEE;
        }

        override public function getTitleText():String {
            return Language.text("cardMountCountDisplay", getCardCount());
        }
        
        override protected function isOwner():Boolean {
            return false;
        }
        
        override protected function isSetViewForevroungOnMouseClicked():Boolean {
            return false;
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, Language.s.drawCardForMe, getContextMenuItemCardDraw, false);
            addMenuItem(menu, Language.s.drawCardForEveryone, getContextMenuItemCardDrawPublic, false);
            addMenuItem(menu, Language.s.drawCardClosed, getContextMenuItemCardDrawSecret, false);
            
            addMenuItem(menu, Language.s.drawCardMany, getContextMenuItemCardDrawMany, true);
            
            addMenuItem(menu, Language.s.selectCardFromMount, getContextMenuItemCardSelect, true);
            
            view.contextMenu = menu;
        }
        
        private function getContextMenuItemCardDraw(event:ContextMenuEvent):void {
            try {
                drawCard(false);
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
        private function getContextMenuItemCardDrawPublic(event:ContextMenuEvent):void {
            try {
                drawCard(true);
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
        private function getContextMenuItemCardDrawSecret(event:ContextMenuEvent):void {
            try {
                drawCardSecret();
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
        protected function getContextMenuItemCardDrawMany(event:ContextMenuEvent):void {
            try {
                openDrawCardWindow();
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
        protected function getContextMenuItemCardSelect(event:ContextMenuEvent):void {
            try {
                openSelectCardWindow();
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
        override protected function isPrintCardText():Boolean {
            return false;
        }
        
        public function drawCard(isOpen_:Boolean, count:int = 1):void {
            if( this.cardCount <= 0 ) {
                return;
            }
            
            sender.drawCard( isOpen_,
                             getSelfOwnerId(),
                             getSelfOwnerName(),
                             this.getMountName(),
                             getNewCardImgId(),
                             this.getX() + (getWidth() * Map.getSquareLength() / 3),
                             this.getY() + 10,
                             getId(),
                             count,
                             printCardDrawMessage);
        }
        
        private function printCardDrawMessage(jsonData:Object):void {
            if( jsonData["result"] != "OK" ) {
                return;
            }
            
            var cardDataList:Array = jsonData["cardDataList"];
            var openCardNames:Array = [];
            var closeCardNames:Array = [];
            
            for each(var cardData:Object in cardDataList) {
                    if( cardData == null ) {
                        return;
                    }
                    
                    var card:Card = new Card(cardData);
                    if( card.isOpenMode() ) {
                        openCardNames.push( card.getCardName() );
                    } else {
                        closeCardNames.push( card.getCardName() );
                    }
                }
            
            if( openCardNames.length > 0 ) {
                var cardsText:String = openCardNames.join(Language.s.drawCardAndOpenMessageSeparactor);
                printCardLog(Language.s.drawCardAndOpenMessage,
                             [this.getMountNameForDisplay(), cardsText]);
            }
            
            if( closeCardNames.length > 0 ) {
                printCardLog(Language.s.drawCardMessage,
                             [this.getMountNameForDisplay()]);
            }
        }
        
        private function getNewCardImgId():String {
            var newCardImgId:String = MovablePiece.getDefaultId();
            return newCardImgId;
        }
        
        public function drawCardSecret(count:int = 1):void {
            printCardLog(Language.s.drawCardSecretMessage,
                         [this.getMountNameForDisplay()]);
            
            var isOpen:Boolean = false;
            var ownerId:String = Card.getNobodyOwner();
            var ownerName:String = "";
            
            var newCardImgId:String = MovablePiece.getDefaultId();
            
            sender.drawCard( isOpen,
                             ownerId,
                             ownerName,
                             this.getMountName(),
                             getNewCardImgId(),
                             this.getX() + 10,
                             this.getY() + 10,
                             getId(),
                             count,
                             printCardDrawMessage);
        }
        
        protected function openDrawCardWindow():void {
            var window:DrawCardWindow = DodontoF.popup(DrawCardWindow, true) as DrawCardWindow;
            window.setCardMount(this);
        }
        
        
        protected function openSelectCardWindow():void {
            var window:SelectCardWindow = DodontoF.popup(SelectCardWindow, true) as SelectCardWindow;
            window.setCardMount(this);
        }
        
        
        override protected function canDoubleClick():Boolean {
            return true;
        }
        
        override protected function doubleClickEvent(event:MouseEvent):void {
            drawCard(false);
        }
                
    }
}

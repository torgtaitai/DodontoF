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
    
    public class CardZone extends Card {
        
        public static function getTypeStatic():String {
            return "CardZone";
        }
        
        public function CardZone(params:Object) {
            super(params);
            setTitleVisible(false);
            view.alpha = 0.5;
            view.setLineDiameter( 0 );
        }
        
        override public function isTrashable():Boolean {
            return false;
        }
        
        override public function canExtendOnPositionX():Boolean {
            return false;
        }
        
        override public function canExtendOnPositionY():Boolean {
            return false;
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "カード置き場";
        }
        
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x_:int,
                                           y_:int):Object {
            var characterJsonData:Object = Card.getJsonData(imageName_, imageNameBack_, x_, y_);
            
            characterJsonData.type = getTypeStatic();
            
            return characterJsonData;
        }
        
        override public function getJsonData():Object {
            var characterJsonData:Object = super.getJsonData();
            
            characterJsonData.type = getTypeStatic();
            
            return characterJsonData;
        }
        
        override protected function setParams(params:Object):void {
            super.setParams(params);
        }
        
        override protected function getWidthSize():Number {
            return 4;
        }
        
        override protected function getHeightSize():Number {
            return 2;
        }
        
        override public function isPickupable():Boolean {
            return false;
        }
        
        override public function getRoundColor():int {
            return 0xFFFFCC;
        }
        override protected function getCardBackColor(message:String):uint {
            return 0xFFFFCC;
        }
        
        override public function getLoadImageUrl():String {
            return "<p align='center'><font size=\"70\"><br><br><br>" + this.getTitleText() + "</font></p>"
        }
        
        override public function getTitleText():String {
            return this.getOwnerName() + "の手札置き場";
        }
        
        override protected function isOwner():Boolean {
            return false;
        }
        
        override protected function isSetViewForevroungOnMouseClicked():Boolean {
            return false;
        }
        
        override protected function isPrintCardText():Boolean {
            return false;
        }
        
        public function hitTestObject(card:Card):Boolean {
            if( card == this ) {
                return false;
            }
            
            return view.hitTestObject(card.getView());
        }
        
        public function getCenterX():Number {
            return getX() + ( 1 * Map.getSquareLength() );
        }
        
        public function getCenterY():Number {
            return getY() + ( -2 * Map.getSquareLength() );
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "手札置き場を自分の管理へ", changeOwner);
            addMenuItem(menu, "手札置き場の削除", getContextMenuItemRemoveCharacter, true);
            
            view.contextMenu = menu;
        }
        
        override public function changeOwner(event:ContextMenuEvent = null):void {
            ChatWindow.getInstance().sendSystemMessage("が「" + getOwnerName() + "」のカード一式を受け取りました。");
            
            setOwnerName( getSelfOwnerName() );
            
            loadViewImage();
            sender.changeCharacter( getJsonData() );
            
            var cards:Array = getMap().getTargetTypes( [Card.getTypeStatic()] );
            
            for(var i:int = 0 ; i < cards.length ; i++) {
                var card:Card = cards[i] as Card;
                
                if( hitTestObject(card) ) {
                    card.changeOwner();
                }
            }
        }
        
        override protected function canRotate():Boolean {
            return false;
        }
        
        override protected function canDoubleClick():Boolean {
            return false;
        }
    }
}

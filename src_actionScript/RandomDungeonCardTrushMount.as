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
    
    public class RandomDungeonCardTrushMount extends CardTrushMount {
        
        public static function getTypeStatic():String {
            return "RandomDungeonCardTrushMount";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x_:int,
                                           y_:int):Object {
            var characterJsonData:Object = CardMount.getJsonData(imageName_, imageNameBack_, x_, y_);
            
            characterJsonData.type = getTypeStatic();
            
            return characterJsonData;
        }
        
        override public function getJsonData():Object {
            var characterJsonData:Object = super.getJsonData();
            
            characterJsonData.type = getTypeStatic();
            
            return characterJsonData;
        }
        
        public function RandomDungeonCardTrushMount(params:Object) {
            super(params);
        }
        
        override public function getTitleText():String {
            return "捨て札：" + getCardCount() + "枚";
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "一番上のカードを場に戻す", getContextMenuItemCardReturn);
            addMenuItem(menu, "Aのみ山に戻して次のダンジョンタイルを準備する", getContextShuffleForNextRandomDungeon, true);
            
            view.contextMenu = menu;
        }
        
        private function getContextShuffleForNextRandomDungeon(event:ContextMenuEvent):void {
            try {
                sender.shuffleForNextRandomDungeon(this.getMountName(), this.getId());
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
   }
}

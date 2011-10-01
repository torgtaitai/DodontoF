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
    
    public class RandomDungeonCardMount extends CardMount {
        
        public static function getTypeStatic():String {
            return "RandomDungeonCardMount";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "ランダムダンジョン用カード山";
        }
        
        override public function getCardCount():int {
            return super.getCardCount() - this.cardCountDisplayDiff;
        }
        
        public static function getJsonData(imageName_:String,
                                           imageNameBack_:String,
                                           x_:int,
                                           y_:int):Object {
            var params:Object = CardMount.getJsonData(imageName_, imageNameBack_, x_, y_);
            
            params.type = getTypeStatic();
            params.cardCountDisplayDiff = 0;
            
            return params;
        }
        
        override public function getJsonData():Object {
            var params:Object = super.getJsonData();
            
            params.type = getTypeStatic();
            params.cardCountDisplayDiff = this.cardCountDisplayDiff;
            
            return params;
        }
        
        private var cardCountDisplayDiff:int = 0;
        
        public function RandomDungeonCardMount(params:Object) {
            super(params);
        }
        
        override protected function setParams(params:Object):void {
            this.cardCountDisplayDiff = params.cardCountDisplayDiff;
            
            super.setParams(params);
        }
        
        override public function getTitleText():String {
            return "山札:" + getCardCount() + "枚";
        }
        
        /*
        override protected function initContextMenu():void {
            super.initContextMenu();
            
            var menu:ContextMenu = view.contextMenu;
            addMenuItem(menu, "Aのみ山に戻して次のダンジョンタイルを準備する", getContextShuffleForNextRandomDungeon, true);
        }
        
        private function getContextShuffleForNextRandomDungeon(event:ContextMenuEvent):void {
            try {
                sender.shuffleForNextRandomDungeon(this.getId());
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        */
        
        
    }
}
    

//--*-coding:utf-8-*--

package {

    import mx.controls.Alert;
    import flash.text.TextFormatAlign;
    import flash.text.TextFormat;
    import flash.text.TextField;
    import mx.controls.Text;
    import mx.core.UIComponent;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import mx.managers.PopUpManager;
    import mx.core.UIComponent;
    
    public class Memo extends MapMarker {
        
        public static function getTypeStatic():String {
            return "Memo";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        
        public static function getJsonData(message:String):Object {
            var color:uint = 0xFFFFFF;//0xBBBB00;
            var isPaint:Boolean = true;
            var width:int = 1;
            var height:int = 1;
            var positionX:int = 0;
            var positionY:int = 0;
            var isFront:Boolean = true;
            
            var jsonData:Object = MapMarker.getJsonData(message, color, isPaint,
                                                        width, height, positionX, positionY, getTypeStatic());
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            return jsonData;
        }
        
        public function Memo(params:Object) {
            super(params);
        }
        
        override public function canSnapOnPositionX():Boolean {
            return false;
        }
        
        override public function canSnapOnPositionY():Boolean {
            return false;
        }
        
        override public function isGotoGraveyard():Boolean {
            return true;
        }
        
        override public function getSquareLength():int {
            return 1;
        }
        
        override public function snapViewPosition():Boolean {
            return false;
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "共有メモの変更", this.getItemPopUpChangeWindow);
            addMenuItem(menu, "共有メモの削除", this.getContextMenuItemRemoveCharacter);
            
            view.contextMenu = menu;
            
            view.doubleClickEnabled = true;
            view.addEventListener(MouseEvent.DOUBLE_CLICK, function(event:MouseEvent):void {
                    popUpChangeWindow();
                });
        }
        
        override protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            popUpChangeWindow();
        }
        
        protected function popUpChangeWindow():void {
            var window:ChangeMemoWindow = DodontoF.popup(ChangeMemoWindow, true) as ChangeMemoWindow;
            window.setMemo(this);
        }
        
        override protected function getMapLayer():UIComponent {
            return getMap().getFrontLayer();
        }
        
        private var isFirst:Boolean = true;
        
        override protected function initDraw(x:Number, y:Number):void {
            //view.setLineDiameter(8);
            view.setLineColor(0x00AAAA);
            loadViewImage();
            //move(x, y, true);
            var memos:Array = DodontoF_Main.getInstance().getMap().findExistPiecesByTypeName(getType());
            var memoCountIndex:int = memos.length;
            if( memoCountIndex < 0 ) {
                memoCountIndex = 0;
            }
            
            if( ! isFirst ) {
                return;
            }
            
            view.x = int(memoCountIndex / 5) * Map.getSquareLength() * 1.2 + 10;
            view.y = int(memoCountIndex % 5) * Map.getSquareLength() * 1.2 + 10;
            view.scaleX = getScaleRate();
            view.scaleY = getScaleRate();
            
            isFirst = false
        }
        
        private function getScaleRate():Number {
            return 1.0;
        }
        
        private function getName():String {
            var parts:Array = getMessage().split("\n");
            if( parts.length == 0 ) {
                return "(no title)";
            }
            return parts[0];
        }
        
        override public function loadViewImage():void {
            var name:String = getName();
            var imageUrl:String = "image/memo.png";//document.png";
            var size:int = 1;
            view.loadImageWidthHeight(name, imageUrl, size, size);
            
            view.toolTip = getMessage();
        }
        
        override protected function getTextAlpha():Number {
            return 0.7;
        }
        
    }
}
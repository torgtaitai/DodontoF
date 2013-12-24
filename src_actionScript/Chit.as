//--*-coding:utf-8-*--

package {
    
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormatAlign;
    import flash.text.TextFormat;
    import flash.text.TextField;
    import mx.controls.Text;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import mx.core.UIComponent;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import mx.managers.PopUpManager;
    
    public class Chit extends MovablePiece {
        
        private var width:int;
        private var height:int;
        private var imageUrl:String;
        private var info:String;
        private var color:uint = 0xBBBBFF;
        
        public static function getTypeStatic():String {
            return "chit";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return Language.s.Chit;
        }
        
        
        public static function getJsonData(imageUrl:String,
                                           width:int,
                                           height:int,
                                           info:String,
                                           createPositionX:int,
                                           createPositionY:int):Object {
            var draggable:Boolean = true;
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), createPositionX, createPositionY, draggable);
            
            jsonData.width = width;
            jsonData.height = height;
            jsonData.imageUrl = imageUrl;
            jsonData.info = info;
            
            return jsonData;
        }
        
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.width = getWidth();
            jsonData.height = getHeight();
            jsonData.imageUrl = imageUrl;
            jsonData.info = info;
            
            return jsonData;
        }
        
        public function Chit(params:Object) {
            updateParams(params);
            
            super(params);
            
            setDraggable(false);
            view.setRoundColor(color);
        }
        
        override public function getWidth():int {
            return this.width;
        }
        
        override public function getHeight():int {
            return this.height;
        }
        
        public function setWidth(width_:int):void {
            this.width = width_;
        }
        
        public function setHeight(height_:int):void {
            this.height = height_;
        }
        
        
        public function setInfo(text:String):void {
            if( text == null ) {
                return;
            }
            this.info = text;
        }
        
        public function setUrl(url:String):void {
            this.imageUrl = url;
        }
        
        override public function loadViewImage():void {
            view.loadImageWidthHeightRotation(this.imageUrl,
                                              this.width, this.height,
                                              getRotation());
            
            super.loadViewImage();
            
            view.toolTip = this.info;
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, Language.s.deleteChit, this.getContextMenuItemRemoveCharacter);
            addMenuItem(menu, Language.s.cloneChit, this.getContextMenuItemClonePiece, true);
            
            view.contextMenu = menu;
        }
        
        protected function getContextMenuItemClonePiece(event:ContextMenuEvent):void {
            sender.addCharacter(this.getJsonDataEmptyId());
        }
        
        override public function isGotoGraveyard():Boolean {
            return true;
        }
        
        override public function getMapLayer():UIComponent {
            return getMap().getCharacterLayer();
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            loadViewImage();
            move(x, y, true);
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>analyzeChangedCharacterChanged Chit is changed Begin");
            
            super.update(params);
            updateParams(params);
            
            refresh();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged Chit is changed End");
        }
        
        private function updateParams(params:Object):void {
            this.width = params.width;
            this.height = params.height;
            this.imageUrl = params.imageUrl;
            setInfo( params.info );
        }
        
        public function refresh():void {
            initDraw(getX(), getY());
            loadViewImage();
            setPickuped();
        }
        
        override public function getOwnWidth():int {
            return getWidth() * Map.getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeight() * Map.getSquareLength();
        }
        
        override public function canExtendOnPositionX():Boolean {
            return true;
        }
    }
}
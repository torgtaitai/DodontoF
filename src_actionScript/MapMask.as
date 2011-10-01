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
    
    public class MapMask extends MovablePiece {
        
        private var width:int;
        private var height:int;
        private var name:String = null;
        
        private var color:uint = 0x000000;
        private var lineColor:uint = 0xFFFF99;
        private var lockedLineColor:uint = 0xFF9999;
        
        private var alpha:Number = 1.0;
        
        public static function getTypeStatic():String {
            return "mapMask";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "マップマスク";
        }
        
        
        public static function getJsonData(width:int,
                                           height:int,
                                           name:String,
                                           color:int,
                                           alpha:Number,
                                           createPositionX:int,
                                           createPositionY:int):Object {
            Log.logging("addMapMask begin");
            
            var draggable:Boolean = true;
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), createPositionX, createPositionY, draggable);
            
            jsonData.width = width;
            jsonData.height = height;
            jsonData.name = name;
            jsonData.color = color;
            jsonData.alpha = alpha;
            
            return jsonData;
        }
        
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.width = getWidth();
            jsonData.height = getHeight();
            jsonData.name = getName();
            jsonData.color = getColor();
            jsonData.alpha = getAlpha();
            
            Log.logging("MapMask.getJsonData.imgId", jsonData.imgId);
            
            return jsonData;
        }
        
        public function MapMask(params:Object) {
            updateParams(params);
            
            super(params);
            
            //自分の環境に仮作成する場合のために、作成直後はドラッグ不可に。
            //応答が正常ならどちらにしろupdateで更新されるはずなのでこの実装で問題は無い。
            setDraggable(false);
            
            setMenuVisible();
        }
        
        override public function getWidth():int {
            return this.width;
        }
        
        override public function getHeight():int {
            return this.height;
        }
        
        override public function getName():String {
            return this.name;
        }
        
        public function setName(name_:String):void {
            this.name = name_;
        }
                
        public function getColor():uint {
            return this.color;
        }
        
        public function setColor(color_:uint):void {
            this.color = color_;
        }
        
        public function getAlpha():Number {
            return this.alpha;
        }
        
        public function setAlpha(a_:Number):void {
            this.alpha = a_;
        }
        
        public function setWidth(width_:int):void {
            this.width = width_;
        }
        
        public function setHeight(height_:int):void {
            this.height = height_;
        }
        
        override public function isGotoGraveyard():Boolean {
            return false;
        }
        
        private var changeMenu:ContextMenuItem;
        private var moveLockMenu:ContextMenuItem;
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            changeMenu  = addMenuItem(menu, "マップマスクの変更", this.getItemPopUpChangeWindow);
            moveLockMenu = addMenuItem(menu, "マップマスクの固定", this.getContextMenuItemMoveLock);
            addMenuItem(menu, "マップマスクの削除", this.getContextMenuItemRemoveCharacter);
            
            view.contextMenu = menu;
            setMenuVisible();
        }
        
        private function setMenuVisible():void {
            if( changeMenu == null ) {
                return;
            }
            
            changeMenu.visible = getDraggable();
            moveLockMenu.visible = getDraggable();
        }
        
        protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            popUpChangeWindow();
        }
        
        public function popUpChangeWindow():void {
            try {
                var window:ChangeMapMaskWindow = DodontoF.popup(ChangeMapMaskWindow, true) as ChangeMapMaskWindow;
                window.init(this);
            } catch(e:Error) {
                Log.loggingExceptionDebug("Character.popUpChangeWindow()", e);
            }
        }
        
        private function getContextMenuItemMoveLock(event:ContextMenuEvent):void {
            try {
                Log.logging("getContextMenuItemMoveLock begin.");
                setDraggable(false);
                drawSquare();
                sender.changeCharacter( getJsonData() );
                
                Log.logging("getContextMenuItemMoveLock end.");
            } catch(e:Error) {
                Log.loggingException("MapMask.getContextMenuItemMoveLock()", e);
            }
        }
        
        override public function getMapLayer():UIComponent {
            return getMap().getMapMaskLayer();
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            move(x, y, true);
            
            drawSquare();
        }
        
        private function updateParams(params:Object):void {
            this.width = params.width;
            this.height = params.height;
            this.name = params.name;
            this.color = params.color;
            if( params.alpha != null ) {
                this.alpha = parseFloat(params.alpha);
            }
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>analyzeChangedCharacterChanged MapMask is changed Begin");
            
            super.update(params);
            updateParams(params);
            
            refresh();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged MapMask is changed End");
        }
        
        public function refresh():void {
            setMenuVisible();
            initDraw(getX(), getY());
        }
        
        private function getMaskLineColor():uint {
            if( getDraggable() ) {
                return lineColor;
            }
            return lockedLineColor;
        }
        
        private function drawSquare():void {
            view.graphics.clear();
            
            view.graphics.lineStyle(5, getMaskLineColor());
            view.graphics.beginFill(this.color, 1.0);
            
            view.graphics.drawRect(0,
                                   0,
                                   getSquareLength() * width,
                                   getSquareLength() * height);
            view.graphics.endFill();
            
            printName();
            
            view.alpha = this.alpha;
        }
        
        private function getNameTextField(textHeight:int):TextField {
            
            var textField:TextField = new TextField();
            
            var format:TextFormat = new TextFormat();
            format.bold = true;
            format.size = textHeight;
            format.align = TextFormatAlign.CENTER;
            textField.defaultTextFormat = format;
            
            textField.wordWrap = true;
            textField.multiline = true;
            textField.selectable = false;
            textField.mouseEnabled = false;
            textField.width = getWidth() * Map.getSquareLength() - 6;
            textField.autoSize = TextFieldAutoSize.CENTER;
            textField.background = true;
            textField.backgroundColor = this.color;
            textField.textColor = 0xFFFFFF - this.color;
            textField.text = this.name;
            
            return textField;
        }
        
        private var mainTextField:TextField = null;
        
        
        private function printName():void {
            if( mainTextField != null ) {
                try {
                    view.removeChild(mainTextField);
                    mainTextField = null;
                } catch (e:Error) {
                }
            }
            
            if( this.name == null ) {
                return;
            }
            
            var textHeight:int = 21;
            mainTextField = getNameTextField(textHeight);
            mainTextField.alpha = this.alpha;
            
            mainTextField.x = 3;
            mainTextField.y = (getHeight() * Map.getSquareLength() / 2) - textHeight + 6;
            view.addChild(mainTextField);
        }
        
        override public function snapMovablePieceViewPosition(isListed:Boolean = false):void {
            return;
        }
        
        override public function getOwnWidth():int {
            return getWidth() * Map.getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeight() * Map.getSquareLength();
        }
        
    }
}
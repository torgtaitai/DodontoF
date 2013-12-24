//--*-coding:utf-8-*--

package {

    import flash.geom.Point;
    import mx.controls.Alert;
    import flash.text.TextFieldAutoSize;
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
    
    public class MapMarker extends MovablePiece {
        
        private var message:String = "";
        private var color:uint = 0xBBBB00;
        private var isPaint:Boolean = false;
        private var width:int;
        private var height:int;
        
        public static function getTypeStatic():String {
            return "mapMarker";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return Language.s.mapMarker;
        }
        
        
        public static function getJsonData(message:String, color:uint,
                                           isPaint:Boolean,
                                           width:int,
                                           height:int,
                                           createPositionX:int,
                                           createPositionY:int,
                                           type:String = null):Object {
            var draggable:Boolean = true;
            if( type == null ) {
                type = getTypeStatic();
            }
            var jsonData:Object = MovablePiece.getJsonData(type, createPositionX, createPositionY, draggable);
            
            jsonData.message = message;
            jsonData.color = color;
            jsonData.isPaint = isPaint;
            jsonData.width = width;
            jsonData.height = height;
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.message = getMessage();
            jsonData.color = getColor();
            jsonData.isPaint = isPaintMode();
            jsonData.width = getWidth();
            jsonData.height = getHeight();
            
            return jsonData;
        }
        
        public function MapMarker(params:Object) {
            this.message = params.message;
            
            super(params);
            
            view.setIsDrawBack(false);
            view.setMaintainAspectRatio(false);
        }
        
        public function setMessage(message_:String):void {
            this.message = message_;
        }
        
        public function getMessage():String {
            return this.message;
        }
        
        public function setColor(color_:uint):void {
            this.color = color_;
        }
        
        public function getColor():uint {
            return this.color;
        }
        
        public function setPaintMode(b:Boolean):void {
            this.isPaint = b;
        }
        
        public function isPaintMode():Boolean {
            return this.isPaint;
        }
        
        public function setWidth(w:int):void {
            this.width = w;
        }
        
        override public function getWidth():int {
            return this.width;
        }
        
        public function setHeight(h:int):void {
            this.height = h;
        }
        
        override public function getHeight():int {
            return this.height;
        }
        
        override public function isGotoGraveyard():Boolean {
            return false;
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, Language.s.changeMapMarker, this.getItemPopUpChangeWindow);
            addMenuItem(menu, Language.s.deleteMapMarker, this.getContextMenuItemRemoveCharacter);
            
            view.contextMenu = menu;
        }
        
        protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            var window:ChangeMapMarkerWindow = DodontoF.popup(ChangeMapMarkerWindow, true) as ChangeMapMarkerWindow;
            window.setMapMarker(this);
        }
        
        override public function getMapLayer():UIComponent {
            return getMap().getMapMarkerLayer();
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            loadViewImage();
            move(x, y, true);
            
            //drawSquare();
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>analyzeChangedCharacterChanged MapMask is changed Begin");
            
            super.update(params);
            this.message = params.message;
            
            if( params.color != null ) {
                this.color = parseInt(params.color);
            }
            this.isPaint = (params.isPaint == null ? false : params.isPaint);
            this.width = (params.width == null ? 1 : params.width);
            this.height = (params.height == null ? 1 : params.height);
            
            updateImage();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged MapMask is changed End");
        }
        
        public function updateImage():void {
            view.setRoundColor(this.color);
            view.setBackGroundColor(this.color);
            view.setIsDrawBack( this.isPaint );
            initDraw(getX(), getY());
            printInfo();
            loadViewImage();
        }
        
        override protected function droped():void {
        }
        
        override public function canExtendOnPositionY():Boolean {
            return true;
        }
        
        override public function loadViewImage():void {
            var imageUrl:String = "image/MapMarker.gif";
            var size:int = 1;
            view.loadImageWidthHeight(imageUrl, width, height);
            
            view.toolTip = getMessage();
        }
        
        
        private function getNameTextField(textHeight:int, text:String,
                                          textX:int, textY:int):TextField {
            
            var textField:TextField = new TextField();
            
            var format:TextFormat = new TextFormat();
            format.bold = true;
            format.size = textHeight;
            format.align = TextFormatAlign.CENTER;
            textField.defaultTextFormat = format;
            
            textField.wordWrap = false;//true;
            textField.multiline = false;//true;
            textField.selectable = false;
            textField.mouseEnabled = false;
            textField.width = getWidth() * Map.getSquareLength() - (textX * 2);
            //textField.autoSize = TextFieldAutoSize.CENTER;
            textField.background = false;
            //textField.backgroundColor = this.color;
            textField.textColor = Utils.getComplementaryColor( this.color );
            textField.text = text.split(/\r/)[0];
            textField.x = textX;
            textField.y = textY;
            
            textField.height = textHeight * 1.5;//getHeight() * Map.getSquareLength() - textY;
            
            return textField;
        }
        
        private var mainTextField:TextField = null;
        
        
        private function printInfo():void {
            if( mainTextField != null ) {
                try {
                    view.removeChild(mainTextField);
                    mainTextField = null;
                } catch (e:Error) {
                }
            }
            
            if( ! isPaintMode() ) {
                return;
            }
            
            var textHeight:int = 15;
            var textX:int = 3;
            var textY:int = (getHeight() * Map.getSquareLength() / 2) - textHeight + 6;
            
            mainTextField = getNameTextField(textHeight, getMessage(), textX, textY);
            mainTextField.alpha = getTextAlpha();
            
            view.addChild(mainTextField);
        }
        
        protected function getTextAlpha():Number {
            return 1;
        }
        
        override public function getOwnWidth():int {
            return getWidth() * Map.getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeight() * Map.getSquareLength();
        }
        
    }
}
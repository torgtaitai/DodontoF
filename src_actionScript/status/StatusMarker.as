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
    
    public class StatusMarker extends MovablePiece {
        
        private var message:String = "";
        //private var target:Character;
        private var targetId:String = "";
        
        public function getTargetId():String {
            return targetId;
        }
        
        private function getTarget():Character {
            return findTargetCharacter(targetId);
        }
        
        private function findTargetCharacter(id_:String):Character {
            var p:Piece = getMap().findExistCharacterById(id_);
            var t:Character = p as Character;
            return t;
        }
        
        private function setTargetId(targetId_:String):void {
            targetId = targetId_;
            updateAllToolTips();
        }
        
        private function updateAllToolTips():void {
            var characters:Array = getMap().findExistPiecesByTypeName( Character.getTypeStatic() );
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:Character = characters[i] as Character;
                character.updateStatusMarker();
            }
            
            setToolTip();
        }
        
        public static function getTypeStatic():String {
            return "statusMarker";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        
        public static function getJsonData(message:String,
                                           createPositionX:int,
                                           createPositionY:int
                                           ):Object {
            var draggable:Boolean = true;
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), createPositionX, createPositionY, draggable);
            
            jsonData.message = message;
            jsonData.targetId = "";
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.message = this.message;
            jsonData.targetId = getTargetId();
            
            return jsonData;
        }
        
        public function StatusMarker(params:Object) {
            Log.logging("StatusMarker begin");
            this.message = params.message;
            Log.logging("pass1");
            setTargetId( params.targetId );
            Log.logging("pass2");
            
            super(params);
            Log.logging("pass3");
            
            view.setIsDrawBack(false);
            Log.logging("StatusMarker end");
        }
        
        public function getMessage():String {
            return this.message;
        }
        
        public function setMessage(message_:String):void {
            this.message = message_;
        }
        
        public function getStatusName():String {
            return this.message.split(/\r/)[0];
        }
        
        public function getPrintStatus():String {
            var printMessage:String = "";
            printMessage += getStatusName();
            
            if( getTarget() != null ) {
                printMessage += ( "@" + getTarget().getName() );
            }
            
            return printMessage;
        }
        
        override public function getWidth():int {
            //return 1;
            if( getTarget() == null ) {
                return 1;
            }
            return getTarget().getWidth();
        }
        
        override public function getHeight():int {
            //return 1;
            if( getTarget() == null ) {
                return 1;
            }
            return getTarget().getWidth();
        }
        
        override protected function isGotoGraveyard():Boolean {
            return false;
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "状態マーカーの変更", this.getItemPopUpChangeWindow);
            addMenuItem(menu, "状態マーカーの削除", this.getContextMenuItemRemoveCharacter);
            
            view.contextMenu = menu;
        }
        
        protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            var window:ChangeStatusMarkerWindow = DodontoF.popup(ChangeStatusMarkerWindow, true) as ChangeStatusMarkerWindow;
            window.setStatusMarker(this);
        }
        
        override protected function getMapLayer():UIComponent {
            return getMap().getStatusMarkerLayer();
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
            setTargetId( params.targetId );
            
            view.setBackGroundColor(this.color);
            //view.setIsDrawBack(false);
            
            view.setRoundColor(this.color);
            //view.setIsDrawRound(false);
            
            updateAllToolTips();
            
            initDraw(getX(), getY());
            printInfo();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged MapMask is changed End");
        }
        
        public function getView():ImageSprite {
            return view;
        }
        
        override protected function droped():void {
            var point:Point = getMap().getMouseCurrentPoint();
            
            var characters:Array = getMap().getExistCharactersOrderdByViewIndex(point);
            
            var dropedCharacter:Character = null;
            
            for(var i:int = 0 ; i < characters.length ; i++ ) {
                var character:Character = characters[i] as Character;
                if( character != null ) {
                    dropedCharacter = character;
                    break;
                }
            }
            
            if( dropedCharacter == null ) {
                setTargetId("");
            } else {
                setTargetId(dropedCharacter.getId());
                initDraw(dropedCharacter.getX(), dropedCharacter.getY());
            }
            printInfo();
        }
        
        public function dropedByTargetCharacter(x:Number, y:Number):void {
            move(x, y, true);
            sender.changeCharacter(this.getJsonData());
        }
        
        override protected function dragged():void {
        }
        
        override public function canSnapOnPositionY():Boolean {
            return true;
        }
        
        public function loadViewImage():void {
            var name:String = "name";
            var imageUrl:String = "image/statusMarker.png"; //"image/MapMarker.gif";
            var size:int = 1;
            view.loadImageWidthHeight(name, imageUrl, getWidth(), getHeight());
            
            setToolTip();
        }
        
        private function setToolTip():void {
            if( view == null ) {
                return;
            }
            
            view.toolTip = getPrintStatus();
        }
        
        private var color:uint = 0xFBEC35;//0xBBBB00;
        
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
            textField.background = true;
            textField.backgroundColor = this.color;
            textField.textColor = 0xFFFFFF - this.color;
            textField.text = text.split(/\r/)[0];
            textField.x = textX;
            textField.y = textY;
            
            textField.height = textHeight + 8;
            
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
            
            var textHeight:int = 12;
            var textX:int = 3;
            var textY:int = (getHeight() * Map.getSquareLength() / 2) - textHeight + 4;
            
            mainTextField = getNameTextField(textHeight, getPrintStatus(), textX, textY);
            
            view.addChild(mainTextField);
        }
        
    }
}
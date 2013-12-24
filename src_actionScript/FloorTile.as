//--*-coding:utf-8-*--

package {
    
    import mx.core.UIComponent;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import mx.managers.PopUpManager;
    import mx.controls.Alert;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.TextFieldAutoSize;
    
    
    public class FloorTile extends MovablePiece {
        
        private var imageUrl:String;
        private var width:int;
        private var height:int;
        
        private var thisObj:FloorTile;
        
        public static function getTypeStatic():String {
            return "floorTile";
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return Language.s.floorTile;
        }
        
        
        
        public static function getJsonData(imageUrl:String,
                                           width:int,
                                           height:int,
                                           rotation:int,
                                           createPositionX:int,
                                           createPositionY:int):Object {
            var draggable:Boolean = true;
            var jsonData:Object = MovablePiece.getJsonData(getTypeStatic(), createPositionX,
                                                           createPositionY, draggable, rotation);
            
            jsonData.imageUrl = imageUrl;
            jsonData.width = width;
            jsonData.height = height;
            
            return jsonData;
        }
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.imageUrl = imageUrl;
            jsonData.width = width;
            jsonData.height = height;
            
            return jsonData;
        }
        
        public function FloorTile(params:Object) {
            this.thisObj = this;
            
            this.imageUrl = params.imageUrl;
            this.width = params.width;
            this.height = params.height;
            
            super(params);
            
            //設置した瞬間はタイル情報はFlash側に借り作成されるだけ。
            //このため、作成直後はドラッグ不可に。
            //正常にデータがサー側に生成されれば
            // update() でDraggableに更新されるはずなのでこの実装で問題ないです。
            setDraggable(false);
            
            view.setMaintainAspectRatio(false);
        }
        
        override public function isGotoGraveyard():Boolean {
            return false;
        }
        
        
        private var menuList:Array = new Array();
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            menuList.push( addMenuItem(menu, Language.s.fixFlexFloorTile, this.getContextMenuItemMoveLock) );
            menuList.push( addMenuItem(menu, Language.s.rotationRight,    this.getContextMenuItemFunctionObRotateCharacter( 90), true) );
            menuList.push( addMenuItem(menu, Language.s.rotation180, this.getContextMenuItemFunctionObRotateCharacter(180)) );
            menuList.push( addMenuItem(menu, Language.s.rotationLeft,    this.getContextMenuItemFunctionObRotateCharacter(270)) );
            menuList.push( addMenuItem(menu, Language.s.deleteFloorTile, this.getContextMenuItemRemoveCharacter, true) );
            
            view.contextMenu = menu;
        }
        
        private function getContextMenuItemMoveLock(event:ContextMenuEvent):void {
            setDraggable( ! getDraggable() );
            drawTile();
            sender.changeCharacter( getJsonData() );
        }
        
        protected function getContextMenuItemFunctionObRotateCharacter(rotationDiff:Number):Function {
            return function(event:ContextMenuEvent):void {
                var rotation:Number = getRotation();
                rotation += rotationDiff;
                rotation = ( rotation % 360 );
                setRotation( rotation );
                
                thisObj.loadViewImage();
                sender.changeCharacter( thisObj.getJsonData() );
            };
        }
        
        override public function getMapLayer():UIComponent {
            return getMap().getMapTileLayer();
        }
        
        private var lineColor:uint = 0xFFFF99;
        private var lockedLineColor:uint = 0xFF9999;
        
        private function getLineColor():uint {
            if( getDraggable() ) {
                return lineColor;
            }
            return lockedLineColor;
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            drawTile();
            move(x, y, true);
        }
        
        private function drawTile():void {
            view.setLineColor( getLineColor() )
            view.setLineDiameter(10);
            loadViewImage();
        }
        
        private var editable:Boolean = false;
        
        public function setEditMode(b:Boolean):void {
            this.editable = b;
            view.setIsDrawRound(this.editable);
            drawTile();
            
            for each(var menu:ContextMenuItem in menuList) {
                    menu.visible = b;
                }
        }
        
        override public function loadViewImage():void {
            view.loadImageWidthHeightRotation(this.imageUrl,
                                              this.width, this.height,
                                              getRotation());
        }
        
        override protected function update(params:Object):void {
            super.update(params);
            
            this.imageUrl = params.imageUrl;
            this.width = params.width;
            this.height = params.height;
            
            setEditMode( getMap().isFloorTileEditMode() );
            
            initDraw(getX(), getY());
        }
        
        public function getImageUrl():String {
            return imageUrl;
        }
        
        
        override protected function initCreation():void {
            var textHeight:int = 50;
            
            var nameTextField:TextField = new TextField();
            nameTextField.text = Language.s.creating;
            
            nameTextField.background = true;
            nameTextField.multiline = false;
            nameTextField.selectable = false;
            nameTextField.mouseEnabled = false;
            nameTextField.y = (textHeight * -1);
            
            nameTextField.autoSize = flash.text.TextFieldAutoSize.CENTER;
            nameTextField.height = textHeight;
            
            var format:TextFormat = new TextFormat(); 
            format.size = textHeight;
            nameTextField.setTextFormat(format);
            
            var allWidth:int = this.width * getSquareLength();
            nameTextField.x = ( (1.0 * allWidth / 2) - (nameTextField.width / 2) );
            
            view.addChild(nameTextField);
        }
        
        override public function getWidth():int {
            return this.width;
        }
        
        override public function getHeight():int {
            return this.height;
        }
        
        override public function getOwnWidth():int {
            return getWidth() * getSquareLength();
        }
        
        override public function getOwnHeight():int {
            return getHeight() * getSquareLength();
        }
        
        override public function getDraggable():Boolean {
            
            if( ! super.getDraggable() ) {
                return false;
            }
            return this.editable;
        }
        

   }
}

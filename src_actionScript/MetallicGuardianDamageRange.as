//--*-coding:utf-8-*--

package {
    
    import mx.core.UIComponent;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.geom.Point;
    import flash.display.Graphics;
    
    public class MetallicGuardianDamageRange extends MovablePiece {
        
        private var name:String = "";
        private var maxRange:int = 1;
        private var minRange:int = 1;
        private var color:int = 0x000000;
        
        private var upperLayer:UIComponent = new UIComponent();
        
        public static function getTypeStatic():String {
            return "MetallicGuardianDamageRange"
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return "メタリックガーディアン攻撃範囲";
        }
        
        public static function getJsonData(name:String,
                                           minRange:int,
                                           maxRange:int,
                                           color:String,
                                           characterPositionX:int,
                                           characterPositionY:int):Object {
            var draggable:Boolean = true;
            var counters:Object = null;
            var statusAlias:Object = null;
            var rotation:Number = 0;
            
            var jsonData:Object = 
                MovablePiece.getJsonData(getTypeStatic(),
                                         characterPositionX, characterPositionY,
                                         draggable, rotation);
            jsonData.name = name
            jsonData.minRange = minRange;
            jsonData.maxRange = maxRange;
            jsonData.color = color;
            
            jsonData.imageName = "";
            jsonData.size = 0;
            
            return jsonData;
        }
        
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.name = name;
            jsonData.minRange = minRange;
            jsonData.maxRange = maxRange;
            jsonData.color = "0x" + getColor().toString(16);
            
            return jsonData;
        }
        
        public function MetallicGuardianDamageRange(params:Object) {
            
            updateLocal(params);
            super(params);
            
            view.setIsDrawBack(false);
            view.addChild(upperLayer);
            upperLayer.x = getSquareLength() / 2;
            upperLayer.y = getSquareLength() / 2;
        }
        
        override public function getName():String {
            return this.name;
        }
        
        public function setName(s:String):void {
            this.name = s;
        }
        
        public function getMaxRange():int {
            return this.maxRange;
        }
        
        public function setMaxRange(v:int):void {
            this.maxRange = v;
        }
        
        public function getMinRange():int {
            return this.minRange;
        }
        
        public function setMinRange(v:int):void {
            this.minRange = v;
        }
        
        public function getColor():int {
            return color;
        }
        
        public function setColor(color_:int):void {
            color = color_;
        }
        
        override protected function initContextMenu():void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            addMenuItem(menu, "攻撃範囲の変更", this.getItemPopUpChangeWindow);
            addMenuItem(menu, "攻撃範囲の削除", this.getContextMenuItemRemoveCharacter);
            addMenuItem(menu, "右回転", this.getContextMenuItemRightRotateCharacter, true);
            addMenuItem(menu, "左回転", this.getContextMenuItemLeftRotateCharacter);
            
            view.contextMenu = menu;
        }
        
        protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            popUpChangeWindow();
        }

        public function popUpChangeWindow():void {
            try {
                var window:ChangeMetallicGuardianDamageRangeWindow = 
                    DodontoF.popup(ChangeMetallicGuardianDamageRangeWindow, true) as ChangeMetallicGuardianDamageRangeWindow;
                window.setDamageRange(this);
            } catch(e:Error) {
                Log.loggingException("MagicRange.popUpChangeWindow()", e);
            }
        }
        
        private function getContextMenuItemRightRotateCharacter(event:ContextMenuEvent):void {
            rotateByMenu(90);
        }
        private function getContextMenuItemLeftRotateCharacter(event:ContextMenuEvent):void {
            rotateByMenu(-90);
        }
        private function rotateByMenu(value:int):void {
            setDiffRotation( value );
            loadViewImage();
            
            DodontoF_Main.getInstance().getGuiInputSender().getSender()
                .changeCharacter( getJsonData() );
        }
        
        
        override public function getMapLayer():UIComponent {
            return getMap().getMagicRangeLayer();
        }
        
        override protected function canRotate():Boolean {
            return true;
        }
        
        protected function getCenterImageUrl():String {
            return "image/centerMarker.png";
        }
        
        override public function loadViewImage():void {
            Log.logging("loadViewImage Begin");
            
            var size:int = 1;
            view.setIsDrawRound(false);
            view.loadImageWidthHeightRotation(getCenterImageUrl(), size, size, getRotation());
            super.loadViewImage();
            
            this.upperLayer.rotation = getRotation();
            initDrawRangeSquare();
            
            Log.logging("loadViewImage End");
        }
        
        override protected function initDraw(x:Number, y:Number):void {
            clearDrown();
            move(x, y, true);
            loadViewImage();
        }
        
        
        private function initDrawRangeSquare():void {
            clearDrown();
            
            var points:Array = getSquarePoints(this.maxRange);
            var ignorePoints:Array = getSquarePoints(this.minRange - 1);
            
            points = removeIgnorePoint(points, ignorePoints);
            Log.logging("points", points);
            Log.logging("ignorePoints", ignorePoints);
            
            drawSquares(points, false);
            drawSquares(ignorePoints, true);
            
            view.toolTip = this.name + "[" + this.maxRange + "/" + this.minRange + "]";
        }
        
        private function getSquarePoints(range:int):Array {
            var points:Array = [];
            
            if( range < 0 ) {
                return points;
            }
            
            points.push([0, 0]);
            
            range = range + 1;
            
            for(var i:int = 0 ; i < range ; i++) {
                var x:int = range - i - 1;
                
                for(var y:int = 0 ; y < x ; y++) {
                    points.push([i, y + 1]);
                    points.push([i * -1 - 1, y + 1]);
                }
            }
            
            return points;
        }
        
        private function removeIgnorePoint(points:Array, ignorePoints:Array):Array {
            var result:Array = new Array();
            
            for each(var p:Array in points) {
                    var x:int = p[0];
                    var y:int = p[1];
                    
                    if( findPoint(x, y, ignorePoints)) {
                            continue;
                        }
                    result.push( p );
                }
            
            return result;
        }
        
        private function findPoint(x:int, y:int, points:Array):Boolean {
            for each(var p:Array in points) {
                    if((x == p[0]) && (y == p[1])) {
                        return true;
                    }
                }
            return false;
        }
        
        private function drawSquares(points:Array, isTranparent:Boolean = false):void {
            
            for(var i:int = 0 ; i < points.length ; i++) {
                var point:Array = points[i];
                drawSquare( point[0], point[1], isTranparent );
            }
        }
        
        
        private var alreadyDrawedPosition:Object = new Object();
        
        private function clearDrown():void {
            getViewGraphics().clear();
            alreadyDrawedPosition = new Object();
        }
        
        private function getViewGraphics():Graphics {
            return upperLayer.graphics;
        }
        
        private function drawSquare(x:int, y:int, isTranparent:Boolean):void {
            var lineAlpha:Number = (isTranparent ? 0.001 : 1.0);
            getViewGraphics().lineStyle(0, 0x000000, lineAlpha);
            
            
            var drawAlpha:Number = (isTranparent ? 0.001 : 0.5);
            getViewGraphics().beginFill(color, drawAlpha);
            
            if( y < 0 ) {
                y += 1;
            }
            
            if( x < 0 ) {
                x += 1;
            }
            
            var isAdded:Boolean = addAlreadyDrawdPosition(x, y);
            if( ! isAdded ) {
                //既に描写済みの座標なのでパス。
                return;
            }
            
            getViewGraphics().drawRect( (x * getSquareLength()) - getSquareLength() / 2,
                                    (y * getSquareLength() * -1) - getSquareLength() / 2,
                                    getSquareLength(),
                                    getSquareLength() );
            getViewGraphics().endFill();
        }
        
        private function addAlreadyDrawdPosition(x:int, y:int):Boolean {
            var positionInfo:String = "[" + x + ", " + y + "]";
            
            if( alreadyDrawedPosition[positionInfo] != null ) {
                Log.logging("this position is already dorawd", positionInfo);
                return false;
            }
            
            Log.logging("fist dorawing...", positionInfo);
            alreadyDrawedPosition[positionInfo] = true;
            
            return true;
        }
        
        override protected function update(params:Object):void {
            Log.loggingTuning("=>MagicRange update Begin");
            
            super.update(params);
            updateLocal(params);
            updateRefresh();
            
            Log.loggingTuning("=>analyzeChangedCharacterChanged MagicRange changed End");
        }
        
        private function updateLocal(params:Object):void {
            this.name = params.name;
            this.minRange = parseInt(params.minRange);
            this.maxRange = parseInt(params.maxRange);
            this.color = params.color;
            this.upperLayer.rotation = params.rotation;
        }
        
        public function updateRefresh():void {
            initDraw(getX(), getY());
        }
   }
}

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
    
    public class LogHorizonRange extends MovablePiece implements MapRange {
        
        private var name:String = "";
        private var range:int = 1;
        private var color:int = 0x000000;
        
        public static function getTypeStatic():String {
            return "LogHorizonRange"
        }
        
        override public function getType():String {
            return getTypeStatic();
        }
        
        override public function getTypeName():String {
            return Language.s.LogHorizonRange;
        }
        
        public static function getJsonData(name:String,
                                           range:int,
                                           color:String,
                                           characterPositionX:int,
                                           characterPositionY:int):Object {
            var draggable:Boolean = true;
            var statusAlias:Object = null;
            
            var jsonData:Object = 
                MovablePiece.getJsonData(getTypeStatic(),
                                         characterPositionX, characterPositionY,
                                         draggable);
            jsonData.name = name
            jsonData.range = range;
            jsonData.color = color;
            
            jsonData.imageName = "";
            jsonData.size = 0;
            
            return jsonData;
        }
        
        
        override public function getJsonData():Object {
            var jsonData:Object = super.getJsonData();
            
            jsonData.name = name;
            jsonData.range = range;
            jsonData.color = "0x" + getColor().toString(16);
            
            return jsonData;
        }
        
        public function LogHorizonRange(params:Object) {
            
            updateLocal(params);
            super(params);
            
            view.setIsDrawBack(false);
        }
        
        override public function getName():String {
            return this.name;
        }
        
        public function setName(s:String):void {
            this.name = s;
        }
        
        public function getRange():int {
            return this.range;
        }
        
        public function setRange(v:int):void {
            this.range = v;
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
            
            addMenuItem(menu, Language.s.changeAtackRange, this.getItemPopUpChangeWindow);
            addMenuItem(menu, Language.s.deleteAtackRange, this.getContextMenuItemRemoveCharacter);
            
            view.contextMenu = menu;
        }
        
        protected function getItemPopUpChangeWindow(event:ContextMenuEvent):void {
            popUpChangeWindow();
        }

        public function popUpChangeWindow():void {
            try {
                var window:ChangeLogHorizonRangeWindow = 
                    DodontoF.popup(ChangeLogHorizonRangeWindow, true) as ChangeLogHorizonRangeWindow;
                window.setRange(this);
                
            } catch(e:Error) {
                Log.loggingException("MagicRange.popUpChangeWindow()", e);
            }
        }
        
        override public function getMapLayer():UIComponent {
            return getMap().getMagicRangeLayer();
        }
        
        override protected function canRotate():Boolean {
            return false;
        }
        
        
        override protected function initDraw(x:Number, y:Number):void {
            move(x, y, true);
            initDrawRange();
        }

        
        public function initDrawRange():void {
            loadViewImage();
            clearDrown();
            initDrawRangeSquare();
        }
        
        
        override public function loadViewImage():void {
            var size:int = Utils.getMapRangeSize();
            
            view.setIsDrawRound(false);
            view.loadImage(Utils.getCenterImageUrl(), size);
        }
        
        private var alreadyDrawedPosition:Object = new Object();
        
        public function clearDrown():void {
            getViewGraphics().clear();
            alreadyDrawedPosition = new Object();
        }
        
        public function initDrawRangeSquare():void {
            var points:Array = getSquarePoints(this.range);
            
            drawSquares(points);
            
            view.toolTip = this.name + "[" + Language.s.range + ":" + this.range + "]";
        }
        
        static private function getSquarePoints(range:int):Array {
            var points:Array = [];
            
            points.push([0, 0]);
            
            for(var i:int = 0 ; i < range ; i++) {
                var basePoints:Array = Utils.clone(points);
                
                for each(var p:Array in basePoints) {
                    var x:int = p[0];
                    var y:int = p[1];
                    extendPoint(x, y, points);
                }
            }
            
            return points;
        }
        
        static private function extendPoint(x:int, y:int, points:Array):void {
            addPoint(x + 1, y    , points);
            addPoint(x    , y + 1, points);
            addPoint(x - 1, y    , points);
            addPoint(x    , y - 1, points);
        }
        
        static private function addPoint(x:int, y:int, points:Array):void {
            if( findPoint(x, y, points) ) {
                return;
            }
            points.push([x, y]);
        }
        
        static private function findPoint(x:int, y:int, points:Array):Boolean {
            for each(var p:Array in points) {
                    if((x == p[0]) && (y == p[1])) {
                        return true;
                    }
                }
            return false;
        }
        
        private function drawSquares(points:Array):void {
            
            for(var i:int = 0 ; i < points.length ; i++) {
                var point:Array = points[i];
                drawSquare( point[0], point[1] );
            }
        }
        
        
        private function getViewGraphics():Graphics {
            return view.graphics;
        }
        
        private function drawSquare(x:int, y:int):void {
            
            var drawAlpha:Number = 0.5;
            getViewGraphics().beginFill(color, drawAlpha);
            
            var isAdded:Boolean = addAlreadyDrawdPosition(x, y);
            if( ! isAdded ) {
                //既に描写済みの座標なのでパス。
                return;
            }
            
            var length:int = Utils.getMapRangeSquareLength();
            getViewGraphics().drawRect( (x * length),
                                        (y * length * -1),
                                        length,
                                        length );
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
            this.range = parseInt(params.range);
            this.color = params.color;
        }
        
        override public function updateRefresh():void {
            initDraw(getX(), getY());
        }
        
        override public function snapViewPosition():Boolean {
            return snapViewPositionForMapRange(this);
        }
        
   }
}

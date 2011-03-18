//--*-coding:utf-8-*--

package {
    
    import mx.controls.Alert;
    import flash.events.ContextMenuEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import com.adobe.serialization.json.JSON;
    import flash.events.MouseEvent;
	import mx.core.UIComponent;
    
    public class PaintablePreviewLoader extends PreviewLoader {
        private static var eraseColor:int = PaintablePreviewLoaderSquare.getEraseColor();
        
        private var paintSquare:UIComponent = new UIComponent();
        private var thisObj:PaintablePreviewLoader;
        private var squaresList:Array = new Array();
        
        public function PaintablePreviewLoader() {
            super();
            this.addChild(paintSquare);
            this.thisObj = this;
        }
        
        private var getColorFunction:Function = null;
        private var setColorFunction:Function = null;
        private var isDrawing:Boolean = false;
        private var isErasing:Boolean = false;
        private var isSyringe:Boolean = false;
        
        public function setEraser(isErasing_:Boolean = true):void {
            isErasing = isErasing_;
        }
        
        public function setSyringe(isSyringe_:Boolean = true):void {
            isSyringe = isSyringe_;
        }
        
        private var syringeAfter:Function;
        
        public function setSyringeAfter(f_:Function):void {
            syringeAfter = f_;
        }
        
        public function getResult():Array {
            var result:Array = new Array(getHeightSize());
            
            for(var y:int = 0 ; y < result.length; y++) {
                result[y] = new Array( getWidthSize() );
                for(var x:int = 0 ; x < result[y].length ; x++) {
                    result[y][x] = squaresList[y][x].getColor();
                }
            }
            
            return result;
        }
        
        public function clearSquares():void {
            for(var y:int = 0 ; y < getHeightSize() ; y++) {
                var squares:Array = squaresList[y];
                if( squares == null ) {
                    continue;
                }
                
                for(var x:int = 0 ; x < getWidthSize() ; x++) {
                    var square:PaintablePreviewLoaderSquare = squares[x];
                    try {
                        this.paintSquare.removeChild(square);
                    } catch (e:Error) {
                    }
                }
            }
        }
        
        public function drawSquare(mapMarks:Array,
                                   getColorFunction_:Function,
                                   setColorFunction_:Function):void {
            getColorFunction = getColorFunction_;
            setColorFunction = setColorFunction_;
            
            initSquareList();
            drawSquareList(mapMarks);
            initEventOnSquareList();
        }
        
        private function initSquareList():void {
            squaresList = new Array( getHeightSize() );
            
            for(var y:int = 0 ; y < getHeightSize(); y++) {
                for(var x:int = 0 ; x < getWidthSize() ; x++) {
                    if( squaresList[y] == null ) {
                        squaresList[y] = new Array( getWidthSize() );
                    }
                    var square:PaintablePreviewLoaderSquare = getNewSquare(x, y);
                    this.paintSquare.addChild(square);
                }
            }
        }
        
        private function drawSquareList(mapMarks:Array):void {
            for(var y:int = 0 ; y < getHeightSize(); y++) {
                for(var x:int = 0 ; x < getWidthSize() ; x++) {
                    var square:PaintablePreviewLoaderSquare = squaresList[y][x];
                    var color:int = getSquareColor(x, y, mapMarks);
                    this.drawSquareOne(square, color);
                }
            }
        }
        
        private function initEventOnSquareList():void {
            for(var y:int = 0 ; y < getHeightSize(); y++) {
                for(var x:int = 0 ; x < getWidthSize() ; x++) {
                    initEventOnSquareOne(x, y);
                }
            }
        }
        
        private var paintSize:int = 1;
        
        public function setPaintSize(size:int):void {
            paintSize = size;
        }
        
        private function getTargetSquares(x_center:int, y_center:int):Array {
            var size:Number = (paintSize/ 2);
            
            var min:int = Math.floor(size);
            var max:int = Math.round(size);
            
            var x_min:int = x_center - min;
            var x_max:int = x_center + max;
                
            var y_min:int = y_center - min;
            var y_max:int = y_center + max;
                
            var results:Array = new Array();
            
            for(var x:int = x_min ; x < x_max ; x++) {
                for(var y:int = y_min ; y < y_max ; y++) {
                    var square:PaintablePreviewLoaderSquare = getSquare(x, y);
                    if( square == null) {
                        continue;
                    }
                    results.push(square);
                }
            }
            
            return results;
        }
        
        private function getSquare(x:int, y:int):PaintablePreviewLoaderSquare {
            if( x < 0 ) {
                return null;
            }
            if( x >= getWidthSize() ) {
                return null;
            }
            
            if( y < 0 ) {
                return null;
            }
            
            if( y >= squaresList.length ) {
                return null;
            }
            
            var square:PaintablePreviewLoaderSquare = squaresList[y][x];
            
            return square;
        }
        
        private function initEventOnSquareOne(x:int, y:int):void {
            
            var square:PaintablePreviewLoaderSquare = squaresList[y][x];
            square.addEventListener(MouseEvent.MOUSE_DOWN, 
                                    function(event:MouseEvent):void {
                                        thisObj.isDrawing = true;
                                        thisObj.mouseOverEvent(square, x, y);
                                    });
            square.addEventListener(MouseEvent.MOUSE_UP, 
                                    function(event:MouseEvent):void {
                                        thisObj.isDrawing = false;
                                    });
            square.addEventListener(MouseEvent.MOUSE_OVER,
                                    function(event:MouseEvent):void {
                                        thisObj.mouseOverEvent(square, x, y);
                                    });
        }
        
        private function getSquareColor(x:int, y:int, mapMarks:Array):int {
            var color:int = eraseColor;
            
            if( mapMarks[y] != null ) {
                if( mapMarks[y][x] != null ) {
                    color = mapMarks[y][x];
                }
            }
            
            return color;
        }
        
        private function getNewSquare(x:int, y:int):PaintablePreviewLoaderSquare {
            var square:PaintablePreviewLoaderSquare = new PaintablePreviewLoaderSquare();
            
            var length:Number = getLength();
            square.x = x * length;
            square.y = y * length;
            square.width = length;
            square.height = length;
            squaresList[y][x] = square;
            
            initContextMenu(square);
            
            return square;
        }
        
        
        private function initContextMenu(square:PaintablePreviewLoaderSquare):void {
            var menu:ContextMenu = new ContextMenu();
            menu.hideBuiltInItems();
            
            MovablePiece.addMenuItem(menu, "色取得（スポイト）", thisObj.getFunctionForSyringeFromMenu(square));
            
            square.contextMenu = menu;
        }
        
        private function getFunctionForSyringeFromMenu(view:PaintablePreviewLoaderSquare):Function {
            return function(event:ContextMenuEvent):void {
                pickupColorForce(view);
            }
        }
        
        private function syringeFromView(view:PaintablePreviewLoaderSquare):void {
            pickupColor(view);
            if( syringeAfter != null ) {
                syringeAfter.call();
            }
        }
        
        private function getCurrentDrawingColor():int {
            if( isErasing ) {
                return eraseColor;
            }
            
            return getColorFunction.call();
        }
        
        private function drawToViews(views:Array):void {
            //Alert.show("views.length : " + views.length);
            for(var i:int = 0 ; i < views.length ; i++) {
                var view:PaintablePreviewLoaderSquare = views[i];
                var color:int = getCurrentDrawingColor();
                drawSquareOne(view, color);
            }
        }
        
        private function mouseOverEvent(view:PaintablePreviewLoaderSquare, x:int, y:int):void {
            
            if( isSyringe ) {
                syringeFromView(view);
                return;
            }
            
            if( isDrawing ) {
                var views:Array = getTargetSquares(x, y);
                drawToViews(views);
                return;
            }
        }
        
        private function pickupColor(view:PaintablePreviewLoaderSquare, isForce:Boolean = false):void {
            if( ! isDrawing ) {
                    return;
            }
            
            pickupColorForce(view);
        }
        private function pickupColorForce(view:PaintablePreviewLoaderSquare):void {
            Log.logging("view.getColor()", view.getColor());
            setColorFunction.call(null, view.getColor());
            isDrawing = false;
            Log.logging("pickupColor!!!!!!!!!");
        }
        
        private function drawSquareOne(view:PaintablePreviewLoaderSquare, color:int):void {
            Log.logging("color", color);
            
            var length:Number = getLength();
            
            var x:int = view.x / length;
            var y:int = view.y / length;
            
            view.setColor(color);
            view.drawSquare();
        }
    }
}

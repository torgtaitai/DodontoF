//--*-coding:utf-8-*--

package {
    
    import flash.display.BlendMode;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.geom.Point;
    import mx.controls.Alert;
    import mx.core.UIComponent;
    import mx.core.Application;
    import mx.controls.Image;
    import flash.display.BitmapData;
    import flash.utils.ByteArray;
    import flash.geom.Matrix;
    import flash.display.Loader;
    import flash.net.URLRequest;
    
    
    public class MapPainter {
        
        private var otherDrawLayer:UIComponent = new UIComponent();
        private var drawBackImageUrl:String =  Config.getInstance().getTransparentImage();
        
        private var drawTargetLayer:Sprite = new Sprite();
        private var preDrawTargetLayer:Sprite = new Sprite();
        
        private var ownDrawingLine:Array = new Array();
        
        private var isDrawMode:Boolean = false;
        private var isEraseMode:Boolean = false;
        private var drawLineWeight:int = 1;
        private var drawColor:uint = 0x112233;
        
        private var lineDrawType:String = "line";
        private var eraseDrawType:String = "erase";
        
        private var isStraightLine:Boolean = false;
        private var preStraightLineMode:Boolean = false;
        
        private var map:Map;
        
        
        public function MapPainter():void {
        }
        
        public function getOtherDrawLayer():UIComponent {
            return otherDrawLayer;
        }
        
        public function init(map_:Map):void {
            this.map = map_;
            
            otherDrawLayer.blendMode = BlendMode.LAYER;
            otherDrawLayer.addChild(drawTargetLayer);
            
            drawTargetLayer.blendMode = BlendMode.LAYER;
            otherDrawLayer.addChild(preDrawTargetLayer);
            preDrawTargetLayer.blendMode = BlendMode.LAYER;
            preDrawTargetLayer.alpha = 0.5;
        }
        

        public function changeDraws(draws:Array, imageUrl:String, mapWidth:int, mapHeight:int):void {
            Log.logging("changeDraws Begin");
            
            if( ownDrawingLine.length == 0 ) {
                drawTargetLayer.graphics.clear();
            }
            
            printBackDraws(draws, imageUrl, mapWidth, mapHeight);
        }
        
        private function printBackDraws(draws:Array, imageUrl:String, mapWidth:int, mapHeight:int):void {
            Log.logging("printBackDraws Begin");
            
            drawBackImage(imageUrl);
            
            Log.logging("changeDrawsOnly");
            changeDrawsOnly(draws);
        }

        private function drawBackImage(imageUrl:String):void {
            Log.logging("imageUrl", imageUrl);
            
            if( imageUrl == null || imageUrl == "") {
                imageUrl =  Config.getInstance().getTransparentImage();
                Log.logging("imageUrl is empty. so set transparent.git");
            }
            
            imageUrl = Config.getInstance().getUrlString(imageUrl);
            Log.logging("changed imageUrl", imageUrl);
            
            if( drawBackImageUrl != imageUrl) {
                drawBackImageUrl = imageUrl
                Log.logging("image source set!");
                
                var imageLoader:Loader = new Loader();
                imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.completeHandlerForDrawBackImage);
                imageLoader.load( new URLRequest(imageUrl) );
            }
        }
        
        private function completeHandlerForDrawBackImage(event:Event):void {
            var imageLoader:Loader = event.target.loader;
            
            var bitmapData:BitmapData = new BitmapData(imageLoader.width, imageLoader.height, true, 0x000000);
            bitmapData.draw(imageLoader);
            
            var layer:UIComponent = otherDrawLayer;
            layer.graphics.clear();
            
            layer.graphics.beginBitmapFill(bitmapData, null, false, false);
            layer.graphics.drawRect(0, 0, imageLoader.width, imageLoader.height);
            layer.graphics.endFill();
        }
        
        public function changeDrawsOnly(draws:Array):void {
            if( draws == null ) {
                return;
            }
            
            otherDrawLayer.removeChild( preDrawTargetLayer );
            otherDrawLayer.removeChild( drawTargetLayer );
            
            try {
                deleteDrawLayers(draws);
                addDrawLayers(draws);
                countDrawLayers(draws);
            } catch (error:Error) {
                Log.loggingException("Map.changeDraws", error);
            }
            
            otherDrawLayer.addChild( drawTargetLayer );
            otherDrawLayer.addChild( preDrawTargetLayer );
            
            Log.logging("changeDraws End");
        }
        
        
        private function deleteDrawLayers(draws:Array):void {
            var currentCount:int = otherDrawLayer.numChildren
            var diffCount:int = currentCount - draws.length;
            Log.logging("draws.length", draws.length);
            Log.logging("currentCount", currentCount);
            Log.logging("diffCount", diffCount);
            
            for(var i:int = 0 ; i < diffCount ; i++) {
                var targetIndex:int = currentCount - i - 1;
                Log.logging("removeChildAt targetIndex", targetIndex);
                otherDrawLayer.removeChildAt( targetIndex );
            }
        }
        
        private function countDrawLayers(draws:Array):void {
            var count:int = 0;
            
            for each(var data:Array in draws) {
                    if( data == null ) {
                        continue;
                    }
                    
                    var info:Object = data[0];
                    if( info == null ) {
                        continue;
                    }
                    
                    count += data.length - 1;
                }
            
            DrawMapWindow.setLineCount(count);
        }
        
        private function addDrawLayers(draws:Array):void {
            Log.logging("addDrawLayers Begin draws.length", draws.length);
            
            for(var i:int = otherDrawLayer.numChildren ; i < draws.length  ; i++) {
                var data:Array = draws[i];
                changeDrawOneLoop(data);
            }
            
            Log.logging("addDrawLayers End");
        }
        

        private function changeDrawOneLoop(data:Array):void {
            
            if( data == null ) {
                return;
            }
            
            var info:Object = data.shift();
            if( info == null ) {
                return;
            }
            
            changeDraw(info, data);
            
            return;
        }
        
        private function changeDraw(info:Object, data:Array):void {
            Log.logging("changeDraw Begin");
            Log.logging("changeDraw info", info);
            
            if( info.type == lineDrawType || 
                info.type == eraseDrawType ) {
                drawLineByPenData(info, data);
            }
        }
        
        private function drawLineByPenData(info:Object, data:Array):void {
            Log.logging("drawLineByPenData info", info);
            Log.logging("drawLineByPenData, data", data);
            
            var layer:Sprite = createNewDrawLayer(info);
            if( layer == null ) {
                Log.logging("drawLineByPenData createNewDrawLayer is null");
                return;
            }
            Log.logging("add draw line layer");
            
            drawLineByPenDataToLayer(info, data, layer);
            Log.logging("drawLineByPenData End");
        }
        
        private function drawLineByPenDataToLayer(info:Object, data:Array, layer:Sprite):void {
            Log.logging("drawLineByPenDataToLayer Begin");
            
            layer.graphics.lineStyle();
            layer.graphics.lineStyle(info.weight, info.color);
            
            for(var i:int = 0 ; i < data.length ; i++) {
                var xy:Array = data[i];
                
                if( i == 0 ) {
                    layer.graphics.moveTo(xy[0], xy[1]);
                } else {
                    layer.graphics.lineTo(xy[0], xy[1]);
                }
            }
        }
        
        private function createNewDrawLayer(info:Object):Sprite {
            var layer:Sprite = new Sprite();
            layer.blendMode = ((info.type == lineDrawType) ? BlendMode.LAYER : BlendMode.ERASE);
            
            var component:UIComponent = new UIComponent();
            component.addChild(layer);
            
            otherDrawLayer.addChild(component);
            
            return layer;
        }
        


        public function setDrawMode(b:Boolean):void {
            isDrawMode = b;
            
            setPenShade( isDrawMode );
            
            if( isDrawMode ) {
                Application.application.parent.addEventListener(KeyboardEvent.KEY_DOWN, undoRedo);
            } else {
                Application.application.parent.removeEventListener(KeyboardEvent.KEY_DOWN, undoRedo);
            }
        }
        
        private function setPenShade(isSet:Boolean):void {
            try {
                if( isSet ) {
                    Log.logging("setPenShade isDrawMode ON");
                    Application.application.parent.addEventListener(MouseEvent.MOUSE_MOVE, printPenShade);
                } else {
                    Log.logging("setPenShade isDrawMode OFF");
                    Application.application.parent.removeEventListener(MouseEvent.MOUSE_MOVE, printPenShade);
                }
            } catch (e:Error) {
                Log.loggingException("MapPainter.setPenShade", e);
            }
        }
        
        private function undoRedo(event:KeyboardEvent):void {
            if( ! event.ctrlKey ) {
                return;
            }
            
            if( event.keyCode == String("Z").charCodeAt(0) ) {
                DrawMapWindow.getInstance().undoDrawOnMap();
            }
            
            if( event.keyCode == String("Y").charCodeAt(0) ) {
                DrawMapWindow.getInstance().redoDrawOnMap();
            }
        }
        
        private function printPenShade(event:Event):void {
            preDrawTargetLayer.graphics.clear();
            preDrawTargetLayer.graphics.lineStyle(drawLineWeight, drawColor);
            preDrawTargetLayer.blendMode = ( isEraseMode ? BlendMode.ERASE : BlendMode.LAYER );
            
            var x:Number = DodontoF_Main.getInstance().getDodontoF().mouseX;
            var y:Number = DodontoF_Main.getInstance().getDodontoF().mouseY;
            
            var point:Point = preDrawTargetLayer.globalToLocal( new Point(x, y) );
            preDrawTargetLayer.graphics.moveTo(point.x, point.y)
            preDrawTargetLayer.graphics.lineTo(point.x + 0.5, point.y + 0.5);
        }
        
        public function undoDrawOnMap(resultFunction:Function):void {
            DodontoF_Main.getInstance().getGuiInputSender().undoDrawOnMap(resultFunction);
        }
        
        
        public function getDrawMode():Boolean {
            return isDrawMode;
        }
        
        
        public function setDrawState(size:int, color:uint, isErase_:Boolean):void {
            Log.logging("setDrawState isDrawMode", isDrawMode);
            
            isEraseMode = isErase_;
            drawLineWeight = size;
            drawColor = color;
            
            drawTargetLayer.graphics.clear();
            
            Log.logging("setDrawState isErase", isEraseMode);
            drawTargetLayer.blendMode = ( isEraseMode ? BlendMode.ERASE : BlendMode.LAYER );
        }
        
        public function setStraightLineMode(b:Boolean):void {
            isStraightLine = b;
        }
        
        private function isVerticalHorizontalLine(event:MouseEvent):Boolean {
            return  event.shiftKey;
        }
        
        private function isSnapOnSquare(event:MouseEvent):Boolean {
            return  event.ctrlKey;
        }
        
        private function isStraightLineMode(event:MouseEvent):Boolean {
            if( isStraightLine ) {
                return true;
            }
            return  (event.altKey || event.ctrlKey || event.shiftKey);
        }
        
        public function beginDrawByPen(event:MouseEvent):void {
            clearOwnDrawingLine();
            
            var info:Object = {
                "type" : getCurrentLineDrawType(),
                "weight" : drawLineWeight,
                "color" : drawColor };
            ownDrawingLine.push( info );
            
            var firstPoint:Array = getDrawPoint(event.localX, event.localY, event);
            ownDrawingLine.push( firstPoint );
            
            initPen(false);
            
            if( ! isStraightLineMode(event) ) {
                // クリックのみでも点を描くため
                var point:Point = new Point(event.localX + 0.5, event.localY + 0.5);
                drawTargetLayer.graphics.lineTo(point.x, point.y);
                ownDrawingLine.push([point.x, point.y]);
            }
            
            preStraightLineMode = isStraightLineMode(event);
            
            setPenShade(false);
            Application.application.parent.addEventListener(MouseEvent.MOUSE_MOVE, drawLineByPen);
        }
        
        private function initPen(isClear:Boolean = true):void {
            if( isClear ) {
                drawTargetLayer.graphics.clear();
            }
            drawTargetLayer.graphics.lineStyle(drawLineWeight, drawColor);
            
            var firstPoint:Array = ownDrawingLine[1];
            drawTargetLayer.graphics.moveTo(firstPoint[0], firstPoint[1]);
        }
        
        private function clearOwnDrawingLine():void {
            while (ownDrawingLine.length > 0) {
                ownDrawingLine.pop();
            }
        }
        
        
        private function getCurrentLineDrawType():String {
            if( isEraseMode ) {
                return eraseDrawType;
            }
            return lineDrawType;
        }
        
        private function drawLineByPen(event:MouseEvent):void {
            if( ownDrawingLine.length <= 1 ) {
                return;
            }
            
            var point:Array = ownDrawingLine[ownDrawingLine.length - 1];
            var x:Number = drawTargetLayer.mouseX;
            var y:Number = drawTargetLayer.mouseY;
            
            // 移動したときのみ描き込む。
            if (x == point[0] && y == point[1]) {
                return;
            }
            
            if( isStraightLineMode(event) ) {
                drawStraightLine(x, y, event);
            } else {
                drawFreeLine(x, y, event);
            }
            
            preStraightLineMode = isStraightLineMode(event);
        }
        
        private function drawFreeLine(x:Number, y:Number, event:MouseEvent):void {
            if( preStraightLineMode != isStraightLineMode(event) ) {
                drawPastFreeLine();
            }
            
            drawTargetLayer.graphics.lineTo(x, y);
            ownDrawingLine.push( [x, y] );
        }
        
        private function drawPastFreeLine():void {
            initPen();
            
            var pastBeginIndex:int = 2; //配列の0は情報、1はinitPenで初期化されるので、2から描画開始。
            
            for(var i:int = pastBeginIndex ; i < ownDrawingLine.length ; i++) {
                var point:Array = ownDrawingLine[i];
                drawTargetLayer.graphics.lineTo(point[0], point[1]);
            }
        }
        
        private function drawStraightLine(x:Number, y:Number, event:MouseEvent):void {
            initPen();
            
            var point:Array = getDrawPoint(x, y, event);
            drawTargetLayer.graphics.lineTo(point[0], point[1]);
        }
        
        private function getDrawPoint(x:Number, y:Number, event:MouseEvent):Array {
            var point:Array = [x, y];
            
            if( isSnapOnSquare(event) ) {
                point = getSnapedXY(x, y);
            } else if( isVerticalHorizontalLine(event) ) {
                point = getVerticalHorizontalLine(x, y);
            }
            
            return point;
        }
        
        private function getSnapedXY(x:Number, y:Number):Array {
            var point:Point = map.getSnapViewPoint(x, y, Map.getSquareLength());
            x = point.x * Map.getSquareLength();
            y = point.y * Map.getSquareLength();
            return [x, y];
        }
        
        private function getVerticalHorizontalLine(x2:Number, y2:Number):Array {
            if( ownDrawingLine.length < 2 ) {
                return [x2, y2];
            }
            
            var firstPoint:Array = ownDrawingLine[1];
            
            var x1:Number = firstPoint[0];
            var y1:Number = firstPoint[1];
            
            var xLength:Number = Math.abs(x2 - x1);
            var yLength:Number = Math.abs(y2 - y1);
            
            if( xLength > yLength ) {
                if( xLength / 2 > yLength) {
                    return [x2, y1];
                }
                
                var diffY:Number = ((y2 - y1) > 0) ? xLength : -xLength;
                return [x2, y1 + diffY];
            }
            
            if( yLength / 2 > xLength) {
                return [x1, y2];
            }
            
            var diffX:Number = ((x2 - x1) > 0) ? yLength : -yLength;
            return [x1 + diffX, y2];
            
            /*
            var radian:Number = Math.atan2(xLength, yLength);
            var angle:Number = radian / Math.PI;
            
            if( angle > 0.75 ) {
                return [x2, y2];
            } else if( angle > 0.5 ) {
                return [x2, y2];
            }
            */
        }
        
        
        public function endDrawByPen(event:MouseEvent):void {
            if( isStraightLineMode(event) ) {
                var lastPoint:Array = getDrawPoint(drawTargetLayer.mouseX, drawTargetLayer.mouseY, event);
                
                ownDrawingLine = [ownDrawingLine[0],
                                  ownDrawingLine[1],
                                  lastPoint];
            }
            
            Application.application.parent.removeEventListener(MouseEvent.MOUSE_MOVE, drawLineByPen);
            setPenShade(true);
            
            sendOwnDraws();
            Log.logging("sendOwnDraws!");
            
            clearOwnDrawingLine();
        }
        
        private function sendOwnDraws():void {
            if ( ownDrawingLine.length == 0) {
                return;
            }
            
            DodontoF_Main.getInstance().getGuiInputSender().drawOnMap(ownDrawingLine);
            DrawMapWindow.clearRedoList();
        }
        
    }
}


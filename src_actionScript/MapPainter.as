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
    
    public class MapPainter {
        
        private var otherDrawLayer:UIComponent = new UIComponent();
        
        private var drawTargetLayer:Sprite = new Sprite();
        private var preDrawTargetLayer:Sprite = new Sprite();
        
        private var ownDrawingLine:Array = new Array();
        
        private var isDrawMode:Boolean = false;
        private var isEraseMode:Boolean = false;
        private var drawLineWeight:int = 1;
        private var drawColor:uint = 0x112233;
        
        private var lineDrawType:String = "line";
        private var eraseDrawType:String = "erase";
        
        private var isStraightLineMode:Boolean = false;
        private var isStraightLineOnSquareMode:Boolean = false;
        
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
        

        public function changeDraws(draws:Array):void {
            Log.logging("changeDraws Begin");
            
            if( ownDrawingLine.length == 0 ) {
                drawTargetLayer.graphics.clear();
            }
            
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
        }
        
        private function setPenShade(isSet:Boolean):void {
            try {
                if( isSet ) {
                    Log.logging("setPenShade isDrawMode ON");
                    preDrawTargetLayer.addEventListener(Event.ENTER_FRAME, printPenShade);
                } else {
                    Log.logging("setPenShade isDrawMode OFF");
                    preDrawTargetLayer.removeEventListener(Event.ENTER_FRAME, printPenShade);
                }
            } catch (e:Error) {
            }
        }
        
        private var shadePrintCounter:int = 0;
        private var shadePrintCountTime:int = 5;
        
        private function printPenShade(event:Event):void {
            
            //毎回カーソルに影（書き込み予定筆跡）を描くと重いので適当に飛ばす。
            shadePrintCounter++;
            if( shadePrintCounter < shadePrintCountTime ) {
                return;
            }
            shadePrintCounter = 0;
            
            
            preDrawTargetLayer.graphics.clear();
            preDrawTargetLayer.blendMode = ( isEraseMode ? BlendMode.ERASE : BlendMode.LAYER );
            preDrawTargetLayer.graphics.lineStyle(drawLineWeight, drawColor);
            
            var x:Number = DodontoF_Main.getInstance().getDodontoF().mouseX;
            var y:Number = DodontoF_Main.getInstance().getDodontoF().mouseY;
            
            var point:Point = preDrawTargetLayer.globalToLocal( new Point(x, y) );
            preDrawTargetLayer.graphics.moveTo(point.x, point.y);
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
        
        
        public function beginDrawByPen(event:MouseEvent):void {
            clearOwnDrawingLine();
            
            isStraightLineMode = event.shiftKey || event.ctrlKey;
            isStraightLineOnSquareMode = event.ctrlKey;
            
            var info:Object = {
                "type" : getCurrentLineDrawType(),
                "weight" : drawLineWeight,
                "color" : drawColor };
            ownDrawingLine.push( info );
            
            drawTargetLayer.graphics.lineStyle(info.weight, info.color);
            drawTargetLayer.graphics.moveTo(event.localX, event.localY);
            
            var firstPoint:Array = getDrawPoint(event.localX, event.localY);
            ownDrawingLine.push( firstPoint );
            
            if( ! isStraightLineMode ) {
                // クリックのみでも点を描くため
                var point:Point = new Point(event.localX + 0.5, event.localY + 0.5);
                drawTargetLayer.graphics.lineTo(point.x, point.y);
                ownDrawingLine.push([point.x, point.y]);
            }
            
            setPenShade(false);
            drawTargetLayer.addEventListener(Event.ENTER_FRAME, drawLineByPen); 
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
        
        private function drawLineByPen(event:Event):void {
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
            
            drawTargetLayer.graphics.lineTo(x, y);
            
            if( isStraightLineMode ) {
                drawStraightLine(x, y);
            } else {
                ownDrawingLine.push( [x, y] );
            }
        }
        
        private function drawStraightLine(x:Number, y:Number):void {
            var point:Array = getDrawPoint(x, y);
            
            drawTargetLayer.graphics.clear();
            drawTargetLayer.graphics.lineStyle(drawLineWeight, drawColor);
            
            var firstPoint:Array = ownDrawingLine[1];
            drawTargetLayer.graphics.moveTo(firstPoint[0], firstPoint[1]);
            drawTargetLayer.graphics.lineTo(point[0], point[1]);
        }
        
        private function getDrawPoint(x:Number, y:Number):Array {
            if( isStraightLineOnSquareMode ) {
                var point:Point = map.getSnapViewPoint(x, y, Map.getSquareLength());
                x = point.x * Map.getSquareLength();
                y = point.y * Map.getSquareLength();
            }
            
            return [x, y];
        }
        
        public function endDrawByPen(event:MouseEvent):void {
            if( isStraightLineMode ) {
                var point:Array = getDrawPoint(drawTargetLayer.mouseX, drawTargetLayer.mouseY);
                ownDrawingLine.push( point );
            }
            
            drawTargetLayer.removeEventListener(Event.ENTER_FRAME, drawLineByPen);
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


//--*-coding:utf-8-*--

package {
    
    import flash.events.MouseEvent;
    import mx.controls.Image;
    import mx.core.UIComponent;
    import flash.geom.Point;
    import mx.events.DragEvent;

    public class Rotater {
        
        private var thisObj:Rotater;
        
        //private var dragDropForRotate:DragDrop = new DragDrop();
        
        public function Rotater():void {
            thisObj = this;
        }
        
        
        private var rotateMarkerBase:UIComponent = new UIComponent();
        private var rotateImage:UIComponent = new UIComponent();
        private var rotateMarker:UIComponent;
        
        private var piece:MovablePiece;
        private var view:ImageSprite;
        private var height:Number;
        
        static private var rotatingObject:Rotater;
        
        public function init(view_:ImageSprite, piece_:MovablePiece):void {
            view  = view_;
            piece = piece_;
            
            rotateMarkerBase.addChild(rotateImage);
            
            initMarkerBasePosition();
            
            rotateMarker = createRotateMarker();
            rotateMarkerBase.addChild(rotateMarker);
            addRotateRotateMarker()
            
            view.addChild(rotateMarkerBase);
            
            initEvent();
        }
        
        private var is2ndMarker:Boolean = false;
        
        public function set2ndMarker(b:Boolean):void {
            is2ndMarker = b;
        }
        
        static private var isRotateMarkerGlobalVisible:Boolean = true;
        
        static public function setGlobalVisible( b:Boolean ) :void {
            isRotateMarkerGlobalVisible = b;
        }
        
        private function setRotateMarkerVisible(visible:Boolean):void {
            if( rotateMarker == null ) {
                return;
            }
            
            if( ! isRotateMarkerGlobalVisible ) {
                visible = false;
            }
            
            rotateMarker.visible = visible;
        }
        
        private function initEvent():void {
            var markerVisibler:Function = function(event:MouseEvent):void {
                if( ! thisObj.piece.getDraggable() ) {
                    return;
                }
                
                if( ! isRotating() ) {
                    thisObj.setRotateMarkerVisible(true);
                }
            };
            view.addEventListener(MouseEvent.MOUSE_OVER, markerVisibler);
            view.addEventListener(MouseEvent.CLICK, markerVisibler);
            
            view.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
                if( ! isRotating() ) {
                    thisObj.setRotateMarkerVisible(false);
                }
            });
        }
        
        
        public function setBaseRotation(rotation:Number):void {
            rotateMarkerBase.rotation = rotation
        }
        
        static public function isAnyRotating():Boolean {
            var b:Boolean = (rotatingObject != null);
            return b;
        }
    
        private function isRotating():Boolean {
            var b:Boolean = (rotatingObject == this);
            return b;
        }
            
        
        
        private var isRotateImageDrawn:Boolean = false;
        
        private function clearRotateImage():void {
            rotateImage.visible = false;
            isRotateImageDrawn = false;
            rotateImage.graphics.clear();
        }
        
        private function drawRotateImage(rotation:Number):void {
            if( ! isRotating() ) {
                return;
            }
            
            rotateImage.visible = true;
            rotateImage.rotation = rotation;
            
            if( isRotateImageDrawn ) {
                return;
            }
            isRotateImageDrawn = true;
            
            var diffX:Number = getWidth() / 2;
            var diffY:Number = getHeight() / 2;
            var rotateImageColor:uint = 0xBBBBBB;
            
            rotateImage.graphics.lineStyle(5, rotateImageColor);
            rotateImage.graphics.drawRect(0 - diffX, 0 - diffY,
                                          getWidth(), getHeight());
        }
        
        private function getMarkerWidth():Number {
            return piece.getOwnWidth() * 0.3;
        }
        
        [Embed(source='image/cursor/rotateMarker.swf')]
        [Bindable]
        private var rotateMarkerImageSource:Class;
        
        private function createRotateMarker():UIComponent {
            var marker:Image = new Image();
            marker.source = rotateMarkerImageSource;
            return marker;
        }
        
        private function initMarkerBasePosition():void {
            rotateMarkerBase.x = getWidth() / 2;
            rotateMarkerBase.y = getHeight() / 2;
        }
        
        public function update():void {
            if( rotateMarker == null ) {
                return;
            }
            
            initMarkerBasePosition();
            initRotateMarkerPosition();
            
            rotateMarker.width = getMarkerWidth();
            rotateMarker.height = getMarkerWidth();
        }
        
        private function initRotateMarkerPosition():void {
            var point:Point = getMarkerInitPoint();
            rotateMarker.x = point.x;
            rotateMarker.y = point.y;
        }
        
        private function getMarkerInitPoint():Point {
            var diff:Number = getMarkerWidth() * -0.2;
            var rate:int = -1;
            
            var point:Point = new Point();
            point.x = (getWidth() / 2) * rate + diff;
            point.y = (getHeight() / 2) * rate + diff;
            
            return point;
        }
        
        private function addRotateRotateMarker():void {
            rotateMarker.width = getMarkerWidth();
            rotateMarker.height = getMarkerWidth();
            
            setRotateMarkerVisible( false );
            initRotateMarkerPosition();
            
            addMouseDownEventToRotateMarker();
            addMouseMoveEventToRotateMarker();
            addMouseUpEventToRotateMarker();
            addMouseOverEventToRotateMarker();
            addMouseOutEventToRotateMarker();
        }
        
        private function addMouseDownEventToRotateMarker():void {
            rotateMarker.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    event.stopPropagation();
                    
                    if( rotatingObject != null ) {
                        rotatingObject.stopRotation();
                    }
                    rotatingObject = thisObj;
                    
                    piece.setViewForeground();
                    
                    var localPoint:Point = new Point(event.stageX, event.stageY);
                    var basePoint:Point = rotateMarkerBase.globalToLocal(localPoint);
                    
                    var diff:Number = (rotateMarker.width / -2);
                    rotateMarker.startDrag();
                });
        }
        
        private function addMouseMoveEventToRotateMarker():void {
            rotateMarker.addEventListener(MouseEvent.MOUSE_MOVE, function(event:MouseEvent):void {
                    if( ! isRotating() ) {
                        return;
                    }
                    
                    var rotation:Number = thisObj.getRotationOnMarker(rotateMarker.x, rotateMarker.y, event);
                    thisObj.drawRotateImage(rotation);
                });
            
        }
        
        private function addMouseUpEventToRotateMarker():void {
            rotateMarker.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    event.stopPropagation();
                    stopRotationFunction(event);
                });
            
        }
        
        private function addMouseOverEventToRotateMarker():void {
            rotateMarker.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
                    if( ! isRotating() ) {
                        rotateMarker.scaleX = 1.5;
                        rotateMarker.scaleY = 1.5;
                    }
                });
        }
        
        private function addMouseOutEventToRotateMarker():void {
            rotateMarker.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
                    if( ! isRotating() ) {
                        rotateMarker.scaleX = 1.0;
                        rotateMarker.scaleY = 1.0;
                    }
                });
        }
        
        private function stopRotationFunction(event:MouseEvent = null):void {
            rotateMarker.stopDrag();
            
            var rotation:Number = getRotationOnMarker(rotateMarker.x, rotateMarker.y, event);
            
            initRotateMarkerPosition();
            setRotateMarkerVisible( false );
            
            clearRotateImage();
            
            if( rotation != 0 ) {
                    thisObj.piece.setDiffRotation(rotation);
                    thisObj.piece.loadViewImage();
                    
                    DodontoF_Main.getInstance().getGuiInputSender().getSender()
                        .changeCharacter( thisObj.piece.getJsonData() );
            }
            
            if( rotatingObject != null ) {
                if( rotatingObject != this ) {
                    try {
                        rotatingObject.stopRotation();
                    } catch(e:Error) {
                        Log.loggingExceptionDebug("Character.popUpChangeWindow()", e);
                    }
                }
            }
            rotatingObject = null;
        }
        
        private function rotateAction(obj:Object):void {
            var event:MouseEvent = obj.event;
            //event.stopPropagation();
            stopRotationFunction( event );
        }
        
        public function stopRotation():void {
            stopRotationFunction();
        }
        
        static public function stopRotation():void {
            if( rotatingObject != null ) {
                rotatingObject.stopRotationFunction();
            }
            rotatingObject = null;
        }
        
        private function getRotationFromXY(dx:Number, dy:Number):Number {
            var radians:Number = Math.atan2(dy, dx);
            var rotation:Number = radians * 180 / Math.PI;
            return rotation;
        }
        
        private function getBaseDiffRotation():Number {
            var dx:Number = getWidth();
            var dy:Number = getHeight();
            
            var rotation:Number = getRotationFromXY(dx, dy);
            
            return rotation;
        }
        
        private function getRotationOnMarker(dx:Number, dy:Number, event:MouseEvent = null):Number {
            var isAltKey:Boolean = (event == null ? false : event.altKey);
            
            var rotation:Number = getRotationFromXY(dx, dy);
            
            rotation -= getBaseDiffRotation();//54;
            rotation += 180;
            
            if( ! isAltKey ) {
                var currentRotation:Number = piece.getRotation();
                var totalRotation:Number = currentRotation + rotation;
                
                totalRotation += 15;
                totalRotation += (360 * 2);
                
                var rotationIndex:int = totalRotation / 30;
                totalRotation = rotationIndex * 30;
                rotation = totalRotation - currentRotation;
            }
            
            rotation += (360 * 2);
            rotation = rotation % 360;
            
            return rotation;
        }
        
        
        public function getWidth():int {
            return piece.getOwnWidth();
        }
        
        private function getHeight():int {
            return piece.getOwnHeight();
        }
        
        
    }
    
}

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
            addRotateRotateMarker( rotateMarkerBase, rotateMarker );
            
            view.addChild(rotateMarkerBase);
            
            //dragDropForRotate.addDropEvent( piece.getMapLayer() );
            
            initEvent();
        }
        
        private var is2ndMarker:Boolean = false;
        
        public function set2ndMarker(b:Boolean):void {
            is2ndMarker = b;
        }
        
        private function setMarkerVisible(marker:UIComponent, visible:Boolean):void {
            if( marker == null ) {
                return;
            }
            
            marker.visible = visible;
        }
        
        private function initEvent():void {
            var markerVisibler:Function = function(event:MouseEvent):void {
                if( ! thisObj.piece.getDraggable() ) {
                    return;
                }
                
                if( ! isRotating() ) {
                    setMarkerVisible(thisObj.rotateMarker, true);
                }
            };
            view.addEventListener(MouseEvent.MOUSE_OVER, markerVisibler);
            view.addEventListener(MouseEvent.CLICK, markerVisibler);
            
            view.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
                if( ! isRotating() ) {
                    setMarkerVisible(thisObj.rotateMarker, false);
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
            
            /*
            var marker:UIComponent = new UIComponent();
            var lineColor:uint = 0xEEEE00;
            var color:uint = 0xEE0000;
            marker.alpha = 0.75;
            
            marker.graphics.beginFill(lineColor);
            marker.graphics.drawCircle(0 + getMarkerWidth() / 2, 0 + getMarkerWidth() / 2, getMarkerWidth() * 0.5);
            marker.graphics.endFill();
            
            marker.graphics.beginFill(color);
            marker.graphics.drawCircle(0 + getMarkerWidth() / 2, 0 + getMarkerWidth() / 2, (getMarkerWidth() * 0.4));
            marker.graphics.endFill();
            */
            
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
            
            var marker:UIComponent = rotateMarker;
            initMarkerPosition(marker);
            
            marker.width = getMarkerWidth();
            marker.height = getMarkerWidth();
        }
        
        private function initMarkerPosition(marker:UIComponent):void {
            var point:Point = getMarkerInitPoint();
            marker.x = point.x;
            marker.y = point.y;
        }
        
        private function getMarkerInitPoint():Point {
            var diff:Number = getMarkerWidth() * -0.2;
            var rate:int = -1;
            
            var point:Point = new Point();
            point.x = (getWidth() / 2) * rate + diff;
            point.y = (getHeight() / 2) * rate + diff;
            
            return point;
        }
        
        private function addRotateRotateMarker( base:UIComponent, marker:UIComponent ):UIComponent {
            base.addChild(marker);
            
            marker.width = getMarkerWidth();
            marker.height = getMarkerWidth();
            marker.visible = false;
            
            initMarkerPosition(marker);
            marker.visible = false;
            
            //marker.toolTip = "Ctrlキーで任意角度";
            
            marker.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    event.stopPropagation();
                    
                    if( rotatingObject != null ) {
                        rotatingObject.stopRotation();
                    }
                    rotatingObject = thisObj;
                    
                    piece.setViewForeground();
                    
                    var localPoint:Point = new Point(event.stageX, event.stageY);
                    var basePoint:Point = base.globalToLocal(localPoint);
                    
                    var diff:Number = (marker.width / -2);
                    marker.startDrag();
                });
            
            marker.addEventListener(MouseEvent.MOUSE_MOVE, function(event:MouseEvent):void {
                    if( ! isRotating() ) {
                        return;
                    }
                    
                    var rotation:Number = thisObj.getRotationOnMarker(marker.x, marker.y, event.ctrlKey);
                    thisObj.drawRotateImage(rotation);
                });
            
            stopRotationFunction = function(ctrlKey:Boolean):void {
                marker.stopDrag();
                
                var rotation:Number = thisObj.getRotationOnMarker(marker.x, marker.y, ctrlKey);
                
                thisObj.initMarkerPosition(marker);
                marker.visible = false;
                
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
            };
            
            /*
            var value:Object = {};
            dragDropForRotate.setDropEventWidthHeigth(marker,
                                                      marker.width - 3, marker.height - 3,
                                                      value, rotateAction);
            */
            
            marker.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
                    event.stopPropagation();
                    stopRotationFunction(event.ctrlKey);
                });
            
            marker.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
                    if( ! isRotating() ) {
                        marker.scaleX = 1.5;
                        marker.scaleY = 1.5;
                    }
                });
            
            marker.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
                    if( ! isRotating() ) {
                        marker.scaleX = 1.0;
                        marker.scaleY = 1.0;
                    }
                });
        
            return marker;
        }
        
        private function rotateAction(obj:Object):void {
            var event:MouseEvent = obj.event;
            //event.stopPropagation();
            stopRotationFunction(event.ctrlKey);
        }
        
        private var stopRotationFunction:Function;
        
        public function stopRotation():void {
            stopRotationFunction(false);
        }
        
        static public function stopRotation():void {
            if( rotatingObject != null ) {
                rotatingObject.stopRotationFunction(false);
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
        
        private function getRotationOnMarker(dx:Number, dy:Number, isCtrlKey:Boolean):Number {
            var rotation:Number = getRotationFromXY(dx, dy);
            
            rotation -= getBaseDiffRotation();//54;
            rotation += 180;
            
            if( ! isCtrlKey ) {
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

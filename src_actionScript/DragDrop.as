//--*-coding:utf-8-*--

package {
    
	import flash.display.Bitmap;
	import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import mx.core.UIComponent;
    import mx.events.DragEvent;
    import mx.core.DragSource;
    import mx.managers.DragManager;
    
    public class DragDrop {
        
        private var thisObj:DragDrop;
        private var layer:UIComponent;
        
        private var dropValueKey:String = "dropValueKey";
        private var dropAction:Function;
        private var name:String = "";
        
        public function DragDrop(name_:String):void {
            thisObj = this;
            name = name_;
        }
        
        
        public function addDropEvent(component:UIComponent):void {
            removeDropEvent();
            
            Log.logging("DragDrop.addDropEvent at ", name);
            
            layer = component;
            layer.addEventListener(DragEvent.DRAG_DROP, dragDropHandler);
            layer.addEventListener(DragEvent.DRAG_OVER, dragOverHandler);
            layer.addEventListener(DragEvent.DRAG_ENTER, dragEnter);
        }
        
        public function getLayer():UIComponent {
            return layer;
        }
        
        public function removeDropEvent():void {
            if( layer ==  null ) {
                return;
            }
            
            Log.logging("DragDrop.removeDropEvent at ", name);
            
            layer.removeEventListener(DragEvent.DRAG_DROP, dragDropHandler);
            layer.removeEventListener(DragEvent.DRAG_OVER, dragOverHandler);
            layer.removeEventListener(DragEvent.DRAG_ENTER, dragEnter);
            layer = null;
        }
        
        private function dragDropHandler(event:DragEvent):void {
            if( event.action != DragManager.MOVE ) {
                //MOVE以外のアクション（つまりドロップが行われていない場合）は無視
                return;
            }
            
            var value:Object = event.dragSource.dataForFormat(dropValueKey);
            value.event = event;
            dropAction(value);
        }
        
        private function dragOverHandler(event:DragEvent):void {
            if( thisObj.moveAction == null ) {
                return;
            }
            
            thisObj.moveAction(event);
            event.stopPropagation();
        }
        
        public function dragEnter(e:DragEvent):void {
            DragManager.acceptDragDrop(layer);
        }
        
        
        
        private function setDropAction(action:Function):void {
            dropAction = action;
        }
        
        
        private var moveAction:Function;
        public function setMoveEvent(action:Function):void {
            moveAction = action;
        } 
        
        public function setDropEvent(component:UIComponent, value:Object, action:Function):void {
            var width:Number = component.width;
            var height:Number = component.height;
            setDropEventWidthHeigth(component, width, height, value, action);
        }
        
        
        public function setDropEventWidthHeigth(component:UIComponent,
                                                width:Number, height:Number,
                                                value:Object, action:Function):void {
            component.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    event.stopPropagation();
                    
                    thisObj.dragStartHandler(event, component, width, height, value, action);
                });
        }
        
        public function dragStartHandler(event:MouseEvent,
                                         component:UIComponent, 
                                         width:Number, height:Number,
                                         value:Object, action:Function):void{
            Log.logging("dragStartHandler Begin");
            
            setDropAction(action);
            
            Log.logging("create Draged Data");
            var dragSource:DragSource = new DragSource();
            dragSource.addData(value, dropValueKey);
            
            Log.logging("create dragging image");
            try {
                var bitmap:Bitmap = Utils.getBitMap(component, width, height);
            } catch (e:Error) {
                Log.loggingException("DragDrop.dragStartHandler", e);
            }
            
            var imageProxy:UIComponent = new UIComponent();
            imageProxy.addChild(bitmap);
            
            DragManager.doDrag(component, dragSource, event, imageProxy);
            
            Log.logging("dragStartHandler End");
        }
    }
}

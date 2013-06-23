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
        
        
        public function addDropEvent(component:UIComponent, action:Function):void {
            removeDropEvent();
            
            Log.logging("DragDrop.addDropEvent at ", name);
            
            layer = component;
            layer.addEventListener(DragEvent.DRAG_DROP, dropHandler);
            layer.addEventListener(DragEvent.DRAG_ENTER, dragEnter);
            
            dropAction = action;
        }
        
        public function getLayer():UIComponent {
            return layer;
        }
        
        public function removeDropEvent():void {
            if( layer ==  null ) {
                return;
            }
            
            Log.logging("DragDrop.removeDropEvent at ", name);
            
            layer.removeEventListener(DragEvent.DRAG_DROP, dropHandler);
            layer.removeEventListener(DragEvent.DRAG_ENTER, dragEnter);
            layer = null;
        }
        
        private function dropHandler(event:DragEvent):void {
            if( event.action != DragManager.MOVE ) {
                //MOVE以外のアクション（つまりドロップが行われていない場合）は無視
                return;
            }
            
            var value:Object = event.dragSource.dataForFormat(dropValueKey);
            value.event = event;
            dropAction(value);
        }
        
        private function dragEnter(e:DragEvent):void {
            DragManager.acceptDragDrop(layer);
        }
        
        
        
        public function setDropEvent(component:UIComponent, value:Object):void {
            var width:Number = component.width;
            var height:Number = component.height;
            setDropEventWidthHeigth(component, value, width, height);
        }
        
        
        public function setDropEventWidthHeigth(component:UIComponent, value:Object,
                                                width:Number, height:Number):void {
            component.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
                    event.stopPropagation();
                    
                    thisObj.startDrag(event, component, value, width, height);
                });
        }
        
        public function startDrag(event:MouseEvent,
                                  component:UIComponent, 
                                  value:Object,
                                  width:Number, height:Number):void{
                                  
            Log.logging("startDrag Begin");
            
            var dragSource:DragSource = new DragSource();
            dragSource.addData(value, dropValueKey);
            
            var bitmap:Bitmap = Utils.getBitMap(component, width, height);
            var imageProxy:UIComponent = new UIComponent();
            imageProxy.addChild(bitmap);
            
            DragManager.doDrag(component, dragSource, event, imageProxy);
            
            Log.logging("startDrag End");
        }
        
        
   }
}

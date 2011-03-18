package {
    
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import mx.core.UIComponent;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    
    public class PreviewLoader extends UIComponent {
        
            
        private var imageLoader:Loader = new Loader();
        private var widthSize:int = 50;
        private var heightSize:int = 50;
        private var maxLimitSize:int = 1;
        private var gridLayer:UIComponent = new UIComponent();
        private var rate:Number = 1;
        private var imageName:String = "";
        
        public function PreviewLoader() {
            this.addChild(imageLoader);
            this.addChild(gridLayer);
        }
        
        public function loadImage(url:String, size:int):void {
            loadImageWidthHeight(url, size, size);
        }
        
        public function loadImageWidthHeight(url:String, widthSize_:int, heightSize_:int, maxLimitSize_:int = 1):void {
            imageName = url;
            widthSize = widthSize_;
            heightSize = heightSize_;
            maxLimitSize = maxLimitSize_;
            
            this.height = maxLimitSize * Map.getSquareLength();
            this.width = maxLimitSize * Map.getSquareLength();
            
            rate =  1.0;
            var maxSize:int = Math.max(widthSize, heightSize);
            if( maxSize > maxLimitSize ) {
                rate =  maxLimitSize / maxSize;
            }
            
            if( imageName == "" ) {
                imageLoader.visible = false;
                return;
            }
            imageLoader.visible = true;
            
            imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.completeHandler);
            imageLoader.contentLoaderInfo.addEventListener(Event.UNLOAD, this.unLoadHandler);
            imageLoader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR, this.ioErrorHandler);
            
            imageLoader.load(new URLRequest(url));
        }
        
        private function ioErrorHandler(event:Event):void {
            //NO action
        }
        
        
        private function unLoadHandler(event:Event):void {
            Log.logging("unLoadHandler");
        }
        
        public function drawGrid(color:uint = 0x000000):void {
            gridLayer.graphics.clear();
            Map.drawGrid(widthSize, heightSize, gridLayer, rate * Map.getSquareLength(), color);
        }
        
        private var loadImageCompleteFunction:Function = null;
        
        public function setLoadImageCompleate(f_:Function):void {
            loadImageCompleteFunction = f_;
        }
        
        private function completeHandler(event:Event):void {
            var printWidthSize:Number = widthSize *  rate;
            var printHeightSize:Number = heightSize * rate;
            
            event.target.loader.width = printWidthSize * Map.getSquareLength();
            event.target.loader.height = printHeightSize * Map.getSquareLength();
            
            if( loadImageCompleteFunction != null ) {
                loadImageCompleteFunction();
            }
        }
        
        protected function getLength():Number {
            return Map.getSquareLength() * rate;
        }
        
        protected function getWidthSize():int {
            return widthSize;
        }
        
        protected function getHeightSize():int {
            return heightSize;
        }
        
    }
}

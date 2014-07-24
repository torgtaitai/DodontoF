package {
	import mx.core.UIComponent;
    import flash.geom.Point;
    
    public class PaintablePreviewLoaderSquare extends UIComponent {
        
        private static var eraseColor:int = -1;
        
        public static function getEraseColor():int {
            return eraseColor;
        }
        
        private var color:int = 0;
        private var isErase:Boolean = false;
        
        public function setColor(color_:int):void {
            color = color_;
            
            if( color == eraseColor ) {
                isErase = true;
                alpha = 0.1;
                color = 0xFFFFFF;
            } else {
                isErase = false;
                alpha = 1;
            }
        }
        
        public function getColor():int {
            if( isErase ) {
                return eraseColor;
            }
            
            return color;
        }
        
        public function drawSquare():void {
            var view:UIComponent = this;
            view.graphics.clear();
            view.graphics.lineStyle(1, 0x000000);
            view.graphics.beginFill(color, alpha);
            
            view.graphics.drawRect(0,
                                   0,
                                   view.width,
                                   view.height);
            view.graphics.endFill();
        }
    }
}

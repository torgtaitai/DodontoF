//--*-coding:utf-8-*--

package {
    
	import flash.display.Bitmap;
    import mx.core.FlexLoader;
    import flash.ui.ContextMenu;
    import flash.display.DisplayObject;
    import mx.effects.Rotate;
    import mx.core.UIComponent;
    import flash.display.Sprite;
    import flash.events.Event;
    import mx.events.FlexEvent;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.geom.Point;
    import flash.events.IOErrorEvent;
    import mx.controls.Alert;
    import mx.controls.Image;
    import mx.core.UIComponentCachePolicy;

    public class ImageSprite extends UIComponent {
        
        private var upperLayer:UIComponent = new UIComponent();
        private var innerLayer:UIComponent = new UIComponent();
        
        private var image:Image = new Image();
        
        private var widthSize:Number;
        private var heightSize:Number;
        static private var squareLength:int = Map.getSquareLength();
        
        private var isDrowRound:Boolean = true;
        private var isDrowBack:Boolean = true;
        private var imageUrl:String = "";
        private var preImageUrl:String = "";
        private var lineDiameter:int = 4;
        static private var backColorDefault:int = -1;
        private var backColor:int = backColorDefault;
        static private var roundColorDefault:int = 0xBBBB00;
        private var roundColor:int = roundColorDefault;
        static private var roundOutColorDefault:int = 0x000000;
        private var roundOutColor:int = roundOutColorDefault;
        
        private var base:UIComponent = new UIComponent();
        
        public function ImageSprite() {
            this.cachePolicy = UIComponentCachePolicy.ON;
            this.addChild( this.base );
            this.addChild( this.innerLayer );
            
            this.base.useHandCursor = true;
            
            this.base.addChild( image );
            this.base.addChild( upperLayer );
            
            this.image.smoothBitmapContent = true;
            
            //FlexEvent.UPDATE_COMPLETE
            image.addEventListener(Event.COMPLETE, completeHandler);
            
        }
        
        public function paintUpperLayer():void {
            var color:int = 0xBBBBBB;
            
            upperLayer.alpha = 0.001;
            upperLayer.graphics.clear();
            upperLayer.graphics.lineStyle(1, color);
            upperLayer.graphics.beginFill(color);
            upperLayer.graphics.drawRect(0, 0,
                                              (widthSize * squareLength),
                                              (heightSize * squareLength));
            upperLayer.graphics.endFill();
        }
        
        public function addChildToBase(obj:DisplayObject):void {
            this.base.addChild(obj);
        }
        
        public function setBackGroundColor(value:int = -1):void {
            if( value == -1 ) {
                value = backColorDefault;
            }
            this.backColor = value;
        }
        
        public function setLineColor(c:int = -1):void {
            if( c == -1 ) {
                c = roundOutColorDefault;
            }
            roundOutColor = c;
        }
        
        public function loadImage(url:String, size:int, diffPoint:Point = null):void {
            loadImageWidthHeight(url, size, size, diffPoint);
        }
        
        public function setMaintainAspectRatio(b:Boolean):void {
            image.maintainAspectRatio = b;
        }
        
        public function setIsDrawRound(b:Boolean):void {
            isDrowRound = b;
            if( ! isDrowRound ) {
                this.base.graphics.clear();
            }
        }
        
        public function setIsDrawBack(b:Boolean):void {
            isDrowBack = b;
            if( ! isDrowBack ) {
                this.base.graphics.clear();
            }
        }
        
        public function loadImageWidthHeightRotation(url:String,
                                                     widthSize_:Number, heightSize_:Number,
                                                     rotation:Number = 0):void {
            var diffPoint:Point = new Point(0, 0);
            diffPoint = getRotationDiffPoint(rotation, widthSize_, heightSize_);
            base.rotation = rotation;
            
            loadImageWidthHeight(url, widthSize_, heightSize_, diffPoint);
        }
        
        static public function getRotationDiffPoint(rotation:int,
                                                    widthSize_:Number,
                                                    heightSize_:Number):Point {
            var x:Number = widthSize_ * squareLength / 2.0 ;
            var y:Number = heightSize_ * squareLength / 2.0 ;
            
            var radian:Number = rotation * Math.PI / 180;
            var cos:Number = Math.cos(radian);
            var sin:Number = Math.sin(radian);
            
            var s:Number = x * cos - y * sin;
            var t:Number = x * sin + y * cos;
            
            var diffX:Number = x - s;
            var diffY:Number = y - t;

            return new Point(diffX, diffY);
        }
        
        public function loadImageWidthHeight(url:String,
                                             widthSize_:Number, heightSize_:Number,
                                             diffPoint:Point = null):void {
            Log.logging("imageLoader url begin", url);
            
            imageUrl = url;
            widthSize = widthSize_;
            heightSize = heightSize_;
            
            if( imageUrl == null || imageUrl == "" ) {
                this.base.visible = false;
                return;
            }
            
            this.base.visible = true;
            
            imageUrl = Config.getInstance().getUrlString(imageUrl);
            
            if( preImageUrl == imageUrl ) {
                zoomImage();
            } else {
                preImageUrl = imageUrl;
                image.source = imageUrl;
            }
            
            if( diffPoint != null ) {
                base.x = diffPoint.x;
                base.y = diffPoint.y;
                //isDrowBack = false;
            }
            
            initBaseColor();
            
            Log.logging("imageLoader url end", imageUrl);
        }
        
        public function setLineDiameter(l:int):void {
            lineDiameter = l;
        }
        
        public function initBaseColor():void {
            this.base.graphics.clear();
            
            this.base.graphics.lineStyle(lineDiameter, roundOutColor);
            if( isDrowRound ) {
                this.base.graphics.drawRect(0, 0,
                                            (widthSize * squareLength),
                                            (heightSize * squareLength));
            }
            
            this.base.graphics.lineStyle(lineDiameter, roundColor);
            
            if( isDrowBack ) {
                if( backColor != -1 ) {
                    this.base.graphics.beginFill(backColor);
                }
            }
            
            if( isDrowRound ) {
                var diff:Number = (lineDiameter / 2);
                this.base.graphics.drawRect(diff, diff, 
                                            ((widthSize * squareLength) - diff * 2),
                                            ((heightSize * squareLength) - diff* 2) );
            }
            
            if( isDrowBack ) {
                this.base.graphics.endFill();
            }
            
        }
        
        public function setRoundColor(value:int = -1):void {
            if( value == -1 ) {
                value = roundColorDefault;
            }
            this.roundColor = value;
        }
        
        
        public function setContextMenu(menu:ContextMenu):void {
            upperLayer.contextMenu = menu;
        }
        
        private var imageX:Number = 0;
        
        public function snapImagePosition():void {
            image.x = 0;
            image.y = 0;
            
            if( image.content == null ) {
                return;
            }
            
            if( ! image.maintainAspectRatio ) {
                return;
            }
            
            var rate:Number = (image.content.width / image.content.height);
            var rateView:Number = (image.width / image.height);
            
            if( rate == rateView ) {
                return;
            }
            
            if( rate > rateView ) {
                var imageHeight:Number = image.width / rate;
                image.y = ((image.height - imageHeight) / 2);
            }
            if( rate < rateView ) {
                var imageWidth:Number = image.height * rate;
                image.x = ((image.width - imageWidth) / 2);
            }
            
            imageX = image.x;
        }
        
        private function completeHandler(event:Event = null):void {
            zoomImage();
            Utils.smoothingImage(image);
        }
        
        private function zoomImage():void {
            paintUpperLayer();
            
            image.width = squareLength * widthSize;
            image.height = squareLength * heightSize;
            
            try {
                snapImagePosition();
            } catch (e:Error) {
            }
            
            if( resultFunction != null ) {
                resultFunction.call();
            }
            
            mirror();
        }
        

        private var mirrored:Boolean = false;
        
        public function setMirrored(b:Boolean):void {
            mirrored = b;
        }
        
        private function mirror():void {
            if( mirrored ) {
                image.scaleX = -1;
                image.x = image.width - imageX;
            } else {
                image.scaleX = 1;
                image.x = imageX;
            }
        }
        
        private var resultFunction:Function = null;
        public function setResultFunction(f:Function):void {
            resultFunction = f;
        }
        
        
        public function addChildInner(obj:DisplayObject):void {
            innerLayer.addChild(obj);
        }
        
        public function removeChildInner(obj:DisplayObject):void {
            innerLayer.removeChild(obj);
        }
        
    }
}

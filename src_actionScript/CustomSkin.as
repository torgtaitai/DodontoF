//--*-coding:utf-8-*--

package {
    
    import mx.skins.ProgrammaticSkin;
    import mx.controls.Image;
    import mx.core.UIComponent;
    
    public class CustomSkin extends UIComponent { //ProgrammaticSkin {
    
        public function CustomSkin() {
            super();
        }
        
        private var image:Image = null;
        
        private function setImageSize(currentWidth:Number, currentHeight:Number):void {
            var imageUrl:String = Config.getInstance().getUrlString("image/skin.jpg");
            
            if( image.source != imageUrl ) {
                image.source = imageUrl;
            }
            image.width = currentWidth;
            image.height = currentHeight;
        }
        
        protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
            if( image == null ) {
                image = new Image();
                image.maintainAspectRatio = false;
                this.addChild(image);
            }
            
            setImageSize(unscaledWidth, unscaledHeight);
            
            /*
            graphics.clear();
            graphics.beginFill(0x000000,1);
            graphics.drawEllipse(0,0,unscaledWidth,unscaledHeight);
            graphics.endFill();
            */
        }
    }
}

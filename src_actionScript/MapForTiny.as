//--*-coding:utf-8-*--

package {
    
    import mx.core.UIComponent;
    import mx.controls.Alert;
    
    public class MapForTiny extends Map {
        
        override public function init(parent:UIComponent):void {
            initContextMenu();
            
            imageLayer.setMaintainAspectRatio(false);
            baseLayer.addChild(imageLayer);
            baseLayer.addChild(characterLayer);
            parent.addChild(baseLayer);
        }
    }
}

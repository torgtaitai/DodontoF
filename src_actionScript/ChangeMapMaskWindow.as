//--*-coding:utf-8-*--

package {
    public class ChangeMapMaskWindow extends AddMapMaskWindow {
        import mx.managers.PopUpManager;
        
        private var mapMask:MapMask = null;
        
        public function init(mapMask_:MapMask):void {
            title = "マスク変更" 
            mapMask  = mapMask_;
            
            this.isCreate = false;
            this.isMany.height = 0;
            this.changeExecuteSpace.height = 25;
            this.height += 25;
            
            this.maskName.text = mapMask.getName();
            this.mapMaskColorPicker.selectedColor = mapMask.getColor();
            this.alphaSlider.value = mapMask.getAlpha();
            this.mapMaskHeigth.value = mapMask.getHeight();
            this.mapMaskWidth.value =  mapMask.getWidth();
            this.draggable = mapMask.getDraggable();
        }
        
        override protected function setMaxMaskName():void {
        }
        
        override protected function setDragEvent():void {
        }
        
        override public function changeMapMask():void {
            mapMask.setName(this.maskName.text);
            mapMask.setColor(this.mapMaskColorPicker.selectedColor);
            mapMask.setAlpha(this.alphaSlider.value);
            mapMask.setHeight(this.mapMaskHeigth.value);
            mapMask.setWidth(this.mapMaskWidth.value);
            mapMask.refresh();
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.getSender().changeCharacter( mapMask.getJsonData() );
            
            PopUpManager.removePopUp(this);
        }
    }
}


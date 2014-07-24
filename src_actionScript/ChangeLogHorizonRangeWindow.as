//--*-coding:utf-8-*--

package {
    
    import mx.containers.TitleWindow;
    import mx.managers.PopUpManager;
    import mx.collections.ArrayCollection;
    
    public class ChangeLogHorizonRangeWindow  extends AddLogHorizonRangeWindow {
        
        private var logHorizonRange:LogHorizonRange;
        
        public function setRange(range_:LogHorizonRange):void {
            logHorizonRange = range_;
        }
        
        override protected function setup():void {
            title = Language.s.addLogHorizonRangeMenu;
            executeButton.label = Language.s.changeButton;
            
            rangeName.text = logHorizonRange.getName();
            range.value = logHorizonRange.getRange();
            
            rangeColorPicker.selectedColor = logHorizonRange.getColor();
        }

        override public function execute():void {
            try{
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
                
                logHorizonRange.setName( rangeName.text );
                logHorizonRange.setRange( range.value );
                
                var color:int = parseInt("0x" + rangeColorPicker.selectedColor.toString(16));
                logHorizonRange.setColor( color );
                logHorizonRange.updateRefresh();
                
                guiInputSender.getSender().changeCharacter( logHorizonRange.getJsonData() );
                
                closeAction();
            } catch(error:Error) {
                this.status = error.message;
            }
        }

    }
}

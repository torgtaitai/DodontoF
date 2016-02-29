//--*-coding:utf-8-*--

package {
    import mx.managers.PopUpManager;
    
    public class ChangeStandingGraphicsWindow extends AddStandingGraphicsWindow {
        
        private var effectId:String = "";
        private var info:Object = new Object();
        
        public function init(info_:Object):void {
            info = info_;
            
            title = Language.s.changeStandingGraphics;
            executeButton.label = Language.s.changeButton;
            
            effectId = info.effectId;
            
            characterName.text = info.name;
            state.text = info.state;
            imageSelecter.selectImageUrl( info.source );
            imageSelecter.setMirrored(info.mirrored);
            
            var leftIndex:int = parseInt(info.leftIndex);
            leftIndexSlider.value = ((leftIndex == 0) ? 1 : leftIndex);
            
            Utils.selectComboBox(motionComboBox, info.motion);
        }
        
        protected override function isLoadInitImageList():Boolean {
            return false;
        }
        
        protected override function addIdToPrams(params:Object):void {
            params.effectId = effectId;
        }
        
        protected override function execute():void {
            var index:int = ChangeCutInMovieWindow.getEffectIndex(effectId)
            if( index == -1 ) {
                PopUpManager.removePopUp(this);
            }
            
            var params:Object = getEffectParams();
            StandingGraphicsManageWindow.standingGraphicInfos[index] = params;
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.changeEffect(params);
            
            PopUpManager.removePopUp(this);
        }
        
        
    }
}


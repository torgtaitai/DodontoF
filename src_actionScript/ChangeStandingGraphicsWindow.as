//--*-coding:utf-8-*--

package {
    import mx.managers.PopUpManager;
    
    public class ChangeStandingGraphicsWindow extends AddStandingGraphicsWindow {
        
        private var index:int = 0;
        private var effectId:String = "";
        
        public function init(info:Object, index_:int):void {
            title = Language.s.changeStandingGraphics;
            executeButton.label = Language.s.changeButton;
            
            index = index_;
            effectId = info.effectId;
            
            characterName.text = info.name;
            state.text = info.state;
            source.text = info.source;
            imageSelecter.setMirrored(info.mirrored);
            
            leftIndex.value = ((parseInt(info.leftIndex) == 0) ? 1 : parseInt(info.leftIndex));
        }
        
        protected override function isLoadInitImageList():Boolean {
            return false;
        }
        
        protected override function addIdToPrams(params:Object):void {
            params.effectId = effectId;
        }
        
        protected override function execute():void {
            var params:Object = getEffectParams();
            
            StandingGraphicsManageWindow.standingGraphicInfos[index] = params;
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.changeEffect(params);
            
            PopUpManager.removePopUp(this);
        }
        
    }
}


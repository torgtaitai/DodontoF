//--*-coding:utf-8-*--

package {
    import mx.managers.PopUpManager;
    
    public class ChangeCutInMovieWindow extends AddCutInMovieWindow {
        
        private var index:int = 0;
        private var effectId:String = "";
        private var cutInInfo:Object = new Object();
        
        public function init(cutInInfo_:Object, index_:int):void {
            cutInInfo = cutInInfo_;
            
            title = "カットイン変更";
            executeButton.label = "変更";
            
            index = index_;
            effectId = cutInInfo.effectId;
            
            message.text = cutInInfo.message;
            if( cutInInfo.displaySeconds != null ) {
                displaySeconds.value = cutInInfo.displaySeconds;
            }
            
            imageWidth.value = parseInt(cutInInfo.width);
            imageHeight.value = parseInt(cutInInfo.height);
            
            if(  cutInInfo.cutInTag != null ) {
                cutInTag.text = cutInInfo.cutInTag;
            }

            
            if( cutInInfo.volume == null ) {
                cutInInfo.volume = 0.1;
            }
            volume.value = parseFloat(cutInInfo.volume);
            
            if( cutInInfo.isTail == null ) {
                isTail.selected = true;
            } else {
                isTail.selected = cutInInfo.isTail;
            }
            
            Utils.selectComboBox(positionCoboBox, cutInInfo.position, 'data', 3);
        }
        
        override public function imageLoadComplete():void {
            imageSource.text = cutInInfo.source;
            soundSourceEdit.text = cutInInfo.soundSource;
            isSoundLoopCheck.selected = cutInInfo.isSoundLoop;
            imageSource.enabled = true;
            printPreview();
        }
        
        protected override function getCommandParamsExt(params:Object):void {
            params.effectId = effectId;
        }
        
        protected override function execute():void {
            var params:Object = getCommandParams();
            
            CutInBase.cutInInfos[index] = params;
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.changeEffect(params);
            
            PopUpManager.removePopUp(this);
        }
        
    }
}


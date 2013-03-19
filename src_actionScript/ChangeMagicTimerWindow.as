//--*-coding:utf-8-*--

package {
    
    public class ChangeMagicTimerWindow extends AddMagicTimerWindow {
        
        private var magicTimer:MagicTimer;
        
        public function setMagicTimer(magicTimer_:MagicTimer):void {
            magicTimer = magicTimer_;
        }
        
        override protected function setup():void {
            title = "魔法タイマー変更";
            executeButton.label = "変更";
            
            magicTimerName.text = magicTimer.getName();
            magicTimerTimeRange.value = magicTimer.getTimeRange();
            magicTimerCreateRound.value = magicTimer.getCreateRound();
            magicTimerInitiative.value = magicTimer.getInitiative();
            magicTimerInfo.text = magicTimer.getInfo();
        }
        
        protected override function execute(magicTimerNameText:String,
                                            magicTimerTimeRangeValue:int,
                                            magicTimerCreateRoundValue:int,
                                            magicTimerInitiativeValue:Number,
                                            magicTimerInfoText:String):void {
            
            var guiInputSender:GuiInputSender =
                DodontoF_Main.getInstance().getGuiInputSender();
            
            guiInputSender.changeMagicTimer(magicTimer,
                                            magicTimerNameText,
                                            magicTimerTimeRangeValue,
                                            magicTimerCreateRoundValue,
                                            magicTimerInitiativeValue,
                                            magicTimerInfoText);
        }
    }
}


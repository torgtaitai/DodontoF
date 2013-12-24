//--*-coding:utf-8-*--

package {
    
    import mx.containers.TitleWindow;
    import mx.managers.PopUpManager;
    import mx.collections.ArrayCollection;
    
    public class ChangeMagicRangeWindow  extends AddMagicRangeWindow {
        
        private static var magicRange:MagicRange;
        public static function setMagicRange(magicRange_:MagicRange):void {
            magicRange = magicRange_;
        }

        override protected function setup():void {
            title = Language.s.changeMagicRangeDD3rdWindowTitle;
            executeButton.label = Language.s.changeButton;
            
            magicRangeName.text = magicRange.getName();
            magicRangeFeets.value = magicRange.getFeets();
            
            selectMagicRangeType(magicRangeType, magicRange.getRangeType());
            
            magicRangeColorPicker.selectedColor = magicRange.getColor();
            magicRangeTimeRange.value = magicRange.getTimeRange();
            setMagicRangeRestTime();
            magicRangeInfo.text = magicRange.getInfo();
            isShowOnInitiativeWindow.selected = ( ! magicRange.isHideMode());
        }

        static public function selectMagicRangeType(magicRangeTypeLocal:Object, targetType:String):void {
            var list:ArrayCollection = magicRangeTypeLocal.dataProvider as  ArrayCollection;
            for (var i:int=0; i < list.length ;i++){
                Log.logging("list[i].data", list[i].data);
                Log.logging("targetType", targetType);
                if(list[i].data == targetType){
                    magicRangeTypeLocal.selectedIndex = i;
                    Log.logging("magicRangeTypeLocal.selectedIndex", magicRangeTypeLocal.selectedIndex);
                    return;
                }
            }
        }

        /**
         * 魔法範囲の残り時間表示用処理。
         */
        override public function setMagicRangeRestTime():void {
            var timeRange:int = magicRangeTimeRange.value;
            var restRound:int = MagicRange.getRestRound( timeRange,
                                                         magicRange.getCreateRound(),
                                                         magicRange.getInitiative() );
            magicRangeRestTime.width = 40;
            magicRangeRestTime.text = "" + restRound + "　／";
        }
        
        override public function execute():void {
            try{
                var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();

                guiInputSender.changeMagicRange(
                                                magicRange,
                                                magicRangeName.text,
                                                magicRangeFeets.value,
                                                magicRangeType.selectedItem.data,
                                                ("0x" + magicRangeColorPicker.selectedColor.toString(16)),
                                                magicRangeInfo.text,
                                                magicRangeTimeRange.value,
                                                isHide());

                PopUpManager.removePopUp(this);
            } catch(error:Error) {
                this.status = error.message;
            }
        }

    }
}

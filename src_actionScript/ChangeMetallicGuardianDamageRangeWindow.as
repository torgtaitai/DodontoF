//--*-coding:utf-8-*--

package {
    
    import mx.managers.PopUpManager;
    import mx.collections.ArrayCollection;
    
    public class ChangeMetallicGuardianDamageRangeWindow extends AddMetallicGuardianDamageRangeWindow {
        
        private var damageRange:MetallicGuardianDamageRange;
        
        public function setDamageRange(range_:MetallicGuardianDamageRange):void {
            damageRange = range_;
        }

        override protected function setup():void {
            title = "攻撃範囲変更";
            executeButton.label = "変更";
            
            rangeName.text = damageRange.getName();
            maxRange.value = damageRange.getMaxRange();
            minRange.value = damageRange.getMinRange();
            rangeColorPicker.selectedColor = damageRange.getColor();
        }
        
        
        override public function execute():void {
            try{
                damageRange.setName(rangeName.text);
                damageRange.setMaxRange(maxRange.value);
                damageRange.setMinRange(minRange.value);
                damageRange.setColor( rangeColorPicker.selectedColor );
                damageRange.updateRefresh();
                
                var characterJsonData:Object = damageRange.getJsonData();
                
                DodontoF_Main.getInstance().getGuiInputSender().getSender().changeCharacter(characterJsonData);
                
                PopUpManager.removePopUp(this);
            } catch(error:Error) {
                this.status = error.message;
            }
        }

    }
}
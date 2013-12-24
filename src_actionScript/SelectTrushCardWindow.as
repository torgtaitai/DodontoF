//--*-coding:utf-8-*--
package {

    import mx.core.UIComponent;
    
	public class SelectTrushCardWindow extends SelectCardWindow {
        
        override protected function init():void {
            title = Language.s.selectTrushCard;
            howToLabel.text = Language.s.selectTrushCardInfo;
        }
        
        override protected function getMountCardInfos():void {
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.getTrushMountCardInfos( cardMount.getMountName(),
                                              cardMount.getId(),
                                              printMountCardInfos );
        }
            
        override protected function drawTargetCard(card:Card, component:UIComponent, x:int, y:int):void {
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.getSender().drawTargetTrushCard( card.getJsonData(),
                                                            cardMount.getSelfOwnerId(),
                                                            cardMount.getSelfOwnerName(),
                                                            cardMount.getId(),
                                                            cardMount.getMountName(),
                                                            card.getId(),
                                                            x, y,
                                                            getRemoveComponentFunction(component));
        }
    }
}
//--*-coding:utf-8-*--
package {

    import mx.core.UIComponent;
    
	public class SelectTrushCardWindow extends SelectCardWindow {
        
        override protected function init():void {
            title = "捨て札カード選択";
            howToLabel.text = "捨て札のカードは以下の通り。抜き取りたいカードをドラッグしてカード置き場（緑のマットの上）にドロップしてください。";
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
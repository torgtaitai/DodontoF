//--*-coding:utf-8-*--

package {

    public class CardRankerCommand implements GameCommand {
        
        public function getGameType():String {
            return "CardRanker";
        }
        
        private var count:int = 0;
        private var cardRankerRandomChoice:RegExp = /CardRanker : .*ランダムモンスター選択.+：(.+)/m;
        
        public function executeCommand(params:Object):void {
            
            if( params.uniqueId != DodontoF_Main.getInstance().getStrictlyUniqueId() ) {
                Log.logging("自分自身の発言でないなら、カード追加処理は無し");
                return;
            }
            
            Log.logging("CutInCommandRollVisualDice.addCard params.chatMessage", params.chatMessage);
            
            var result:Object = cardRankerRandomChoice.exec(params.chatMessage);
            Log.logging("addCard match result", result);
            
            if( result == null ) {
                return;
            }
            
            Log.logging("カードランカーカードを自動作製！");
            
            var monsterName:String = result[1];
            Log.logging("monsterName", monsterName);
            
            //var color:uint = 0xFFFFFF;//Utils.getComplementaryColor( ChatWindow.getInstance().getChatFontColorValue() );
            //DodontoF_Main.getInstance().getGuiInputSender().addMapMarker(monsterName, color, true, 1, 1, 6, 0);
            //return;
            
            var imageName:String = 'cards/cardRanker/Ningyo.png';
            if( (count++ % 2) != 0 ) {
                imageName = 'cards/cardRanker/Red_4.png';
            }
            DodontoF_Main.getInstance().getGuiInputSender().getSender()
                .addCardRankerCard(imageName,
                                   imageName,
                                   100, 100);
        }
    }
}
        
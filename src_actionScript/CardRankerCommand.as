//--*-coding:utf-8-*--

package {
    
    import flash.events.Event;
    
    public class CardRankerCommand implements GameCommand {
        
        public function getGameType():String {
            return "CardRanker";
        }
        
        private var count:int = 0;
        private var cardRankerRandomChoice:RegExp = /CardRanker : .*ランダムモンスター選択.+→\s*(.+：(.+))/m;
        
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
            
            createCard(monsterName);
        }
        
        
        
        private function getCardList(monsterName:String):void {
            
            var result:Function =  function(event:Event):void {
                Log.logging('CardRankerCommand.getCardList result');
                
                var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
                cards = jsonData as Array;
                Log.logging('cards', cards);
                
                createCard(monsterName);
            }
            
            DodontoF_Main.getInstance().getGuiInputSender().getSender().getCardList('CardRanker', result);
        }
        
        private function createCard(monsterName:String):void {
            Log.logging('createCard monsterName', monsterName);
            
            if( cards == null || cards.length == 0 ) {
                getCardList(monsterName);
                return;
            }
            
            var card:Object = getCardInfo(monsterName);
            Log.logging("card", card);
            
            if( card == null ) {
                return;
            }
            
            DodontoF_Main.getInstance().getGuiInputSender().getSender()
                .addCardRankerCard(card['imageName'],
                                   card['imageNameBack'],
                                   100, 100);
        }
        
        private function getCardInfo(monsterName:String):Object {
            Log.logging("getCardInfo monsterName", monsterName);
            
            for each(var card:Object in cards) {
                var imageName:String = card['imageName'];
                var name:String = Card.getCardNameWhenImageData(imageName);
                
                if( name == monsterName ) {
                    return card;
                }
            }
            
            return null;
        }
        
        static private var cardBack:String = './cards/cardRanker/card_back.png';
        static private var cards:Array = [];
    }
}

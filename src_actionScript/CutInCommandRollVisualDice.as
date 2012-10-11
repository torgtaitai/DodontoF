//--*-coding:utf-8-*--

package {

    public class CutInCommandRollVisualDice extends CutInCommandBase {
        
        override protected function getCommand():String {
            return "rollVisualDice";
        }
        
        override protected function getPrintMessageText(params:Object):String {
            return params.chatMessage;
        }
        
        override protected function executeCommand(params:Object):void {
            Log.logging("CutInCommandRollVisualDice.executeCommand params", params);
            
            //addCard(params);
            rollDice(params);
        }
        
        
        private var cardRankerRandomChoice:RegExp = /CardRanker : .*ランダムモンスター選択.+：(.+)/m;
        
        private function addCard(params:Object):void {
            
            if( ChatWindow.getInstance().diceBotGameType.selectedItem.gameType != "CardRanker" ) {
                Log.logging("カードランカーではないので、この処理は無し");
                return;
            }
            
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
        private var count:int = 0;
        
        private function rollDice(params:Object):void {
            var randResults:Array = getRandResults(params);
            Log.logging("randResults", randResults);
            
            if( randResults == null ) {
                Log.logging("randResults is null.");
                return;
            }
            
            var resultText:String = getRollResultText(params);
            Log.logging("resultText", resultText);
            
            for(var i:int = 0 ; i < randResults.length ; i++) {
                
                var result:Array = randResults[i];
                if( (result == null) || (result.length != 2) ) {
                    continue;
                }
                
                var value:int = result[0];
                var diceType:int = result[1];
                
                if( DiceInfo.isValidDiceMax(diceType) ) {
                    if( diceType == 100 ) {
                        addDice(100, getD10Value(value / 10), resultText);
                        addDice( 10, getD10Value(value % 10), resultText);
                    } else {
                        addDice(diceType, value, resultText);
                    }
                }
            }
            
            getDiceBox().castDice();
        }
        
        private function getRandResults(params:Object):Array {
            if( ! isDiceBoxVisible() ) {
                Log.logging("diceBox invisible.");
                return null;
            }
            
            var randResults:Array = params.randResults;
            if( randResults == null ) {
                return null;
            }
            if( randResults.length == 0 ) {
                return null;
            }
            
            return randResults;
        }
        
        private function getD10Value(value:int):int {
            if( value == 0 ) {
                return 10;
            }
            return value;
        }
        
        private function getRollResultText(params:Object):String {
            var message:String = params.chatMessage;
            if( message == null ) {
                return "";
            }
            
            var tailReg:RegExp = /→\s*([^→]+)\Z/;
            var result:Object = tailReg.exec(message);
            
            if( result == null ) {
                return getSimpleMessage(message);
            }
            
            var resultText:String = result[1];
            Log.logging("resultText", resultText);
            
            return resultText;
        }
        
        private function getSimpleMessage(message:String):String {
            var index:int = message.indexOf(":");
            if( index == -1 ) {
                return message;
            }
            
            return message.slice(index + 1);
        }
        
        private function addDice(diceType:int, value:int, text:String):void {
            if( ! isDiceBoxVisible() ) {
                Log.logging("diceBox invisible.");
                return;
            }
            
            var params:Object = {
                "resultValue" : value,
                "resultText" : text
            }
            
            getDiceBox().createDice('d' + diceType, params);
        }
        
        private function getDiceBox():DiceBox {
            var diceBox:DiceBox = DodontoF_Main.getInstance().getDiceBox();
            return diceBox;
        }
        
        private function isDiceBoxVisible():Boolean {
            var diceBox:DiceBox = getDiceBox();
            if( diceBox == null ) {
                return false;
            }
            
            return diceBox.visible;
        }
        
    }
}

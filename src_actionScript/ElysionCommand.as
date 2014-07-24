//--*-coding:utf-8-*--

package {

    public class ElysionCommand implements GameCommand {
        
        public function getGameType():String {
            return "Elysion";
        }
        
        static private var preDate:Object = null;
        
        private var elysionDateReg:RegExp = /(\r|\n)Elysion : (.*DATE) → (\d+)/i;
        private var elysionDateCompleteReg:RegExp = /(\r|\n)Elysion : (.*DATE)\d\d/i;
        
        public function executeCommand(params:Object):void {
            try {
                dateCommandForElysionCatched(params);
            } catch (e:Error) {
                Log.loggingException("CutInCommandRollVisualDice.dateCommandForElysion", e);
            }
        }
        
        private function dateCommandForElysionCatched(params:Object):void {
            
            if( elysionDateCompleteReg.exec(params.chatMessage) != null ) {
                Log.logging("Date Command is already Finished.");
                //Dateコマンドが一度正式に完了したので、前回保持データを削除。
                preDate = null;
                return;
            }
            
            var result:Object = elysionDateReg.exec(params.chatMessage);
            Log.logging("elysionDateReg result", result);
            
            if( result == null ) {
                return;
            }
            
            var dateCommand:String = result[2];
            var number:String = result[3];
            
            if( preDate == null ) {
                preDate = {
                    name: getName(params),
                    number: number };
                Log.logging("preDate", preDate);
                return;
            }
            
            if( params.uniqueId != DodontoF_Main.getInstance().getStrictlyUniqueId() ) {
                Log.logging("is not own message");
                preDate = null;
                return;
            }
            
            var dice1:String = number;
            var pc1:String = getName(params);
            var dice2:String = preDate.number;
            var pc2:String = preDate.name;
            preDate = null;
            
            var pcList:String = pc1 + "," + pc2
            var diceString:String = "" + dice1 + dice2;
            
            if( dice1 > dice2 ) {
                pcList = pc2 + "," + pc1;
                diceString = "" + dice2 + dice1;
            }
            
            var command:String = dateCommand.toUpperCase() + diceString + "[" + pcList + "]";
            Log.logging("command", command);
            ChatWindow.getInstance().sendChatMessage(ChatWindow.getInstance().publicChatChannel, command);
        }
        
        private function getName(params:Object):String {
            return DodontoF_Main.getInstance().getDodontoF().getUserNameByUniqueId(params.uniqueId);
        }
        
    }
}

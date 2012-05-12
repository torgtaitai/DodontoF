//--*-coding:utf-8-*--

package {

    /*
      how to use:
      
      new CutInCommandGetDiceBotInfos().sendCommand();
      
      add to : ChatMessageTrader.as
         cutInList = [new CutInMovie(), new CutInCommandGetDiceBotInfos()]; << add here!
      
    */
    
    public class CutInCommandGetDiceBotInfos extends CutInCommandBase {
        
        override protected function getCommand():String {
            return "getDiceBotInfos";
        }
        
        override protected function executeCommand(params:Object):void {
            DodontoF_Main.getInstance().getGuiInputSender().getSender().getDiceBotInfos();
        }
    }
}

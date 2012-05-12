//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class ChangeBotTableWindow extends AddBotTableWindow {
        
        
        private var originalCommand:String;
        
        
        override protected function setup():void {
            title = "ダイスボット表変更";
            executeButton.label = "変更";
            
            setVisiblePrintSampleButton( false );
        }
        
        override public function initAfter():void {
            originalCommand = commandText.text;
        }
        
        override public function execute():void {
            changeBotTable();
        }
        
        private function changeBotTable():void {
            window.changeBotTable(commandText.text, diceText.text, titleText.text,
                                  getTableTextFromTextArea(),
                                  originalCommand,
                                  checkResult);
        }
        
    }
}


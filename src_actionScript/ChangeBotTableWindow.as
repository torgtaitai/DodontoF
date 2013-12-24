//--*-coding:utf-8-*--

package {
    import mx.controls.Alert;
    
    public class ChangeBotTableWindow extends AddBotTableWindow {
        
        
        private var originalCommand:String;
        
        
        override protected function setup():void {
            title = Language.s.changeBotTableWindowTitle;
            executeButton.label = Language.s.botTableChangeButton;
            
            setVisiblePrintSampleButton( false );
        }
        
        override public function initAfter():void {
            originalCommand = commandText.text;
        }
        
        /**
         * 表変更処理
         */
        override public function execute():void {
            window.changeBotTable(commandText.text, diceText.text, titleText.text,
                                  getTableTextFromTextArea(),
                                  originalCommand,
                                  checkResult);
        }
        
    }
}


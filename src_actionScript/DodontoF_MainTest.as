//--*-coding:utf-8-*--
package {
    
    
	public class DodontoF_MainTest extends DodontoF_Main {
        
		public function DodontoF_MainTest():void {
            tests = [["login", this.test_login],
                     ["addCharacter", this.test_addCharacter]]
            sender = new SharedDataSenderDummy();
            //Log.setTuning();
            super();
        }

        override protected function newSharedDataSender():SharedDataSender {
            return sender;
        }

        
        private var sender:SharedDataSenderDummy;
        private var assertCont:int = 0;
        private var falseCont:int = 0;
        private var tests:Array = new Array();
        private var currentTestTitle:String = "";
        
        private function setup():void {
            dodontoF.dodontoFSpacer.height = 0;
            dodontoF.diceWindowPanel.width = 10;
            dodontoF.initiativeListWindowBase.width = 50;
            dodontoF.chatDiceBox.percentHeight = 100;
            
            sender.init();
            
            this.getGuiInputSender().setSaveDataDirIndex("3");
            sender.removeRoom();
        }
        
        private function teardown():void {
        }
        
        private function nextTest():void {
            if( tests.length <= 0 ) {
                log("assertCont : " +  assertCont);
                log("falseCont : " +  falseCont);
                log("OK.");
                log("all Finished.");
                return;
            }
            
            var testInfo:Array = tests.shift();
            currentTestTitle = testInfo.shift();
            var test:Function = testInfo.shift();
            
            log("BEGIN : " + currentTestTitle);
            setup();
            try {
                test.call();
            } catch (e:Error) {
                logErrror(e);
            }
            teardown();
        }

        private function logErrror(e:Error):void {
            log("exception in " + currentTestTitle);
            log(e.message);
        }

        private function setResultCheckFunction(func:Function):void {
            try {
                sender.setResultFunction( func );
            } catch (e:Error) {
                logErrror(e);
                nextTest();
            }
        }
        
        private function log(message:String):void {
            dodontoF.chatWindow.addMessageToChatLog("test", message, "000000", 100);
        }
        private function logError(message:String):void {
            dodontoF.chatWindow.addMessageToChatLog("Asserto!!!", message, "ff0000", 100);
        }
        
        override public function login():void {
            log("TEST begin");
            nextTest();
        }
        
        public function test_login():void {
            setResultCheckFunction( this.result_Login );
            sender.refresh();
        }
        public function result_Login():void {
            assertEquals(1, sender.getRefreshedCount(), "isRefreshed");
            nextTest();
        }
        
        
        public function test_addCharacter():void {
            setResultCheckFunction( this.test_addCharacter_2 );
            sender.refresh();
        }
        
        public function test_addCharacter_2():void {
            assertEquals(0, sender.getExistPiecesCount(), "addCharacter check 2")
            
            setResultCheckFunction( null );
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.addCharacter("sampleCharacterName2", //name
                                        "./saveData/characterImages/chara08_a2_81.gif", //url
                                        1, //size
                                        99, //initiative
                                        "info message", //info
                                        0, //x
                                        0); //y
            
            setResultCheckFunction( this.test_addCharacter_3 );
            sender.refresh();
        }
        public function test_addCharacter_3():void {
            assertEquals(1, sender.getExistPiecesCount(), "addCharacter check 3.");
            nextTest();
        }
        
        private function assertEquals(good:Object, result:Object, message:String = ""):void {
            if( good == result ) {
                assertCont++;
                return;
            }
            
            falseCont++;
            
            var errorMessage:String = "assert in " + message + "\n";
            errorMessage += "        expect ＜" + good + "＞\n";
            errorMessage += "           but ＜" + result + "＞";
            throw new Error(errorMessage);
        }
        
    }
}


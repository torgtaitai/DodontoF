package {

    import flexunit.framework.TestCase;
    import flexunit.framework.TestSuite;

    public class TestRoundTimer extends TestCase {
        
        public function TestRoundTimer(method:String) {
            super(method);
        }
        
        private var sender:DummySharedDataSender = new DummySharedDataSender();
        private var roundTimer:RoundTimer;
        
        public override function setUp():void {
            roundTimer = new RoundTimer;
            sender.setRoundTimer(roundTimer);
            roundTimer.setSender(sender);
        }
        
        public override function tearDown():void {
        }
        
        private var uniqueId:int = 0;
        
        private function getCharacterFromInitiative(initiative:Number):Character {
            uniqueId++;
            
            var name:String = "name" + uniqueId;
            var imageUrl:String = "";
            var size:int = 1;
            var id:String = "id_" + uniqueId;
            
            return new Character(name, imageUrl, size, id, initiative);
        }

        public function checkRoundAndInitiative(title:String, round:Number, initiative:Number):void {
            assertEquals(title + "-round", round, roundTimer.getCurrentRound());
            assertEquals(title + "-initiative", initiative, roundTimer.getCurrentInitiative());
        }
        
        public function test_setTimer_usual():void {
            roundTimer.setCharacters([getCharacterFromInitiative(2),
                                      getCharacterFromInitiative(3),
                                      getCharacterFromInitiative(1)]);
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 3);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 1, 2);
            
            roundTimer.next();
            checkRoundAndInitiative("next2", 1, 1);
            
            roundTimer.next();
            checkRoundAndInitiative("next3", 2, 3);
            
            roundTimer.next();
            checkRoundAndInitiative("next4", 2, 2);
        }
        
        public function test_setTimer_skiped():void {
            roundTimer.setCharacters([getCharacterFromInitiative(3),
                                      getCharacterFromInitiative(0)]);
            
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 3);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 1, 0);
            
            roundTimer.next();
            checkRoundAndInitiative("next2", 2, 3);
            
            roundTimer.next();
            checkRoundAndInitiative("next3", 2, 0);
            
            roundTimer.next();
            checkRoundAndInitiative("next4", 3, 3);
        }
        
        public function test_setTimer_skipedAndDplicated():void {
            roundTimer.setCharacters([getCharacterFromInitiative(1),
                                      getCharacterFromInitiative(3),
                                      getCharacterFromInitiative(4),
                                      getCharacterFromInitiative(3)]);
            
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 4);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 1, 3);
                   
            roundTimer.next();
            checkRoundAndInitiative("next2", 1, 1);
                   
            roundTimer.next();
            checkRoundAndInitiative("next3", 2, 4);
        }
        
        public function test_setTimer_empty():void {
            roundTimer.setCharacters([]);
            
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 0);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 2, 0);
            
            roundTimer.next();
            checkRoundAndInitiative("next2", 3, 0);
        }
        
        public function test_setTimer_oneZero():void {
            roundTimer.setCharacters([getCharacterFromInitiative(0)]);
            
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 0);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 2, 0);
            
            roundTimer.next();
            checkRoundAndInitiative("next2", 3, 0);
        }
        
        public function test_setTimer_one():void {
            roundTimer.setCharacters([getCharacterFromInitiative(3)]);
            
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 3);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 2, 3);
            
            roundTimer.next();
            checkRoundAndInitiative("next2", 3, 3);
        }
        
        public function test_setTimer_floatNumber():void {
            roundTimer.setCharacters([getCharacterFromInitiative(3.2),
                                      getCharacterFromInitiative(4),
                                      getCharacterFromInitiative(3.2),
                                      getCharacterFromInitiative(1),
                                      getCharacterFromInitiative(3.1)]);
            
            roundTimer.reset();
            checkRoundAndInitiative("reset", 1, 4);
            
            roundTimer.next();
            checkRoundAndInitiative("next1", 1, 3.2);
            
            roundTimer.next();
            checkRoundAndInitiative("next2", 1, 3.1);
            
            roundTimer.next();
            checkRoundAndInitiative("next3", 1, 1);
            
            roundTimer.next();
            checkRoundAndInitiative("next3", 2, 4);
        }
            

        public function test_setTimer_previous():void {
            roundTimer.setCharacters([getCharacterFromInitiative(3.2),
                                      getCharacterFromInitiative(4),
                                      getCharacterFromInitiative(3.2),
                                      getCharacterFromInitiative(1),
                                      getCharacterFromInitiative(3.1)]);
            var title:String;
            title = "previous1st";
            roundTimer.reset();
            checkRoundAndInitiative(title + "-reset", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous1", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous2", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
            
            title = "previous2nd";
            roundTimer.next();
            roundTimer.next();
            checkRoundAndInitiative(title + "-next1", 1, 3.1);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous1", 1, 3.2);
            roundTimer.previous();
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous2", 1, 4);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous3", 1, 4);
            
            title = "previous3rd";
            roundTimer.next();
            roundTimer.next();
            roundTimer.next();
            roundTimer.next();
            checkRoundAndInitiative(title + "-next1", 2, 4);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous3", 1, 1);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous1", 1, 3.1);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous2", 1, 3.2);
            assertEquals(1, roundTimer.getHistoryCount());
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous4", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous5", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
        }
            
        public function test_setTimer_previous_reset():void {
            roundTimer.setCharacters([getCharacterFromInitiative(3.2),
                                      getCharacterFromInitiative(4),
                                      getCharacterFromInitiative(3.2),
                                      getCharacterFromInitiative(1),
                                      getCharacterFromInitiative(3.1)]);
            var title:String;
            title = "previous1st";
            roundTimer.reset();
            checkRoundAndInitiative(title + "-reset", 1, 4);
            roundTimer.next();
            roundTimer.next();
            checkRoundAndInitiative(title + "-next1", 1, 3.1);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous1", 1, 3.2);
            
            title = "previous2nd";
            roundTimer.next();
            checkRoundAndInitiative(title + "-next1", 1, 3.1);
            roundTimer.reset();
            checkRoundAndInitiative(title + "-reset", 1, 4);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous1", 1, 3.1);
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous1", 1, 3.2);
            assertEquals(1, roundTimer.getHistoryCount());
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous2", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
            roundTimer.previous();
            checkRoundAndInitiative(title + "-previous3", 1, 4);
            assertEquals(0, roundTimer.getHistoryCount());
        }
            
        public static function addSuite(testSuite:TestSuite):void {
            testSuite.addTest( new TestRoundTimer("test_setTimer_usual") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_skiped") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_skipedAndDplicated") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_empty") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_oneZero") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_one") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_floatNumber") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_previous") );
            testSuite.addTest( new TestRoundTimer("test_setTimer_previous_reset") );
        }
   }
}
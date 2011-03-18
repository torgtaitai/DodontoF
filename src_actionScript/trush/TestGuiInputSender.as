package {

    import flexunit.framework.TestCase;
    import flexunit.framework.TestSuite;
    import com.adobe.serialization.json.JSON;

    public class TestGuiInputSender extends TestCase {
    
        private var guiInputSender:GuiInputSender = new GuiInputSender();
        private var sender:DummySharedDataSender = new DummySharedDataSender();
        
        public function TestGuiInputSender(method:String) {
            super(method);
            
            guiInputSender.setSender(sender);
        }
        
        public override function setUp():void {
            sender.clear();
        }
        
        public override function tearDown():void {
        }
        
        
        public function testNormalInput():void {
            guiInputSender.changeMap("sample.jpeg", "20", "20");
            var resultString:String = sender.getSendParamString();
            var resultJsonData:Object = JSON.decode(resultString);
            
            var goodResult:String = 'mapData={"yMax":20,"imageSource":"sample.jpeg","mapType":"imageGraphic","xMax":20}&Command=changeMap&saveDataDirIndex=0';
            var goodResultJsonData:Object = JSON.decode(goodResult);
            assertEquals(goodResultJsonData, resultJsonData);
        }
        
        public static function addSuite(testSuite:TestSuite):void {
            //testSuite.addTest( new TestGuiInputSender("testNormalInput") );
        }
    
    }
}

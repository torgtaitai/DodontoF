package {

    import flexunit.framework.TestCase;
    import flexunit.framework.TestSuite;

    public class TestActionScript extends TestCase {
        
        public function TestActionScript(method:String) {
            super(method);
        }
        
        public override function setUp():void {
        }
        
        public override function tearDown():void {
        }
        
        
        
        public function testRegExp():void {
            var regExp:RegExp = new RegExp( "\\d" , "ig" );
            var values:Array= "corn2".match( regExp );
            
            assertEquals("1", values.length);
            assertEquals("2", values[0]);
        }
        
        public function testRegExp2():void {
            assertEquals("boo\nfoo", deleteEndReturn("boo\nfoo\n"));
            assertEquals("boo\r\nfoo", deleteEndReturn("boo\r\nfoo\r\n"));
        }
        public function deleteEndReturn(str:String):String {
            var pattern:RegExp = /\r?\n$/;
            return str.replace(pattern, "");
        }
        
        
        public static function addSuite(testSuite:TestSuite):void {
            testSuite.addTest( new TestActionScript("testRegExp") );
            testSuite.addTest( new TestActionScript("testRegExp2") );
        }
    }
}
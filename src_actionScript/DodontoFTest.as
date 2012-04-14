//--*-coding:utf-8-*--

package {
        
    import org.libspark.as3unit.*;
    import org.libspark.as3unit.assert.*;
    import flash.events.EventDispatcher;
    import flash.events.Event;
    
    public class DodontoFTest extends EventDispatcher {
        use namespace test;
        use namespace before;
        use namespace after;
        
        private var sender:SharedDataSenderDummy;
        
        before function setup():void {
            sender = new SharedDataSenderDummy();
            sender.init();
        }
        
        after function teardown():void {
        }
        
        test function tesMap.isOutOfMapPosition_4x3_2():void {
            var xMax:int = 4;
            var yMax:int = 3; 
            assertEquals(true,  Map.isOutOfMapPosition(1, 0, xMax, yMax, 2), "[1, 0], [4, 3], 2");
            assertEquals(true,  Map.isOutOfMapPosition(2, 0, xMax, yMax, 2), "[2, 0], [4, 3], 2");
            assertEquals(false, Map.isOutOfMapPosition(3, 0, xMax, yMax, 2), "[3, 0], [4, 3], 2");
            
            assertEquals(true,  Map.isOutOfMapPosition(1, 0, xMax, yMax, 2), "[1, 0], [4, 3], 2");
            assertEquals(true,  Map.isOutOfMapPosition(1, 1, xMax, yMax, 2), "[1, 1], [4, 3], 2");
            assertEquals(false, Map.isOutOfMapPosition(1, 2, xMax, yMax, 2), "[1, 2], [4, 3], 2");
            
        }
        test function tesMap.isOutOfMapPosition_5x5_3():void {
        }
        
        test function testLogin():void {
            sender.setSaveDataDirIndex(99);
            
            /*
            var job:Job = new Sequence(new DoFunction( function():void{sender.refresh()} ),
                                       new Wait(10000),
                                       new DoFunction( function():void{
                                               assertEquals(true, sender.isRefreshed(), "isRefreshed")}));
            */
            
            var beforeDate:Number = new Date().time;
            new Sleep(10000).start();;
            
            var afterDate:Number = new Date().time;
            assertEquals(4, (afterDate - beforeDate), "diffSeconds");
            
        }
    }
}

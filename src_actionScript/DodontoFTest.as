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

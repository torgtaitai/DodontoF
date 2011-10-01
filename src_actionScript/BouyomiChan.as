//--*-coding:utf-8-*--

package {
    
    import flash.net.Socket;
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.events.IOErrorEvent;
    
    public class BouyomiChan {
        
        static private var socket:Socket = null;
        private var buffer:String = "";
        
        public function sendText(text:String):void {
            buffer = text;
            
            Log.loggingTest("buffer", buffer);
            
            initSocket();
            send();
        }
        
        private function initSocket():void {
            Log.loggingTest("initSocket begin");
            
            if( socket != null ) {
                Log.loggingTest("initSocket already executed.");
                return;
            }
            
            socket = new Socket();
            //socket.addEventListener( Event.CONNECT, onConnect);
            socket.addEventListener( IOErrorEvent.IO_ERROR, onError);
            //socket.addEventListener( ProgressEvent.SOCKET_DATA, onSocketData);
            
            connectSocket();
            
            Log.loggingTest("initSocket end");
        }
        
        /*
　送信データフォーマット
　　[0-1]   16bit コマンド(0x0001)
　　[2-3]   16bit 速度(-1：デフォルト, 50〜300)
　　[4-5]   16bit 音程(-1：デフォルト, 50〜200)
　　[6-7]   16bit 音量(-1：デフォルト,  0〜100)
　　[8-9]   16bit 声質( 0：デフォルト,  1〜8:AquesTalk, 10001〜:SAPI5) 1:女性1、2:女性2、3:男性1、4:男性2、5:中性、6:ロボット、7:機械1、8:機械2、10001〜:SAPI5）
　　[10]     8bit 文字列の文字コード(0:UTF-8, 1:Unicode, 2:Shift-JIS)
　　[11-14] 32bit 文字列の長さ
　　[15-??] ??bit 文字列データ
         */
        //private function onConnect(event : Event) : void {
        private function send():void {
            Log.loggingTest("onConnect begin");
            socket.flush();
            
            
            socket.writeShort(0x0001); //[0-1]   16bit コマンド(0x0001)
            socket.flush();
            return;
            
            socket.writeShort(50); //[2-3]   16bit 速度(-1：デフォルト, 50〜300)
            socket.writeShort(50); //[4-5]   16bit 音程(-1：デフォルト, 50〜200)
            socket.writeShort(100); //[6-7]   16bit 音量(-1：デフォルト,  0〜100)
            socket.writeShort(8); //[8-9]   16bit 声質( 0：デフォルト,  1〜8:AquesTalk, 10001〜:SAPI5)
            socket.writeByte(0); //[10]     8bit 文字列の文字コード(0:UTF-8, 1:Unicode, 2:Shift-JIS)
            socket.writeInt(buffer.length); //[11-14] 32bit 文字列の長さ
            socket.writeUTFBytes(buffer);//[15-??] ??bit 文字列データ
            
            
            socket.flush();
            Log.loggingTest("onConnect end");
        }
        
        private function connectSocket():void {
            Log.loggingTest("connectSocket begin");
            var localhost:String = "127.0.0.1";
            var port:int = 50001;
            socket.connect(localhost, port);
            Log.loggingTest("connectSocket end");
        }
        
        private function onError(event:IOErrorEvent):void {
            Log.loggingTest( "IOErrorEvent", event.type );
            socket.close();
            socket = null;
        }
    }
}

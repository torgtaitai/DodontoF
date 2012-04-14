//--*-coding:utf-8-*--

package {
    
    import flash.net.Socket;
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.events.IOErrorEvent;
    
    public class BouyomiChan {
        
        static private var socket:Socket = null;
        private var buffer:String = "";
        
        public function sendTexts(texts:Array):void {
            if( ! isTalkMode() ) {
                return;
            }
            
            var text:String = "";
            
            for(var i:int = 0 ; i < texts.length ; i++) {
                text += Utils.htmlToText(texts[i]);
            }
            
            sendText(text);
        }
        
        private function isTalkMode():Boolean {
            var window:ChatWindow = ChatWindow.getInstance();
            if( window == null ) {
                return false;
            }
            
            return window.isTalkMode();
        }
        
        public function sendText(text:String):void {
            if( ! isTalkMode() ) {
                return;
            }
            
            buffer = text;
            Log.loggingTuning("sendText buffer", buffer);
            
            send();
        }
        
        private function initSocket():void {
            Log.loggingTest("initSocket begin");
            
            try {
                if( socket != null ) {
                    Log.loggingTest("initSocket already executed.");
                    return;
                }
                
                socket = new Socket();
                //socket.addEventListener( Event.CONNECT, onConnect);
                socket.addEventListener( IOErrorEvent.IO_ERROR, onError);
                //socket.addEventListener( ProgressEvent.SOCKET_DATA, onSocketData);
                
                connectSocket();
                
            } catch(e:Error) {
                Log.loggingTest("BouyomiChan.initSocket() Exception!!!!!!!!!!");
            }
            Log.loggingTest("initSocket end");
        }
        
        private function onError(event:IOErrorEvent):void {
            Log.loggingError( "IOErrorEvent", event.type );
            socket.close();
            socket = null;
        }
        
        private function connectSocket():void {
            Log.loggingTest("connectSocket begin");
            var localhost:String = "127.0.0.1";
            var port:int = 50001;
            socket.connect(localhost, port);
            Log.loggingTest("connectSocket end");
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
            initSocket();
            
            Log.loggingTest("onConnect begin");
            
            var bytes:ByteArray = new ByteArray();
            bytes.writeShort(0x0001); //[0-1]   16bit コマンド(0x0001)
            bytes.writeShort(-1);     //[2-3]   16bit 速度(-1：デフォルト, 50〜300)
            bytes.writeShort(-1);     //[4-5]   16bit 音程(-1：デフォルト, 50〜200)
            bytes.writeShort(-1);     //[6-7]   16bit 音量(-1：デフォルト,  0〜100)
            bytes.writeShort( 0);     //[8-9]   16bit 声質( 0：デフォルト,  1〜8:AquesTalk, 10001〜:SAPI5)
            bytes.writeByte(  0);     //[10]     8bit 文字列の文字コード(0:UTF-8, 1:Unicode, 2:Shift-JIS)
            bytes.writeInt(buffer.length); //[11-14] 32bit 文字列の長さ
            
            Log.loggingTest("bytes", bytes.toString());
            Log.loggingTest("bytes", bytes.toString());
            socket.writeBytes(bytes);
            
            var textBytes:ByteArray = new ByteArray();
            bytes.writeMultiByte(buffer, 'utf-8');//[15-??] ??bit 文字列データ
            
            socket.writeBytes(textBytes);
            
            /*
            bytes.writeShort(0x0001); //[0-1]   16bit コマンド(0x0001)
            bytes.writeShort(51); //[2-3]   16bit 速度(-1：デフォルト, 50〜300)
            bytes.writeShort(51); //[4-5]   16bit 音程(-1：デフォルト, 50〜200)
            bytes.writeShort(50); //[6-7]   16bit 音量(-1：デフォルト,  0〜100)
            bytes.writeShort(2); //[8-9]   16bit 声質( 0：デフォルト,  1〜8:AquesTalk, 10001〜:SAPI5)
            bytes.writeByte(0); //[10]     8bit 文字列の文字コード(0:UTF-8, 1:Unicode, 2:Shift-JIS)
            bytes.writeInt(buffer.length); //[11-14] 32bit 文字列の長さ
            bytes.writeUTFBytes(buffer);//[15-??] ??bit 文字列データ
            */
            //bytes.writeBytes(textBytes, 'utf-8');//[15-??] ??bit 文字列データ
            
            socket.flush();
            Log.loggingTest("socket.flush end");
            
            try {
                Log.loggingTest("socket.close() begin");
                socket.close();
                Log.loggingTest("socket.close() end");
            } catch(e:Error) {
                Log.loggingTest("BouyomiChan socket.close Exception!!!!!!!");
            }
            socket = null;
            Log.loggingTest("onConnect end");
        }
        
    }
}

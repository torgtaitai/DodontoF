//--*-coding:utf-8-*--

package {
    
    import flash.events.Event;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
    
    public class TextTalker {
        
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
        
        public function sendText(text:String):void {
            if( ! isTalkMode() ) {
                return;
            }
            
            buffer = getBuffer(text);
            Log.loggingTuning("sendText buffer", buffer);
            
            send();
        }
        
        static private var diceBotResultRegExp:RegExp = /\A(.+?)( +.*)?\r.+→ *(.+)\Z/m;
        
        static private function getBuffer(text:String):String {
            Log.logging("getBuffer Begin text", text);
                
            var index:int = text.indexOf( ChatMessageTrader.getChatMessageSeparator() );
            Log.logging("index", index);
            
            if( index != -1 ) {
                text = text.slice(index + 1);
            }
            
            Log.logging("text", text);
            
            var result:Object = diceBotResultRegExp.exec(text);
            
            if( result == null ) {
                Log.logging("diceRoll not matched");
                return text;
            }
            
            var roll:String = result[1];
            var message:String = getMessage(result[2]);
            var rollResult:String = result[3];
            Log.logging("roll", roll);
            Log.logging("rollResult", rollResult);
            
            text = roll + message + "、" + rollResult;
            Log.logging("getBuffer result", text);
            
            return text;
        }
        
        static private function getMessage(text:String):String {
            if( text == null ) {
                return "";
            }
            
            var result:Object = /「(.+)」/.exec(text);
            
            if( result == null ) {
                return text;
            }
            
            var message:String = "、" + result[1];
            Log.logging("getMessage result", message);
            
            return message;
        }
        
        private function isTalkMode():Boolean {
            var window:ChatWindow = ChatWindow.getInstance();
            if( window == null ) {
                return false;
            }
            
            return window.isTalkMode();
        }
        
        //private var sound:Sound;
        static private var sounds:Array = new Array();
        static private var soundChannel:SoundChannel;
        
        private function send():void {
            Log.logging("onConnect begin");
            
            var ttsUrl:String = getGoogleTextToSpeachUrl();
            Log.logging("ttsUrl", ttsUrl);
            
            var proxyUrl:String = "talkerProxy.php";
            var request:URLRequest = new URLRequest(proxyUrl);
            request.method = URLRequestMethod.POST;
            var variables:URLVariables = new URLVariables();
            variables.url = ttsUrl;
            request.data = variables;
            
            var sound:Sound = new Sound();
            sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
            sound.load(request);
            sounds.push(sound);
            
            Log.logging("onConnect end");
        }
        
        private function getGoogleTextToSpeachUrl():String {
            var readText:String = getReadText();
            var ttsUrl:String = "http://translate.google.com/translate_tts"
                + "?tl=ja"
                + "&q=" + encodeURI(readText);
            
            return ttsUrl;
        }
        
        private function getQuery():String {
            var readText:String = getReadText();
            return encodeURI(readText)
        }
        
        private function getReadText():String {
            var index:int = buffer.indexOf("：");
            if( index == -1 ) {
                index = 0;
            }
            
            var text:String = buffer.slice(index, index + 100);
            buffer = "";
            
            return text;
        }
        
        private function onSoundLoadComplete(event:Event):void {
            try {
                playSound();
            } catch(e:Error) {
                Log.loggingException("onSoundLoadComplete error", e);
            }
        }
        
        private function playSound():void {
            if( isPlaying() ) {
                Log.logging("playSound stop");
                return;
            }
            Log.logging("playSound start");
            
            //var sound:Sound = sounds[0];
            var sound:Sound = sounds.shift();
            if( sound == null ) {
                return;
            }
            
            soundChannel = sound.play();
            soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
        }
        
        static private function isPlaying():Boolean {
            return (soundChannel != null);
        }
        
        private function onSoundComplete(event:Event):void {
            //var sound:Sound = sounds.shift();
            //sound.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
            //soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
            soundChannel = null;
            
            Log.logging("Sound Completed end");
            
            playSound();
        }
    }
}

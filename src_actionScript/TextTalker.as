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
            
            var index:int = text.indexOf( ChatMessageTrader.getChatMessageSeparator() );
            Log.logging("index", index);
            if( index != -1 ) {
                text = text.slice(index + 1);
            }
            Log.logging("text", text);
            
            buffer = text;
            Log.loggingTuning("sendText buffer", buffer);
            
            send();
        }
        
        private function isTalkMode():Boolean {
            var window:ChatWindow = ChatWindow.getInstance();
            if( window == null ) {
                return false;
            }
            
            return window.isTalkMode();
        }
        
        private var isPlaying:Boolean;
        private var sound:Sound;
        private var soundChannel:SoundChannel;
        
        /*
        private function send():void {
            Log.loggingTuning("onConnect begin");
            
            var query:String = getQuery();
            Log.loggingTuning("query", query);
            
            //var url:String = "talkerProxy.rb";
            var url:String = "talkerProxy.php";
            url = Config.getInstance().getUrlString(url);
            
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.POST;
            var variables:URLVariables = new URLVariables();
            variables.data = query;
            request.data = variables;
            
            sound = new Sound();
            sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
            sound.load(request);
            Log.loggingTuning("request", request);
            
            isPlaying = true;
            
            Log.loggingTuning("onConnect end");
        }
        */
        
        
        private function send():void {
            Log.logging("onConnect begin");
            
            var ttsUrl:String = getGoogleTextToSpeachUrl();
            Log.logging("ttsUrl", ttsUrl);
            
            var proxyUrl:String = "talkerProxy.php";
            //var proxyUrl:String = "talkerProxy.rb";
            var request:URLRequest = new URLRequest(proxyUrl);
            request.method = URLRequestMethod.POST;
            var variables:URLVariables = new URLVariables();
            variables.url = ttsUrl;
            request.data = variables;
            
            sound = new Sound();
            sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
            sound.load(request);
            
            isPlaying = true;
            
            Log.logging("onConnect end");
        }
        
        private function getGoogleTextToSpeachUrl():String {
            //var url:String = "http://translate.google.com/translate_tts";
            //var url:String = "http://translate.google.com/translate_tts?q=%E3%81%8A%E3%81%AF%E3%82%88%E3%81%86"
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
                Log.loggingTuning("Sound loaded begin");
                soundChannel = sound.play();
                soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
                Log.loggingTuning("Sound loaded end");
            } catch(e:Error) {
                Log.loggingException("onSoundLoadComplete error", e);
            }
        }
        
        private function onSoundComplete(event:Event):void {
            Log.loggingTuning("Sound completed begin");
            soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
            sound.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
            isPlaying = false;
        
            soundChannel = null;
            sound = null;
            Log.loggingTuning("Sound Completed end");
        }
    }
}

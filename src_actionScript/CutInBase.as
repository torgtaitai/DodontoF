//--*-coding:utf-8-*--

package {

    import mx.controls.Alert;
    import com.adobe.serialization.json.JSON;
    import flash.events.Event;
    import flash.media.Sound;
    import flash.net.URLRequest;
    import mx.collections.ArrayCollection;
    import mx.controls.Image;
    import mx.controls.VideoDisplay;
    import mx.core.UIComponent;
    import mx.effects.Move;
    import mx.events.EffectEvent;
    
    public class CutInBase {
        
        [Bindable]
            static public var cutInInfos:ArrayCollection = new ArrayCollection();
        
        static public function setCutInInfos(cutInInfos_:ArrayCollection):void {
            cutInInfos = cutInInfos_;
        }
        
        protected var dodontoF:DodontoF;
        protected var bSoundOn:Boolean = true;
        protected var effectable:Boolean = true;

        public function CutInBase():void {
            dodontoF = DodontoF_Main.getInstance().getDodontoF();
        }
        
        protected function getMarkString():String {
            return "###CutInDummy###";
        }
        
        public function getCutInMessage(params:Object):String {
            var paramsString:String = JSON.encode(params);
            return (getMarkString() + paramsString);
        }
        
        public function isTargetMarker(chatMessage:String):Boolean {
            return ( chatMessage.indexOf( getMarkString() ) == 0 );
        }
        
        static private var chatLineSpliter:RegExp = /(\r|\n)/;
        
        public function matchCutIn(chatMessage:String):Object {
            Log.logging("chatMessage", chatMessage);
            
            var result:Object = {
                "resultData" : null
            };
            
            if( isTargetMarker(chatMessage) ) {
                result.resultData = new Object();
                result.resultData.chatMessage = chatMessage;
                result.resultData.cutInInfo = null;
                return result;
            }
            
            var lines:Array = chatMessage.split( chatLineSpliter );
            var line:String = lines[0];
            
            for(var i:int = 0 ; i < cutInInfos.length ; i++) {
                var cutInInfo:Object = cutInInfos[i];
                var tailMessage:String = cutInInfo.message;
                
                if( ! isTail(line, tailMessage) ) {
                    continue;
                }
                
                result.resultData = new Object();
                result.resultData.chatMessage = getCutInMessageWithChatMessage( cutInInfo, chatMessage, tailMessage );
                result.resultData.cutInInfo = cutInInfo;
                
                break;
            }
            
            return result;
        }
        
        private function getCutInMessageWithChatMessage(params:Object, message:String, tail:String):String {
            Log.logging("getCutInMessageWithChatMessage called.");
            var newParams:Object = Utils.clone(params);
            
            //チャット文字の末尾が 〜〜@(カットイン名)　のような名前なら、末尾を削除。
            message = Utils.cutChatTailWhenMarked(message, tail);
            
            newParams["chatMessage"] = message;
            
            return getCutInMessage(newParams);
        }
        
        private function isTail(line:String, tail:String):Boolean {
            var index:int = line.lastIndexOf(tail);
            if( index == -1 ) {
                return false;
            }
            
            if( index != (line.length - tail.length) ) {
                return false;
            }
            
            return true;
        }
        
        public function setEffectable(b:Boolean):void {
            effectable = b;
        }
        
        public function setSoundOn(b:Boolean):void {
            bSoundOn = b;
        }
        
        protected function getWindowTitle(params:Object):String {
            return "【" + params.message + "】";
        }
        
        protected function getPrintMessageText(params:Object):String {
            if( params.chatMessage != null ) {
                return params.chatMessage;
            }
            
            return "【" + params.message + "】";
            //return "DUMMY";
        }
        
        public function effect(effectString:String):String {
            var paramsString:String = effectString.substring( getMarkString().length );
            Log.logging("paramsString", paramsString);
            
            var message:String;
            var params:Object = {};
            try {
                params = JSON.decode(paramsString);
                Log.logging("params", params);
                message = getPrintMessageText(params);
            } catch (error:Error) {
                message = paramsString
            }
            
            if( ! effectable ) {
                Log.logging("effectable false");
                return message;
            }
            
            executeEffect(params);
            
            return message;
        }
        
        protected function executeEffect(params:Object):void {
        }
    }
}

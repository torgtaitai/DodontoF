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
        
        protected var effectable:Boolean = false;

        public function CutInBase():void {
        }
        
        protected function getMarkString():String {
            return "###CutInDummy###";
        }
        
        public function getCutInMessage(params:Object):String {
            if( params == null ) {
                params = new Object();
            }
            
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
            
            for(var i:int = 0 ; i < cutInInfos.length ; i++) {
                var cutInInfo:Object = cutInInfos[i];
                
                var isTailEnable:Boolean = (cutInInfo.isTail == null ? true : cutInInfo.isTail);
                if( ! isTailEnable ) {
                    continue;
                }
                
                var tailMessage:String = cutInInfo.message;
                
                if( ! isTail(lines, tailMessage) ) {
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
            
            var result:String = getCutInMessage(newParams);
            Log.logging("getCutInMessageWithChatMessage result", result);
            
            return result;
        }
        
        private function isTail(lines:Array, tail:String):Boolean {
            for each(var line:String in lines) {
                if( isTailLine(line, tail) ) {
                    return true;
                }
            }
            return false;
        }
        
        private function isTailLine(line:String, tail:String):Boolean {
            Log.logging("isTail line", line);
            Log.logging("isTail tail", tail);
            
            var index:int = line.lastIndexOf(tail);
            if( index == -1 ) {
                Log.logging("false1");
                return false;
            }
            
            if( index != (line.length - tail.length) ) {
                Log.logging("false2");
                return false;
            }
            
            Log.logging("true");
            return true;
        }
        
        public function setEffectable(b:Boolean):void {
            effectable = b;
        }
        
        protected function getWindowTitle(params:Object):String {
            return "【" + params.message + "】";
        }
        
        protected function getPrintMessageText(params:Object):String {
            Log.logging("getPrintMessageText params", params);
            
            if( params.chatMessage != null ) {
                return params.chatMessage;
            }
            
            return "【" + params.message + "】";
        }
        
        public function effect(effectString:String):String {
            Log.logging("effectString Begin");
            var paramsString:String = effectString.substring( getMarkString().length );
            Log.logging("paramsString", paramsString);
            
            var message:String;
            var params:Object = {};
            try {
                params = JSON.decode(paramsString);
                message = getPrintMessageText(params);
            } catch (error:Error) {
                message = "params error[" + paramsString + "]";
            }
            Log.logging("message", message);
            
            if( ! effectable ) {
                Log.logging("effectable false");
                return message;
            }
            
            if( ! Config.getInstance().getCutInDisplayState() ) {
                Log.logging("Config.getInstance().getCutInDisplayState() false");
                return message;
            }
            
            executeEffect(params);
            
            Log.logging("effectString End message", message);
            return message;
        }
        
        protected function executeEffect(params:Object):void {
        }
    }
}

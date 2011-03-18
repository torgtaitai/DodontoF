//--*-coding:utf-8-*--

package {
    
    import flash.display.Loader;
    import mx.controls.ComboBox;
    import mx.collections.ArrayCollection;
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.utils.URLUtil;
    import mx.core.UIComponent;
    import com.adobe.serialization.json.JSON;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.utils.ByteArray;
    import mx.containers.TabNavigator;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import mx.controls.Label;
    
    public class Utils {
        
        public static function timer(seconds:int, action:Function):void {
            var timer : Timer = new Timer(seconds * 1000, 1);
            timer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent) : void {
                    action();
                });
            timer.start();
        }
        
        public static function getJsonString(jsonData:Object):String {
            var jsonString:String = JSON.encode(jsonData);
            return jsonString;
        }
        
        public static function getEncodedJsonString(jsonData:Object):String {
            var jsonString:String = getJsonString(jsonData);
            Log.logging("jsonString", jsonString);
            
            var encodeJsonString:String = encodeURIComponent(jsonString);
            Log.logging("encodeJsonString", encodeJsonString);
            
            return encodeJsonString;
        }
        
        public static function getJsonDataFromString(jsonString:String):Object {
            var jsonData:Object = null;
            
            try {
                if( jsonString == null ) {
                    jsonData = new Object();
                } else {
                    jsonData = JSON.decode(jsonString);
                }
            } catch( e:Error ) {
                //Log.loggingException("SharedDataReceiver.getJsonDataFromString()", e);
            }
            
            return jsonData;
        }
        
        
        static private var patternFlv:RegExp = /.+\.flv$/i;
        
        static public function isFlvFile(source:String):Boolean {
            var index:int = source.search( patternFlv );
            return ( index != -1 );
        }
        
        static public function isMovie(source:String):Boolean {
            return (isFlvFile(source) || isYoutubeUrl(source));
        }
        
        static public function isYoutubeUrl(source:String):Boolean {
            return ( getYoutubeId(source) != "notFound" );
        }
        
        static private var youtubeIdRegExp:RegExp = /^http:\/\/www\.youtube\..+\/watch\?v=(.+)/;
        
        static public function getYoutubeId(source:String):String {
            var result:Object = youtubeIdRegExp.exec(source);
            
            if( result == null ) {
                return "notFound";
            }
            
            var youtubeId:String = result[1];
            
            return youtubeId;
        }
        
        static public function setSkin(component:UIComponent):void {
            //component.setStyle("borderSkin", CustomSkin);
        }
        
        static public function getInitiativeInt(initiative:Number):int {
            return Math.floor(initiative);
        }
        
        static public function getInitiativeModify(initiative:Number):int {
            var initiativeModify:int = Math.round(initiative * 100) %100;
            return initiativeModify;
        }
        
        static public function getInitiative(initiativeInt:int, initiativeModify:int):Number {
            var initiative:Number = initiativeInt + (initiativeModify / 100);
            
            return initiative;
        }
        
        static public function getToolTipMessage(piece:InitiativedPiece):String {
            var toolTipMessage:String = "";
            
            toolTipMessage += "[" + piece.getName() + "]";
            
            var addInfos:Array = piece.getAdditionalInfos();
            toolTipMessage += addInfos.join("\n");
            toolTipMessage += "\n";
            
            toolTipMessage += piece.getInfo();
            
            return toolTipMessage;
        }
        
        
        static public function selectComboBox(comboBox:ComboBox, key:String, field:String = "data"):void {
            comboBox.validateNow();
            
            var list:ArrayCollection = comboBox.dataProvider as  ArrayCollection;
            for (var i:int=0; i < list.length ;i++){
                if(list[i][field] == key){
                    comboBox.selectedIndex = i;
                    return;
                }
            }
            
            comboBox.selectedIndex = 0;
        }
        
        static public function getComboBoxText(combobox:ComboBox):String {
            var text:String = "";
            if( combobox.selectedItem != null ) {
                text = combobox.selectedItem.data;
            }
            return text;
        }
        
        public static function getLocalImageUrl(url:String):String {
            if( DodontoF_Main.getInstance().canUseExternalImage() ) {
                return url;
            }
            
            if( ! Utils.isOwnHostUrl(url) ) {
                url = Config.getInstance().getUrlString("./image/vote/cross.png");
            }
            return url;
        }
        
        public static function isOwnHostUrl(url:String):Boolean {
            var httpExp:RegExp = /^http/;
            var httpExpResult:Object = httpExp.exec(url);
            if( httpExpResult == null ) {
                return true;
            }
            
            var targetServerName:String = URLUtil.getServerName(url);
            
            var ownUrl:String = mx.core.Application.application.url;
            var ownServerName:String = URLUtil.getServerName(ownUrl);
            
            var result:Boolean = (ownServerName == targetServerName);
            
            return result;
        }
        
        public static function getOwnBaseUrl():String {
            var url:String = mx.core.Application.application.url;
            Log.logging("getOwnUrlBase url", url);
            
            var regExp:RegExp = /(.+\/)/i;
            var regResult:Object = regExp.exec(url);
            
            if( regResult == null ) {
                Log.loggingTuning("getOwnUrlBase CanNotGetOwnUrl");
                return "CanNotGetOwnBaseUrl";
            }
            
            var ownBaseUrl:String = regResult[1];
            Log.loggingTuning("getOwnUrlBase ownUrl", ownBaseUrl);
            return ownBaseUrl;
        }
        
        public static function getOwnUrl():String {
            var url:String = mx.core.Application.application.url;
            Log.logging("url", url);
            var regExp:RegExp = /(.+\.swf)/i;
            var regResult:Object = regExp.exec(url);
            
            if( regResult == null ) {
                Log.logging("getOwnUrl CanNotGetOwnUrl");
                return "CanNotGetOwnUrl";
            }
            
            var ownUrl:String = regResult[1];
            Log.loggingTuning("getOwnUrl ownUrl", ownUrl);
            return ownUrl;
        }
        
        public static function changeZenkakuToHankakuOnDiceBot(str:String):String{
            str = changeZenkakuToHankakuOnAlphabet(str);
            str = changeZenkakuToHankakuOnNumber(str);
            str = changeZenkakuToHankakuOnOperator(str);
            str = changeZenkakuToHankakuOnMark(str);
            return str;
        }
        
        // 文字列の中の全角記号を半角に直して戻す
        public static function changeZenkakuToHankakuOnMark(str:String):String {
            str = changeZenkakuToHankakuOnAll(str, "＠", null, "@");
            str = changeZenkakuToHankakuOnAll(str, "「", null, "[");
            str = changeZenkakuToHankakuOnAll(str, "」", null, "]");
            str = changeZenkakuToHankakuOnAll(str, "［", null, "[");
            str = changeZenkakuToHankakuOnAll(str, "］", null, "]");
            str = changeZenkakuToHankakuOnAll(str, "、", null, ",");
            str = changeZenkakuToHankakuOnAll(str, "，", null, ",");
            return str;
        }
        
        // 文字列の中の全角算術記号を半角に直して戻す
        public static function changeZenkakuToHankakuOnOperator(str:String):String {
            str = changeZenkakuToHankakuOnAll(str, "（", null, "(");
            str = changeZenkakuToHankakuOnAll(str, "）", null, ")");
            str = changeZenkakuToHankakuOnAll(str, "＊", null, "*");
            str = changeZenkakuToHankakuOnAll(str, "／", null, "/");
            str = changeZenkakuToHankakuOnAll(str, "＋", null, "+");
            str = changeZenkakuToHankakuOnAll(str, String.fromCharCode(65293),  null, "-");
            str = changeZenkakuToHankakuOnAll(str, "＝", null, "=");
            str = changeZenkakuToHankakuOnAll(str, "＞", null, ">");
            str = changeZenkakuToHankakuOnAll(str, "＜", null, "<");
            return str;
        }
        
        // 文字列の中の全角英字を半角英字に直して戻す
        public static function changeZenkakuToHankakuOnAlphabet(str:String):String {
            str = changeZenkakuToHankakuOnAll(str, "Ａ", "Ｚ", "A");
            str = changeZenkakuToHankakuOnAll(str, "ａ", "ｚ", "a");
            return str;
        }
        
        // 文字列の中の全角数字を半角数字に直して戻す
        public static function changeZenkakuToHankakuOnNumber(str:String):String {
            str = changeZenkakuToHankakuOnAll(str, "０", "９", "0");
            return str;
        }
        
        public static function getChangedCharacterZenkakuToHankaku(targetChar:String,
                                                                   startCode:Number, endCode:Number,
                                                                   changeStartCode:Number):String {
            var code:Number = targetChar.charCodeAt(0);
            
            if( (code >= startCode) && (code <= endCode) ) {
                var diff:Number = (code - startCode);
                code = changeStartCode + diff;
            }
            
            return String.fromCharCode(code);
        }
        
        public static function changeZenkakuToHankakuOnAll(str:String,
                                                           startString:String, endString:String,
                                                           changeStartString:String):String {
            var startCode:Number = startString.charCodeAt(0);
            if( endString == null ) {
                endString = startString;
            }
            var endCode:Number = endString.charCodeAt(0);
            var changeStartCode:Number = changeStartString.charCodeAt(0);
            
            var resultString:String = "";
            var isDiceStringEnd:Boolean = false;
            
            for(var i:int = 0 ; i < str.length ; i++){
                var targetChar:String = str.charAt(i);
                
                if( isDiceStringEnd ) {
                    resultString += targetChar;
                    continue;
                }
                
                if( (targetChar == " ") || (targetChar == "　") ) {
                    isDiceStringEnd = true;
                } else {
                    targetChar = getChangedCharacterZenkakuToHankaku(targetChar, startCode, endCode, changeStartCode);
                }
                
                resultString += targetChar;
            }
            
            return resultString;
        }
        
        
        private static function setValue(obj:Object, key:String, value:int, defaultValue:int):void {
            if( obj[key] == 0 ) {
                obj[key] = value;
            }
            if( obj[key] == 0 ) {
                obj[key] = defaultValue;
            }
            
        }
        
        public static function getSizeInfo(imageLoader:Loader, width:int, height:int, defaultValue:int = 10):Object {
            var result:Object = {
                "width"  : width,
                "height" : height,
                "type"   : "notFind"};
            
            setValue(result, "width", imageLoader.contentLoaderInfo.width, defaultValue);
            setValue(result, "height", imageLoader.contentLoaderInfo.height, defaultValue);
            
            return result;
        }
        
        static public function clone(source:Object):*{
            var myBA:ByteArray = new ByteArray();
            myBA.writeObject(source);
            myBA.position = 0;
            return(myBA.readObject());
        }
        
        static public function getColorString(colorValue:int):String {
            var color:String = colorValue.toString(16);
            while( color.length < 6 ) {
                color = "0" + color;
            }
            
            return color;
        }
        
        static public function cutChatTailWhenMarked(chatMessage:String, tail:String):String {
            var index1:int = chatMessage.lastIndexOf("@");
            var index2:int = chatMessage.lastIndexOf("＠");
            
            var index:int = (index1 > index2) ? index1 : index2;
            
            if(index == -1) {
                return chatMessage;
            }
            
            return chatMessage.slice(0, index);
        }
        
        static public function shiftTabFocus(tab:TabNavigator, event:KeyboardEvent, action:Function):Boolean {
            var nextTabIndex:int = -1;
            
            if( event.keyCode == Keyboard.RIGHT ) {
                nextTabIndex = tab.selectedIndex + 1;
            } else if( event.keyCode == Keyboard.LEFT ) {
                nextTabIndex = tab.selectedIndex - 1;
            } else {
                return false;
            }
            
            if( nextTabIndex < 0 ) {
                nextTabIndex = (tab.numChildren - 1);
            }
            if( nextTabIndex > (tab.numChildren - 1)) {
                nextTabIndex = 0;
            }
            Log.logging("nextTabIndex", "" + nextTabIndex);
            
            tab.selectedIndex = nextTabIndex;
            
            action(nextTabIndex);
            
            return true;
        }
        
        static public function htmlToText(html:String):String {
            var result:String;
            
            var label:Label = new Label();
            label.visible = false;
            
            DodontoF_Main.getInstance().addChild(label);
            
            label.htmlText = html;
            label.validateNow();
            
            result = label.text;
            
            DodontoF_Main.getInstance().removeChild(label);
            label = null;
            
            return result;
        }
        
    }
}


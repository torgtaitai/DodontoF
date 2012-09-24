//--*-coding:utf-8-*--

package {
    
    import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
    import com.adobe.serialization.json.JSON;
    import flash.display.Loader;
    import flash.events.KeyboardEvent;
    import flash.events.TimerEvent;
    import flash.media.SoundTransform;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    import mx.collections.ArrayCollection;
    import mx.containers.TabNavigator;
    import mx.controls.Alert;
    import mx.controls.ComboBox;
    import mx.controls.Image;
    import mx.controls.Label;
    import mx.controls.ToolTip;
    import mx.core.UIComponent;
    import mx.styles.CSSStyleDeclaration;
    import mx.styles.StyleManager;
    import mx.utils.URLUtil;
    import mx.controls.SWFLoader;
    import flash.system.Capabilities;
    import mx.utils.StringUtil;
    import mx.effects.Glow;
    import mx.events.CloseEvent;
    
    
    public class Utils {
        
        public static function timer(seconds:Number, action:Function):void {
            var timer:Timer = new Timer(seconds * 1000, 1);
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
        
        
        static public function isMovie(source:String):Boolean {
            return (isFlvFile(source) || isYoutubeUrl(source));
        }
        
        
        static private var patternFlv:RegExp = /.+\.flv$/i;
        
        static public function isFlvFile(source:String):Boolean {
            var index:int = source.search( patternFlv );
            return ( index != -1 );
        }
        
        static private var youtubeIdRegExp:RegExp = /^http:\/\/www\.youtube\..+\/watch\?v=(.+)/;
        
        static public function isYoutubeUrl(source:String):Boolean {
            return ( getYoutubeId(source) != "notFound" );
        }
        
        static public function getYoutubeId(source:String):String {
            var result:Object = youtubeIdRegExp.exec(source);
            
            if( result == null ) {
                return "notFound";
            }
            
            var youtubeId:String = result[1];
            
            return youtubeId;
        }
        
        
        static private var patternSwf:RegExp = /.+\.swf$/i;
        
        static public function isSwfFile(source:String):Boolean {
            var index:int = source.search( patternSwf );
            return ( index != -1 );
        }
        
        
        static public function setSkin(component:UIComponent):void {
            if( CustomSkin.isSkinDefined() ) {
                component.setStyle("borderSkin", CustomSkin);
            }
        }
        
        
        /*　イニシアティブの算出方法について
          イニシアティブ値は 1.03 なら イニシアティブ値１、修正値３のように
          小数点2桁を修正値として扱う。
          ただし、1.99のように修正値が90以上の場合は、修正値から100を引いて修正値 −1 のように負に数える。
          （90以上の修正値はゲームで使わないと仮定）
          このため、 1.99 は イニシアティブ値２、修正値 −1　となる。
        */
        static private var initiativeModifyLimit:int = 100;
        static private var initiativeModifyMax:int = 90;
        
        static public function getInitiativeInt(initiative:Number):int {
            Log.logging("Utils.getInitiativeInt initiative", initiative);
            
            var initiativeInt:int = Math.floor(initiative);
            Log.logging("initiativeInt", initiativeInt);
            
            var modify:int = getInitiativeModify(initiative);
            Log.logging("modify", modify);
            
            if( modify < 0 ) {
                initiativeInt += 1;
            }
            
            Log.logging("result initiativeInt", initiativeInt);
            return initiativeInt;
        }
        
        static public function getInitiativeModify(initiative:Number):int {
            
            var modify:int = Math.round(initiative * initiativeModifyLimit) % initiativeModifyLimit;
            
            if( modify > initiativeModifyMax ) {
                if( modify < initiativeModifyLimit ) {
                    modify -= initiativeModifyLimit;
                } else {
                    modify = initiativeModifyMax;
                }
            }
            
            return modify;
        }
        
        static public function getInitiative(initiativeInt:int, initiativeModify:int):Number {
            Log.logging("Utils.getInitiative");
            Log.logging("initiativeInt", initiativeInt);
            Log.logging("initiativeModify", initiativeModify);
            
            var initiative:Number = initiativeInt + (initiativeModify / 100);
            Log.logging("initiative", initiative);
            
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
        
        
        static public function selectComboBox(comboBox:ComboBox, key:String, field:String = "data", defaultIndex:int = 0):int {
            comboBox.validateNow();
            
            var list:ArrayCollection = comboBox.dataProvider as  ArrayCollection;
            if( list.length == 0 ) {
                return -1;
            }
            
            for(var i:int = 0 ; i < list.length ; i++) {
                if(list[i][field] == key){
                    comboBox.selectedIndex = i;
                    return i;
                }
            }
            
            comboBox.selectedIndex = defaultIndex;
            return -1;
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
        
        // http://www.dodontof.com/DodontoF/DodontoF.swf?loginRoom=1
        public static function getOwnRawUrl():String {
            //return FlexGlobals.topLevelApplication.application.url;
            return mx.core.Application.application.url;
        }
        
        // url : http://www.dodontof.com/DodontoF/DodontoF.swf
        // hostUrl : www.dodontof.com
        public static function isOwnHostUrl(url:String):Boolean {
            var httpExp:RegExp = /^http/;
            var httpExpResult:Object = httpExp.exec(url);
            if( httpExpResult == null ) {
                return true;
            }
            
            var targetServerName:String = URLUtil.getServerName(url);
            
            var ownUrl:String = getOwnRawUrl();
            var ownServerName:String = URLUtil.getServerName(ownUrl);
            
            var result:Boolean = (ownServerName == targetServerName);
            
            return result;
        }
        
        // http://www.dodontof.com/DodontoF/
        public static function getOwnBaseUrl():String {
            var url:String = getOwnRawUrl();
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
        
        // http://www.dodontof.com/DodontoF/DodontoF.swf
        public static function getOwnUrl():String {
            var url:String = getOwnRawUrl();
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
                
                //if( (targetChar == " ") || (targetChar == "　") ) {
                //    isDiceStringEnd = true;
                //} else {
                //    targetChar = getChangedCharacterZenkakuToHankaku(targetChar, startCode, endCode, changeStartCode);
                //}
                targetChar = getChangedCharacterZenkakuToHankaku(targetChar, startCode, endCode, changeStartCode);
                
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
            var marks:Array = ["@", "＠"];
            
            var index:int = -1;
            for each(var mark:String in marks) {
                index = chatMessage.lastIndexOf(mark + tail);
                if( index != -1 ) {
                    break;
                }
            }
            
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
        
        static public function setToolTipStyle(fontSize:int, maxWidth:int):void {
            var toolTipStyle:CSSStyleDeclaration = StyleManager.getStyleDeclaration("ToolTip");
            //var toolTipStyle:CSSStyleDeclaration = StyleManager.getStyleManager(null).getStyleDeclaration("ToolTip");
            
            toolTipStyle.setStyle("fontSize", fontSize);
            /*
            toolTipStyle.setStyle("fontStyle", "regular");
            toolTipStyle.setStyle("fontFamily", "Arial");
            toolTipStyle.setStyle("color", "#FFFFFF");
            toolTipStyle.setStyle("backgroundColor", "#33CC99");
            */
            
            ToolTip.maxWidth = maxWidth;
        }
        
        static public function getBitMap(component:UIComponent, width:Number, height:Number):Bitmap {
            var bitmapData:BitmapData = new BitmapData(width, height);
            bitmapData.draw(component);
            
            var bitmap:Bitmap = new Bitmap();
            bitmap.bitmapData = bitmapData;
            
            return bitmap;
        }

        static public function isSameArray(array1:Array, array2:Array):Boolean {
            if( array1.length != array2.length ) {
                return false;
            }
            
            for(var i:int = 0 ; i < array1.length ; i++) {
                if( array1[i] != array2[i] ) {
                    return false;
                }
            }
            
            return true;
        }
        
        static public function setImageVolume(obj:Object, volume:Number):void {
            Log.logging("setImageVolume volume", volume);
            
            var swf:SWFLoader = obj as SWFLoader;
            if( swf == null ) {
                Log.logging("setImageVolume obj is NOT SWFLoader");
                return;
            }
            
            var soundTransform:SoundTransform = new SoundTransform(volume);
            swf.soundTransform = soundTransform;
        }
        
        
        static public function getEnterText():String {
            if( isWindowsOs() ) {
                Log.logging("isWindowsOs")
                return "\r\n";
            }
            Log.logging("linux")
            return "\n";
        }
        
        
        static private function isWindowsOs():Boolean {
            var fullVersionString:String = flash.system.Capabilities.version;
            Log.loggingTuning(fullVersionString, "fullVersionString"); //output MAC 9,0,115,0
            
            // WIN 9,0,0,0  // Flash Player 9 for Windows
            // MAC 7,0,25,0   // Flash Player 7 for Macintosh
            // LNX 9,0,115,0  // Flash Player 9 for Linux
            // AND 10,2,150,0 // Flash Player 10 for Android
            
            return ( fullVersionString.indexOf("WIN ") == 0 );
        }
        
        
        static private function getFlashVersion():int {
            var fullVersionString:String = flash.system.Capabilities.version;
            Log.loggingTuning(fullVersionString, "fullVersionString"); //output MAC 9,0,115,0
            
            var versionNoString:String = fullVersionString.split(" ")[1].split(",")[0];
            Log.loggingTuning(versionNoString, "versionNoString"); //9
            
            var version:int = parseInt(versionNoString);
            Log.loggingTuning("version", version); //9
            
            return version;
        }
        
        static public function isFileRefecenseLoadMethodSupportVersion():Boolean {
            var version:int = getFlashVersion();
            
            if ( version < 10) {
                return false;
            }
            return true;
        }
        
        static public function getTimeTextForChat(time:Number):String {
            var date:Date = new Date();
            //time = time - date.getTimezoneOffset();
            date.setTime(time * 1000);
            
            var dateString:String =
                StringUtil.substitute("{0}:{1}：", 
                                      formatZero(date.hours, 2),
                                      formatZero(date.minutes, 2));
            /*
            var dateString:String = 
                StringUtil.substitute("{0}/{1}/{2} {3}:{4}:{5}.{6}", 
                                      formatZero(date.fullYear, 2),
                                      formatZero(date.month, 2),
                                      formatZero(date.date, 2),
                                      formatZero(date.hours, 2),
                                      formatZero(date.minutes, 2),
                                      formatZero(date.seconds, 2),
                                      formatZero(date.milliseconds, 2));
            */
            
            return dateString;
        }
        
        static private function formatZero(number:Number, count:uint):String {
            var string:String = String(number);
            while (string.length < count) {
                string = "0" + string;
            }
            return string;
        }
        
        static public function isEqual(obj1:Object, obj2:Object):Boolean {
            return (mx.utils.ObjectUtil.compare(obj1, obj2) == 0);
        }
        
        static public function glowEffect(target:Object, glow:Glow = null):void {
            glowEffects( [target], glow);
        }
        
        static public function glowEffects(targets:Array, glow:Glow = null):void {
            
            if( glow == null ) {
                glow = DodontoF_Main.getInstance().getDodontoF().getGlowEffect();
            }
            
            glow.end();
            glow.play( targets );
        }
        
        
        static public function getTimeText(seconds:Number):String {
            if( seconds < 60 ) {
                return "" + seconds.toFixed(1) + "秒";
            }
            
            var minute:Number = (seconds / 60)
            if( minute < 60 ) {
                return "" + minute.toFixed(1) + "分";
            }
            
            var hours:Number = (seconds / 60 / 60)
            return "" + hours.toFixed(1) + "時間";
        }
        
        
        static public function getComplementarColor(baseColor:uint):uint {
            var red:int   = baseColor / 0x10000;
            var green:int = (baseColor / 0x100) & 0xFF;
            var blue:int  = baseColor & 0xFF;
            
            var max:int = Math.max(red, green, blue);
            var min:int = Math.min(red, green, blue);
            
            var total:int = max + min;
            
            var newRed:int   = total - red;
            var newGreen:int = total - green;
            var newBlue:int  = total - blue;
            
            var color:uint = newRed * 0x10000 + newGreen * 0x100 + newBlue;
            
            return color;
        }
        
        static public function askByAlert(title:String, question:String, action:Function):void {
            var result:Alert = Alert.show(question, title, 
                                          Alert.OK | Alert.CANCEL, null, 
                                          function(e:CloseEvent) : void {
                                              if (e.detail == Alert.OK) {
                                                  action();
                                              }
                                          }
                                          );
        }
        
        static public function getComplementaryColor(color:uint):uint {
            return 0xFFFFFF - color;
        }
    }
}


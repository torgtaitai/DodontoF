//--*-coding:utf-8-*--

package {
    
	import flash.display.Bitmap;
	import flash.display.BitmapData;
    import com.adobe.serialization.json.JSON;
    import flash.display.IBitmapDrawable;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.TimerEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.media.SoundTransform;
    import flash.net.FileReference;
    import flash.system.Capabilities;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    import mx.collections.ArrayCollection;
    import mx.containers.TabNavigator;
    import mx.controls.Alert;
    import mx.controls.ComboBox;
    import mx.controls.Image;
    import mx.controls.Label;
    import mx.controls.SWFLoader;
    import mx.controls.ToolTip;
    import mx.core.UIComponent;
    import mx.effects.Glow;
    import mx.events.CloseEvent;
    import mx.graphics.ImageSnapshot;
    import mx.graphics.codec.JPEGEncoder;
    import mx.styles.CSSStyleDeclaration;
    import mx.styles.StyleManager;
    import mx.utils.StringUtil;
    import mx.utils.URLUtil;
    import org.msgpack.MessagePack;
    
    
    public class Utils {
        
        [Embed(source="./image/unknownTarget.png")]
        [Bindable]
        public static var invalidImage:Class;
        
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
        
        public static function getMessagePack(data:Object):ByteArray {
            //var bytes:ByteArray = MessagePack.encode(data);
            var bytes:ByteArray = MessagePack.encoder.write(data);
            return bytes;
        }
        
        public static function getMessagePackDataFromBytes(bytes:ByteArray):Object {
            if( bytes == null ) {
                return new Object();
            }
            
            var data:Object = null;
            
            try {
                //data = MessagePack.decode(bytes);
                data = MessagePack.decoder.read(bytes);
            } catch( e:Error ) {
                //Log.loggingException("SharedDataReceiver.getMessagePackDataFromBytes()", e);
            }
            
            return data;
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
                //component.setStyle("borderSkin", CustomSkin);
                component.setStyle("backgroundImage", Config.getInstance().getSkinImageUrl());
                component.setStyle("backgroundSize","100%");
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
        
        static public function selectSuggestComboBox(comboBox:SuggestComboBox, key:String,
                                                        field:String = "data", defaultString:String = null):int {
            var index:int = selectComboBox(comboBox, key, field);
            if( index >= 0 ) {
                return index;
            }
            
            comboBox.setText( defaultString );
            return -1;
        }
        
        static public function selectComboBox(comboBox:ComboBox, key:String, field:String = "data", defaultIndex:int = 0,
                                              isMatch:Function = null):int {
            comboBox.validateNow();
            
            var list:ArrayCollection = comboBox.dataProvider as  ArrayCollection;
            if( list.length == 0 ) {
                return -1;
            }
            
            if( isMatch == null ) {
                isMatch = function(text:String):Boolean {
                    return (text == key);
                }
            }
            
            for(var i:int = 0 ; i < list.length ; i++) {
                var text:String = list[i][field];
                if( isMatch(text) ) {
                    comboBox.selectedIndex = i;
                    return i;
                }
            }
            
            comboBox.selectedIndex = defaultIndex;
            return -1;
        }
        
        static public function selectGameTypeComboBox(comboBox:ComboBox, key:String):int {
            
            var isMatch:Function = function(gameType:String):Boolean {
                
                if( gameType == key ) {
                    return true;
                }
                
                if( gameType.indexOf(key + ":") != -1 ) {
                    return true;
                }
                
                if( key == null ) {
                    return false;
                }

                if(key.indexOf(gameType + ":") != -1) {
                    return true;
                }
                
                return false;
            }
            
            return selectComboBox(comboBox, key, "gameType", 0, isMatch);
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
        
        public static function changeZenkakuToHankaku(str:String):String{
            return new ZenkakuToHankaku().changeForDiceBot(str);
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
        
        private static function setValue(obj:Object, key:String, value:int, defaultValue:int):void {
            if( obj[key] == 0 ) {
                obj[key] = value;
            }
            if( obj[key] == 0 ) {
                obj[key] = defaultValue;
            }
            
        }
        
        
        static public function newSameClassInstance(obj:Object):Object {
            var className:String = flash.utils.getQualifiedClassName(obj);
            var klass:Class = Class( flash.utils.getDefinitionByName(className) );
            return new klass();
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
        
        static public function setToolTipStyle(fontSize:int, maxWidth:int = -1):void {
            var toolTipStyle:CSSStyleDeclaration = StyleManager.getStyleDeclaration("ToolTip");
            //var toolTipStyle:CSSStyleDeclaration = StyleManager.getStyleManager(null).getStyleDeclaration("ToolTip");
            
            toolTipStyle.setStyle("fontSize", fontSize);
            /*
            toolTipStyle.setStyle("fontStyle", "regular");
            toolTipStyle.setStyle("fontFamily", "Arial");
            toolTipStyle.setStyle("color", "#FFFFFF");
            toolTipStyle.setStyle("backgroundColor", "#33CC99");
            */
            
            if( maxWidth != -1 ) {
                ToolTip.maxWidth = maxWidth;
            }
        }
        
        static public function getBitMap(component:UIComponent, width:Number, height:Number):Bitmap {
            var bitmap:Bitmap = new Bitmap();
            bitmap.bitmapData = getBitMapData(component, width, height);
            return bitmap;
        }
        
        static private function getBitMapData(component:UIComponent, width:Number, height:Number):BitmapData {
            var bitmapData:BitmapData = new BitmapData(width, height);
            
            if( component == null ) {
                return bitmapData;
            }
            
            try { 
                bitmapData.draw(component);
            } catch (e:Error) {
                bitmapData.draw( new invalidImage().bitmapData );
            }
            
            return bitmapData;
        }
        
        static public function getHashDiff(array1:Array, array2:Array):String {
            var result:String = "";
            if( array1.length != array2.length ) {
                result += StringUtil.substitute("diff length before:{0}, after:{1}",
                                             array1.length, array2.length) + "\n";
            }
            
            for(var i:int = 0 ; i < array1.length ; i++) {
                if( array1[i] != array2[i] ) {
                    result += StringUtil.substitute("diff item\rbefore: \"{1}\"\r   after: \"{2}\"",
                                                    i, array1[i], array2[i]);
                    return result;
                }
            }
            
            return "";
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
        
        
        //flash.display::AVM1Movie -> MovieClip
        static public function setImageVolume(obj:Object, volume:Number, isPlayMovie:Boolean):void {
            Log.logging("setImageVolume volume", volume);
            
            var sprite:Sprite = obj as Sprite;
            if( sprite == null ) {
                Log.logging("setImageVolume obj is NOT Sprite");
                return;
            }
            Log.logging("setImageVolume obj is Sprite");
            
            var soundTransform:SoundTransform = new SoundTransform(volume);
            sprite.soundTransform = soundTransform;
            
            if( ! isPlayMovie ) {
                stopMovie(obj);
            }
        }
        
        static private function stopMovie(obj:Object):void {
            
            var movieClip:MovieClip = obj as MovieClip;
            if( movieClip == null ) {
                Log.logging("setImageVolume obj is NOT MovieClip");
                return;
            }
            
            Log.logging("setImageVolume obj is MovieClip");
            
            var maxFlame:int = movieClip.totalFrames;
            Log.logging("maxFlame", maxFlame);
            Log.logging("framesLoaded", movieClip.framesLoaded);
            var defaultFlame:int = 20;
            var targetFlame:int = Math.min(maxFlame, defaultFlame);
            Log.logging("targetFlame", targetFlame);
            
            movieClip.gotoAndStop(targetFlame);
        }
        
        static public function stopMoviewPlay(obj:Object):void {
            try {
                var image:Image = obj as Image;
                if( image != null ) {
                    Log.logging("stopMoviewPlay obj is Image so, flash.media.SoundMixer.stopAll()");
                    image.unloadAndStop();
                    return;
                }
                
                var movieClip:MovieClip = obj as MovieClip;
                if( movieClip == null ) {
                    Log.logging("stopMoviewPlay obj is NOT MovieClip");
                    return;
                }
                
                Log.logging("stopMoviewPlay obj is MovieClip");
                movieClip.stop();
                
            } catch( e:Error ) {
                Log.loggingException("Utils.stopMoviewPlay()", e);
            }
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
            
            return dateString;
        }
        
        static private function formatZero(number:Number, count:uint):String {
            var string:String = String(number);
            while (string.length < count) {
                string = "0" + string;
            }
            return string;
        }

        static public function getDateString(date:Date = null):String {
            if( date == null ) {
                date = new Date();
            }
            
            var dateString:String = 
                StringUtil.substitute("{0}/{1}/{2} {3}:{4}:{5}.{6}", 
                                      formatZero(date.fullYear, 2),
                                      formatZero(date.month, 2),
                                      formatZero(date.date, 2),
                                      formatZero(date.hours, 2),
                                      formatZero(date.minutes, 2),
                                      formatZero(date.seconds, 2),
                                      formatZero(date.milliseconds, 2));
            
                return dateString;
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
        

        static public function setGameTypeToComboBox(gameType:String, diceBotGameType:ComboBox):void {
            Log.logging("setGameTypeToComboBox Begin");
            
            var index:int = Utils.selectGameTypeComboBox(diceBotGameType, gameType);
            if( index == -1 ) {
                index = Utils.selectComboBox(diceBotGameType, gameType, "name");
            }
            
            if( index == -1 ) {
                Log.logging("gameType not found", gameType);
                
                addNewGameType(gameType, diceBotGameType);
                index = Utils.selectGameTypeComboBox(diceBotGameType, gameType);
                Log.logging("gameType add result", index);
            }
            
            diceBotGameType.validateNow();
            Log.logging("setGameTypeToComboBox End");
        }
        
        static private function addNewGameType(gameType:String, diceBotGameType:ComboBox):void {
            var diceBotInfos:Array = DodontoF_Main.getInstance().getDiceBotInfos();
            
            var info:Object = Utils.clone(diceBotInfos[0]);
            info.name = gameType;
            info.gameType = gameType;
            info.prefixs = [];
            info.info = "独自ダイス未実装";
            
            diceBotInfos.push( info );
            Log.logging("gameType", gameType);
            Log.logging("info", info);
            
            diceBotGameType.dataProvider = diceBotInfos;
        }
        
        
        static public function saveCaptureImage(component:UIComponent):void {
            Log.logging("saveCaptureImage Begin");
            
            var bmp:BitmapData = capture(component);
            
            if(bmp == null) {
                Log.printSystemLogPublic("画面キャプチャーに失敗しました。コマなどに外部画像を使用している場合はキャプチャを行うことは出来ません。画像を差し替えあるいはコマを削除してから、もう一度お試しください。");
                return;
            }
            
            var fileData:ByteArray = new JPEGEncoder().encode(bmp);
            
            saveImage(fileData, new Date().getTime() + ".jpg");
            Log.logging("saveCaptureImage End");
        }
        
        static public function capture(component:UIComponent):BitmapData {
            var result:BitmapData = new BitmapData(component.width, component.height);
        
            try {
                result.draw(component, new Matrix());
            } catch(e:Error) {
                return null;
            }
        
            return result;
        }
    
        static public function saveImage(date:ByteArray, fileName:String):void {
            var onComplete:Function = function(event:Event):void
            {
                Log.printSystemLogPublic(fileName + "を保存しました");
                onDestruct();
            }
            var onIOError:Function = function(event:IOErrorEvent):void
            {
                Alert.show(event.toString(), "保存失敗");
                onDestruct();
            }
            var onDestruct:Function = function():void
            {
                file.removeEventListener(Event.COMPLETE, onComplete);
                file.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                file = null;
            }
            
            var file:FileReference = new FileReference();
            file.addEventListener(Event.COMPLETE, onComplete);
            file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            file.save(date, fileName);
        }
    

        static public function getMouseLocalPoint(component:UIComponent):Point {
            var base:UIComponent = DodontoF_Main.getInstance().getDodontoF();
            var mousePoint:Point = new Point(base.mouseX, base.mouseY);
            var point:Point = component.globalToLocal(mousePoint);
            return point;
        }
        
        
        static public function getKeys(obj:Object, ignorePrefix:String = null):Array {
            var keys:Array = [];
            
            for(var key:String in obj){
                if(ignorePrefix != null) {
                    if(key.indexOf(ignorePrefix) == 0) {
                        continue;
                    }
                }
                keys.push(key);
            }
            keys.sort();
            
            return keys;
        }
        
        
        static public function getDiceBotLanguageName(gameType:String):String {
            var diceBotLanguageName:String = Language.diceBotLangPrefix + gameType;
            var langName:String = Language.s[diceBotLanguageName];
            return langName;
        }
        
        static public function setDiceBotDataProvider(comboBox:ComboBox,
                                                      diceBotInfos:Array):void {
            for(var i:int = 0 ; i < diceBotInfos.length; i++) {
                var info:Object = diceBotInfos[i];
                var langName:String = getDiceBotLanguageName( info['gameType'] );
                if( langName != null ) {
                    info['name'] = langName;
                }
            }
            comboBox.dataProvider = diceBotInfos;
        }
        
        static public function sendSystemMessage(message:String,
                                                  args:Array = null, strictlyUniqueId:String = null):void {
            DodontoF_Main.getInstance().getChatWindow().sendSystemMessage( message, args, strictlyUniqueId );
        }
        
        static public function smoothingImage(image:Image):void {
            smoothing( image.content );
        }
        static public function smoothingLoader(image:Loader):void {
            smoothing( image.content );
        }
        
        static public function smoothing(obj:Object):void {
            
            //外部URL有効の場合にsmoothingすると外部URL使用した全セーブデータのロードでクラッシュするため、ここでsmoothingを拒否。
            if( Config.canUseExternalImageModeOn ) {
                return;
            }
            
            var bmp:Bitmap = obj as Bitmap;
            if (bmp != null) {
                bmp.smoothing = true;
            }
        }
        
        static public function isValidSendTo(sendto:String):Boolean {
            return ((sendto != null) && (sendto != ""));
        }
        
        
        static public function getMapRangeSize():int {
            return DodontoF_Main.getInstance().getMap().getGridInterval();
        }
        
        static public function getMapRangeSquareLength():int {
            return Map.getSquareLength() * getMapRangeSize();
        }
        
        static public function getCenterImageUrl():String {
            return "image/centerMarker.png";
        }
        
        static public function removeBaseDiceBot(diceBotInfos:Object):Object {
            
            for(var i:int = 0 ; i < diceBotInfos.length; i++) {
                var info:Object = diceBotInfos[i];
                
                if( info.gameType == baseDiceBotGameType ) {
                    diceBotInfos.splice(i, 1);
                    return info;
                }
            }
            return null;
        }
        
        static public function get baseDiceBotGameType():String {
            return 'BaseDiceBot';
        }
        
    }
}


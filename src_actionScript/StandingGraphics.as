//--*-coding:utf-8-*--

package {
    
	import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.net.URLRequest;
    import flash.utils.Timer;
    import mx.controls.Alert;
    import mx.controls.Image;
    import mx.core.UIComponent;
    import mx.effects.Effect;
    
    public class StandingGraphics {
        
        static private var imageLoaderEventHash:Object = new Object();
        
        private var standingGraphicInfosOriginal:Array = new Array();
        private var imageInfos:Array = new Array(getMaxLeftIndex());
        private var baseX:int = 0;
        private var baseY:int = 0;
        private var baseWidth:int = 0;
        private var displayState:Boolean = true;
        private var noTargetImageAplha:Number = 0.7;
        
        private var speakMarker:String = "@speak";
        
        public function isSpeakState(state:String):Boolean {
            var ignoreStateRegExp:RegExp = new RegExp(speakMarker + "$");
            return (state.match(ignoreStateRegExp) != null);
        }
        
        static public function getMaxLeftIndex():int {
            return 12;
        }
        
        public function clear():void {
            standingGraphicInfosOriginal = new Array();
        }
        
        public function add(info:Object):void {
            
            info = copyInfoAjusted(info);
            
            if( findTargetSource(info.name, info.state) != null ) {
                Log.loggingError( Language.text("standingGraphicDuplicateError",
                                                info.name, info.state) );
                return;
            }
            
            standingGraphicInfosOriginal.push(info);
        }
        
        private function copyInfoAjusted(infoOriginal:Object):Object {
            
            var info:Object = Utils.clone(infoOriginal);
            info.leftIndex = getLeftIndex(info.leftIndex);
            return info;
        }
        
        private function getLeftIndex(leftIndex:int):int {
            if( leftIndex == 0 ) {
                leftIndex = 1;
            }
            return leftIndex
        }
        
        public function isDisplayStateOn():Boolean {
            return displayState;
        }
        
        
        public function setDisplayState(b:Boolean):void {
            displayState = b;
            
            if( isDisplayStateOn() ) {
                return;
            }
            
            clearAllExistImages();
        }
        
        public function clearAllExistImages():void {
            for(var i:int = 0 ; i < this.imageInfos.length ; i++) {
                var imageInfo:Object = this.imageInfos[i] as Object;
                if( imageInfo == null ) {
                    continue;
                }
                
                var component:UIComponent = imageInfo.component as UIComponent;
                var leftIndex:int = i;
                removeImageComponent(component, leftIndex);
            }
        }
        
        
        
        private function pushStandingGraphicInfosFromCharacters(infos:Array):void {
            var map:Map = DodontoF_Main.getInstance().getMap();
            var characters:Array = map.getCharacters();
            
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:Character = characters[i];
                if( character.isHideMode() ) {
                    continue;
                }
                
                var characterInfo:Object = {
                    "name" : character.getName(),
                    "state" : "",
                    "source" : character.getImageUrl()
                };
                infos.push(characterInfo);
            }
        }
        
        private function getStandingGraphicInfos(pushCharacterInfoFinction:Function = null):Array {
            var infos:Array = new Array();
            
            if( ! isDisplayStateOn() ) {
                return infos;
            }
            
            for(var i:int = 0 ; i < standingGraphicInfosOriginal.length ; i++) {
                var info:Object = standingGraphicInfosOriginal[i];
                infos.push(info);
            }
            
            if( pushCharacterInfoFinction == null ) {
                pushCharacterInfoFinction = pushStandingGraphicInfosFromCharacters;
            }
            
            pushCharacterInfoFinction(infos);
            
            return infos;
        }
        
        public function findAllStates(name:String, isAll:Boolean = false):Array {
            Log.logging("StandingGraphics.findAllStates begin");
            
            var stateList:Array = new Array();
            
            var standingGraphicInfos:Array = getStandingGraphicInfos();
            for(var i:int = 0 ; i < standingGraphicInfos.length ; i++) {
                var info:Object = standingGraphicInfos[i];
                
                if( name != info.name ) {
                    continue;
                }
                if( info.state == "" ) {
                    continue;
                }
                
                if( ! isAll ) {
                    //口パク用の立ち絵なので指定が無い限りは全状態取得の対象外
                    if( isSpeakState(info.state) ) {
                        continue;
                    }
                }
                
                stateList.push(info.state);
            }
            
            stateList.sort();
            
            Log.logging("StandingGraphics.findAllStates end");
            return stateList;
        }
        
        public function findAllNames():Array {
            var names:Array = new Array();
            
            var standingGraphicInfos:Array = getStandingGraphicInfos();
            for(var i:int = 0 ; i < standingGraphicInfos.length ; i++) {
                var info:Object = standingGraphicInfos[i];
                if( names.indexOf(info.name) == -1 ) {
                    names.push(info.name);
                }
            }
                
            return names;
        }
        
        public function findTargetSource(name:String,
                                         state:String,
                                         chatMessage:String = "",
                                         pushCharacterInfoFinction:Function = null):String {
            var result:Object = findTargetInfo(name, state, chatMessage, pushCharacterInfoFinction);
            if( result.info == null ) {
                return null;
            }
            
            return result.info.source;
        }
        
        private function findTargetInfo(name:String,
                                        state:String,
                                        chatMessage:String = "",
                                        pushCharacterInfoFinction:Function = null):Object {
            Log.logging("Standinggraphicinfos.findTargetInfo Begin");
            Log.logging("name", name);
            Log.logging("state", state);
            Log.logging("chatMessage", chatMessage);
            
            var result:Object = {
                'info':null,
                'chatMessage':chatMessage
            };
            
            var standingGraphicInfos:Array = getStandingGraphicInfos( pushCharacterInfoFinction );
            
            for(var i:int = 0 ; i < standingGraphicInfos.length ; i++) {
                var info:Object = standingGraphicInfos[i];
                if( name != info.name ) {
                    continue;
                }
                
                Log.logging("name == info.name");
                
                if( state == info.state ) {
                    Log.logging("state == info.state", state);
                    result.info = info;
                }
                
                if( chatMessage == "" ) {
                    Log.logging("chatMessage == '', so continue");
                    continue;
                }
                
                if( info.state == "" ) {
                    Log.logging("info.state == '', so continue");
                    continue;
                }
                
                if( isHitTailAnyLine(chatMessage, info.state) ) {
                    //チャット文字の末尾が 〜〜@(カットイン名)　のような名前なら、末尾を削除。
                    result.info = info;
                    result.chatMessage = Utils.cutChatTailWhenMarked(chatMessage, info.state);
                    break;
                }
            }
            
            Log.logging("Standinggraphicinfos.findTargetInfo End result", result);
            return result;
        }
        
        static private var chatLineSpliter:RegExp = /(\r|\n)/;
        
        private function isHitTailAnyLine(linesString:String, tail:String):Boolean {
            var lines:Array = linesString.split( chatLineSpliter );
            
            for(var i:int = 0 ; i < lines.length ; i++) {
                var line:String = lines[i];
                
                var index:int = line.search(tail);
                if( index == -1 ) {
                    continue;
                }
                
                if( index == (line.length - tail.length) ) {
                    return true;
                }
            }
            
            return false;
        }
        
        static public function getTypeStatic():String {
            return "standingGraphicInfos";
        }
        
        public function print(nameBase:String,
                              chatMessage:String,
                              effectable:Boolean,
                              filterImageInfos:Array,
                              chatWindowX:int,
                              chatWindowY:int,
                              chatWindowWidth:int):Object {
            Log.logging("StandingGraphics.print Begin");
            Log.logging("nameBase", nameBase);

            var name:String = nameBase;
            var state:String = "";
            
            var params:Array = nameBase.split(/\t/);
            if(params.length == 2) {
                name = params[0];
                state = params[1];
            }
            
            var result:Object = {
                "senderName" : name,
                'chatMessage' : chatMessage
            }
            
            if( result.senderName == "" ) {
                Log.logging("StandingGraphics.print End, result.senderName == null, result", result);
                return result;
            }
            
            result = analyzeAtmarkNameAndStand(result);
            
            Log.logging("findTargetInfo calling...");
            var findResult:Object = findTargetInfo(result.senderName, state, result.chatMessage);
            if(findResult.info == null) {
                Log.logging("StandingGraphics.print End, findResult.info == null, result", result);
                return result;
            }
            
            result.chatMessage = findResult.chatMessage;
            var info:Object = copyInfoAjusted( findResult.info );
            
            if( ! effectable ) {
                Log.logging("StandingGraphics.print End, effectable == false, result", result);
                return result;
            }
            
            info.source = Config.getInstance().getUrlString(info.source);
            
            Log.logging("findTargetInfo 2nd calling...");
            var speakImageResult:Object = findTargetInfo(result.senderName, state + speakMarker, result.chatMessage);
            if( speakImageResult.info != null ) {
                var speakInfo:Object = {
                    "image" : speakImageResult.info.source,
                    "message" : result.chatMessage};
                filterImageInfos.splice(0, 0, speakInfo);
            }
            
            adjustmentPosition(chatWindowX, chatWindowY, chatWindowWidth);
            
            printImage(filterImageInfos, info);
            
            Log.logging("StandingGraphics.print End, result", result);
            return result;
        }
        
        
        private function analyzeAtmarkNameAndStand(result:Object):Object {
            var names:Array = findAllNames();
            
            var nameMarkderReg:RegExp = /(@|＠)([^@＠]+)/g;
            var match:Object = nameMarkderReg.exec(result.chatMessage);
            
            while( match != null ) {
                var matchFullText:String = match[0];
                var matchText:String = match[2];

                Log.logging("result.chatMessage", result.chatMessage);
                Log.logging("names", names);
                for each(var name:String in names) {
                    if( matchText != name ) {
                        continue;
                    }
                    
                    result.senderName = name;
                    result.chatMessage = result.chatMessage.replace(matchFullText, '');
                    Log.logging("match result.chatMessage", result.chatMessage);
                    return result;
                }
                
                match = nameMarkderReg.exec(result.chatMessage);
            }
            
            Log.logging("NO match result.chatMessage", result.chatMessage);
            return result;
        }
        
        
        private function adjustmentPosition(chatWindowX:int, chatWindowY:int, chatWindowWidth:int):void {
            //ウィンドサイズの分高さを調整。
            baseY = chatWindowY - 30;
            
            //カットインが左端だと見栄えが悪いので調整。
            baseX = chatWindowX + 10;
            
            //幅一杯だと見栄えが悪いので調整
            baseWidth = chatWindowWidth - 10;
        }
        
        
        private function printImage(filterImageInfos:Array, 
                                    info:Object):void {
            Log.logging("printImage begin"); 
            
            var imageCompleteHandlerFunction:Function
                = getImageCompleteHandler(filterImageInfos, info);
            
            var existEvent:Event = imageLoaderEventHash[info.source] as Event;
            Log.logging("imageLoaderEventHash info.source", info.source); 
            
            if( existEvent == null ) {
                Log.logging("existEvent is null, so loadImage called."); 
                loadImage(info.source, imageCompleteHandlerFunction);
            } else {
                Log.logging("existEvent is NOT null, get image from Hash DB"); 
                imageCompleteHandlerFunction(existEvent);
            }
            
            Log.logging("printImage end"); 
        }
        
        private function loadImage(source:String, imageCompleteHandlerFunction:Function):void {
            Log.logging("loadImage begin source", source);
            
            source = Config.getInstance().getUrlString(source);
            
            var imageLoader:Loader = new Loader();
            imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageCompleteHandlerFunction);
            imageLoader.load(new URLRequest(source));
        }
        
        private function getImageCompleteHandler(filterImageInfos:Array,
                                                 info:Object):Function {
            return function(event:Event):void {
                imageCompleteHandler(event, filterImageInfos, info);
            };
        }
        
        private var imageWidthRate:Number = 1;//0.4;
        
        private function imageCompleteHandler(event:Event, filterImageInfos:Array,
                                              info:Object):void {
            
            Log.loggingTuning("imageCompleteHandler begin info.name", info.name);
            
            saveEventHash(event, info.source);
            
            var image:Loader = event.target.loader;
            adjustmentImagePosition(image, info);
            addImage(image, filterImageInfos, info);
            
            Utils.smoothingLoader( image );
            
            Log.logging("imageCompleteHandler end");
        }
        
        
        private function adjustmentImagePosition(image:Loader, info:Object):void {
            var imageHeigthMinimum:int = 200;
            var imageSizeInfo:Object = Utils.getSizeInfo(image, 0, 0, imageHeigthMinimum);
            
            image.height = imageSizeInfo.height;
            image.width = imageSizeInfo.width;
            
            if( Config.getInstance().isAdjustImageSizeMode() ) {
                if( image.height < imageHeigthMinimum ) {
                    setImageSizeFromHeigth(imageHeigthMinimum, image);
                }
                
                var imageHeigthMax:int = baseY - 50;
                if( image.height > imageHeigthMax ) {
                    setImageSizeFromHeigth(imageHeigthMax, image);
                }
                
                var imageWidthMax:int = baseWidth * imageWidthRate;
                if( image.width > imageWidthMax ) {
                    setImageSizeFromWidth(imageWidthMax, image);
                }
            }
            
            var leftIndex:int = getLeftIndex(info.leftIndex);
            var leftIndexRate:Number = ((leftIndex - 1) / 12);
            var leftPadding:Number = ((baseWidth - image.width) * leftIndexRate);
            
            image.x = baseX + leftPadding;
            image.y = baseY - image.height;
            
            if( info.mirrored ) {
                image.x += image.width;
                image.scaleX *= -1;
            }
        }
        
        
        private function setImageSizeFromHeigth(height:int, image:Loader):void {
            var rate:Number = (height / image.height);
            image.width = image.width * rate;
            image.height = height;
        }
        
        private function setImageSizeFromWidth(width:int, image:Loader):void {
            var rate:Number = (width / image.width);
            image.width = width;
            image.height = image.height * rate;
        }
        
        
        
        private function saveEventHash(event:Event, source:String):void {
            Log.logging("saveEventHash begin"); 
            
            var loaderInfo:LoaderInfo = event.currentTarget as LoaderInfo;
            
            imageLoaderEventHash[source] = event;
            Log.logging("saveEventHash end"); 
        }
        
        
        private function addImage(imageLoader:Loader,
                                  filterImageInfos:Array,
                                  info:Object):void {
            
            var component:UIComponent = new UIComponent();
            component.addChild(imageLoader);
            
            clearExistImages(info.name, info.leftIndex);
            addImageComponent(component, imageLoader, info);
            
            component.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
                    removeImageComponent(component, info.leftIndex);
                });
            
            Log.logging("filterImageInfos", filterImageInfos);
            
            for(var i:int = 0 ; i < filterImageInfos.length ; i++) {
                var info:Object = filterImageInfos[i];
                var imageName:String = info.image;
                var message:String = info.message;
                loadImage(imageName, getImageCompFundlerForFilter(imageLoader, component, message, info));
            }
        }
        
        public function clearExistImages(name:String, leftIndex:int = -1):void {
            
            for(var i:int = 0 ; i < this.imageInfos.length ; i++) {
                var imageInfo:Object = this.imageInfos[i] as Object;
                if( imageInfo == null ) {
                    continue;
                }
                
                var component:UIComponent = imageInfo.component as UIComponent;
                var imageName:String = imageInfo.name as String;
                
                if( isDeleteImage(i, leftIndex, imageName, name) ) {
                    Log.logging("削除");
                    removeImageComponent(component, leftIndex);
                    continue;
                }
                
                Log.logging("半透明化");
                component.alpha = noTargetImageAplha;
            }
        }
        
        private function isDeleteImage(index:int, leftIndex:int, 
                                       imageName:String, name:String):Boolean {
            if( imageName == name ) {
                return true;
            }
            
            if( leftIndex == index ) {
                return true;
            }
            
            return false;
        }
        
        private function removeImageComponent(component:UIComponent, leftIndex:int):void {
            try {
                getLayer().removeChild( component );
                stopEffect(leftIndex);
                this.imageInfos[leftIndex] = null;
                
            } catch(e:Error) {
                //Log.loggingException("StandingGraphicInfos:clear", e);
            }
        }
        
        private function stopEffect(leftIndex:int):void {
            
            var info:Object = this.imageInfos[leftIndex];
            
            if( info == null || info.effect == null) {
                return;
            }
            
            try {
                info.effct.stop();
            } catch(e:Error) {
                //エフェクト強制STOP処理でエラーになる＝すでに停止していると考えて特に対処無し。
                //Log.loggingException("stopEffect error", e);
            }
        }
        
        
        private function addImageComponent(component:UIComponent,
                                           imageLoader:Loader, info:Object):void {

            var leftIndex:int = info.leftIndex;
            
            getLayer().addChild(component);
            this.imageInfos[leftIndex] = {"component" : component,
                                          "imageLoader" : imageLoader,
                                          "name" : info.name,
                                          "motion" : info.motion,
                                          "effect" : null };
            addPlayNewEffect(info);
        }
        
        private function addPlayNewEffect(info:Object):void {
            
            var leftIndex:int = info.leftIndex;
            stopEffect(leftIndex);
            
            var info:Object = this.imageInfos[leftIndex];
            if( info == null ) {
                return;
            }
            
            var height:int = info.imageLoader.height;
            var width:int = info.imageLoader.width;
            
            var effect:Effect = new MotionEffect().
                getMotionEffect(info.component, height, width, info.motion);
            
            if( effect == null ) {
                return;
            }
            
            effect.play();
            info.effect = effect;
        }
        
        
        private function getLayer():UIComponent {
            return DodontoF_Main.getInstance().getStandingGraphicLayer();
        }
        
        
        private function getImageCompFundlerForFilter(baseLoader:Loader, component:UIComponent,
                                                      message:String, info:Object):Function {
            return function(event:Event):void {
                var loader:Loader = event.target.loader;
                loader.x = baseLoader.x;
                loader.y = baseLoader.y;
                var imageSizeInfo:Object = Utils.getSizeInfo(loader, 0, 0, baseLoader.height);
                
                loader.width = (imageSizeInfo.width / imageSizeInfo.height) * baseLoader.height;
                loader.height = baseLoader.height;
                if( info.mirrored ) {
                    loader.scaleX = -1;
                }
                
                component.addChild(loader);
                
                if( message == null ) {
                    return;
                }
                
                var messages:Array = message.split(messageSplitter);
                startImageChangeTimer(messages, baseLoader, loader, component);
            }
        }
        
        private var messageSplitter:RegExp = /[・…,\.、。，．!！\?？　\s]/;
        
        private function startImageChangeTimer(messages:Array, baseLoader:Loader, loader:Loader, component:UIComponent):void {
            if( messages.length <= 0 ) {
                try {
                    baseLoader.visible = true;
                    component.removeChild(loader);
                } catch (e:Error) {
                }
                return;
            }
            
            if( baseLoader == null ) {
                return;
            }
            if( loader == null ) {
                return;
            }
            
            changeSpeakImage(baseLoader, loader, true);
            
            var sleepParChar:Number = 0.15 * 1000;
            var part:String = messages.shift();
            var timer:Timer = new Timer(part.length * sleepParChar, 1);
            
            timer.addEventListener( flash.events.TimerEvent.TIMER, function(event:TimerEvent):void {
                    changeSpeakImage(baseLoader, loader, false);
                    
                    var timerForStopSpeak:Timer = new Timer(1 * sleepParChar, 1);
                    timerForStopSpeak.addEventListener( flash.events.TimerEvent.TIMER, function(event:TimerEvent):void {
                            startImageChangeTimer(messages, baseLoader, loader, component);
                        });
                    timerForStopSpeak.start(); 
                });
            
            timer.start(); 
        }
        
        private function changeSpeakImage(baseLoader:Loader, loader:Loader, isSpeak:Boolean):void {
            baseLoader.visible = (! isSpeak);
            loader.visible = isSpeak;
        }
        

    }
}

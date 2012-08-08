//--*-coding:utf-8-*--

package {
    
    import mx.controls.Alert;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import mx.controls.Image;
    import mx.core.UIComponent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    
    
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
            var name:String = info.name;
            var state:String = info.state;
            var source:String = info.source;
            var mirrored:Boolean = info.mirrored;
            var leftIndex:int = info.leftIndex;
            if( leftIndex == 0 ) {
                leftIndex = 1;
            }
            
            if( findTargetSource(name, state) != null ) {
                Log.loggingError("キャラクター名：" + name
                                 + "、状態：" + state 
                                 + "、はすでに登録済みの立ち絵が存在します。");
                return;
            }
            
            var target:Object = {
                "name" : name,
                "state" : state,
                "source" : source,
                "mirrored": mirrored,
                "leftIndex" : leftIndex
            };
            
            standingGraphicInfosOriginal.push(target);
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
        
        
        private function pushStandingGraphicInfosFromCharacters(infos:Array):void {
            var map:Map = DodontoF_Main.getInstance().getMap();
            var characters:Array = map.getCharacters();
            
            for(var i:int = 0 ; i < characters.length ; i++) {
                var character:Character = characters[i];
                
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
            var result:Object = {
                'info':null,
                'chatMessage':chatMessage
            };
            
            Log.logging("chatMessage", chatMessage);
            
            var standingGraphicInfos:Array = getStandingGraphicInfos( pushCharacterInfoFinction );
            for(var i:int = 0 ; i < standingGraphicInfos.length ; i++) {
                var info:Object = standingGraphicInfos[i];
                if( name == info.name ) {
                    if( state == info.state ) {
                        result.info = info;
                    }
                    
                    if( chatMessage == "" ) {
                        continue;
                    }
                    
                    if( info.state == "" ) {
                        continue;
                    }
                    
                    Log.logging('isHitTailAnyLine info.state', info.state);
                    if( isHitTailAnyLine(chatMessage, info.state) ) {
                        Log.logging('isHitTailAnyLine chatMessage', chatMessage);
                        Log.logging('isHitTailAnyLine info', info);
                        
                        //チャット文字の末尾が 〜〜@(カットイン名)　のような名前なら、末尾を削除。
                        result.info = info;
                        result.chatMessage = Utils.cutChatTailWhenMarked(chatMessage, info.state);
                        break;
                    }
                }
            }
            
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
        
        public function shiftAllImagesYPosition(diff:int):void {
            for(var i:int = 0 ; i < this.imageInfos.length ; i++) {
                var imageInfo:Object = this.imageInfos[i] as Object;
                if( imageInfo == null ) {
                    continue;
                }
                
                var component:UIComponent = imageInfo.component as UIComponent;
                component.y = diff;
            }
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
                this.imageInfos[leftIndex] = null;
            }
        }
        
        public function clearExistImages(name:String, leftIndex:int = -1):void {
            Log.logging("clearExistImages name", name);
            Log.logging("clearExistImages leftIndex", leftIndex);
            
            for(var i:int = 0 ; i < this.imageInfos.length ; i++) {
                var imageInfo:Object = this.imageInfos[i] as Object;
                if( imageInfo == null ) {
                    continue;
                }
                
                var component:UIComponent = imageInfo.component as UIComponent;
                var imageName:String = imageInfo.name as String;
                Log.logging("imageName", imageName);
                Log.logging("imageInfos loop index i", i);
                
                if( isDeleteImage(i, leftIndex, imageName, name) ) {
                    Log.logging("削除");
                    removeImageComponent(component, i);
                    this.imageInfos[i] = null;
                    continue;
                }
                
                Log.logging("半透明化");
                component.alpha = noTargetImageAplha;
            }
            
            Log.logging("clearExistImages End");
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
                var dodontoFComp:UIComponent = DodontoF_Main.getInstance().getStandingGraphicLayer();
                dodontoFComp.removeChild( component );
            } catch(e:Error) {
                //Log.loggingException("StandingGraphicInfos:clear", e);
            }
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
            
            if( name == "" ) {
                return result;
            }
            
            var findResult:Object = findTargetInfo(name, state, chatMessage);
            if(findResult.info == null) {
                return result;
            }
            
            result.chatMessage = findResult.chatMessage
            
            var leftIndex:int = findResult.info.leftIndex;
            if( leftIndex == 0 ) {
                leftIndex = 1;
            }
            
            if( ! effectable ) {
                return result;
            }
            
            var source:String = findResult.info.source;
            source = Config.getInstance().getUrlString(source);
            
            var mirrored:Boolean = findResult.info.mirrored;
            
            var speakImageResult:Object = findTargetInfo(name, state + speakMarker, chatMessage);
            if( speakImageResult.info != null ) {
                var kuchipaku:Object = {
                    "image" : speakImageResult.info.source,
                    "message" : findResult.chatMessage};
                filterImageInfos.splice(0, 0, kuchipaku);
            }
            
            adjustmentPosition(chatWindowX, chatWindowY, chatWindowWidth);
            
            printImage(leftIndex, filterImageInfos, name, source, mirrored);
            
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
        
        
        private function printImage(leftIndex:int, filterImageInfos:Array, name:String,
                                    source:String, mirrored:Boolean):void {
            Log.logging("printImage begin"); 
            
            var imageCompleteHandlerFunction:Function = getImageCompleteHandler(leftIndex, filterImageInfos, name, source, mirrored);
            
            var existEvent:Event = imageLoaderEventHash[source] as Event;
            Log.logging("imageLoaderEventHash source", source); 
            
            if( existEvent == null ) {
                Log.logging("existEvent is null, so loadImage called."); 
                loadImage(source, imageCompleteHandlerFunction);
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
        
        private function getImageCompleteHandler(leftIndex:int, filterImageInfos:Array,
                                                 name:String, source:String, mirrored:Boolean):Function {
            return function(event:Event):void {
                imageCompleteHandler(event, leftIndex, filterImageInfos, name, source, mirrored);
            };
        }
        
        private var imageWidthRate:Number = 1;//0.4;
        
        private function imageCompleteHandler(event:Event, leftIndex:int, filterImageInfos:Array,
                                              name:String, source:String, mirrored:Boolean):void {
            
            Log.loggingTuning("imageCompleteHandler begin name", name);
            
            saveEventHash(event, source);
            
            var image:Loader = event.target.loader;
            
            var imageHeigthMinimum:int = 200;
            var imageSizeInfo:Object = Utils.getSizeInfo(image, 0, 0, imageHeigthMinimum);
            
            image.height = imageSizeInfo.height;
            image.width = imageSizeInfo.width;
            
            if( Config.getInstance().isAdjustImageSizeMode() ) {
                if( image.height < imageHeigthMinimum ) {
                    setImageSizeFromHeigth(imageHeigthMinimum, image);
                }
                
                var imageHeigthMax:int = baseY - 50;//baseY * 0.9;
                if( image.height > imageHeigthMax ) {
                    setImageSizeFromHeigth(imageHeigthMax, image);
                }
                
                var imageWidthMax:int = baseWidth * imageWidthRate;
                if( image.width > imageWidthMax ) {
                    setImageSizeFromWidth(imageWidthMax, image);
                }
            }
            
            
            var leftIndexRate:Number = ((leftIndex - 1) / 12);
            var leftPadding:Number = ((baseWidth - image.width) * leftIndexRate);
            image.x = baseX + leftPadding;
            image.y = baseY - image.height;
            
            if( mirrored ) {
                image.scaleX = -1;
                image.x += image.width;
            }
            
            addImage(leftIndex, image, filterImageInfos, name);
            
            Log.logging("imageCompleteHandler end");
        }
        
        private function saveEventHash(event:Event, source:String):void {
            Log.logging("saveEventHash begin"); 
            
            var loaderInfo:LoaderInfo = event.currentTarget as LoaderInfo;
            
            imageLoaderEventHash[source] = event;
            Log.logging("saveEventHash end"); 
        }
        
        private function addImage(leftIndex:int, imageLoader:Loader, filterImageInfos:Array, name:String):void {
            var component:UIComponent = new UIComponent();
            component.addChild(imageLoader);
            
            var dodontoFComp:UIComponent = DodontoF_Main.getInstance().getStandingGraphicLayer();
            dodontoFComp.addChild(component);
            clearExistImages(name, leftIndex);
            this.imageInfos[leftIndex] = {"component" : component,
                                          "name" : name};
            
            component.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
                    dodontoFComp.removeChild(component);
                });
            
            for(var i:int = 0 ; i < filterImageInfos.length ; i++) {
                var filterImageInfo:Object = filterImageInfos[i];
                var imageName:String = filterImageInfo.image;
                var message:String = filterImageInfo.message;
                loadImage(imageName, getImageCompFundlerForFilter(imageLoader, component, message));
            }
        }
        
        private function getImageCompFundlerForFilter(baseLoader:Loader, component:UIComponent, message:String):Function {
            return function(event:Event):void {
                var loader:Loader = event.target.loader;
                loader.x = baseLoader.x;
                loader.y = baseLoader.y;
                
                var imageSizeInfo:Object = Utils.getSizeInfo(loader, 0, 0, baseLoader.height);
                
                imageSizeInfo.width;
                
                loader.width = (imageSizeInfo.width / imageSizeInfo.height) * baseLoader.height;
                loader.height = baseLoader.height;
                
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
        
        private function setImageSizeFromHeigth(height:int,
                                                image:Loader):void {
            var rate:Number = (height / image.height);
            image.width = image.width * rate;
            image.height = height;
        }
        private function setImageSizeFromWidth(width:int,
                                               image:Loader):void {
            var rate:Number = (width / image.width);
            image.width = width;
            image.height = image.height * rate;
        }
    }
}

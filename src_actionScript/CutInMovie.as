//--*-coding:utf-8-*--


package {
    
    import com.adobe.serialization.json.JSON;
    import flash.display.AVM1Movie;
    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.net.URLRequest;
    import mx.controls.Alert;
    import mx.controls.VideoDisplay;
    import mx.core.IFlexDisplayObject;
    import mx.core.UIComponent;
    import mx.events.EffectEvent;
    import mx.events.MetadataEvent;
    import mx.events.VideoEvent;
    import flash.media.SoundTransform;
    import com.enefekt.tubeloc.*;
    import com.enefekt.tubeloc.event.*;
    
    
    public class CutInMovie extends CutInBase {
        
        private var cutInWindow:CutInWindow;
        private var defaultWidth:int;
        private var defaultHeight:int;
        private var params:Object;

        static private var volumeDefault:Number = 0.1;
        private var volume:Number = volumeDefault;
        private var soundSource:String = null;
        private var isSoundLoop:Boolean = false;
        
        private var youtubeMovie:MovieSprite;
        
        public function CutInMovie() {
        }
        
        override protected function getMarkString():String {
            return "###CutInMovie###";
        }
        
        static public function isFlvFile(source:String):Boolean {
            return Utils.isFlvFile(source);
        }
        
        static public function isMovie(source:String):Boolean {
            return Utils.isMovie(source);
        }
        
        static public function isYoutubeUrl(source:String):Boolean {
            return Utils.isYoutubeUrl(source);
        }
        
        static public function getYoutubeId(source:String):String {
            return Utils.getYoutubeId(source);
        }
        
        
        override protected function isCheckTailMatch():Boolean {
            return true;
        }
        
        
        override protected function executeEffect(params_:Object):void {
            Log.logging("CutInMovie.executeEffect Begin");
            params = params_;
            
            cutInWindow = CutInWindow.getWindow(params.cutInTag);
            
            soundSource = params.soundSource;
            if( soundSource == "" ) {
                soundSource = null;
            }
            
            isSoundLoop = params.isSoundLoop;
            
            if( params.volume == null ) {
                this.volume = volumeDefault;
            } else {
                this.volume = parseFloat(params.volume);
            }
            
            if( isFlvFile(params.source) ) {
                setCutInFlv();
            } else if( isYoutubeUrl(params.source) ) {
                setCutInYoutube();
            } else {
                setCutInImage();
            }
        }
        
        private function setCutInImage():void {
            var imageLoader:Loader = new Loader();
            imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.completeHandlerForImage);
            imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.ioErrorHandler);
            
            var displayObject:DisplayObject = imageLoader;
            var component:UIComponent = new UIComponent();
            component.addChild(displayObject);
            addCutInToCutinWindow(component);
            defaultWidth = parseInt(params.width);
            defaultHeight = parseInt(params.height);
            
            var sourceUrl:String = params.source;
            imageLoader.load( new URLRequest(sourceUrl) );
        }
        
        private function addCutInToCutinWindow(component:DisplayObject):void {
            cutInWindow.addCutIn(component,
                                 getWindowTitle(params),
                                 parseFloat(params.displaySeconds),
                                 params.position);
        }
        
        private function ioErrorHandler(event:Event):void {
            Log.loggingError("ioErrorHandler");
            var imageLoader:Loader = event.target.loader;
            Log.loggingError("指定画像が読み出せませんでした。", imageLoader.loaderInfo.url);
            cutInWindow.closeWindow();
        }
        
        private function playSound():SoundChannel {
            var soundChannel:SoundChannel = new SoundChannel();
            if( this.soundSource == null ) {
                return soundChannel;
            }
            
            var sound:Sound = new Sound();
            var request:URLRequest = new URLRequest(this.soundSource);
            sound.load(request);
            
            var startTime:Number = 0;
            var loops:int = 0;
            
            if( isSoundLoop ) {
                loops = int.MAX_VALUE;
            }
            
            var soundTransform:SoundTransform = new SoundTransform();
            soundTransform.volume = this.volume;
            soundChannel = sound.play(startTime, loops, soundTransform);
            
            return soundChannel;
        }
        
        private function completeHandlerForImage(event:Event):void {
            var imageLoader:Loader = event.target.loader;
            var imageInfo:Object = Utils.getSizeInfo(imageLoader, defaultWidth, defaultHeight);
            imageLoader.width = imageInfo.width;
            imageLoader.height = imageInfo.height;
            var isPlayMovie:Boolean = true;
            Utils.setImageVolume(imageLoader, this.volume, isPlayMovie);
            var soundChannel:SoundChannel = playSound();
            
            cutInWindow.setSize(imageInfo.width, imageInfo.height);
            
            cutInWindow.setCutInStopFunction( function():void {
                    soundChannel.stop();
                    
                    var movieClip:MovieClip = (imageLoader as MovieClip);
                    if( movieClip != null ) {
                        movieClip.stop();
                    } else {
                        imageLoader.unloadAndStop();
                    }
                });
        }
        
        private function setCutInFlv():void {
            var sourceUrl:String = params.source;
            
            var cutInFlv:VideoDisplay = new VideoDisplay();
            cutInFlv.autoPlay = false;
            cutInFlv.visible = true;
            cutInFlv.source = sourceUrl;
            cutInFlv.x = 0;
            cutInFlv.y = 0;
            cutInFlv.autoRewind = true;
            cutInFlv.volume = this.volume;
            
            var soundChannel:SoundChannel = playSound();
            
            initCutInFlv(cutInFlv);
            
            addCutInToCutinWindow(cutInFlv);
            cutInWindow.setCutInStopFunction(function():void {
                    soundChannel.stop();
                    cutInFlv.stop();
                });
            
            cutInFlv.play();
        }
        
        private function initCutInFlv(cutInFlv:VideoDisplay):void {
            cutInFlv.addEventListener(flash.events.Event.COMPLETE,
                                      this.completeHandlerForCutInWindowClose);
            
            cutInFlv.addEventListener(mx.events.MetadataEvent.METADATA_RECEIVED,
                                      this.metadataEventHandlerForCutInFlv);
        }
        
        private function metadataEventHandlerForCutInFlv(event:MetadataEvent):void {
            var metadata:Object = event.info;
            //cutInWindow.setSize(metadata.width, metadata.height);
            cutInWindow.setSize( (metadata.width + 5), (metadata.height + 5));
        }
        
        private function completeHandlerForCutInWindowClose(event:Event):void {
            cutInWindow.closeWindow();
        }
        
        
        private function onPlayerReadyYoutube(playerReadyEvent:PlayerReadyEvent = null):void {
            youtubeMovie.x = 0;
            youtubeMovie.y = 0;
            
            youtubeMovie.width = parseInt(params.width);
            if( youtubeMovie.width == 0 ) {
                youtubeMovie.width = 400
            }
            youtubeMovie.height = parseInt(params.height);
            if( youtubeMovie.height == 0 ) {
                youtubeMovie.height = 300;
            }
            //youtubeMovie.height = 200 + MovieSprite.CHROME_HEIGHT;
            
            youtubeMovie.setVolume( this.volume * 100 );
            
            var soundChannel:SoundChannel = playSound();
            
            cutInWindow.setSize( (youtubeMovie.width  + 10),
                                 (youtubeMovie.height + 10) );
            
            var component_youtube:UIComponent = new UIComponent();
            component_youtube.addChild(youtubeMovie);
            addCutInToCutinWindow(component_youtube);
            
            cutInWindow.setCutInStopFunction(function():void {
                    soundChannel.stop();
                    youtubeMovie.stopVideo();
                });
            
            if( playerReadyEvent != null ) {
                //youtubeMovie.playVideo();
                var youtubeId:String = getYoutubeId(params.source);
                loadYoutube(youtubeId);
            }
        }
        
        
        private function initYoutubeMovie():void {
            youtubeMovie.addEventListener(PlayerReadyEvent.PLAYER_READY, onPlayerReadyYoutube);
            //youtubeMovie.addEventListener(flash.events.Event.COMPLETE, completeHandlerForCutInWindowClose);
        }
        
        private function loadYoutube(youtubeId:String):void {
            youtubeMovie.stopVideo();
            youtubeMovie.clearVideo();
            youtubeMovie.loadVideoById(youtubeId);
            onPlayerReadyYoutube();
        }
        
        private function setCutInYoutube():void {
            var youtubeId:String = getYoutubeId(params.source);
            
            if( youtubeMovie == null ) {
                var chromeless:Boolean = true;
                youtubeMovie = new MovieSprite(youtubeId, chromeless);
                initYoutubeMovie();
                return;
            }
            
            try {
                loadYoutube(youtubeId);
            } catch (e:Error) {
                //Alert.show("youtubeMovie.loadVideoById error");
            }
        }
        
    }
}

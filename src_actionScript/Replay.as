//--*-coding:utf-8-*--
package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import mx.core.UIComponent;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.net.FileReference;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.system.Capabilities;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import mx.collections.ArrayCollection;
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.core.IFlexDisplayObject;
    import mx.events.CloseEvent;
    import flash.net.FileFilter;
    
    
	public class Replay {
        
        [Bindable]
        private var historyIndex:int = 0;
        
        
        //再生位置を変更する度に値が増える。
        //前回と値が一致する場合は再生が続行。
        //一致しない場合は再生位置が変更になったため、再生をやり直す。
        private var replaySeekIndex:int = 0;
        
        private var isPlaying:Boolean = true;
        private var isPausing:Boolean = false;
        private var timeoutId:uint = 0;
        private var sender:SharedDataSender = null;
        private var history:Array = null;
        private var replaySpeed:Number = 1;
        private var restChatSendDataForReplay:Array = new Array();
        
        public function setReplaySpeed(speed:Number):void {
            replaySpeed = speed;
        }
        
        public function setSender(sender_:SharedDataSender):void {
            sender = sender_;
        }
        
        
        private var fileReferenceForSessionReplay:FileReference = null;
        private var loadCaller:Function = null;
        
        public function replayFromSessionRecord():void {
            loadReplayData( playReplayFromData );
        }
        
        public function loadReplayData(call:Function):void {
            Log.logging("loadReplayData begin");
            loadCaller = call;
            
            fileReferenceForSessionReplay = new FileReference();
            fileReferenceForSessionReplay.addEventListener(Event.SELECT, replayFromSessionRecordOnSelect);
            
            var filters:Array = new Array();
            filters.push(new FileFilter(Language.s.playRecordDataFileFormat,"*.rec"));
            
            fileReferenceForSessionReplay.browse(filters);
        }
        
        public function replayFromSessionRecordOnSelect(e:Event):void {
            fileReferenceForSessionReplay.addEventListener(Event.COMPLETE,
                                                           replayFromSessionRecordOnComplete);
            fileReferenceForSessionReplay.load();
        }
        
        private function replayFromSessionRecordOnComplete(e:Event):void {
            var data:ByteArray = fileReferenceForSessionReplay.data as ByteArray;
            var fileName:String = fileReferenceForSessionReplay.name;
            loadCaller(data, fileName);
        }
        
        public function playReplayFromData(data:ByteArray, fileName:String):void {
            var dataString:String = data.toString();
            playReplayFromDataString(dataString);
        }
        
        private function init():void {
            initActiveChannelNames();
            historyIndex = 0;
            restChatSendDataForReplay = new Array();
            setSlider();
            
            DodontoF_Main.getInstance().setLocalReplayMode(true);
            
            var chatWindow:ChatWindow = DodontoF_Main.getInstance().getChatWindow();
            chatWindow.setSoundState(true);
            
            for(var i:int = 0 ; i < ChatWindow.getInstance().chatChannelCount ; i++) {
                if( i != ChatWindow.getInstance().publicChatChannel ) {
                    chatWindow.setChatChannelVisible(i, false);
                }
            }
            
            chatWindow.selectChatChannel(ChatWindow.getInstance().publicChatChannel);
            chatWindow.invisibleChatTab();
        }
        
        public function setSlider():void {
            DodontoF_Main.getInstance().getDodontoF().replaySeekSlider.value = historyIndex;
        }
        
        public function playReplayFromDataString(dataString:String):void {
            Log.loggingError(Language.s.loadingReplayData);
            
            history = SharedDataReceiver.getJsonDataFromString(dataString) as Array;
            DodontoF_Main.getInstance().getDodontoF().replaySeekSlider.maximum = history.length;
            
            init();
            
            Log.loggingError(Language.s.startReplayRecording);
            
            historyIndex = DodontoF_Main.getInstance().getReplayStartPosition() - 1;
            replaySeekIndex = -1;
            beginChangeReplayPoint();
        }
        
        public function addRestChatSendDataForReplay(chatSendData:ChatSendData):void {
            Log.logging("addRestChatSendDataForReplay !!!!");
            restChatSendDataForReplay.push(chatSendData);
        }
        
        private function getPlayingState():Boolean {
            return isPlaying;
        }
        private function setPlayingState(b:Boolean):void {
            isPlaying = b;
            
            if( isPlaying ) {
                DodontoF_Main.getInstance().getDodontoF().setPauseIcon();
            } else {
                DodontoF_Main.getInstance().getDodontoF().setPlayIcon();
            }
        }
        
        //リプレイで表示するチャンネルはここの辺りの処理で制御
        private var activeChannelNames:Array = [];
        
        public function initActiveChannelNames():void {
            activeChannelNames = [DodontoF_Main.publicChatChannelName];
        }
        
        public function setActiveChannel(names:Array):void {
            if( names == null ) {
                activeChannelNames = null;
                return;
            }
            
            activeChannelNames = Utils.clone(names);
        }
        
        public function isIgnoreChannel(channel:int):Boolean {
            var channelName:String = DodontoF_Main.getInstance().getChatChannelName(channel);
            return isIgnoreChannelName(channelName);
        }
        
        public function isIgnoreChannelName(channelName:String):Boolean {
            if( channelName == null ) {
                return false;
            }
            
            if( activeChannelNames == null ) {
                return false;
            }
            
            for(var i:int = 0 ; i < activeChannelNames.length ; i++) {
                if( channelName == activeChannelNames[i] ) {
                    return false;
                }
            }
            
            return true;
        }
        
        private function getChatSleepTimeFromMessageData(chatSendData:ChatSendData):int {
            var channel:int = chatSendData.getChannel();
            if( isIgnoreChannel(channel) ) {
                return 0;
            }
            
            //var chatMessage:String = chatSendData.getMessage();
            var box:ChatMessageLogBox = ChatWindow.getInstance().getChatChannle(0);
            var htmlText:String = box.getLastHtmlText();
            var chatMessage:String = Utils.htmlToText(htmlText);
            Log.logging("sleep chatMessage", chatMessage);
            
            var length:int = chatMessage.length;
            Log.logging("sleep chatMessage.length", length);
            
            var sleepTimeMilliSeconds:int =  (0.3 + length * 0.05) * 1000;
            Log.logging("sleepTime", sleepTimeMilliSeconds / 1000.0);
            
            return sleepTimeMilliSeconds;
        }
        
        private var characterSleepTime:int = 0.5 * 1000;
        
        
        private function replayHistory(currentReplaySeekIndex:int):void {
            
            if( isPausing ) {
                setPlayingState( false );
                isPausing = false;
                restChatSendDataForReplay = new Array();
                return;
            }
            
            if( currentReplaySeekIndex != replaySeekIndex ) {
                beginChangeReplayPoint();
                return;
            }
            
            if( (history.length == historyIndex) && (restChatSendDataForReplay.length == 0) ) {
                endPhase();
                return;
            }
            
            ChatWindow.clearDice();
            
            var sleepTime:int = 0;
            
            if( restChatSendDataForReplay.length > 0 ) {
                sleepTime = printRestChatMessage();
            } else {
                var jsonData:Object = history[historyIndex];
                historyIndex++;
                setSlider();
                
                sleepTime = analyzeForReplay(jsonData);
            }
            sleepTime /= replaySpeed;
            
            timeoutId = setTimeout(replayHistory, sleepTime, currentReplaySeekIndex);
        }
        
        private function endPhase():void {
            if( isRepeat() ) {
                setPlayingState( false );
                var startIndex:int = 1;
                changeReplayPoint( startIndex );
            } else {
                Log.printSystemLogPublic(Language.s.stopReplayRecording);
                setPlayingState( false );
            }
        }
        
        private function isRepeat():Boolean {
            return DodontoF_Main.getInstance().getDodontoF().isRepeat.selected;
        }
        
        public function stopTimer():void {
            if( timeoutId == 0 ) {
                return;
            }
            
            clearTimeout(timeoutId);
            timeoutId = 0;
        }
        
        public function changeReplayPoint(point:int):void {
            DodontoF_Main.getInstance().getDodontoF().replaySeekSlider.enabled = false;
            
            replaySeekIndex++;
            
            historyIndex = point;
            
            //再生が停止している場合には、ここで再生を再開する
            if( ! getPlayingState() ) {
                isPausing = false;
                setPlayingState( true );
                beginChangeReplayPoint();
            }
        }
        
        public function beginChangeReplayPoint():void {
            initChatSize();
            DodontoF_Main.getInstance().clearForReplay();
            
            var params:Array = getPiledReplayData();
            var jsonData:Object = params[0];
            var record:Array = params[1];
            
            analyzeForReplay(jsonData);
            
            for each(var data:Object in record) {
                analyzeForReplay(data);
            }
            
            replayHistory(replaySeekIndex)
            DodontoF_Main.getInstance().getDodontoF().replaySeekSlider.enabled = true;
        }
        
        private function getPiledReplayData():Array {
            Log.logging("getPiledReplayData begin");
            
            var resultJsonData:Object = new Object();
            var record:Array = new Array();
            
            for(var i:int = 0 ; i < historyIndex ; i++) {
                var jsonData:Object = history[i];
                
                for(var key:String in jsonData) {
                    var data:Object = jsonData[key];
                    
                    Log.logging("jsonData key", key);
                    Log.logging("jsonData data", data);
                    if( data == null ) {
                        Log.logging("data is null");
                        continue;
                    }
                    
                    if( key == "record") {
                        var recordData:Object = {
                            "lastUpdateTimes" : jsonData.lastUpdateTimes,
                            "record" : data
                        }
                        record.push( recordData );
                        Log.logging("record.push data");
                        continue;
                    }
                    
                    if( key == "characters") {
                        record = new Array();
                        Log.logging("record.clear();");
                    }
                    
                    resultJsonData[key] = data;
                }
            }
            
            Log.logging("getPiledReplayData End record", record);
            
            return [resultJsonData, record];
        }
        
        private function initChatSize():void {
            var fontSize:int = 26;
            var isReplayMode:Boolean = true;
            ChatWindow.getInstance().setChatFontSize(fontSize, isReplayMode);
        }
        
        public function pauseAndPlay():void {
            DodontoF_Main.getInstance().getDodontoF().setPauseAndPlayIconDisable();
            
            //再生中の場合
            if( getPlayingState() ) {
                isPausing = true;
                return;
            }
            
            //停止中の場合
            setPlayingState( true );
            beginChangeReplayPoint();
        }
        
        private function printRestChatMessage():int {
            Log.logging("printRestChatMessage Begin");
            
            var chatSendData:ChatSendData= restChatSendDataForReplay.shift();
            
            var channel:int = chatSendData.getChannel();
            Log.logging("channel",  channel);
            
            if( isIgnoreChannel(channel) ) {
                Log.logging("isIgnoreChannel");
                return 0;
            }
            
            var time:Number = chatSendData.getParamsNumber("time");
            var uniqueId:String = chatSendData.getParamsString("uniqueId");
            Log.logging("time", time);
            Log.logging("uniqueId", uniqueId);
            
            var window:ChatWindow = DodontoF_Main.getInstance().getChatWindow();
            window.clearPublicChatMessageLog();
            window.addMessageToChatLog(chatSendData, time, uniqueId, true);
            
            return getChatSleepTimeFromMessageData(chatSendData);
        }
        
        private function analyzeForReplay(jsonData:Object):int {
            Log.logging("analyzeForReplay jsonData", jsonData);
            
            var reciever:SharedDataReceiver = sender.getReciever();
            var isValidResponse:Boolean = reciever.analyzeRefreshResponseCatchedCallByJsonData(jsonData);
            Log.logging("analyzeForReplay isValidResponse", isValidResponse);
            
            if( isValidResponse ) {
                if( (jsonData.chatMessageDataLog != null) && 
                    (restChatSendDataForReplay.length != 0) ) {
                    Log.logging("analyzeForReplay restChatSendDataForReplay");
                    var chatSendData:ChatSendData = restChatSendDataForReplay[ restChatSendDataForReplay.length - 1 ];
                    return getChatSleepTimeFromMessageData(chatSendData);
                }
                if( isCharacterData(jsonData) ) {
                    Log.logging("analyzeForReplay isCharacterData");
                    return characterSleepTime;
                }
            }
            
            return 0;
        }
        
        private function isCharacterData(jsonData:Object):Boolean {
            if( jsonData.characters != null ) {
                return true;
            }
            if( jsonData.record != null ) {
                return true;
            }
            return false;
        }
        
	}
}

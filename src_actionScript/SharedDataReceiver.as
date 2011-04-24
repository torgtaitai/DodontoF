//--*-coding:utf-8-*--

package {
    
    import com.adobe.serialization.json.JSON;
    import flash.events.Event;
    import flash.events.DataEvent;
    import flash.net.URLLoader;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;
    import mx.collections.ArrayCollection;
    import mx.controls.Alert;
    import mx.rpc.events.ResultEvent;
    
    public class SharedDataReceiver {
        private var sender:SharedDataSender = null;
        private var chatMessageDataLastWrittenTime:Number = 0;
        private var roundTimer:RoundTimer;
        private var fileReferenceForDownload:FileReference = new FileReference();
        private var map:Map = null;
        private var history:Array;
        private var isHistoryOn:Boolean = false;
        
        private static var dodontoF:DodontoF;
        
        public static function setDodontoF(dodontoF_:DodontoF):void {
            dodontoF = dodontoF_;
        }
        
        
        public function SharedDataReceiver():void {
            history = new Array();
        }
        
        public function setSender(sender_:SharedDataSender):void {
            sender = sender_;
        }
        public function setMap(map_:Map):void {
            map = map_;
        }
        
        public function setRoundTimer(roundTimer_:RoundTimer):void {
            roundTimer = roundTimer_;
        }
        
        public function analyzeRefreshResponse(obj:Object):void {
            Log.loggingTuning("==>Begin analyzeRefreshResponse");
            
            if( sender.isStopRefresh() ) {
                Log.logging("analyzeRefreshResponse(event:Event): refresh is stoped, so no analyze.");
                return;
            }
            
            var isValidResponse:Boolean = false;
            var jsonData:Object = null;
            try {
                Log.logging("analyzeRefreshResponse(event:Event):");
                var result:Object = analyzeRefreshResponseCatched(obj);
                isValidResponse = result.isValidResponse;
                jsonData = result.jsonData;
            } catch(e:Error) {
                //FireFox 3.5系でこの応答エラーが頻発する問題があったためエラーログをコメントアウト
                //Log.loggingException("SharedDataReceiver.analyzeRefreshResponse()", e);
            }
            Log.loggingTuning("==>End analyzeRefreshResponse");
            
            if( ! isValidResponse ) {
                return;
            }
            
            if( isHistoryOn ) {
                addHistory(jsonData);
            }
            
            if( sender.clearRetry() ) {
                retryConnectedCount++;
                Log.loggingErrorOnStatus("サーバとの再接続に成功しました。",
                                         "" + retryConnectedCount + "回目");
            }
            
            refreshNext();
        }
        
        private function addHistory(jsonData_original:Object):void {
            var jsonData:Object = Utils.clone(jsonData_original);
            
            delete jsonData.loginUserInfo;
            delete jsonData.refreshIndex;
            delete jsonData.lastUpdateTimes;
            
            Log.logging("history jsonData", jsonData);
            
            if( ! hasKey(jsonData) ) {
                Log.logging("jsonData has NO key.");
                return;
            }
            
            Log.logging("jsonData has key, so push history!!");
            history.push(jsonData);
        }
        
        private function hasKey(params:Object):Boolean {
            for(var key: String in params){
                return true;
            }
            return false;
        }
        
        private var retryConnectedCount:int = 0;
        
        public function clearChatLastWrittenTime():void {
            chatMessageDataLastWrittenTime = 0;
        }
        
        protected function refreshNext():void {
            refresh();
        }
        
        private function refresh():void {
            sender.refresh();
        }
        
        private function analyzeRefreshResponseCatched(obj:Object):Object {
            var jsonData:Object = getJsonDataFromResultEvent(obj);
            var isValidResponse:Boolean = this.analyzeRefreshResponseCatchedCallByJsonData(jsonData);
            
            return {"isValidResponse" : isValidResponse,
                    "jsonData" : jsonData};
        }
        
        public static function getJsonDataFromResultEvent(obj:Object):Object {
            Log.logging("SharedDataReceiver.getJsonDataFromResultEvent begin");
            
            var resultEvent:ResultEvent = obj as ResultEvent;
            if( resultEvent != null ) {
                Log.loggingTuning("result is resultEvent");
                return resultEvent.result;
            }
            
            var event:Event = obj as Event;
            if( event == null ) {
                Log.loggingTuning("result is NOT Event");
                return obj;
            }
            
            Log.loggingTuning("result is Event");
            
            var loader:URLLoader = URLLoader(event.target);
            var jsonString:String = loader.data;
            Log.logging("jsonString", jsonString);
            jsonString = getJsonStringFromEventResultJsonString(jsonString);
            Log.logging("SharedDataReceiver.getJsonDataFromResultEvent jsonString", jsonString);
            
            var jsonData:Object = getJsonDataFromString(jsonString);
            
            Log.logging("SharedDataReceiver.getJsonDataFromResultEvent end");
            return jsonData;
        }
        
        public static function getJsonDataFromDataEvent(dataEvent:DataEvent):Object {
            var jsonString:String = dataEvent.data;
            jsonString = getJsonStringFromEventResultJsonString(jsonString);
            
            var jsonData:Object = getJsonDataFromString(jsonString);
            return jsonData;
        }
        
        static private var regJsonStringResult:RegExp = /#D@EM>#(.*)#<D@EM#/ms;
        
        private static function getJsonStringFromEventResultJsonString(jsonStringOriginal:String):String {
            var textResult:Object = regJsonStringResult.exec(jsonStringOriginal);
            var jsonString:String = textResult[1];
            
            if( jsonString == null ) {
                jsonString = jsonStringOriginal;
            }
            
            return jsonString;
        }
        
        public static function getJsonDataFromString(jsonString:String):Object {
            return Utils.getJsonDataFromString(jsonString);
        }
        
        public function checkValidRefreshResponse(jsonData:Object):Boolean {
            if( jsonData.warning ) {
                var warningMessage:String = Messages.getMessageFromWarningInfo(jsonData.warning);
                Log.loggingFatalError(warningMessage);
                sender.stopRefresh();
                return false;
            }
            
            
            if( jsonData.refreshIndex == null ) {
                Log.loggingError("refreshIndex is null. this is invalid data.");
                return false;
            }
            
            Log.logging("jsonData.refreshIndex", jsonData.refreshIndex);
            if( ! sender.clearLastRefreshIndex(jsonData.refreshIndex) ) {
                Log.loggingTuning("jsonData.refreshIndex is not lastRefreshIndex");
                return false;
            }
            
            if( jsonData.loginUserInfo == null ) {
                Log.loggingError("loginUserInfo is null. this is invalid data.");
                return false;
            }
            
            return true;
        }
        
        public function analyzeRefreshResponseCatchedCallByJsonData(jsonData:Object):Boolean {
            Log.logging("analyzeRefreshResponseCatchedCallByJsonData jsonData", jsonData);
            
            if( jsonData == null ) {
                Log.loggingError("jsonData is null");
                return false;
            }
            
            if( ! DodontoF_Main.getInstance().isReplayMode() ) {
                if( ! checkValidRefreshResponse(jsonData) ) {
                    return false;
                }
                dodontoF.setLoginUserInfo(jsonData.loginUserInfo);
            }
            
            isFirstChatRefreshFlag = jsonData.isFirstChatRefresh;
            
            if( isFirstChatRefreshFlag ) {
                this.chatMessageDataLastWrittenTime = 0;
                sender.clearLastUpdateTimes();
            }
            
            if( jsonData.playRoomName &&
                sender.checkLastUpdateTimes('playRoomInfo', jsonData.lastUpdateTimes) ) {
                this.analyzePlayRoomInfo(jsonData);
            }
            
            if( jsonData.effects &&
                sender.checkLastUpdateTimes('effects', jsonData.lastUpdateTimes) ) {
                this.analyzeEffects(jsonData.effects);
            }
            
            if( jsonData.chatMessageDataLog &&
                sender.checkLastUpdateTimes('chatMessageDataLog', jsonData.lastUpdateTimes) ) {
                Log.logging("analyzeChatMessageDataLog(jsonData.chatMessageDataLog) begin");
                jsonData.chatMessageDataLog = this.analyzeChatMessageDataLog(jsonData.chatMessageDataLog);
                isFirstChatRefreshFlag = false;
            }
            
            Log.logging("jsonData.characters", jsonData.characters);
            Log.logging("jsonData.lastUpdateTimes", jsonData.lastUpdateTimes);
            
            if( jsonData.roundTimeData &&
                sender.checkLastUpdateTimes('time', jsonData.lastUpdateTimes) ) {
                this.analyzeTime(jsonData.roundTimeData);
            }
            
            if( jsonData.characters &&
                sender.checkLastUpdateTimes('characters', jsonData.lastUpdateTimes) ) {
                
                this.analyzeCharacterData(jsonData.characters);
            }
            
            if( jsonData.mapData &&
                sender.checkLastUpdateTimes('map', jsonData.lastUpdateTimes) ) {
                this.analyzeMap(jsonData.mapData);
            }
            
            //リプレイ再生時専用
            if( DodontoF_Main.getInstance().isReplayMode() ) {
                this.analyzeReplayConfig(jsonData.replayConfig);
            }
            
            if( isInitialRefreshFlag && jsonData.chatMessageDataLog ) {
                initForFirstRefresh();
                isInitialRefreshFlag = false;
            }
            
            return true;
        }
        
        private function analyzeReplayConfig(replayConfig:Object):void {
            Log.logging("analyzeReplayConfig replayConfig", replayConfig);
            
            if( replayConfig == null ) {
                return;
            }
            
            Log.logging("analyzeReplayConfig replayConfig.channelNames", replayConfig.channelNames);
            DodontoF_Main.getInstance().getReplay().setActiveChannel(replayConfig.channelNames);
            DodontoF_Main.getInstance().getDodontoF().selectMenuByManuName("isGridVisible", replayConfig.grid);
            DodontoF_Main.getInstance().getDodontoF().selectMenuByManuName("isPositionVisible", replayConfig.position);
        }
        
        private var isFirstChatRefreshFlag:Boolean = true;
        
        public function isFirstChatRefresh():Boolean {
            Log.logging("isFirstChatRefreshFlag", isFirstChatRefreshFlag);
            Log.logging("isInitialRefreshFlag", isInitialRefreshFlag);
            
            return ( isFirstChatRefreshFlag || isInitialRefreshFlag );
        }
        
        private var isInitialRefreshFlag:Boolean = true;
        
        public function initForFirstRefresh():void {
            DodontoF_Main.getInstance().initForFirstRefresh();
        }
        
        
        private function analyzePlayRoomInfo(playRoomInfo:Object):void {
            Log.logging("analyzePlayRoomInfo playRoomInfo", playRoomInfo);
            
            //{"playRoomChangedPassword":null,"chatChannelNames":["雑談","AAA"],"playRoomName":"プレイルーム","canVisit":false}
            DodontoF_Main.getInstance().setPlayRoomInfo( playRoomInfo.playRoomName,
                                                         playRoomInfo.chatChannelNames,
                                                         playRoomInfo.canUseExternalImage,
                                                         playRoomInfo.canVisit);
            
            Log.logging("analyzePlayRoomInfo end");
        }
        
        private function analyzeEffects(effects:Object):void {
            var tmp:ArrayCollection = new ArrayCollection(effects as Array);
            DodontoF_Main.getInstance().setEffects( tmp );
        }
        
        private function analyzeChatMessageDataLog(chatMessageDataLogObj:Object):Object {
            var result:Array = new Array();
            
            var chatMessageDataLog:Array = chatMessageDataLogObj as Array;
            Log.logging("chatMessageDataLog", chatMessageDataLog);
            
            var lastWrittenTime:Number = this.chatMessageDataLastWrittenTime;
            
            for(var i:int = 0 ; i < chatMessageDataLog.length ; i++) {
                var chatMessageDataSet:Object = chatMessageDataLog[i];
                
                var writtenTime:Number = chatMessageDataSet[0];
                var chatMessageData:Object = chatMessageDataSet[1];
                
                if( this.chatMessageDataLastWrittenTime >= writtenTime ) {
                    continue;
                }
                
                Log.logging("this is new chatLog message.");
                
                if( writtenTime > lastWrittenTime ) {
                    lastWrittenTime = writtenTime;
                }
                
                var senderName:String = chatMessageData['senderName'];
                var chatMessage:String = chatMessageData['message'];
                var color:String = chatMessageData['color'];
                var chatSenderUniqueId:String = chatMessageData['uniqueId'];
                var messageIndex:int = chatMessageData['messageIndex'];
                var sendto:String = chatMessageData['sendto'];
                var channel:int = chatMessageData['channel'];
                
                var isValidMessage:Boolean = ChatWindow.getInstance()
                    .addMessageToChatLogParts(channel,
                                              senderName, chatMessage,
                                              color, writtenTime, chatSenderUniqueId,
                                              messageIndex, sendto);
                if( isValidMessage ) {
                    result.push(chatMessageDataSet);
                }
            }
            ChatWindow.getInstance().printAddedMessageToChatMessageLog();
            
            this.chatMessageDataLastWrittenTime = lastWrittenTime;
            
            return result;
        }
        
        private function analyzeMap(mapData:Object):void {
            if( mapData.mapType != "imageGraphic" ) {
                return;
            }
            
            map.changeMap(mapData.imageSource, mapData.xMax, mapData.yMax, mapData.gridColor);
            map.changeMarks(mapData.mapMarks);
        }
        
        
        private function analyzeCharacterData(characterDataList:Object):void {
            Log.loggingTuning("=>Begin analyzeCharacterData");
            Log.logging("analyzeCharacterData characterDataList", characterDataList);
            
            for(var i:int = 0 ; i < characterDataList.length ; i++) {
                var characterData:Object = characterDataList[i];
                Log.logging("characterData is ", characterData);
                
                this.analyzeAddCharacter(characterData);
                Log.loggingTuning("=>analyzeAddCharacter");
                
                this.analyzeMoveCharacter(characterData);
                Log.loggingTuning("=>analyzeMoveCharacter");
                
                this.analyzeChangedCharacter(characterData);
                Log.loggingTuning("=>analyzeChangedCharacter");
            }
            Log.loggingTuning("=>End analyzeCharacterData pre");
            
            Log.loggingTuning("=>Begin analyzeRemoveCharacter");
            this.analyzeRemoveCharacter(characterDataList);
            Log.loggingTuning("=>End analyzeRemoveCharacter");
            
            this.refreshInitiativeList();
            ChatWindow.getInstance().refreshChatCharacterName();
            
            Log.loggingTuning("=>End analyzeCharacterData");
        }
        
        private function analyzeAddCharacter(characterData:Object):void {
            Log.logging("analyzeAddCharacter( characterData)", characterData);
        
            if( map.findExistCharacter(characterData) != null ) {
                Log.logging("character already exist, so pass charactr create");
                return;
            }
            
            Log.logging("existCharacter check end...");
            addCharacterInOwnMap(characterData);
            
            Log.logging("this.existPieces.push( character )");
        }
        
        public function addCharacterInOwnMap(characterData:Object):void {
            Log.logging("SharedDataReceiver.addCharacterInOwnMap() begin");
            var piece:Piece = this.createPieceFromCharacterData(characterData);
            Log.logging("piece", piece);
            
            if( piece == null ) {
                Log.loggingError("invalid Character", JSON.encode(characterData));
                if( characterData.imgId != null ) {
                    sender.removeInvalidCharacter(characterData.imgId);
                    Log.loggingError("不正なデータが含まれていたため自動削除しました。");
                }
                
                return;
            }
            
            Log.logging("characterData", characterData);
            Log.logging("movablePiece addCharacter");
            map.addExistPieces( piece );
            pickupAddedForReplayMode(piece);
            
            Log.logging("SharedDataReceiver.addCharacterInOwnMap() end");
        }
        
        private function pickupAddedForReplayMode(piece:Piece):void {
            if( ! DodontoF_Main.getInstance().isReplayMode() ) {
                return;
            }
            
            var pickupTarget:InitiativedMovablePiece = piece as InitiativedMovablePiece;
            if( pickupTarget == null ) {
                return;
            }
            
            pickupTarget.pickup();
        }
            
        
        public function removeCharacterOnlyOwnMap(event:Event):void {
            var existList:Array = [];
            
            for(var i:int = 0 ; i < map.getExistPiecesCount() ; i++) {
                var piece:Piece = map.getExistPiece(i);
                if( (piece != null ) && piece.isOnlyOwnMap() ) {
                    piece.remove();
                } else {
                    existList.push( piece );
                }
            }
            
            map.setExistPieces(existList);
        }
        
        public function startHistory():void {
            history = new Array();
            isHistoryOn = true;
        }
        
        public function isSessionRecording():Boolean {
            return isHistoryOn;
        }
        
        public function stopHistory():Boolean {
            if( ! isHistoryOn ) {
                return false;
            }
            
            isHistoryOn = false;
            return true;
        }
        
        public function getHistory():Array {
            return history;
        }
        
        private static var pieceClassList:Array = [MagicRange,
                                                   MagicRangeDD4th,
                                                   MapMask,
                                                   MapMarker,
                                                   Memo,
                                                   FloorTile,
                                                   DiceSymbol,
                                                   MagicTimer,
                                                   CardZone,
                                                   Card,
                                                   CardMount,
                                                   RandomDungeonCardMount,
                                                   CardTrushMount,
                                                   RandomDungeonCardTrushMount,
                                                   Character ];
        
        private function createPieceFromCharacterData(characterData:Object):Piece {
            var piece:Piece = null;
            
            for each(var pieceClass:Object in pieceClassList) {
                if( characterData.type == pieceClass.getTypeStatic() ) {
                    piece = new pieceClass(characterData);
                }
            }
            
            if( piece == null ) {
                var message:String = "SharedDataReceiver.createCharacterFromCharacterData Unknown characterData : ";
                Log.loggingError( message + "imgId", characterData.imgId);
                Log.loggingError( message + "type", characterData.type);
                return null;
            }
            
            piece.init(map, characterData.x, characterData.y);
            piece.analyzeChangedCharacter(characterData);
            
            return piece;
        }
        
        
        private function analyzeRemoveCharacter(characterDataList:Object):void {
            var existList:Array = [];
            for(var i:int = 0 ; i < map.getExistPiecesCount() ; i++) {
                var existCharacter:Piece = map.getExistPiece(i);
                Log.logging("analyzeRemoveCharacter existCharacter ", existCharacter);
                
                var exist:Object = findExistCharacterData(characterDataList, existCharacter);
                
                if( exist == null ) {
                    Log.logging("character is NOT exist, so remove", existCharacter);
                    existCharacter.remove();
                } else {
                    Log.logging("existed character", existCharacter);
                    existList.push( existCharacter );
                }
            }
            
            map.setExistPieces(existList);
        }
        
        private function findExistCharacterData(characterDataList:Object, existCharacter:Piece):Object {
            Log.logging("findExistCharacterData start");
            
            for(var i:int = 0 ; i < characterDataList.length ; i++) {
                Log.logging("characterData gettting....");
                var characterData:Object = characterDataList[i];
                Log.logging("characterData get.");
                
                if( characterData.imgId == existCharacter.getId() ) {
                    return characterData;
                }
            }
            
            return null;
        }
        
        private function analyzeMoveCharacter(characterData:Object):void {
            Log.logging("analyzeMoveCharacter characterData", characterData);
            var character:Piece = map.findExistCharacter(characterData);
            Log.logging("moveCharacter character", character);
            
            if( character == null ) {
                Log.logging("target is NOT character.");
                return;
            }
            Log.logging("target is character.");
            
            var isMoved:Boolean = character.move(characterData.x, characterData.y);
            pickupMovedForReplayMode(isMoved, character);
            
            Log.logging("character moved");
        }
        
        private function pickupMovedForReplayMode(isMoved:Boolean, piece:Piece):void {
            if( ! isMoved ) {
                return;
            }
            
            if( ! DodontoF_Main.getInstance().isReplayMode() ) {
                return;
            }
            
            var pickupTarget:InitiativedMovablePiece = piece as InitiativedMovablePiece;
            if( pickupTarget == null ) {
                return;
            }
            
            pickupTarget.pickupToCenter();
        }
        
        private function analyzeChangedCharacter(characterData:Object):void {
            Log.logging("analyzeChangedCharacter start");
            
            var character:Piece = map.findExistCharacter(characterData);
            if( character != null ) {
                Log.logging("SharedDataSender.analyzeChangedCharacter(characterData)", characterData);
                character.analyzeChangedCharacter(characterData);
            }
            Log.logging("analyzeChangedCharacter end");
        }


        private function analyzeTime(roundTimeData:Object):void {
            this.roundTimer.setExistCharacters( map.getExistPieces() );
            this.roundTimer.setCounterNames(roundTimeData.counterNames);
            this.roundTimer.setTime(roundTimeData.round,
                                    roundTimeData.initiative);
            this.refreshInitiativeList();
        }
        
        
        private function refreshInitiativeList():void {
            Log.logging("refreshInitiativeList() begin");
            roundTimer.setExistCharacters( map.getExistPieces() );
            roundTimer.refreshInitiativeList();
            Log.logging("refreshInitiativeList() end");
        }
        

        /*
        public function saveResult(event:Event):void {
            Log.loggingTuning("saveResult begin");
            try {
                var jsonData:Object = getJsonDataFromResultEvent(event);
                Log.loggingError("jsonData", jsonData);
                var saveData:Object = jsonData.saveData;
                Log.loggingError("saveData", saveData);
                var saveDataString:String = JSON.encode(jsonData);
                Log.loggingError("saveDataString", saveDataString);
                
                var fileReferenceForSave:FileReference = new FileReference();
                fileReferenceForSave.addEventListener(Event.COMPLETE, function(event:Event):void {});
                fileReferenceForSave.save(saveDataString, "DodontoF.sav");
            } catch(e:Error) {
                Log.loggingException("SharedDataReceiver.saveResult()", e);
            }
            Log.loggingTuning("saveResult end");
        }
        */

    }
}


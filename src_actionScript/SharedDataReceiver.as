//--*-coding:utf-8-*--

package {
    
    import com.adobe.serialization.json.JSON;
    import flash.events.Event;
    import flash.events.DataEvent;
    import flash.net.URLLoader;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;
    import mx.controls.Alert;
    import mx.rpc.events.ResultEvent;
    
    public class SharedDataReceiver {
        private var sender:SharedDataSender = null;
        private var chatMessageDataLastWrittenTime:Number = 0;
        private var roundTimer:RoundTimer;
        private var fileReferenceForDownload:FileReference = new FileReference();
        private var map:Map = null;
        private static var dodontoF:DodontoF;
        
        public static function setDodontoF(dodontoF_:DodontoF):void {
            dodontoF = dodontoF_;
        }
        
        
        public function SharedDataReceiver():void {
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
            
            RecordHistory.getInstance().addHistory(jsonData);
            
            if( sender.clearRetry() ) {
                retryConnectedCount++;
                Log.loggingErrorOnStatus(Language.s.connectToServerSuccessfully,
                                         Language.text("xTimes", retryConnectedCount));
            }
            
            sender.refreshNext();
        }
        
        private var retryConnectedCount:int = 0;
        
        public function clearChatLastWrittenTime():void {
            chatMessageDataLastWrittenTime = 0;
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
            
            var dataEvent:DataEvent = obj as DataEvent;
            if( dataEvent != null ) {
                Log.loggingTuning("result is DataEvent");
                return getJsonDataFromDataEvent(dataEvent);
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
            
            Log.logging("SharedDataReceiver.getJsonDataFromResultEvent end, jsonData", jsonData);
            
            return jsonData;
        }


        public static function getJsonDataFromDataEvent(dataEvent:DataEvent):Object {
            var jsonString:String = dataEvent.data;
            jsonString = getJsonStringFromEventResultJsonString(jsonString);
            
            var jsonData:Object = getJsonDataFromString(jsonString);
            return jsonData;
        }
        
        static private var regJsonStringResult:RegExp = /#D@EM>#(.*)#<D@EM#/ms;
        
        public static function getJsonStringFromEventResultJsonString(jsonString:String):String {
            Log.logging('getJsonStringFromEventResultJsonString jsonString', jsonString);
            
            var textResult:Object = regJsonStringResult.exec(jsonString);
            Log.logging('textResult', textResult);
            
            if( textResult == null ) {
                return jsonString;
            }
            
            var matchedJsonString:String = textResult[1];
            if( matchedJsonString == null ) {
                return jsonString;
            }
            
            Log.logging('matchedJsonString', matchedJsonString);
            return matchedJsonString;
        }
        
        public static function getJsonDataFromString(jsonString:String):Object {
            return Utils.getJsonDataFromString(jsonString);
        }
        
        public function checkValidRefreshResponse(jsonData:Object):Boolean {
            var warningMessage:String = getRefreshResponseWarning(jsonData);
            if( warningMessage != "" ) {
                ChatWindow.getInstance().addLocalMessage(warningMessage);
                Alert.show(warningMessage);
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
        
        private function getRefreshResponseWarning(jsonData:Object):String {
            if( jsonData.warning == null ) {
                return getTimeLimitMessage();
            }
            
            var warningMessage:String = Messages.getMessageFromWarningInfo(jsonData.warning);
            return warningMessage;
        }
        
        private var timeLimit:Date;
        
        private function getTimeLimitMessage():String {
            var limitSecond:int = DodontoF_Main.getInstance().getLoginTimeLimitSecond();
            
            if( limitSecond <= 0 ) {
                return "";
            }
            
            if( timeLimit == null ) {
                timeLimit = new Date();
                var limitMilliSecond:Number = timeLimit.getTime() + limitSecond * 1000;
                timeLimit.setTime(limitMilliSecond);
            }
            
            var lastMilliSecond:Number = timeLimit.getTime() - new Date().getTime();
            if( lastMilliSecond > 0 ) {
                //Log.logging("lastSecond", lastMilliSecond / 1000);
                return "";
            }
            
            return Messages.getMessage("loginTimeLimitHasComes", [limitSecond]);
        }
        
        
        public function analyzeRefreshResponseCatchedCallByJsonData(jsonData:Object):Boolean {
            Log.logging("analyzeRefreshResponseCatchedCallByJsonData Begin jsonData", jsonData);
            
            if( jsonData == null ) {
                //Log.loggingError("jsonData is null");
                return false;
            }
            
            
            if( ! DodontoF_Main.getInstance().isReplayMode() ) {
                if( jsonData.lastUpdateTimes == null ) {
                    Log.logging("lastUpdateTimes is null, this is empty response data.");
                    return true;
                }
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
                jsonData.chatMessageDataLog = this.analyzeChatMessageDataLog(jsonData.chatMessageDataLog);
                isFirstChatRefreshFlag = false;
            }
            
            Log.logging("jsonData.characters", jsonData.characters);
            Log.logging("jsonData.lastUpdateTimes", jsonData.lastUpdateTimes);
            
            if( sender.checkLastUpdateTimes('time', jsonData.lastUpdateTimes) ) {
                analyzeTime(jsonData);
            }
            
            if( jsonData.characters &&
                sender.checkLastUpdateTimes('characters', jsonData.lastUpdateTimes) ) {
                
                this.analyzeCharacterData(jsonData.characters);
                sender.checkLastUpdateTimes('record', jsonData.lastUpdateTimes);
                sender.checkLastUpdateTimes('recordIndex', jsonData.lastUpdateTimes);
            }
            
            if( jsonData.record &&
                sender.checkLastUpdateTimes('record', jsonData.lastUpdateTimes) ) {
                
                sender.checkLastUpdateTimes('characters', jsonData.lastUpdateTimes);
                sender.checkLastUpdateTimes('recordIndex', jsonData.lastUpdateTimes);
                
                this.analyzeRecordData(jsonData.record);
                Log.logging("on jsonData.record jsonData.lastUpdateTimes", jsonData.lastUpdateTimes);
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
            
            Log.logging("jsonData.lastUpdateTimes", jsonData.lastUpdateTimes);
            
            return true;
        }
        
        private var isFirstReplayConfigCheck:Boolean = true;
        
        private function analyzeReplayConfig(replayConfig:Object):void {
            Log.logging("analyzeReplayConfig replayConfig", replayConfig);
            
            if( isFirstReplayConfigCheck ) {
                selectMenuByManuName("isDiceVisible", true, true);
                isFirstReplayConfigCheck = false;
            }
            
            if( replayConfig == null ) {
                return;
            }
            
            Log.logging("analyzeReplayConfig replayConfig.channelNames", replayConfig.channelNames);
            DodontoF_Main.getInstance().getReplay().setActiveChannel(replayConfig.channelNames);
            selectMenuByManuName("isGridVisible", replayConfig.grid, true);
            selectMenuByManuName("isPositionVisible", replayConfig.position, true);
            selectMenuByManuName("isDiceVisible", replayConfig.dice, true);
            selectMenuByManuName("isAdjustImageSize", replayConfig.adjustStand, true);
            
            var chatWindow:ChatWindow = DodontoF_Main.getInstance().getChatWindow();
            chatWindow.setSoundState( getToggledValue(replayConfig.sound, true) );
            
            ChatWindow.getInstance().setChatBackgroundColor(replayConfig.chatBackgroundColor);
        }
        
        
        public function selectMenuByManuName(menuName:String, toggledObject:Object, defaultValue:Boolean):void {
            var toggled:Boolean = getToggledValue(toggledObject, defaultValue);
            DodontoF_Main.getInstance().getDodontoF().selectMenuByManuName(menuName, toggled);
        }

        private function getToggledValue(toggledObject:Object, defaultValue:Boolean):Boolean {
            var toggled:Boolean = toggledObject as Boolean;
            
            if( toggledObject == null ) {
                toggled = defaultValue;
            }
            return toggled;
        }
            
        
        private var isFirstChatRefreshFlag:Boolean = true;
        
        public function isFirstChatRefresh():Boolean {
            Log.logging("isFirstChatRefreshFlag", isFirstChatRefreshFlag);
            Log.logging("isInitialRefreshFlag", isInitialRefreshFlag);
            
            return ( isFirstChatRefreshFlag || isInitialRefreshFlag );
        }
        
        private var isInitialRefreshFlag:Boolean = true;
        
        public function isInitialRefresh():Boolean {
            return isInitialRefreshFlag;
        }
        
        public function initForFirstRefresh():void {
            DodontoF_Main.getInstance().initForFirstRefresh();
        }
        
        
        private function analyzePlayRoomInfo(playRoomInfo:Object):void {
            Log.logging("analyzePlayRoomInfo playRoomInfo", playRoomInfo);
            
            //{"playRoomChangedPassword":null,"chatChannelNames":["雑談","AAA"],"playRoomName":"プレイルーム","canVisit":false}
            DodontoF_Main.getInstance().setPlayRoomInfo( playRoomInfo.playRoomName,
                                                         playRoomInfo.chatChannelNames,
                                                         playRoomInfo.canUseExternalImage,
                                                         playRoomInfo.canVisit,
                                                         playRoomInfo.backgroundImage,
                                                         playRoomInfo.gameType,
                                                         playRoomInfo.viewStateInfo);
            
            Log.logging("analyzePlayRoomInfo end");
        }
        
        private function analyzeEffects(effects:Object):void {
            var tmp:Array = effects as Array;
            DodontoF_Main.getInstance().setEffects( tmp );
        }
        
        private function analyzeChatMessageDataLog(chatMessageDataLogObj:Object):Object {
            Log.logging("analyzeChatMessageDataLog() Begin", chatMessageDataLogObj);
            
            var result:Array = new Array();
            
            var chatMessageDataLog:Array = chatMessageDataLogObj as Array;
            
            var lastWrittenTime:Number = this.chatMessageDataLastWrittenTime;
            
            for(var i:int = 0 ; i < chatMessageDataLog.length ; i++) {
                
                var chatMessageDataSet:Object = chatMessageDataLog[i];
                Log.logging("chatMessageDataSet", chatMessageDataSet);
                
                var writtenTime:Number = chatMessageDataSet[0];
                var chatMessageData:Object = chatMessageDataSet[1];
                
                if( this.chatMessageDataLastWrittenTime >= writtenTime ) {
                    Log.logging("chatMessage is NOT new");
                    continue;
                }
                
                Log.logging("this is new chatLog message.");
                
                if( writtenTime > lastWrittenTime ) {
                    lastWrittenTime = writtenTime;
                    Log.logging("lastWrittenTime", lastWrittenTime);
                }
                
                var senderName:String = chatMessageData['senderName'];
                var chatMessage:String = chatMessageData['message'];
                var color:String = chatMessageData['color'];
                var chatSenderUniqueId:String = chatMessageData['uniqueId'];
                var sendto:String = chatMessageData['sendto'];
                var sendtoName:String = chatMessageData['sendtoName'];
                var channel:int = chatMessageData['channel'];
                
                var data:ChatSendData = new ChatSendData(channel, chatMessage);
                data.setNameAndState(senderName);
                data.setColorString(color);
                data.setSendto(sendto, sendtoName);
                
                var isValidMessage:Boolean = ChatWindow.getInstance()
                    .addMessageToChatLogParts(data, writtenTime, chatSenderUniqueId);
                Log.logging("addMessageToChatLogParts result", isValidMessage);
                
                if( isValidMessage ) {
                    Log.logging("isValidMessage");
                    result.push(chatMessageDataSet);
                }
            }
            ChatWindow.getInstance().printAddedMessageToChatMessageLog();
            
            this.chatMessageDataLastWrittenTime = lastWrittenTime;
            
            return result;
        }
        
        private function analyzeMap(mapData:Object):void {
            Log.logging("analyzeMap Begin");
            if( mapData.mapType != "imageGraphic" ) {
                return;
            }
            
            map.changeMap(mapData.imageSource, mapData.mirrored,
                          mapData.xMax, mapData.yMax,
                          mapData.gridColor, mapData.gridInterval, mapData.isAlternately);
            map.changeMarks(mapData.mapMarks, mapData.mapMarksAlpha);
			Log.logging("mapData.drawsImage", mapData.drawsImage);
            map.changeDraws(mapData.draws, mapData.drawsImage);
            
            Log.logging("analyzeMap End");
        }
        
        
        private function analyzeCharacterData(characterDataList:Object):void {
            Log.loggingTuning("=>Begin analyzeCharacterData");
            Log.logging("analyzeCharacterData characterDataList", characterDataList);
            
            characterDataList = getCharacterDataList(characterDataList);
            
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
            Log.loggingTuning("analyzeCharacterData for loop end");
            
            Log.loggingTuning("=>Begin analyzeRemoveCharacter");
            this.analyzeRemoveCharacter(characterDataList);
            Log.loggingTuning("=>End analyzeRemoveCharacter");
            
            this.refreshInitiativeList();
            ChatWindow.getInstance().refreshChatCharacterName();
            
            Log.loggingTuning("=>End analyzeCharacterData");
        }
        
        private function getCharacterDataList(characterDataList:Object):Object {
            if( ! isNeedChangeCharacterData() ) {
                return characterDataList;
            }
            
            for(var i:int = 0 ; i < characterDataList.length ; i++) {
                characterDataList[i] = 
                    SharedDataReceiver.getJsonDataFromString(characterDataList[i]);
            }
            
            return characterDataList;
        }
        
        private function isNeedChangeCharacterData():Boolean {
            if( DodontoF_Main.getInstance().isSQLiteMode() ) {
                return true;
            }
            if( DodontoF_Main.getInstance().isMySqlKaiMode() ) {
                return true;
            }
            
            return false;
        }
        
        private function analyzeAddCharacters(list:Array):void {
            for each(var data:Object in list) {
                analyzeAddCharacter(data);
            }
        }
        
        private function analyzeAddCharacter(characterData:Object):void {
            var found:Piece = map.findExistCharacter(characterData);
            if( found != null ) {
                Log.logging("character already exist, so pass charactr create");
                return;
            }
            
            Log.logging("existCharacter check end...");
            addCharacterInOwnMap(characterData);
            
            Log.logging("this.existPieces.push( character )");
        }
        
        public function addCharacterInOwnMap(characterData:Object):void {
            Log.logging("SharedDataReceiver.addCharacterInOwnMap() begin");
            var piece:Piece = this.addNewCharacterToMap(characterData);
            Log.logging("piece", piece);
            
            if( piece == null ) {
                Log.loggingError("invalid Character", JSON.encode(characterData));
                if( characterData.imgId != null ) {
                    sender.removeInvalidCharacter(characterData.imgId);
                    Log.loggingError(Language.s.deleteInvalidDataAutomatically);
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
        
        
        public function removeCharacterOnlyOwnMap(event:Event = null):void {
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
        
        
        
        private function analyzeRecordData(record:Object):void {
            Log.loggingTuning("=>Begin analyzeRecordData");
            Log.logging("record", record);
            
            for(var i:int = 0 ; i < record.length ; i++) {
                var recordData:Object = record[i];
                Log.logging("recordData", recordData);
                
                var command:String = recordData[1];
                var data:Array = recordData[2];
                Log.loggingTuning("command", command);
                Log.loggingTuning("data", data);
                
                if( command == "addCharacter" ) {
                    this.analyzeAddCharacters(data);
                    Log.loggingTuning("=>analyzeAddCharacter");
                } else if( command == "changeCharacter" ) {
                    this.analyzeMoveCharacters(data);
                    Log.loggingTuning("=>analyzeMoveCharacter");
                    this.analyzeChangedCharacters(data);
                    Log.loggingTuning("=>analyzeChangedCharacter");
                } else if( command == "removeCharacter" ) {
                    this.analyzeRemoveCharacterForRecord(data);
                }
            }
            Log.loggingTuning("analyzeRecordData for loop end");
            
            this.removeCharacterOnlyOwnMap();
            this.refreshInitiativeList();
            ChatWindow.getInstance().refreshChatCharacterName();
            
            Log.loggingTuning("=>End analyzeRecordData");
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
                                                   Chit,
                                                   Card,
                                                   CardMount,
                                                   RandomDungeonCardMount,
                                                   CardTrushMount,
                                                   RandomDungeonCardTrushMount,
                                                   MetallicGuardianDamageRange,
                                                   LogHorizonRange,
                                                   Character ];
        
        static public function createPieceFromCharacterData(characterData:Object):Piece {
            for each(var pieceClass:Object in pieceClassList) {
                if( characterData.type == pieceClass.getTypeStatic() ) {
                    return new pieceClass(characterData);
                }
            }
            
            return null;
        }
        
        
        private function addNewCharacterToMap(characterData:Object):Piece {
            var piece:Piece = createPieceFromCharacterData(characterData);
            
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
        
        
        private function analyzeRemoveCharacterForRecord(removeIds:Object):void {
            Log.logging("analyzeRemoveCharacterForRecord Begin removeIds", removeIds);
            
            for each(var removeId:String in removeIds) {
                removeCharacterFromMap(removeId);
            }
            
            Log.logging("analyzeRemoveCharacterForRecord End");
        }
        
        private function removeCharacterFromMap(removeId:String):void {
            for(var i:int = 0 ; i < map.getExistPiecesCount() ; i++) {
                var existCharacter:MovablePiece = map.getExistPiece(i) as MovablePiece;
                Log.logging("removeCharacterFromMap existCharacter ", existCharacter);
                
                if( existCharacter == null ) {
                    continue;
                }
                
                if( removeId == existCharacter.getId() ) {
                    existCharacter.deleteFromMap();
                    return;
                }
            }
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
        
        private function analyzeMoveCharacters(list:Array):void {
            for each(var data:Object in list) {
                analyzeMoveCharacter(data);
            }
        }
        
        private function analyzeMoveCharacter(characterData:Object):void {
            Log.logging("analyzeMoveCharacter Begin characterData", characterData);
            var character:Piece = map.findExistCharacter(characterData);
            Log.logging("moveCharacter character", character);
            
            if( character == null ) {
                Log.logging("target is NOT character.");
                return;
            }
            Log.logging("target is character.");
            
            var isMoved:Boolean = character.move(characterData.x, characterData.y);
            pickupMovedForReplayMode(isMoved, character);
            
            Log.logging("analyzeMoveCharacter End");
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
        
        private function analyzeChangedCharacters(list:Array):void {
            for each(var data:Object in list) {
                analyzeChangedCharacter(data);
            }
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


        private function analyzeTime(jsonData:Object):void {
            if( jsonData.roundTimeData ) {
                analyzeRoundTimeData(jsonData.roundTimeData);
            }
            if( jsonData.resource ) {
                analyzeResource(jsonData.resource);
            }
        }
        
        private function analyzeRoundTimeData(roundTimeData:Object):void {
            this.roundTimer.setExistCharacters( map.getExistPieces() );
            this.roundTimer.setCounterNames(roundTimeData.counterNames);
            this.roundTimer.setTime(roundTimeData.round,
                                    roundTimeData.initiative);
            this.refreshInitiativeList();
        }
        
        private function analyzeResource(resource:Object):void {
            ResourceWindow.getInstance().setResourceList(resource as Array);
        }
        
        
        private function refreshInitiativeList():void {
            Log.logging("refreshInitiativeList() begin");
            roundTimer.setExistCharacters( map.getExistPieces() );
            roundTimer.refreshInitiativeList();
            Log.logging("refreshInitiativeList() end");
        }
        
    }
}


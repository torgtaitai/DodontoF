//--*-coding:utf-8-*--

package {
    
    import com.adobe.serialization.json.JSON;
    import flash.events.Event;
    import flash.events.SecurityErrorEvent;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.FileFilter;
    import flash.net.FileReference;
    import flash.net.sendToURL;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.*;
    import mx.controls.Alert;
    import flash.geom.Point;
    import flash.events.DataEvent;
    import mx.utils.UIDUtil;
    import flash.events.TimerEvent;
    
    
    public class SharedDataSender {
        
        protected var loadParams:Object = null;
        
        private var uniqueId:String = "";
        
        private var strictlyUniqueId:String = createUniqueString();
        
        protected var refreshTimeoutSecond:int = 10;
        protected var refreshTimeoutPadding:int = 10;
        protected var refreshIntervalFirstPaddingSecond:Number = 5;
        protected var refreshIntervalSecond:Number = 1.5;
        protected var retryWaitSeconds:int = 1;
        
        
        private var thisObj:SharedDataSender = null;
        protected var map:Map = null;
        protected var saveDataDirIndex:int = -1;
        
        protected var lastUpdateTimes:Object = getInitLastUpdateTimes();
        protected var receiver:SharedDataReceiver = newReceiverForInitialize();
        protected var refreshLoader:URLLoader = null;
        protected var refreshIndex:int = 0;
        
        
        public function SharedDataSender() {
            thisObj = this;
            receiver.setSender(this);
        }
        
        public function setUniqueId(uniqueId_:String):void {
            this.uniqueId = uniqueId_;
        }
        
        public function getUniqueId():String {
            return this.uniqueId;
        }
        
        private var uniqueIdSeparator:String = "\t";
        
        public function getUniqueIdFromStrictlyUniqueId(strictlyUniqueId:String):String {
            var parats:Array = strictlyUniqueId.split(uniqueIdSeparator);
            return parats[0];
        }
        
        public function getStrictlyUniqueIdForRefresh():Array {
            return [Number(uniqueId), Number(strictlyUniqueId)];
        }
        
        public function getStrictlyUniqueId():String {
            return this.uniqueId + uniqueIdSeparator + this.strictlyUniqueId;
        }
        
        public function isOwnStrictlyUniqueId(targetStrictlyId:String):Boolean {
            return ( targetStrictlyId == getStrictlyUniqueId() );
        }
        
        public function isOwnUniqueIdByStrictlyId(targetStrictlyId:String):Boolean {
            var targetId:String = getUniqueIdFromStrictlyUniqueId(targetStrictlyId);
            return ( targetId == this.uniqueId );
        }
        
        public function setRefreshTimeout(timeout:Number):void {
            this.refreshTimeoutSecond = timeout;
        }
        
        public function setRefreshInterval(value:Number):void {
            this.refreshIntervalSecond = value;
        }
        
        public function setMap(map_:Map):void {
            map = map_;
            receiver.setMap(map);
        }
        
        public function getMap():Map {
            return map;
        }
        
        public function getReciever():SharedDataReceiver {
            return receiver;
        }
        
        public function getRoomNumber():int {
            return saveDataDirIndex;
        }
        
        public function setSaveDataDirIndex(roomNumber:int):void {
            saveDataDirIndex = roomNumber;
        }
        
        public function checkRoomStatus(roomNumber:int, adminPassword:String, resultFunction:Function):void {
            var data:Object = {
                "roomNumber" : roomNumber,
                "adminPassword" : adminPassword
            };
            var obj:Object = getParamObject("checkRoomStatus", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function loginPassword(roomNumber:int, password:String,
                                      visiterMode:Boolean, resultFunction:Function):void {
            Log.logging("SharedDataSender.login");
            var data:Object = {
                "roomNumber" : roomNumber,
                "password" : password,
                "visiterMode" : visiterMode
            };
            
            var obj:Object = getParamObject("loginPassword", data);
            sendCommandData(obj, resultFunction);
        }
        
        protected var saveFileExtension:String = "sav";
        protected var mapSaveFileExtension:String = "msv";
        
        protected var fileReferenceForSaveDownload:FileReference;
        
        public function saveFileDownload(saveFileName:String, resultFunction:Function):void {
            
            fileReferenceForSaveDownload = new FileReference();
            fileReferenceForSaveDownload.addEventListener(Event.COMPLETE,
                                                      function(event:Event):void {
                                                          resultFunction();
                                                      });
            
            saveFileName = Config.getInstance().getUrlString(saveFileName);
            var request:URLRequest = new URLRequest(saveFileName);
            fileReferenceForSaveDownload.download(request);
        }
        
        public function saveAllData(chatPaletteData:String, resultFunction:Function):void {
            var data:Object = {
                "chatPaletteData": chatPaletteData,
                "baseUrl": Utils.getOwnBaseUrl() };
            
            var obj:Object = getParamObject("saveAllData",  data);
            sendCommandData(obj, resultFunction);
        }
        
        public function save(resultFunction:Function):void {
            var obj:Object = getParamObject("save")
            sendCommandData(obj, resultFunction);
        }
        
        public function saveMap(resultFunction:Function):void {
            var obj:Object = getParamObject("saveMap")
            sendCommandData(obj, resultFunction);
        }
        
        public function load(params:Object, resultFunction:Function):void {
            loadSelectFile(params, saveFileExtension, resultFunction);
        }
        
        public function loadMap(params:Object):void {
            loadSelectFile(params, mapSaveFileExtension);
        }
        
        protected function loadSelectFile(params:Object, extension:String, resultFunction:Function = null):void {
            loadParams = params;
            
            var fileReferenceForUpload:FileReference = new FileReference();
            var commandName:String = "load";
            fileReferenceForUpload.addEventListener(Event.SELECT,
                                                    getFileSelectHandlerForLoad(commandName, resultFunction));
            
            var filters:Array = new Array();
            filters.push(new FileFilter(Language.text("saveDataFilter", extension), "*." + extension));
            
            fileReferenceForUpload.browse(filters);
        }
        
        
        protected function getFileSelectHandlerForLoad(commandName:String, resultFunction:Function = null):Function {
            return function(event:Event):void {
                var fileReference:FileReference = event.currentTarget as FileReference;
                if( fileReference == null ) {
                    return;
                }
                
                thisObj.sendFileBytesUpload(fileReference, commandName, thisObj.loadParams, resultFunction);
            }
        }
        
        private var allSaveDataFileExtensions:String = "*.tgz;*.tar.gz";
        
        public function loadAllSaveData():void {
            Log.loggingTuning("loadAllSaveData begin");
            loadParams = new Object();
            
            var commandName:String = "loadAllSaveData";
            
            var fileReference:FileReference = new FileReference();
            
            fileReference.addEventListener(Event.SELECT,
                                           getFileSelectHandlerForLoad(commandName, analyzeLoadAllSaveDataResult));
            
            var filters:Array = new Array();
            filters.push( new FileFilter(Language.text("allSaveDataFilter", allSaveDataFileExtensions),
                                         allSaveDataFileExtensions) );
            
            fileReference.browse(filters);
            Log.loggingTuning("loadAllSaveData end");
        }
        
        
        public function analyzeLoadAllSaveDataResult(obj:Object):void {
            Log.loggingTuning('analyzeLoadAllSaveDataResult Begin');
            
            var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(obj);
            Log.loggingTuning('allSaveData jsonData', jsonData);
            
            if( jsonData.resultText != 'OK' ) {
                var message:String = Language.getKeywordText( jsonData.resultText );
                Log.loggingError( Language.s.loadAllSaveDataError + message );
                return;
            }
            
            DodontoF_Main.getInstance().getChatPaletteWindow().loadFromText( jsonData.chatPaletteSaveData );
            Utils.sendSystemMessage(Language.s.loadAllSaveDataSuccessfully);
            
            //ダイスボットの情報を取得します。
            //これでダイスボットの表情報をリロードして使用できるようにします。
            DodontoF_Main.getInstance().getGuiInputSender().getSender().getDiceBotInfos();
        }
        
        
        
        
        public function requestReplayDataList(resultFunction:Function):void {
            Log.logging("SharedDataSender.requestReplayDataList Begin");
            
            var data:Object = {
                //特にデータなし
            };
            
            var obj:Object = getParamObject("requestReplayDataList", data);
            sendCommandData(obj, resultFunction);
            
            Log.logging("SharedDataSender.requestReplayDataList End");
        }
        
        public function sendFileBytesUpload(fileReference:FileReference,
                                            commandName:String,
                                            data:Object = null,
                                            resultFunction:Function = null):void {
            fileReference.addEventListener(Event.COMPLETE,
                                           getSendFileBytesUpload(fileReference, commandName, data, resultFunction));
            fileReference.load();
        }
        
        public function getSendFileBytesUpload(fileReference:FileReference,
                                               commandName:String,
                                               data:Object = null,
                                               resultFunction:Function = null):Function {
            return function(e:Event):void {
                if( data == null ) {
                    data = new Object();
                }
                
                data["fileData"] = fileReference.data;
                data["fileName"] = fileReference.name;
                
                var obj:Object = getParamObject(commandName, data);
                sendCommandData(obj, resultFunction);
            }
        }
        
        public function uploadImageData(params:Object, resultFunction:Function, errorFunction:Function):void {
            Log.loggingTuning("SharedDataSenderBody.uploadImageData Begin");
            
            var obj:Object = getParamObject("uploadImageData", params);
            sendCommandData(obj, resultFunction, errorFunction);
            
            Log.loggingTuning("SharedDataSenderBody.uploadImageData End");
        }
        
        public function checkLastUpdateTimes(type:String, lastUpdateTimes:Object):Boolean {
            Log.logging("checkLastUpdateTimes begin.");
            Log.logging("checkLastUpdateTimes type", type);
            
            if( isReplayMode() ) {
                return true;
            }
            
            if( lastUpdateTimes == null ) {
                return false;
            }
            
            var timeValue:Number = lastUpdateTimes[type];
            Log.logging("timeValue", timeValue);
            
            if( this.lastUpdateTimes[type] > timeValue ) {
                return false;
            }
            
            this.lastUpdateTimes[type] = timeValue;
            return true;
        }
        
        public function resurrectCharacter(resurrectCharacterId:String, resultFunction:Function):void {
            var data:Object = {"imgId" : resurrectCharacterId};
            var obj:Object = getParamObject("resurrectCharacter", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function sendRoundTimeData(round:int, initiative:Number, counterNames:Array):void {
            var data:Object = {"round": round,
                                   "initiative": initiative,
                                   "counterNames": counterNames};
            var obj:Object = getParamObject("changeRoundTime", data);
            sendCommandData(obj);
        }
        
        
        public function startRefresh():void {
            refresh();
            startRefreshCheckTimer();
        }
        
        protected function startRefreshCheckTimer():void {
			if( isCommet() ) {
                refreshTimerId = startRefreshCheckTimerForCommet();
			} else {
                refreshTimerId = startRefreshCheckTimerForNotCommet();
            }
        }
        
        private var refreshTimerId:uint = 0;
        
        protected function startRefreshCheckTimerForCommet():uint {
            var timeoutMilliSecond:int = (refreshTimeoutSecond + refreshTimeoutPadding) * 1000;
            return setInterval(completeRefreshCheckTimer, timeoutMilliSecond);
        }
        
        private function startRefreshCheckTimerForNotCommet():uint {
            var timeoutMilliSecond:int = refreshIntervalSecond * 1000;
            Log.loggingTuning("refresh setInterval timeoutMilliSecond", timeoutMilliSecond);
            
            return setInterval(refresh, timeoutMilliSecond);
        }
        
        protected var preRefreshIndex:int = 0;
        
        protected function completeRefreshCheckTimer():void {
            if( preRefreshIndex != refreshIndex ) {
                preRefreshIndex = refreshIndex;
                Log.loggingTuning("refresh has NO problem.");
                return;
            }
            
            Log.loggingTuning("refresh is NOT get response. do refresh automaticaly");
            retryRefresh();
        }
        
        protected function retryRefresh():void {
            Log.loggingErrorOnStatus(Language.s.connectToServerErrorAndReconnect);
            
            isRetry = true;
            
            //接続断が発生したので一旦履歴をクリアーに。
            clearRecord();
            
            if( refreshLoader != null ) {
                closeRefreshLoader();
            }
            
            setTimeout(function():void {
                    Log.loggingErrorOnStatus(Language.s.reconnectingToServer);
                    thisObj.refresh();
                },  (retryWaitSeconds * 1000));
        }
        
        protected var isRetry:Boolean = false;
        
        public function clearRetry():Boolean {
            if( ! isRetry ) {
                return false;
            }
            
            isRetry = false;
            return true;
        }
        
        protected var isStopRefreshOn:Boolean = false;
        
        public function stopRefresh():void {
            isStopRefreshOn = true;
            
            if( refreshTimerId != 0 ) {
                clearInterval( refreshTimerId );
                refreshTimerId = 0;
            }
        }
        
        public function isStopRefresh():Boolean {
            return isStopRefreshOn;
        }
        
        public function logout():void {
            stopRefresh();
            
            var data:Object = {
                "uniqueId": uniqueId};
            
            var obj:Object = getParamObject("logout", data);
            sendCommandData(obj);
        }
        
        private function inclimentRefreshIndex():void {
            refreshIndex++;
        }
        
        private var isCommetMode:Boolean = false;
        
        private function isCommet():Boolean {
            return isCommetMode;
        }
        
        public function setCommet(b:Boolean):void {
            isCommetMode = b;
            Log.loggingTuning("isCommetMode", isCommetMode);
        }
        
        
        public function refreshNext():void {
            inclimentRefreshIndex();
            
			if( isCommet() ) {
                refresh();
            }
        }
        
        public function refresh(obj:Object = null):void {
            if( isStopRefreshOn ) {
                return;
            }
			
            var userName:String = getUserName();
            
            var data:Object = {
                "times": this.lastUpdateTimes,
                "rIndex": this.refreshIndex,
                "name": userName
            };
            
            if( DodontoF_Main.getInstance().isVisiterMode() ) {
                data["isVisiter"] = true;
            }
            
            if( RecordHistory.getInstance().isRecording() ) {
                data["isGetOwnRecord"] = true;
            }
            
            if( DodontoF_Main.getInstance().getMentenanceModeOn() ) {
                data.uniqueId = -1;
            }
            
            var obj:Object = getParamObject("refresh", data);
            Log.logging("refreshData obj", obj);
            
            var isRefresh:Boolean = true;
            sendCommandData(obj, receiver.analyzeRefreshResponse, null, isRefresh);
        }
        
        protected function getUserName():String {
            var userName:String = "";
            
            try {
                userName = ChatWindow.getInstance().getChatCharacterName();
            } catch (error:Error) {
            }
            
            return userName;
        }
        
        protected function isReplayMode():Boolean {
            return DodontoF_Main.getInstance().isReplayMode();
        }
        
        public function clearLastRefreshIndex(index:int):Boolean {
            if( isReplayMode() ) {
                return true;
            }
            
            if( this.refreshIndex != index ) {
                return false;
            }
            
            return true;
        }
        
        public function changeMap(mapImageUrl:String, 
                                  mirrored:Boolean,
                                  mapWidth:int,
                                  mapHeight:int, 
                                  gridColor:uint,
                                  gridInterval:int,
                                  isAlternately:Boolean,
                                  mapMarks:Array,
                                  mapMarksAlpha:Number):void {
            var data:Object = {
                "mapType": "imageGraphic",
                "imageSource": mapImageUrl,
                "mirrored": mirrored,
                "xMax": mapWidth,
                "yMax": mapHeight,
                "gridColor": gridColor,
                "gridInterval": gridInterval,
                "isAlternately": isAlternately,
                "mapMarks": mapMarks,
                "mapMarksAlpha": mapMarksAlpha};
            
            var obj:Object = getParamObject("changeMap", data);
            sendCommandData(obj);
        }
        
        public function drawOnMap(array:Array):void {
            var data:Object = {
                "data" : array
            }
            var obj:Object = getParamObject("drawOnMap", data);
            
            sendCommandData(obj);
            Log.logging("drawLineOnMap End");
        }
        
        public function convertDrawToImage(fileData:Object):void {
            var data:Object = {
                "tagInfo" : {"roomNumber": saveDataDirIndex},
				"fileData" : fileData
            };
            var obj:Object = getParamObject("convertDrawToImage", data);
            
            sendCommandData(obj);
        }
        
        public function clearDrawOnMap():void {
            var data:Object = {
            }
            var obj:Object = getParamObject("clearDrawOnMap", data);
            
            sendCommandData(obj);
        }
        
        public function undoDrawOnMap(resultFunction:Function):void {
            var data:Object = {
            }
            var obj:Object = getParamObject("undoDrawOnMap", data);
            
            sendCommandData(obj, resultFunction);
        }
        
        
        public function deleteImage(imageUrlList:Array,
                                    resultFunction:Function):void {
            var data:Object = {
                "imageUrlList": imageUrlList
            };
            var obj:Object = getParamObject("deleteImage", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function addCardRankerCard(imageName:String, imageNameBack:String, x:int, y:int):void {
            var data:Object = {
                "isText" : false,
                "imageName" : imageName,
                "imageNameBack" : imageNameBack,
                "mountName" : "CardRanker",
                "isUpDown" : false,
                "canDelete" : true,
                "x" : x,
                "y" : y,
                "isBack" : false,
                "isOpen" : true
            };
            var obj:Object = getParamObject("addCard", data);
            sendCommandData(obj);
        }
        
        public function addMessageCard(imageName:String, imageNameBack:String, x:int, y:int):void {
            var data:Object = {
                "isText" : true,
                "imageName" : imageName,
                "imageNameBack" : imageNameBack,
                "mountName" : "messageCard",
                "isUpDown" : false,
                "canDelete" : true,
                "canRewrite": true,
                "x" : x,
                "y" : y
            };
            
            addCard(data);
        }
        
        public function addCard(data:Object):void {
            var obj:Object = getParamObject("addCard", data);
            sendCommandData(obj);
        }
        
        
        public function addCardZone(ownerId:String,
                                    ownerName:String,
                                    x:int, y:int):void {
            var owner:String = "";
            drawCardOnLocal(CardZone.getJsonData, owner, MovablePiece.getDefaultId(), x, y);
            
            var data:Object = {
                "owner" : ownerId,
                "ownerName" : ownerName,
                "x" : x,
                "y" : y
            };
            var obj:Object = getParamObject("addCardZone", data);
            sendCommandData(obj);
        }
        
        public function addCharacter(characterJsonData:Object, keyName:String = null, action:Function = null):void {
            if( keyName == null ) {
                keyName = "name";
            }
            try {
                addCharacterWithError(characterJsonData, keyName, action);
            } catch( e:Error ) {
                Log.loggingException("SharedDataSender.addCharacter()", e);
            }
        }
        
        public function addCharacterWithError(data:Object, keyName:String, action:Function):void {
            Log.logging("SharedDataSender.addCharacter() begin characterData", data);
            
            var clonedData:Object = Utils.clone(data);
            var obj:Object = getParamObject("addCharacter", clonedData);
            
            Log.logging("receiver.addCharacterInOwnMap(characterJsonData) begin");
            data[keyName] = Language.s.generating + data[keyName];
            receiver.addCharacterInOwnMap(data);
            
            Log.logging("SharedDataSender.sendCommandData(obj) begin");
            sendCommandData(obj, getPrintAddFailedCharacterName(action));
            Log.logging("SharedDataSender.sendCommandData(obj) end");
            
            Log.logging("SharedDataSender.addCharacter() end");
        }
        
        public function getPrintAddFailedCharacterName(action:Function):Function {
            return function(event:Object):void {
                var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
                var addFailedCharacterNames:Array = jsonData.addFailedCharacterNames;
                if( addFailedCharacterNames.length == 0 ) {
                    return;
                }
                
                if( action != null ) {
                    if( action() ) {
                        return;
                    }
                }
                
                var message:String = Language.text("characterNameDuplicate", addFailedCharacterNames.join("\" \""));
                DodontoF_Main.getInstance().getChatWindow().addLocalMessage(message);
            }
        }
        
        public function moveCharacter(movablePiece:MovablePiece, x:Number, y:Number):void {
            var data:Object =  {"imgId": movablePiece.getId(),
                                "x": x,
                                "y": y};
            
            var obj:Object = getParamObject("moveCharacter", data);
            sendCommandData(obj);
        }
        
        public function removeCharacter(piece:Piece):void {
            removeCharacters( [piece] );
        }
        
        public function removeInvalidCharacter(characterId:String):void {
            removeCharacterByRemoveInfos( [getRemoveInfo(characterId, true)] );
        }
        
        static public function getRemoveInfo(characterId:String, isGotoGraveyard:Boolean):Object {
            var removeInfo:Object = {"imgId" : characterId,
                                     "isGotoGraveyard" : isGotoGraveyard};
            return removeInfo;
        }
        
        public function removeCharacters(pieces:Array):void {
            var infos:Array = [];
            
            for(var i:int = 0 ; i < pieces.length ; i++) {
                var piece:Piece = pieces[i];
                infos.push( getRemoveInfo(piece.getId(), piece.isGotoGraveyard()) );
            }
            
            removeCharacterByRemoveInfos( infos );
        }
        
        protected function removeCharacterByRemoveInfos(removeInfos:Array):void {
            var obj:Object = getParamObject("removeCharacter", removeInfos);
            sendCommandData(obj);
        }
        
        public function changeCharacter(data:Object, resultFunction:Function = null):void {
            var obj:Object = getParamObject("changeCharacter", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function sendChatMessageAll(name:String, message:String, password:String):void {
            Log.logging("sendChatMessageAll Begin");
            
            var data:Object = {
                "senderName": name,
                "message" : message,
                "password": password,
                "channel": 0,
                "color" : Utils.getColorString(0x000000),
                "uniqueId" : getStrictlyUniqueId() };
            
            var obj:Object = getParamObject("sendChatMessageAll", data);
            
            sendCommandData(obj, sendChatMessageAllCallBack);
            Log.logging("sendChatMessageAll End");
        }
        
        public function sendChatMessageAllCallBack(event:Event):void {
            var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
            Log.logging("sendChatMessageAllCallBack jsonData", jsonData);
            if( jsonData["result"] == "OK" ) {
                Alert.show(Language.s.sendChatAllRoomSuccess + Utils.getJsonString(jsonData["rooms"]));
            } else {
                Alert.show(Language.s.sendChatAllRoomFailed);
            }
        }
        
        public function sendChatMessage(chatSendData:ChatSendData, callBack:Function):void {
            Log.logging("sendChatMessage, chatSendData", chatSendData);
            
            if( chatSendData.isDiceRoll() ) {
                sendDiceBotChatMessage(chatSendData, callBack);
                return;
            }
            
            var data:Object = chatSendData.getSendChatMessageData( getStrictlyUniqueId() );
            var obj:Object = getParamObject("sendChatMessage", data);
            
            var errorFunction:Function = getChatMessageErrorFunction(chatSendData);
            sendCommandData(obj, callBack, errorFunction);
        }
        
        public function sendDiceBotChatMessage(chatSendData:ChatSendData, callBack:Function):void {
            var data:Object = chatSendData.getSendDiceBotChatMessageData( getStrictlyUniqueId() );
            
            var obj:Object = getParamObject("sendDiceBotChatMessage", data);
            
            var errorFunction:Function = getChatMessageErrorFunction(chatSendData);
            sendCommandData(obj, callBack, errorFunction);
        }
        
        private function getChatMessageErrorFunction(data:ChatSendData):Function {
            var errorFunction:Function = function(event:Event):void {
                
                data.inclimentRetryCount();
                
                if( data.isInRetryLimit() ) {
                    retryChatSend(data);
                } else {
                    data.clearRetryCount();
                    SendChatMessageFailedWindow.setData(data);
                }
            }
            
            return errorFunction;
        }
        
        private function retryChatSend(data:ChatSendData):void {
            var second:Number = 0.5;
            
            Utils.timer(second, function():void {
                    Log.loggingTuning("retry");
                    DodontoF_Main.getInstance().getChatWindow().sendChatMessageAgain(data);
                });
        }
        
        
        //ダイスボットの情報を取得します。
        //主な使用目的はダイスボットの表自作機能で新しい表を追加・変更した場合に
        //その表データをリロードするため。
        public function getDiceBotInfos():void {
            Log.logging("SharedDataSender.getDiceBotInfos Begin");
            
            var data:Object = {
                //特にデータなし
            };
            
            var obj:Object = getParamObject("getDiceBotInfos", data);
            
            var resultFunction:Function = DodontoF_Main.getInstance().getDiceBotInfosResult;
            
            sendCommandData(obj, resultFunction);
            
            Log.logging("SharedDataSender.getDiceBotInfos End");
        }
        
        public function getBotTableInfos(resultFunction:Function):void {
            Log.logging("SharedDataSender.getBotTableInfos Begin");
            
            var data:Object = {
                //特にデータなし
            };
            
            var obj:Object = getParamObject("getBotTableInfos", data);
            sendCommandData(obj, resultFunction);
            
            Log.logging("SharedDataSender.getBotTableInfos End");
        }
        
        
        public function addBotTable(command:String, dice:String, title:String, table:String,
                                    gameType:String, resultFunction:Function):void {
                                    
            Log.logging("SharedDataSender.addBotTable Begin");
            
            var data:Object = {
                "command" : command,
                "dice" : dice,
                "title" : title,
                "table" : table,
                "gameType" : gameType };
            
            var obj:Object = getParamObject("addBotTable", data);
            sendCommandData(obj, resultFunction);
            
            Log.logging("SharedDataSender.addBotTable End");
        }
        
        
        public function changeBotTable(command:String, dice:String, title:String, table:String,
                                       gameType:String, originalCommand:String, originalGameType:String,
                                       resultFunction:Function):void {
            Log.logging("SharedDataSender.changeBotTable Begin");
            
            var data:Object = {
                "command" : command,
                "dice" : dice,
                "title" : title,
                "table" : table,
                "gameType" : gameType,
                "originalCommand" : originalCommand,
                "originalGameType" : originalGameType };
            
            var obj:Object = getParamObject("changeBotTable", data);
            sendCommandData(obj, resultFunction);
            
            Log.logging("SharedDataSender.changeBotTable End");
        }
        
        
        public function removeBotTable(command:String, resultFunction:Function):void {
            Log.logging("SharedDataSender.removeBotTable Begin");
            
            var data:Object = {
                "command" : command
            };
            
            var obj:Object = getParamObject("removeBotTable", data);
            sendCommandData(obj, resultFunction);
            
            Log.logging("SharedDataSender.removeBotTable End");
        }
        
        
        
        public function createPlayRoom(createPassword:String,
                                       playRoomName:String,
                                       playRoomPassword:String,
                                       chatChannelNames:Array,
                                       canUseExternalImage:Boolean,
                                       canVisit:Boolean,
                                       gameType:String,
                                       viewStates:Object,
                                       playRoomIndex:int,
                                       resultFunction:Function):void {
            var data:Object = {
                "createPassword": createPassword,
                "playRoomName": playRoomName,
                "playRoomPassword": playRoomPassword,
                "chatChannelNames": chatChannelNames,
                "canUseExternalImage": canUseExternalImage,
                "canVisit": canVisit,
                "gameType": gameType,
                "viewStates": viewStates,
                "playRoomIndex": playRoomIndex
            };
            var obj:Object = getParamObject("createPlayRoom", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function changePlayRoom(playRoomName:String,
                                       playRoomPassword:String,
                                       chatChannelNames:Array,
                                       canUseExternalImage:Boolean,
                                       canVisit:Boolean,
                                       backgroundImage:String,
                                       gameType:String,
                                       viewStates:Object,
                                       playRoomIndex:int,
                                       resultFunction:Function):void {
            DodontoF_Main.getInstance()
                .setPlayRoomInfo(playRoomName,
                                 chatChannelNames,
                                 canUseExternalImage,
                                 canVisit,
                                 backgroundImage,
                                 gameType,
                                 viewStates);
            
            var data:Object = {
                "playRoomName": playRoomName,
                "playRoomPassword": playRoomPassword,
                "chatChannelNames": chatChannelNames,
                "canUseExternalImage": canUseExternalImage,
                "canVisit": canVisit,
                "backgroundImage": backgroundImage,
                "gameType": gameType,
                "viewStates": viewStates
            };
            var obj:Object = getParamObject("changePlayRoom", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function requestImageList(resultFunction:Function):void {
            var data:Object = {
            };
            
            var obj:Object = getParamObject("getImageList", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function requestImageTagInfosAndImageList(resultFunction:Function):void {
            var obj:Object = getParamObject("getImageTagsAndImageList");
            sendCommandData(obj, resultFunction);
        }
        
        public function clearGraveyard(resultFunction:Function):void {
            var obj:Object = getParamObject("clearGraveyard");
            sendCommandData(obj, resultFunction);
        }
        
        public function requestGraveyard(resultFunction:Function):void {
            var obj:Object = getParamObject("getGraveyardCharacterData");
            sendCommandData(obj, resultFunction);
        }
        
        public function getWaitingRoomInfo(resultFunction:Function):void {
            var obj:Object = getParamObject("getWaitingRoomInfo");
            sendCommandData(obj, resultFunction);
        }
        
        public function getPlayRoomStates(minRoom:int, maxRoom:int, resultFunction:Function):void {
            var data:Object = {"minRoom": minRoom,
                               "maxRoom" : maxRoom };
            
            var obj:Object = getParamObject("getPlayRoomStates", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function getLoginInfo(resultFunction:Function, uniqueId:String = null):void {
            var data:Object = {"uniqueId": uniqueId};
            
            var obj:Object = getParamObject("getLoginInfo", data);
            
            sendCommandData(obj, resultFunction);
        }

        public function uploadImageUrl(imageUrl:String, tagInfo:Object, resultFunction:Function):void {
            var data:Object = {"imageUrl": imageUrl,
                                   "tagInfo" : tagInfo };
            
            
            
            var obj:Object = getParamObject("uploadImageUrl", data);
            sendCommandData(obj, resultFunction);
        }


        protected function newReceiverForInitialize():SharedDataReceiver {
            return new SharedDataReceiver();
        }
        
        protected var mentenanceCommands:Array = ["loginPassword", "getLoginInfo", "checkRoomStatus",
                                                  "refresh"];
        
        protected function isIgnoreCommandAtMentenanceMode(commandName:String):Boolean {
            if( ! DodontoF_Main.getInstance().getMentenanceModeOn() ) {
                return false;
            }
            
            return isIgnoreCommand(commandName, mentenanceCommands);
        }
        
        protected function isIgnoreCommand(commandName:String, commands:Array):Boolean {
            for(var i:int = 0 ; i < commands.length ; i++) {
                var command:String = commands[i] as String;
                if( command == commandName ) {
                    return false;
                }
            }
            
            return true;
        }
        
        protected var visiterCommands:Array = 
            ["loginPassword", "getLoginInfo", "checkRoomStatus",
             "refresh", "sendChatMessage", "getDiceBotInfos"];
        
        protected function isIgnoreCommandAtVisiterMode(commandName:String):Boolean {
            if( ! DodontoF_Main.getInstance().isVisiterMode() ) {
                return false;
            }
            
            return isIgnoreCommand(commandName, visiterCommands);
        }
        
        public function startSessionRecording():void {
            var tmpTimes:Object = getInitLastUpdateTimes();
            tmpTimes.chatMessageDataLog = lastUpdateTimes.chatMessageDataLog;
            lastUpdateTimes = tmpTimes;
            
            RecordHistory.getInstance().startRecord();
        }
        
        public function clearLastUpdateTimes():void {
            lastUpdateTimes = getInitLastUpdateTimes();
        }
        
        protected function getInitLastUpdateTimes():Object {
            var lastUpdateTimes:Object = {
                'map': 0,
                'characters': 0,
                'chatMessageDataLog': 0,
                'time': 0,
                'effects': 0,
                'playRoomInfo': 0,
                'record': 0,
                'recordIndex': 0
            };
            return lastUpdateTimes;
        }
        
        public function resetLastUpdateTimeOfInitiativeTimer():void {
            resetLastUpdateTime('time');
        }
        
        public function resetCharactersUpdateTime():void {
            resetLastUpdateTime('characters');
            clearRecord();
        }
        
        protected function resetLastUpdateTime(type:String):void {
            lastUpdateTimes[type] = 0;
        }
        
        protected function closeRefreshLoader():void {
            closeLoader(refreshLoader);
        }
        
        protected function closeLoader(loader:URLLoader):void {
            try {
                loader.close();
            } catch( e:Error ) {
                //refreshLoaderは通信状態が不安定な場合には無理やり閉じる必要がある。
                //つまり、通常の運用でも発生する場合のある例外。
                //このため通常のエラー処理とは異なりエラーログにログ出力していない。
                Log.loggingExceptionDebug("SharedDataSender.closeLoader()", e);
            }
        }
        
        protected function getUrlRequestForSendCommandData(params:Object):URLRequest {
            Log.logging("getUrlRequestForSendCommandData params", params);
            
            var request:URLRequest = new URLRequest();
            request.url = Config.getInstance().getDodontoFServerCgiUrl();
            request.method = URLRequestMethod.POST;
            
            request.contentType = "application/x-msgpack";
            request.data = Utils.getMessagePack(params);
            
            Log.logging("POST to", request.url);
            
            return request;
        }
        
        private function closeLoaderByEvent(event:Event):void {
            var oldLoader:URLLoader = URLLoader(event.target);
            if( oldLoader != refreshLoader ) {
                closeLoader(oldLoader);
            }
        }
        
        protected function getUrlLoaderForSendCommand(callBack:Function,
                                                      errorCallBack:Function):URLLoader {
            
            Log.logging("loader begin");
            var loader:URLLoader = new URLLoader();
            
            var wrappedCallBack:Function = function(event:Event):void {
                if( callBack != null ) {
                    callBack.call(thisObj, event);
                }
                closeLoaderByEvent(event);
            }
            loader.addEventListener(Event.COMPLETE, wrappedCallBack);
            
            var wrappedCallBackForError:Function = function(event:Event):void {
                if( errorCallBack != null ) {
                    errorCallBack(event);
                }
                
                var oldLoader:URLLoader = URLLoader(event.target);
                if( oldLoader != refreshLoader ) {
                    closeLoader(oldLoader);
                }
                
                //接続断が発生したので一旦履歴をクリアーに。
                clearRecord();
            }
            
            loader.addEventListener(IOErrorEvent.IO_ERROR, wrappedCallBackForError);
            loader.addEventListener(Event.UNLOAD, wrappedCallBackForError);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, wrappedCallBackForError);
            
            return loader;
        }
        
        private function clearRecord():void {
            resetLastUpdateTime('recordIndex');
            resetLastUpdateTime('record');
            
            Log.logging("clearRecord called.");
        }
        
            
        
        public static function getJsonString(jsonData:Object):String {
            return Utils.getJsonString(jsonData);
        }
        
        public function getEncodedJsonString(jsonData:Object):String {
            return Utils.getEncodedJsonString(jsonData);
        }
        
        public function getExistPiecesCount():int {
            return map.getExistPiecesCount();
        }
        
        public function removePlayRoom(roomNumbers:Array, resultFunction:Function, ignoreLoginUser:Boolean,
                                       password:String, adminPassword:String, isForce:Boolean):void {
            var data:Object = {
                "roomNumbers": roomNumbers,
                "ignoreLoginUser": ignoreLoginUser,
                "password" : password,
                "adminPassword" : adminPassword,
                "isForce" : isForce
            };
            
            
            var obj:Object = getParamObject("removePlayRoom", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function removeOldPlayRoom(resultFunction:Function):void {
            var data:Object = {
            };
            
            
            var obj:Object = getParamObject("removeOldPlayRoom", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function removeReplayData(replayData:Object, resultFunction:Function):void {
            Log.loggingTuning("SharedDataSender.removeReplayData replayData", replayData);
            
            var obj:Object = getParamObject("removeReplayData", replayData);
            sendCommandData(obj, resultFunction);
        }
        
        
        
        public function addResource(data:Object):void {
            var obj:Object = getParamObject("addResource", data);
            sendCommandData(obj);
        }
        
        public function changeResource(data:Object, resultFunction:Function = null):void {
            var obj:Object = getParamObject("changeResource", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function changeResourcesAll(data:Object):void {
            var obj:Object = getParamObject("changeResourcesAll", data);
            sendCommandData(obj);
        }
        
        public function removeResource(resourceId:String):void {
            var data:Object = {
                "resourceId": resourceId
            };
            
            var obj:Object = getParamObject("removeResource", data);
            sendCommandData(obj);
        }
        
        
        
        public function addEffect(data:Object):void {
            var obj:Object = getParamObject("addEffect", data);
            sendCommandData(obj);
        }
        
        public function changeEffect(data:Object):void {
            var obj:Object = getParamObject("changeEffect", data);
            sendCommandData(obj);
        }
        
        public function changeEffectsAll(data:Object):void {
            var obj:Object = getParamObject("changeEffectsAll", data);
            sendCommandData(obj);
        }
        
        public function removeEffect(effectIds:Array):void {
            var data:Object = {
                "effectIds": effectIds
            };
            
            var obj:Object = getParamObject("removeEffect", data);
            sendCommandData(obj);
        }
        
        public function changeImageTags(data:Object):void {
            var obj:Object = getParamObject("changeImageTags", data);
            sendCommandData(obj);
        }
        
        public function initCards(cardTypes:Array, resultFunction:Function):void {
            var data:Object = {
                "cardTypeInfos": cardTypes
            };
            
            var obj:Object = getParamObject("initCards", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function shuffleForNextRandomDungeon(mountName:String, mountId:String):void {
            var data:Object = {
                "mountName": mountName,
                "mountId": mountId
            };
            
            var obj:Object = getParamObject("shuffleForNextRandomDungeon", data);
            sendCommandData(obj);
        }
        
        public function clearCards():void {
            var data:Object = {
                "types": [Card.getTypeStatic(), CardMount.getTypeStatic()]
            };
            
            var obj:Object = getParamObject("clearCharacterByType",  data);
            sendCommandData(obj);
        }
        
        
        private function drawCardOnLocal(getJsonDataFunction:Function,
                                         owner:String,
                                         imgId:String,
                                         x:int,
                                         y:int,
                                         mountName:String = ""):void {
            var text:String = "<p align='center'><font size=\"72\">LOADING...</font><p>";
            var cardJsonData:Object = getJsonDataFunction(text, text, x, y, mountName);
            
            cardJsonData = getCloneCardJsonData(cardJsonData, x, y);
            cardJsonData.owner = owner;
            cardJsonData.imgId = imgId;
            
            receiver.addCharacterInOwnMap(cardJsonData);
        }
        
        public function drawCard( isOpen:Boolean,
                                  owner:String,
                                  ownerName:String,
                                  mountName:String,
                                  newCardImgId:String,
                                  x:int,
                                  y:int,
                                  imgId:String,
                                  count:int,
                                  action:Function):void {
            
            drawCardOnLocal(Card.getJsonData, owner, newCardImgId, x, y, mountName);
            
            var data:Object = {
                "isOpen": isOpen,
                "mountName": mountName,
                "owner": owner,
                "ownerName":ownerName,
                "x": x,
                "y": y,
                "imgId": imgId,
                "count": count
            };
            
            var obj:Object = getParamObject("drawCard", data);
            
            var resultFunction:Function = function(event:Event):void {
                var data:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
                var result:String = data.result;
                if( result != "OK" ) {
                    receiver.removeCharacterOnlyOwnMap(event);
                }
                action(data);
            };
            
            sendCommandData(obj, resultFunction);
        }
        
        private function getCloneCardJsonData(cardJsonData:Object, x:int, y:int):Object {
            
            cardJsonData = Utils.clone(cardJsonData);
            cardJsonData.imgId = MovablePiece.getDefaultId();
            cardJsonData.x = x;
            cardJsonData.y = y;
            cardJsonData.draggable = false;
            cardJsonData.ownerName = Language.s.generating;
            
            return cardJsonData;
        }
        
        public function exitWaitingRoomCharacter(characterId:String, x:int, y:int, resultFunction:Function):void {
            var data:Object = {
                "characterId" : characterId,
                "x" : x,
                "y" : y};
            
            var obj:Object = getParamObject("exitWaitingRoomCharacter", data);
            sendCommandData(obj, resultFunction);
        }

        public function enterWaitingRoomCharacter(characterId:String, index:int, resultFunction:Function):void {
            var data:Object = {
                "characterId" : characterId,
                "index" : index};
            
            var obj:Object = getParamObject("enterWaitingRoomCharacter", data);
            sendCommandData(obj, resultFunction);
        }

        public function drawTargetCard( cardJsonData:Object,
                                        ownerId:String,
                                        ownerName:String,
                                        mountId:String,
                                        mountName:String,
                                        targetCardId:String,
                                        x:int,
                                        y:int,
                                        resultFunction:Function):void {
            
            cardJsonData = getCloneCardJsonData(cardJsonData, x, y);
            receiver.addCharacterInOwnMap(cardJsonData);
            
            var data:Object = {
                "owner" : ownerId,
                "ownerName" : ownerName,
                "mountId" : mountId,
                "mountName" : mountName,
                "targetCardId" : targetCardId,
                "x": x,
                "y": y
            };
            
            var obj:Object = getParamObject("drawTargetCard", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function drawTargetTrushCard( cardJsonData:Object,
                                             ownerId:String,
                                             ownerName:String,
                                             mountId:String,
                                             mountName:String,
                                             targetCardId:String,
                                             x:int,
                                             y:int,
                                             resultFunction:Function):void {
            cardJsonData = getCloneCardJsonData(cardJsonData, x, y);
            receiver.addCharacterInOwnMap(cardJsonData);
            
            var data:Object = {
                "mountName" : mountName,
                "targetCardId" : targetCardId,
                "x": x,
                "y": y,
                "mountId" : mountId
            };
            
            var obj:Object = getParamObject("drawTargetTrushCard", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function returnCard( mountName:String,
                                    x:int,
                                    y:int,
                                    id_:String ):void {
            var data:Object = {
                "mountName": mountName,
                "x": x,
                "y": y,
                "imgId": id_
            };
            
            var obj:Object = getParamObject("returnCard", data);
            sendCommandData(obj);
        }
        
        
        public function shuffleCards( mountName:String, id_:String, isShuffle:Boolean ):void {
            var data:Object = {
                "mountName": mountName,
                "mountId": id_,
                "isShuffle": isShuffle
            };
            
            var obj:Object = getParamObject("shuffleCards", data);
            sendCommandData(obj);
        }
        
        public function shuffleOnlyMountCards( mountName:String, id_:String ):void {
            var data:Object = {
                "mountName": mountName,
                "mountId": id_
            };
            
            var cardName:String = InitCardWindow.getCardName(mountName);
            Utils.sendSystemMessage(Language.s.shuffleMountAnnounce, [cardName]);
            
            var obj:Object = getParamObject("shuffleOnlyMountCards", data);
            sendCommandData(obj);
        }
        
        public function returnCardToMount( targetCardId:String, mountName:String, id_:String ):void {
            var data:Object = {
                "returnCardId": targetCardId,
                "mountName": mountName,
                "cardMountId": id_
            };
            
            var obj:Object = getParamObject("returnCardToMount", data);
            sendCommandData(obj);
        }
        
        public function dumpTrushCard( targetCardId:String, mountName:String, id_:String ):void {
            var data:Object = {
                "dumpedCardId": targetCardId,
                "mountName": mountName,
                "trushMountId": id_
            };
            
            var obj:Object = getParamObject("dumpTrushCards", data);
            sendCommandData(obj);
        }
        
        public function getMountCardInfos(mountNameForDisplay:String, mountName:String, mountId:String, resultFunction:Function):void {
            Utils.sendSystemMessage(Language.s.searchMountAnnounce,
                                                                                  [mountNameForDisplay]);
            
            var data:Object = {
                "mountName": mountName,
                "mountId": mountId
            };
            
            var obj:Object = getParamObject("getMountCardInfos", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function getTrushMountCardInfos(mountName:String, mountId:String, resultFunction:Function):void {
            var cardName:String = InitCardWindow.getCardName(mountName);
            Utils.sendSystemMessage(Language.s.searchTrushMountAnnounce, [cardName]);
            
            var data:Object = {
                "mountName": mountName,
                "mountId": mountId
            };
            
            var obj:Object = getParamObject("getTrushMountCardInfos", data);
            sendCommandData(obj, resultFunction);
        }
        
        public function getCardList(mountName:String, resultFunction:Function):void {
            var data:Object = {
                "mountName": mountName
            };
            
            var obj:Object = getParamObject("getCardList", data);
            sendCommandData(obj, resultFunction);
        }
        
        
        public function deleteChatLog(resultFunction:Function):void {
            var data:Object = {
            };
            
            var obj:Object = getParamObject("deleteChatLog", data);
            sendCommandData(obj, resultFunction);
        }
        
        
        protected function getParamObject(commandName:String, data:Object = null, paramsName:String = "params"):Object {
            Log.logging("getParamObject Begin");
            
            if( isIgnoreCommandAtMentenanceMode(commandName) ) {
                return null;
            }
            
            if( isIgnoreCommandAtVisiterMode(commandName) ) {
                return null;
            }
            
            var result:Object = new Object();
            
            if( data != null ) {
                result[paramsName] = data;
            }
            
            result["cmd"] = commandName;
            result["room"] = this.saveDataDirIndex;
            result["own"] = getStrictlyUniqueId();
            
            Log.logging("getParamObject result", result);
            
            return result;
        }
        
        protected function sendCommandData(obj:Object,
                                           callBack:Function = null,
                                           errorCallBack:Function = null,
                                           isRefresh:Boolean = false):void {
            
            Log.loggingTuning("==>Begin sendCommandData");
            Log.logging("sendCommandData obj : ", obj);
            
            if( isStopRefreshOn ) {
                Log.logging(Language.s.refreshStopedError);
                return;
            }
            
            try {
                sendCommandDataCatched(obj,
                                       callBack,
                                       errorCallBack,
                                       isRefresh);
            } catch( e:Error ) {
                Log.loggingException("SharedDataSender.sendCommandData()", e);
            }
            Log.loggingTuning("==>End sendCommandData");
        }
        
        protected function sendCommandDataCatched(obj:Object,
                                                  callBack:Function,
                                                  errorCallBack:Function,
                                                  isRefresh:Boolean = false):void {
            if( obj == null ) {
                return;
            }
            
            var request:URLRequest = getUrlRequestForSendCommandData(obj);
            var loader:URLLoader = null;
            
            if( isRefresh ) {
                if( refreshLoader == null ) {
                    refreshLoader = getUrlLoaderForSendCommand(callBack, errorCallBack);
                }
                closeRefreshLoader();
                
                loader = refreshLoader;
            } else {
                loader = getUrlLoaderForSendCommand(callBack, errorCallBack);
            }
            
            loader.load(request);
            Log.logging("loader end");
        }
        
        //一意な文字列作成用
        //マトモにやると文字数多すぎるので適当に時刻から作製
        private function createUniqueString():String {
            // UIDUtil.createUID(); //マジメなやり方
            
            return new Date().time.toString(36);
        }
        
    }
}

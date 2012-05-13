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
    import ym.net.HTTPPostBinary;
    import flash.geom.Point;
    import flash.events.DataEvent;
    import mx.utils.UIDUtil;
    import flash.events.TimerEvent;
    
    
    public class SharedDataSender {
        
        protected var loadParams:Object = null;
        
        private var uniqueId:String = "";
        private var strictlyUniqueId:String = UIDUtil.createUID();
        
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
        
        public function isOwnUniqueId(targetId:String):Boolean {
            var parats:Array = targetId.split("\t");
            var targetUniqeId:String = parats[0];
            return ( targetUniqeId == getUniqueId() );
        }
        
        public function getStrictlyUniqueId():String {
            return this.uniqueId + "\t" + this.strictlyUniqueId;
        }
        
        public function isOwnStrictlyUniqueId(targetStrictlyId:String):Boolean {
            return ( targetStrictlyId == getStrictlyUniqueId() );
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
            var jsonData:Object = {
                "roomNumber" : roomNumber,
                "adminPassword" : adminPassword
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            
            var params:String = getParamString("checkRoomStatus", [["checkRoomStatusData", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function loginPassword(roomNumber:int, password:String,
                                      visiterMode:Boolean, resultFunction:Function):void {
            Log.logging("SharedDataSender.login");
            var jsonData:Object = {
                "roomNumber" : roomNumber,
                "password" : password,
                "visiterMode" : visiterMode
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            
            var params:String = getParamString("loginPassword", [["loginData", jsonParams]]);
            this.sendCommandData(params, resultFunction);
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
        
        public function saveScenario(chatPalleteData:String, resultFunction:Function):void {
            var jsonData:Object = {
                "chatPalleteData": chatPalleteData,
                "baseUrl": Utils.getOwnBaseUrl() };
            var jsonParams:String = getEncodedJsonString(jsonData);
            
            var params:String = this.getParamString("saveScenario",  [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function save(resultFunction:Function):void {
            var params:String = this.getParamString("save", [["extension", saveFileExtension]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function saveMap(resultFunction:Function):void {
            var params:String = this.getParamString("saveMap", [["extension", mapSaveFileExtension]]);
            this.sendCommandData(params, resultFunction);
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
            filters.push(new FileFilter("セーブデータ(*." + extension + ")", "*." + extension));
            
            fileReferenceForUpload.browse(filters);
        }
        
        
        protected function getFileSelectHandlerForLoad(commandName:String, resultFunction:Function = null):Function {
            return function(event:Event):void {
                var fileReference:FileReference = event.currentTarget as FileReference;
                if( fileReference == null ) {
                    return;
                }
                
                if( resultFunction != null ) {
                    fileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, resultFunction);//Event.COMPLETE, resultFunction);
                }
                
                thisObj.sendFileUpload(fileReference, commandName, thisObj.loadParams);
            }
        }
        
        private var scenarioFileExtensions:String = "*.tgz;*.tar.gz";
        
        public function uploadScenarioData():void {
            Log.loggingTuning("uploadScenarioData begin");
            loadParams = new Object();
            
            var commandName:String = "loadScenario";
            
            var loadScenarioFileReference:FileReference = new FileReference();
            
            loadScenarioFileReference.addEventListener(Event.SELECT,
                                                       getFileSelectHandlerForLoad(commandName));
            loadScenarioFileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,
                                                       analyzeLoadScenarioResult);
            
            var filters:Array = new Array();
            filters.push( new FileFilter("シナリオデータ(" + scenarioFileExtensions + ")",
                                         scenarioFileExtensions) );
            
            loadScenarioFileReference.browse(filters);
            Log.loggingTuning("uploadScenarioData end");
        }


        public function analyzeLoadScenarioResult(dataEvent:DataEvent):void {
            Log.logging('analyzeLoadScenarioResult called, dataEvent', dataEvent);
            
            var jsonData:Object = SharedDataReceiver.getJsonDataFromDataEvent(dataEvent);
            Log.logging('analyzeLoadScenarioResult jsonData', jsonData);
            
            if( jsonData.resultText != 'OK' ) {
                Log.loggingError( "シナリオデータ読み込み時にエラーが発生しました：" + jsonData.resultText );
                return;
            }
            
            DodontoF_Main.getInstance().getChatPaletteWindow().loadFromText( jsonData.chatPaletteSaveData );
            DodontoF_Main.getInstance().getChatWindow().sendSystemMessage("シナリオデータ読み込みに成功しました。", false);
        }
        
        
        
        
        public function requestReplayDataList(resultFunction:Function):void {
            Log.logging("SharedDataSender.requestReplayDataList Begin");
            
            var jsonData:Object = {
                //特にデータなし
            };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("requestReplayDataList", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
            
            Log.logging("SharedDataSender.requestReplayDataList End");
        }
        
        public function uploadImageFile(fileReferenceForImageUpload:FileReference,
                                        params:Object):void {
            Log.loggingTuning("uploadImageFile called");
            
            var commandName:String = "uploadImageFile";
            if( isIgnoreCommandAtMentenanceMode(commandName) ) {
                return;
            }
            
            if( isIgnoreCommandAtVisiterMode(commandName) ) {
                return;
            }
            
            sendFileUpload(fileReferenceForImageUpload, "uploadImageFile", params);
        }
        
        public function sendFileUpload(fileReferenceForLocal:FileReference,
                                       commandName:String,
                                       params:Object = null):void {
            var request:URLRequest = new URLRequest( Config.getInstance().getImageUploaderUrl() );
            
            request.method = URLRequestMethod.POST;
            var jsonData:Object = {
                "Command" : commandName,
                "saveDataDirIndex" : this.saveDataDirIndex
            };
            
            if( params != null ) {
                for(var key:String in params) {
                    jsonData[key] = params[key];
                }
            }
            
            var jsonParams:String = getEncodedJsonString(jsonData);
            Log.loggingTuning("load jsonParams", jsonParams);
            
            var variables:URLVariables = new URLVariables();
            variables.__jsonDataForFileUploader__ = jsonParams;
            
            request.data = variables;
            Log.loggingTuning("fileReferenceForLocal.upload(request) calling...");
            
            fileReferenceForLocal.upload(request);
            Log.loggingTuning("fileReferenceForLocal.upload(request) called.");
        }
        
        
        public function uploadImageData(params_obj:Object, resultFunction:Function, errorFunction:Function):void {
            Log.loggingTuning("SharedDataSenderBody.uploadImageData begin");
            
            var params:Array = params_obj as Array;
            var httpdata:HTTPPostBinary = new HTTPPostBinary();
            
            //(params_key:String, data:ByteArray, mimetype:String, filename:String = null)
            
            Log.logging("params.length", params.length);
            while( params.length > 0 ) {
                var param:Array = params.shift();
                var type:String = param.shift();
                
                if( type == "binary" ) {
                    Log.logging("addBinary param[0]:" + param[0] + ", param[1], param[2]:" + param[2] + ", param[3]:" + param[3]);
                    Log.logging("param[1] is null : " + (param[1] == null));
                    httpdata.addBinary(param[0], param[1], param[2], param[3]);
                } else if( type == "string" ) {
                    Log.logging("addString param[0]:" + param[0] + ", param[1]:" + param[1]);
                    httpdata.addString(param[0], param[1]);
                } else {
                    Log.loggingError("other type in uploadImageData");
                }
            }
            
            httpdata.addString("Command", "uploadImageData");
            httpdata.addString("saveDataDirIndex", "" + this.saveDataDirIndex);
            
            var request:URLRequest = new URLRequest();
            request.url = Config.getInstance().getDodontoFServerCgiUrl();
            request.contentType = httpdata.contentType;
            request.method = httpdata.method;
            request.data = httpdata.encodeData();
            
            Log.logging("loader.load() setting");
            var loader: URLLoader = new URLLoader();
            
            loader.addEventListener(IOErrorEvent.IO_ERROR, errorFunction);
            loader.addEventListener(Event.UNLOAD, errorFunction);
            loader.addEventListener(Event.COMPLETE, resultFunction);
            
            Log.logging("loader.load() begin");
            Log.logging("request.url", request.url);
            try {
                loader.load(request);
            } catch (e:Error) {
                Log.loggingException("uploadImageData", e);
                throw e;
            }
            Log.logging("loader.load() end");
            
            Log.loggingTuning("uploadImageData end");
        }
        
        public function checkLastUpdateTimes(type:String, jsonLastUpdateTimes:Object):Boolean {
            Log.logging("checkLastUpdateTimes begin.");
            Log.logging("checkLastUpdateTimes type", type);
            
            if( isReplayMode() ) {
                return true;
            }
            
            var timeValue:Number = jsonLastUpdateTimes[type];
            Log.logging("timeValue", timeValue);
            
            if( this.lastUpdateTimes[type] > timeValue ) {
                return false;
            }
            
            this.lastUpdateTimes[type] = timeValue;
            return true;
        }
        
        public function resurrectCharacter(resurrectCharacterId:String, resultFunction:Function):void {
            var jsonData:Object = {"imgId" : resurrectCharacterId};
            var jsonParams:String = getEncodedJsonString( jsonData );
            
            var params:String = getParamString("resurrectCharacter", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function sendRoundTimeData(round:int, initiative:Number, counterNames:Array):void {
            var jsonData:Object = {"round": round,
                                   "initiative": initiative,
                                   "counterNames": counterNames};
            var jsonParams:String = getEncodedJsonString( jsonData );
            
            var params:String = this.getParamString("changeRoundTime", [["roundTimeData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        
        public function startRefresh():void {
            refresh();
            startRefreshCheckTimer();
        }
        
        protected function startRefreshCheckTimer():void {
			if( isCommet() ) {
                startRefreshCheckTimerForCommet();
			} else {
                startRefreshCheckTimerForNotCommet();
            }
        }
        
        protected function startRefreshCheckTimerForCommet():void {
            var timeoutMilliSecond:int = (refreshTimeoutSecond + refreshTimeoutPadding) * 1000;
            setInterval(completeRefreshCheckTimer, timeoutMilliSecond);
        }
        
        private function startRefreshCheckTimerForNotCommet():void {
            var timeoutMilliSecond:int = refreshIntervalSecond * 1000;
            Log.loggingTuning("refresh setInterval timeoutMilliSecond", timeoutMilliSecond);
            
            setInterval(refresh, timeoutMilliSecond);
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
            Log.loggingErrorOnStatus("サーバとの接続でエラーが発生しました。再接続します。");
            
            isRetry = true;
            
            //接続断が発生したので一旦履歴をクリアーに。
            clearRecord();
            
            if( refreshLoader != null ) {
                closeRefreshLoader();
            }
            
            setTimeout(function():void {
                    Log.loggingErrorOnStatus("再接続中……");
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
        }
        
        public function isStopRefresh():Boolean {
            return isStopRefreshOn;
        }
        
        public function logout():void {
            stopRefresh();
            
            var logoutJsonData:Object = {
                "uniqueId": uniqueId};
            
            var jsonParams:String = getEncodedJsonString(logoutJsonData);
            Log.logging("jsonParams : " + jsonParams);
            
            var params:String = getParamString("logout", [["logoutData", jsonParams]]);
            this.sendCommandData(params);
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
            
            var jsonData:Object = {
                "lastUpdateTimes": this.lastUpdateTimes,
                "refreshIndex": this.refreshIndex,
                "uniqueId": this.uniqueId,
                "userName": userName
            };
            
            if( DodontoF_Main.getInstance().isVisiterMode() ) {
                jsonData["isVisiter"] = true;
            }
            
            if( getReciever().isSessionRecording() ) {
                jsonData["isGetOwnRecord"] = true;
            }
            
            if( DodontoF_Main.getInstance().getMentenanceModeOn() ) {
                jsonData.uniqueId = -1;
            }
            
            var refreshData:String = getEncodedJsonString(jsonData);
            Log.logging("refreshData", refreshData);
            
            var params:String = getParamString("refresh", [["params", refreshData]]);
            Log.logging("refreshData params", params);
            
            var isRefresh:Boolean = true;
            sendCommandData(params, receiver.analyzeRefreshResponse, null, isRefresh);
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
                                  mapMarks:Array):void {
            var changeMapJsonData:Object = {
                "mapType": "imageGraphic",
                "imageSource": mapImageUrl,
                "mirrored": mirrored,
                "xMax": mapWidth,
                "yMax": mapHeight,
                "gridColor": gridColor,
                "gridInterval": gridInterval,
                "isAlternately": isAlternately,
                "mapMarks": mapMarks};
            
            Log.logging("changeMapJsonData");
            var jsonParams:String = getEncodedJsonString(changeMapJsonData);
            Log.logging("jsonParams : " + jsonParams);
            
            var params:String = getParamString("changeMap", [["mapData", jsonParams]]);
            Log.logging("var params:String : " + params);
            this.sendCommandData(params);
        }
        
        public function deleteImage(imageUrlList:Array,
                                    resultFunction:Function):void {
            var jsonData:Object = {
                "imageUrlList": imageUrlList
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("deleteImage", [["imageData", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function addMessageCard(imageName:String, imageNameBack:String, x:int, y:int):void {
            var jsonData:Object = {
                "isText" : true,
                "imageName" : imageName,
                "imageNameBack" : imageNameBack,
                "mountName" : "messageCard",
                "isUpDown" : false,
                "canDelete" : true,
                "x" : x,
                "y" : y
            };
            var addCardData:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("addCard", [["addCardData", addCardData]]);
            this.sendCommandData(params);
        }
        
        public function addCardZone(ownerId:String,
                                    ownerName:String,
                                    x:int, y:int):void {
            var owner:String = "";
            drawCardOnLocal(CardZone.getJsonData, owner, MovablePiece.getDefaultId(), x, y);
            
            var jsonData:Object = {
                "owner" : ownerId,
                "ownerName" : ownerName,
                "x" : x,
                "y" : y
            };
            var dataString:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("addCardZone", [["data", dataString]]);
            this.sendCommandData(params);
        }
        
        public function addCharacter(characterJsonData:Object, keyName:String = "name"):void {
            try {
                addCharacterWithError(characterJsonData, keyName);
            } catch( e:Error ) {
                Log.loggingException("SharedDataSender.addCharacter()", e);
            }
        }
        
        public function addCharacterWithError(characterJsonData:Object, keyName:String):void {
            Log.logging("SharedDataSender.addCharacter() begin characterJsonData", characterJsonData);
            
            var jsonParams:String = getEncodedJsonString(characterJsonData);
            Log.logging("jsonParams", jsonParams);
            
            var params:String = getParamString("addCharacter", [["characterData", jsonParams]]);
            Log.logging("var params:String", params);
            
            Log.logging("receiver.addCharacterInOwnMap(characterJsonData) begin");
            characterJsonData[keyName] = "(作成中・・・)" + characterJsonData[keyName];
            receiver.addCharacterInOwnMap(characterJsonData);
            
            Log.logging("SharedDataSender.sendCommandData(params) begin");
            this.sendCommandData(params, printAddFailedCharacterName);
            Log.logging("SharedDataSender.sendCommandData(params) end");
            
            Log.logging("SharedDataSender.addCharacter() end");
        }
        
        public function printAddFailedCharacterName(event:Object):void {
            var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
            var addFailedCharacterNames:Array = jsonData.addFailedCharacterNames;
            if( addFailedCharacterNames.length == 0 ) {
                return;
            }
            var message:String = "\"" + addFailedCharacterNames.join("\" \"") + "\"という名前のキャラクターはすでに存在するため追加に失敗しました。";
            
            //DodontoF_Main.getInstance().getChatWindow().sendSystemMessage(message, false);
            DodontoF_Main.getInstance().getChatWindow().addLocalMessage(message);
        }
        
        public function moveCharacter(movablePiece:MovablePiece, x:Number, y:Number):void {
            Log.logging("moveCharacter start.");
            var moveData:String = getEncodedJsonString( {"imgId": movablePiece.getId(), "x": x, "y": y});
            Log.logging("moveData", moveData);
            
            var params:String = this.getParamString("moveCharacter", [["characterData", moveData]]);
            this.sendCommandData(params);
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
            var jsonParams:String = getEncodedJsonString( removeInfos );
            var params:String = this.getParamString("removeCharacter", [["removeCharacterData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function changeCharacter(characterJsonData:Object):void {
            var jsonParams:String = getEncodedJsonString(characterJsonData);
            Log.logging("jsonParams : " + jsonParams);
            
            var params:String = getParamString("changeCharacter", [["params", jsonParams]]);
            Log.logging("var params:String : " + params);
            this.sendCommandData(params);
        }
        
        public function sendChatMessage(chatSendData:ChatSendData, callBack:Function):void {
            Log.logging("sendChatMessage, chatSendData", chatSendData);
            
            if( chatSendData.isDiceRoll() ) {
                sendDiceBotChatMessage(chatSendData, callBack);
                return;
            }
            
            var jsonData:Object = {
                "senderName": chatSendData.getNameAndState(),
                "message" : chatSendData.getMessage(),
                "channel": chatSendData.getChannel(),
                "color" : chatSendData.getColor(),
                "uniqueId" : chatSendData.getStrictlyUniqueId(this) };
            
            var sendto:String = chatSendData.getSendto();
            if( ChatMessageTrader.isValidSendTo(sendto) ) {
                jsonData.sendto = sendto;
            }
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("sendChatMessage", [["params", jsonParams]]);
            
            var errorFunction:Function = getChatMessageErrorFunction(chatSendData);
            this.sendCommandData(params, callBack, errorFunction);
        }
        
        public function sendDiceBotChatMessage(chatSendData:ChatSendData, callBack:Function):void {
            var jsonData:Object = {
                "name" : chatSendData.getNameAndState(),
                "state" : chatSendData.getState(),
                "message" : chatSendData.getMessage(),
                "channel" : chatSendData.getChannel(),
                "color" : chatSendData.getColor(),
                "sendto" : chatSendData.getSendto(),
                "randomSeed" : chatSendData.getRandSeed(),
                "gameType" : chatSendData.getGameType()};
            
            var jsonParams:String = getEncodedJsonString(jsonData);
            Log.logging("jsonParams : ", jsonParams);
            
            var params:String = this.getParamString("sendDiceBotChatMessage", [["params", jsonParams]]);
            
            var errorFunction:Function = getChatMessageErrorFunction(chatSendData);
            this.sendCommandData(params, callBack, errorFunction);
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
        
        
        public function sendChatMessageMany(chatCharacterName:String, message:String, color:String):void {
            var jsonData:Object = {
                "senderName": chatCharacterName,
                "message" : message,
                "color" : color
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("sendChatMessageMany", [["params", jsonParams]]);
            this.sendCommandData(params);
        }
        
        
        public function getDiceBotInfos():void {
            Log.logging("SharedDataSender.getDiceBotInfos Begin");
            
            var jsonData:Object = {
                //特にデータなし
            };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getDiceBotInfos", [["params", jsonParams]]);
            
            var resultFunction:Function = DodontoF_Main.getInstance().getDiceBotInfosResult;
            
            this.sendCommandData(params, resultFunction);
            
            Log.logging("SharedDataSender.getDiceBotInfos End");
        }
        
        public function getBotTableInfos(resultFunction:Function):void {
            Log.logging("SharedDataSender.getBotTableInfos Begin");
            
            var jsonData:Object = {
                //特にデータなし
            };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getBotTableInfos", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
            
            Log.logging("SharedDataSender.getBotTableInfos End");
        }
        
        
        public function addBotTable(command:String, dice:String, title:String, table:String,
                                    resultFunction:Function):void {
            Log.logging("SharedDataSender.addBotTable Begin");
            
            var jsonData:Object = {
                "command" : command,
                "dice" : dice,
                "title" : title,
                "table" : table
            };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("addBotTable", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
            
            Log.logging("SharedDataSender.addBotTable End");
        }
        
        
        public function changeBotTable(command:String, dice:String, title:String, table:String,
                                       originalCommand:String,
                                       resultFunction:Function):void {
            Log.logging("SharedDataSender.changeBotTable Begin");
            
            var jsonData:Object = {
                "command" : command,
                "dice" : dice,
                "title" : title,
                "table" : table,
                "originalCommand" : originalCommand
            };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("changeBotTable", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
            
            Log.logging("SharedDataSender.changeBotTable End");
        }
        
        
        public function removeBotTable(command:String, resultFunction:Function):void {
            Log.logging("SharedDataSender.removeBotTable Begin");
            
            var jsonData:Object = {
                "command" : command
            };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("removeBotTable", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
            
            Log.logging("SharedDataSender.removeBotTable End");
        }
        
        
        
        protected function sendCommandData(paramsString:String,
                                           callBack:Function = null,
                                           errorCallBack:Function = null,
                                           isRefresh:Boolean = false):void {
            
            Log.loggingTuning("==>Begin sendCommandData");
            Log.logging("sendCommandData paramsString : ", paramsString);
            
            try {
                sendCommandDataCatched(paramsString,
                                       callBack,
                                       errorCallBack,
                                       isRefresh);
            } catch( e:Error ) {
                Log.loggingException("SharedDataSender.sendCommandData()", e);
            }
            Log.loggingTuning("==>End sendCommandData");
        }
        
        public function createPlayRoom(playRoomName:String,
                                       playRoomPassword:String,
                                       chatChannelNames:Array,
                                       canUseExternalImage:Boolean,
                                       canVisit:Boolean,
                                       gameType:String,
                                       viewStates:Object,
                                       playRoomIndex:int,
                                       resultFunction:Function):void {
            var jsonData:Object = {
                "playRoomName": playRoomName,
                "playRoomPassword": playRoomPassword,
                "chatChannelNames": chatChannelNames,
                "canUseExternalImage": canUseExternalImage,
                "canVisit": canVisit,
                "gameType": gameType,
                "viewStates": viewStates,
                "playRoomIndex": playRoomIndex
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("createPlayRoom", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
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
            var jsonData:Object = {
                "playRoomName": playRoomName,
                "playRoomPassword": playRoomPassword,
                "chatChannelNames": chatChannelNames,
                "canUseExternalImage": canUseExternalImage,
                "canVisit": canVisit,
                "backgroundImage": backgroundImage,
                "gameType": gameType,
                "viewStates": viewStates
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("changePlayRoom", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function requestImageList(resultFunction:Function):void {
            var jsonData:Object = {
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getImageList", [["imageData", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function requestImageTagInfosAndImageList(resultFunction:Function):void {
            var params:String = this.getParamString("getImageTagsAndImageList", []);
            this.sendCommandData(params, resultFunction);
        }
        
        public function clearGraveyard(resultFunction:Function):void {
            var params:String = this.getParamString("clearGraveyard", []);
            this.sendCommandData(params, resultFunction);
        }
        
        public function requestGraveyard(resultFunction:Function):void {
            var params:String = this.getParamString("getGraveyardCharacterData", []);
            this.sendCommandData(params, resultFunction);
        }
        
        public function getWaitingRoomInfo(resultFunction:Function):void {
            var params:String = this.getParamString("getWaitingRoomInfo", []);
            this.sendCommandData(params, resultFunction);
        }
        
        public function getPlayRoomStates(minRoom:int, maxRoom:int, resultFunction:Function):void {
            var jsonData:Object = {"minRoom": minRoom,
                                   "maxRoom" : maxRoom };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getPlayRoomStates", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function getLoginInfo(resultFunction:Function, uniqueId:String = null):void {
            var jsonData:Object = {"uniqueId": uniqueId};
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getLoginInfo", [["params", jsonParams]]);
            
            this.sendCommandData(params, resultFunction);
        }

        public function uploadImageUrl(imageUrl:String, tagInfo:Object, resultFunction:Function):void {
            var jsonData:Object = {"imageUrl": imageUrl,
                                   "tagInfo" : tagInfo };
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            
            var params:String = this.getParamString("uploadImageUrl", [["imageData", jsonParams]]);
            this.sendCommandData(params, resultFunction);
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
        
        protected var visiterCommands:Array = ["loginPassword", "getLoginInfo", "checkRoomStatus",
                                             "refresh", "sendChatMessage"];
        
        protected function isIgnoreCommandAtVisiterMode(commandName:String):Boolean {
            if( ! DodontoF_Main.getInstance().isVisiterMode() ) {
                return false;
            }
            
            return isIgnoreCommand(commandName, visiterCommands);
        }
        
        protected function getParamString(commandName:String, params:Array):String {
            Log.logging("getParamString begin");
            
            if( isIgnoreCommandAtMentenanceMode(commandName) ) {
                return null;
            }
            
            if( isIgnoreCommandAtVisiterMode(commandName) ) {
                return null;
            }
            
            params.push(["Command", commandName]);
            params.push(["saveDataDirIndex", this.saveDataDirIndex]);
            params.push(["commandSender", getStrictlyUniqueId()]);
            
            Log.logging("paramString creating...");
            var paramString:String = new String();
            
            Log.logging("params analyzing ");
            for(var i:int = 0 ; i < params.length ; i++) {
                var param:Array = params[i] as Array;
                
                if( i != 0 ) {
                    paramString += "&";
                }
                
                paramString += param[0];
                paramString += "=";
                paramString += param[1];
            }
            
            Log.logging("getParamString paramString: " + paramString);
            
            return paramString;
        }
        
        public function startSessionRecording():void {
            var tmpTimes:Object = getInitLastUpdateTimes();
            tmpTimes.chatMessageDataLog = lastUpdateTimes.chatMessageDataLog;
            lastUpdateTimes = tmpTimes;
            receiver.startHistory();
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
        
        protected function getUrlRequestForSendCommandData(paramsString:String):URLRequest {
            Log.logging("var request:URLRequest = new URLRequest();");
            var request:URLRequest = new URLRequest();
            request.url = Config.getInstance().getDodontoFServerCgiUrl();
            request.method = URLRequestMethod.POST;
            
            Log.logging("POST to", request.url);
            Log.logging("var variables:URLVariables = new URLVariables(paramsString);");
            var variables:URLVariables = new URLVariables(paramsString);
            request.data = variables;
            
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
        
            
        
        protected function sendCommandDataCatched(paramsString:String,
                                                  callBack:Function,
                                                  errorCallBack:Function,
                                                  isRefresh:Boolean = false):void {
            if( paramsString == null ) {
                return;
            }
            
            var request:URLRequest = getUrlRequestForSendCommandData(paramsString);
            
            /*
            if( callBack == null ) {
                Log.loggingTuning("sendToURL begin");
                sendToURL(request);
                Log.loggingTuning("sendToURL end");
                return;
            }
            */
            
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
        
        public static function getJsonString(jsonData:Object):String {
            return Utils.getJsonString(jsonData);
        }
        
        public function getEncodedJsonString(jsonData:Object):String {
            return Utils.getEncodedJsonString(jsonData);
        }
        
        public function getExistPiecesCount():int {
            return map.getExistPiecesCount();
        }
        
        public function removePlayRoom(roomNumbers:Array, resultFunction:Function, ignoreLoginUser:Boolean):void {
            var jsonData:Object = {
                "roomNumbers": roomNumbers,
                "ignoreLoginUser": ignoreLoginUser
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            
            var params:String = this.getParamString("removePlayRoom", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function removeReplayData(replayData:Object, resultFunction:Function):void {
            Log.loggingTuning("SharedDataSender.removeReplayData replayData", replayData);
            
            var jsonParams:String = getEncodedJsonString( replayData );
            
            var params:String = this.getParamString("removeReplayData", [["replayData", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function addEffect(params_:Object):void {
            var jsonParams:String = getEncodedJsonString( params_ );
            var params:String = this.getParamString("addEffect", [["effectData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function changeEffect(params_:Object):void {
            var jsonParams:String = getEncodedJsonString( params_ );
            var params:String = this.getParamString("changeEffect", [["effectData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function removeEffect(effectId:String):void {
            var jsonData:Object = {
                "effectId": effectId
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("removeEffect", [["effectData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function changeImageTags(params_:Object):void {
            var jsonParams:String = getEncodedJsonString( params_ );
            var params:String = this.getParamString("changeImageTags", [["tagsData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function initCards(cardTypes:Array, resultFunction:Function):void {
            var jsonData:Object = {
                "cardTypeInfos": cardTypes
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("initCards", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function shuffleForNextRandomDungeon(mountName:String, mountId:String):void {
            var jsonData:Object = {
                "mountName": mountName,
                "mountId": mountId
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("shuffleForNextRandomDungeon", [["params", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function clearCards():void {
            var jsonData:Object = {
                "types": [Card.getTypeStatic(), CardMount.getTypeStatic()]
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("clearCharacterByType", [["clearData", jsonParams]]);
            this.sendCommandData(params);
        }
        
        
        private function drawCardOnLocal(getJsonDataFunction:Function,
                                         owner:String,
                                         imgId:String,
                                         x:int,
                                         y:int):void {
            
            var text:String = "<p align='center'><font size=\"72\">LOADING...</font><p>";
            var cardJsonData:Object = getJsonDataFunction(text, text, x, y);
            
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
                                  count:int):void {
            
            drawCardOnLocal(Card.getJsonData, owner, newCardImgId, x, y);
            
            var jsonData:Object = {
                "isOpen": isOpen,
                "mountName": mountName,
                "owner": owner,
                "ownerName":ownerName,
                "x": x,
                "y": y,
                "imgId": imgId,
                "count": count
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("drawCard", [["params", jsonParams]]);
            
            var resultFunction:Function = function(event:Event):void {
                var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
                var result:String = jsonData.result;
                if( result != "OK" ) {
                    receiver.removeCharacterOnlyOwnMap(event);
                }
            };
            
            this.sendCommandData(params, resultFunction);
        }
        
        private function getCloneCardJsonData(cardJsonData:Object, x:int, y:int):Object {
            
            cardJsonData = Utils.clone(cardJsonData);
            cardJsonData.imgId = MovablePiece.getDefaultId();
            cardJsonData.x = x;
            cardJsonData.y = y;
            cardJsonData.draggable = false;
            cardJsonData.ownerName = "(作成中・・・)";
            
            return cardJsonData;
        }
        
        public function exitWaitingRoomCharacter(characterId:String, x:int, y:int, resultFunction:Function):void {
            var jsonData:Object = {
                "characterId" : characterId,
                "x" : x,
                "y" : y};
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("exitWaitingRoomCharacter", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }

        public function enterWaitingRoomCharacter(characterId:String, resultFunction:Function):void {
            var jsonData:Object = {
                "characterId" : characterId};
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("enterWaitingRoomCharacter", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
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
            
            var jsonData:Object = {
                "owner" : ownerId,
                "ownerName" : ownerName,
                "mountId" : mountId,
                "mountName" : mountName,
                "targetCardId" : targetCardId,
                "x": x,
                "y": y
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("drawTargetCard", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
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
            
            var jsonData:Object = {
                "mountName" : mountName,
                "targetCardId" : targetCardId,
                "x": x,
                "y": y,
                "mountId" : mountId
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("drawTargetTrushCard", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function returnCard( mountName:String,
                                    x:int,
                                    y:int,
                                    id_:String ):void {
            var jsonData:Object = {
                "mountName": mountName,
                "x": x,
                "y": y,
                "imgId": id_
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("returnCard", [["params", jsonParams]]);
            this.sendCommandData(params);
        }
        
        
        public function shuffleCards( mountName:String, id_:String, isShuffle:Boolean ):void {
            var jsonData:Object = {
                "mountName": mountName,
                "mountId": id_,
                "isShuffle": isShuffle
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("shuffleCards", [["params", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function dumpTrushCard( targetCardId:String, mountName:String, id_:String ):void {
            var jsonData:Object = {
                "dumpedCardId": targetCardId,
                "mountName": mountName,
                "trushMountId": id_
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("dumpTrushCards", [["data", jsonParams]]);
            this.sendCommandData(params);
        }
        
        public function getMountCardInfos(mountNameForDisplay:String, mountName:String, mountId:String, resultFunction:Function):void {
            DodontoF_Main.getInstance().getChatWindow().sendSystemMessage("が「" + mountNameForDisplay + "」の山札を参照しています。");
            
            var jsonData:Object = {
                "mountName": mountName,
                "mountId": mountId
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getMountCardInfos", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
        
        public function getTrushMountCardInfos(mountName:String, mountId:String, resultFunction:Function):void {
            var cardName:String = InitCardWindow.getCardName(mountName);
            DodontoF_Main.getInstance().getChatWindow().sendSystemMessage("が「" + cardName + "」の捨て札を参照しています。");
            
            var jsonData:Object = {
                "mountName": mountName,
                "mountId": mountId
            };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getTrushMountCardInfos", [["params", jsonParams]]);
            this.sendCommandData(params, resultFunction);
        }
    }
}

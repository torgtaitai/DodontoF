//--*-coding:utf-8-*--

package {
    
    import com.adobe.serialization.json.JSON;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.FileFilter;
    import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.net.sendToURL;
    import flash.utils.*;
    import mx.controls.Alert;
    import mx.controls.Alert;
    import mx.rpc.AbstractOperation;
    import mx.rpc.AsyncToken;
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    import mx.rpc.remoting.Operation;
    import mx.rpc.remoting.mxml.RemoteObject;
    import mx.utils.StringUtil;    
    import ym.net.HTTPPostBinary;
    
    
    public class SharedDataSenderForGaeJava extends SharedDataSender {
        
        private var thisObj:SharedDataSenderForGaeJava = null;
        
        
        public function SharedDataSenderForGaeJava() {
            thisObj = this;
        }
        
        override public function checkRoomStatus(roomNumber:int, adminPassword:String, resultFunction:Function):void {

            var jsonData:Object = {
                "isRoomExist" : true,
                "roomName" : "GoogleWave",
                "roomNumber" : roomNumber,
                "isPasswordLocked" : false,
                "isMentenanceModeOn" : false
            }
            resultFunction(jsonData);
        }
        
        override public function sendRoundTimeData(round:int, initiative:Number, counterNames:Array):void {
            var jsonData:Object = {"round": round,
                                   "initiative": initiative,
                                   "counterNames": counterNames};
            this.sendCommand("changeRoundTime", jsonData);
        }
        
        
        override public function refresh(obj:Object = null):void {
            if( isStopRefreshOn ) {
                return;
            }
            
            this.refreshIndex++;
            
            var userName:String = getUserName();
            
            var jsonData:Object = {
                "lastUpdateTimes": this.lastUpdateTimes,
                "refreshIndex": this.refreshIndex,
                "uniqueId": this.getUniqueId(),
                "userName": userName};
            
            if( DodontoF_Main.getInstance().getMentenanceModeOn() ) {
                jsonData.uniqueId = -1;
            }
            
            sendCommand("refresh", jsonData, receiver.analyzeRefreshResponse);
        }
        
        override public function changeMap(mapImageUrl:String, 
                                  mapWidth:int,
                                  mapHeight:int, 
                                  gridColor:uint,
                                  mapMarks:Array):void {
            var changeMapJsonData:Object = {
                "mapType": "imageGraphic",
                "imageSource": mapImageUrl,
                "xMax": mapWidth,
                "yMax": mapHeight,
                "gridColor": gridColor,
                "mapMarks": mapMarks};
            
            sendCommand("changeMap", changeMapJsonData);
        }
        
        override public function addCharacter(characterJsonData:Object, keyName:String = "name"):void {
            Log.logging("SharedDataSender.addCharacter() begin characterJsonData", characterJsonData);
            
            Log.logging("receiver.addCharacterInOwnMap(characterJsonData) begin");
            var tmpCharacterJsonData:Object = Utils.clone(characterJsonData);
            tmpCharacterJsonData[keyName] = "(作成中・・・)" + tmpCharacterJsonData[keyName];
            receiver.addCharacterInOwnMap(tmpCharacterJsonData);
            Log.logging("receiver.addCharacterInOwnMap(characterJsonData) end");
            
            sendCommand("addCharacter", characterJsonData, printAddFailedCharacterName);
            
            Log.logging("SharedDataSender.addCharacter() end");
        }
        
        override public function printAddFailedCharacterName(event:Object):void {
            var jsonData:Object = SharedDataReceiver.getJsonDataFromResultEvent(event);
            
            if( jsonData.addData != null) {
                Log.loggingError("result.addData : " + jsonData.addData);
            }
            
            var addFailedCharacterNames:Array = jsonData.addFailedCharacterNames;
            if( addFailedCharacterNames.length == 0 ) {
                return;
            }
            var message:String = "\"" + addFailedCharacterNames.join("\" \"") + "\"という名前のキャラクターはすでに存在するため追加に失敗しました。";
            
            DodontoF_Main.getInstance().getChatWindow().sendSystemMessage(message, false);
        }
        
        override public function moveCharacter(movablePiece:MovablePiece, x:Number, y:Number):void {
            var moveData:Object = {"imgId": movablePiece.getId(), "x": x, "y": y};
            sendCommand("moveCharacter", moveData);
        }
        
        override public function sendChatMessage(jsonData:Object):void {
            
            sendCommand("sendChatMessage", jsonData);
            /*
            
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("sendChatMessage", [["chatMessageData", jsonParams]]);
            
            this.sendCommandData(params);
            */
        }
        
        
        override public function requestImageTagInfosAndImageList(resultFunction:Function):void {
            //var params:String = this.getParamString("getImageTagsAndImageList", []);
            //this.sendCommandData(params, resultFunction);
            sendCommand("requestImageTagInfosAndImageList", null, resultFunction);
        }
        
        override public function getPlayRoomStates(minRoom:int, maxRoom:int, resultFunction:Function):void {
            var jsonData:Object = {"minRoom": minRoom,
                                   "maxRoom" : maxRoom };
            var jsonParams:String = getEncodedJsonString( jsonData );
            var params:String = this.getParamString("getParamString", [["params", jsonParams]]);
            sendCommand("getPlayRoomStates", params, resultFunction);
        }
        
        override public function requestLoginInfo(resultFunction:Function):void {
            var params:String = this.getParamString("getLoginInfo", [[]]);
            sendCommand("requestLoginInfo", params, resultFunction);
        }
        
        public function sendCommand(commandName:String, 
                                    params:Object,
                                    resultFunction:Function = null,
                                    errorFunction:Function = null):void {
            var service:RemoteObject = new RemoteObject("Main");
            
            if( resultFunction != null ) {
                service.addEventListener(ResultEvent.RESULT, resultFunction);
            }
            if( errorFunction != null ) {
                service.addEventListener(ResultEvent.RESULT, errorFunction);
            }
            
            var method:AbstractOperation = service.getOperation(commandName);
            var roomNumber:String = String(this.saveDataDirIndex);
            var token:AsyncToken = method.send(roomNumber, params);
        }
        
        
        
        private function onFault(faultEvent:FaultEvent):void {
            Alert.show("faultDetail : " + faultEvent.fault.faultDetail);
        }
        
        private function onResult(resultEvent:ResultEvent):void {
            var result:Object = resultEvent.result;
            Alert.show("result : " + Utils.getJsonString(result));
            Alert.show("result.loginMessage : " + Utils.getJsonString(result.loginMessage));
        }
        
        private function sampleRemoteCall(resultFunction:Function):void {
            var mainService:RemoteObject = new RemoteObject("Main");
            mainService.addEventListener(ResultEvent.RESULT, onResult);
            mainService.addEventListener(FaultEvent.FAULT, onFault);
            
            // メソッド呼び出し
            //var method:AbstractOperation = mainService.getOperation("sayhello");
            //var token:AsyncToken = method.send();
            
            //var method:AbstractOperation = mainService.getOperation("sendParam");
            //var token:AsyncToken = method.send("mokekeke!!!");
            
            var method:AbstractOperation = mainService.getOperation("requestLoginInfo");
            var token:AsyncToken = method.send();
            
            
            /*
            var result:Object = {
                "playRoomStates" : [{"loginUsers":[],"passwordLockState":"--","lastUpdateTime":"---","loginUserCount":0,"index":"0","playRoomName":"samplePlayRoom"}],
                "loginMessage" : "loginMessage",
                "autoLoginRoom" : 0,
                "cardInfos" : [{"title":"TRUMP","type":"trump_jorker3"},{"title":"TORG","type":"torg"}],
                "isDiceBotOn" : true,
                "uniqueId" : getUniqueIdOnWave(),
                "refreshTimeout" : 10,
                "version" : "Ver.1.30.04(2011/04/06)",
                "playRoomMaxNumber" : 1
            };
            
            resultFunction(result);
            */
        }
        
        
    }
}

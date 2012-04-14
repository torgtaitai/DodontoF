//--*-coding:utf-8-*--
package {
    import mx.utils.StringUtil;
    import flash.net.FileReference;
    
	public class GuiInputSender {
        
        private var sender:SharedDataSender;
        private var feetsLimit:int = 100;
        private var characterCreationLimit:int = 10;
        private var maskCreationLimit:int = 100;
        private var playRoomMaxNumber:int = 100;
        
        public function GuiInputSender() {
        }
        
        public function setSender(sender_:SharedDataSender):void {
            sender = sender_;
        }
        
        public function getSender():SharedDataSender {
            return sender;
        }
        
        public function setPlayRoomMaxNumber(n:int):void {
            playRoomMaxNumber = n;
        }
        
        public function saveFileDownload(saveFileName:String, resultFunction:Function):void {
            sender.saveFileDownload(saveFileName, resultFunction);
        }
        
        public function saveScenario(chatPalleteData:String, resultFunction:Function):void {
            sender.saveScenario(chatPalleteData, resultFunction);
        }
        
        public function save(resultFunction:Function):void {
            sender.save(resultFunction);
        }
        
        public function saveMap(resultFunction:Function):void {
            sender.saveMap(resultFunction);
        }
        
        public function clearLastUpdateTimes():void {
            sender.clearLastUpdateTimes();
        }
        
        public function load_(params:Object, resultFunction:Function):void {
            sender.load(params, resultFunction);
        }
        
        public function loadMap(params:Object):void {
            sender.loadMap(params);
        }
        
        public function checkRoomNumber(roomNumber:int):void {
            if( (roomNumber < 0) || (roomNumber > playRoomMaxNumber) ) {
                throw new Error("ルームNo.は0〜" + playRoomMaxNumber + "の値を設定してください。");
            }
        }
        
        public function checkRoomStatus(roomNumber:int, adminPassword:String, resultFunction:Function):void {
            checkRoomNumber(roomNumber);
            sender.checkRoomStatus(roomNumber, adminPassword, resultFunction);
        }
        
        public function loginPassword(roomNumber:int, password:String,
                                      visiterMode:Boolean, resultFunction:Function):void {
            sender.loginPassword(roomNumber, password, visiterMode, resultFunction);
        }
        
        public function getRoomNumber():int {
            return sender.getRoomNumber();
        }
        
        public function getRoomNumberName():String {
            var number:int = sender.getRoomNumber();
            if( number > playRoomMaxNumber ) {
                return "お試しルーム";
            }
            
            return "ルーム" + number;
        }
        
        public function uploadImageFile(fileReferenceForImageUpload:FileReference,
                                        params:Object):void {
            sender.uploadImageFile(fileReferenceForImageUpload, params);
        }
        
        public function uploadImageData(params:Object, resultFunction:Function, errorFunction:Function):void {
            sender.uploadImageData(params, resultFunction, errorFunction);
        }
        
        public function changeMap(mapImageUrl:String,
                                  mirrored:Boolean,
                                  mapWidth:int,
                                  mapHeight:int,
                                  gridColor:uint,
                                  gridInterval:int,
                                  isAlternately:Boolean,
                                  mapMarks:Array):void {
            if( ( mapHeight < 1 ) ||
                ( mapHeight > ChangeMapWindow.getMapMaxHeigth() )) {
                throw new Error("縦マス数の入力値が不正です。1〜" + ChangeMapWindow.getMapMaxHeigth() + "の整数を入力してください。");
            }
                
            if( ( mapWidth < 1 ) ||
                ( mapWidth > ChangeMapWindow.getMapMaxWidth() )) {
                throw new Error("横マス数の入力値が不正です。1〜" + ChangeMapWindow.getMapMaxWidth() + "の整数を入力してください。");
            }
            
            sender.changeMap(mapImageUrl, mirrored, mapWidth, mapHeight,
                             gridColor, gridInterval, isAlternately, mapMarks);
        }
        
        public function deleteImage(imageUrlList:Array,
                                    resultFunction:Function):void {
            sender.deleteImage(imageUrlList, resultFunction);
        }
        
        public function getAndCheckAddCharacterParams(characterName:String, imageUrl:String,
                                                      mirrored:Boolean,
                                                      size:int, isHide:Boolean,
                                                      initiative:Number, info:String,
                                                      counters:Object, statusAlias:Object,
                                                      url:String):Object {
            Log.logging("getAndCheckAddCharacterParams start");
            Log.logging("characterName", characterName);
            Log.logging("imageUrl", imageUrl);
            Log.logging("size", size);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            Log.logging("counters", counters);
            Log.logging("statusAlias", statusAlias);
            
            if( characterName.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            if( imageUrl.length == 0 ) {
                throw new Error("イメージ画像のURLを入力してください。");
            }
            
            if( ( size < 1 ) || ( size > 10 ) ) {
                throw new Error("サイズの入力値が不正です。1〜10の整数を入力してください。");
            }
            
            if( counters == null ) {
                throw new Error("カウンター値が不正です。");
            }
            
            if( statusAlias == null ) {
                throw new Error("ステータスエイリアスが不正です。");
            }
            
            Log.logging("createLoop");
            
            var createName:String = characterName;
            
            var characterParams:Object = new Object;
            characterParams.name = characterName;
            characterParams.imageUrl = imageUrl;
            characterParams.mirrored = mirrored;
            characterParams.size = size;
            characterParams.isHide = isHide;
            characterParams.initiative = initiative;
            characterParams.info = info;
            characterParams.counters = counters;
            characterParams.statusAlias = statusAlias;
            characterParams.url = url;
            
            return characterParams;
        }
        
        public function addCharacter(name:String, imageUri:String, mirrored:Boolean,
                                     size:int, isHide:Boolean,
                                     initiative:Number, info:String,
                                     characterPositionX:int, characterPositionY:int,
                                     dogTag:String, counters:Object, statusAlias:Object,
                                     url:String):void {
            
            var characterJsonData:Object =
                Character.getJsonData(name, imageUri, mirrored,
                                      size, isHide,
                                      initiative, info, 0,
                                      characterPositionX, characterPositionY,
                                      dogTag, counters, statusAlias,
                                      url);
            sender.addCharacter(characterJsonData);
            
            Log.logging("addCharacter end");
        }
        
        public function addMapMask(width:int,
                                   height:int,
                                   name:String,
                                   color:int,
                                   alpha:Number,
                                   createPositionX:int, createPositionY:int):void {
            Log.logging("addMapMask start");
            Log.logging("width", width);
            Log.logging("height", height);
            Log.logging("color", color);
            Log.logging("GuiInputSender createPositionX", createPositionX);
            Log.logging("GuiInputSender createPositionY", createPositionY);
            
            if( width < 0 ) {
                throw new Error("幅が不正な値です。");
            }
            
            if( height < 0 ) {
                throw new Error("高さが不正な値です。");
            }
            
            if( (createPositionX < 0) || (createPositionY < 0) ) {
                throw new Error("設置X,Y座標が0未満の値になっています。");
            }
            
            var characterJsonData:Object =
                MapMask.getJsonData(width, height, name, color, alpha, createPositionX, createPositionY);
            sender.addCharacter(characterJsonData);
            
            Log.logging("addCharacter end");
        }
        
        public function addMapMarker(message:String, color:uint,
                                     isPaint:Boolean,
                                     width:int, height:int,
                                     characterPositionX:int, characterPositionY:int):void {
            if( message.length == 0 ) {
                throw new Error("メッセージを入力してください。");
            }
            
            var characterJsonData:Object =
                MapMarker.getJsonData(message, color,
                                      isPaint, 
                                      width, height, 
                                      characterPositionX, characterPositionY);
            
            sender.addCharacter(characterJsonData, "message");
            
            Log.logging("addMagicRange end");
        }
        
        public function addMagicRange(name:String, feets:int, type:String, color:String,
                                      timeRange:int,
                                      createRound:Number,
                                      initiative:Number,
                                      info:String,
                                      characterPositionX:int, characterPositionY:int):void {
            Log.logging("GuiInputSender addMagicRange characterPositionX", characterPositionX);
            Log.logging("GuiInputSender addMagicRange characterPositionY", characterPositionY);
            Log.logging("timeRange", timeRange);
            Log.logging("createRound", createRound);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) || ((feets % 5) != 0) ) {
                throw new Error("半径の入力値が不正です。1〜" + feetsLimit + "の整数で5の倍数を入力してください。");
            }
            
            if( type.length == 0 ) {
                throw new Error("魔法範囲種別を選択してください。");
            }
            
            if( color.length == 0 ) {
                throw new Error("色を選択してください");
            }
            
            if( (characterPositionX < 0) || (characterPositionY < 0) ) {
                throw new Error("設置X,Y座標が0未満の値になっています。");
            }
            
            var characterJsonData:Object =
                MagicRange.getJsonData(name, feets, type, color,
                                       timeRange,
                                       createRound,
                                       initiative,
                                       info,
                                       characterPositionX, characterPositionY);
            sender.addCharacter(characterJsonData);

            Log.logging("addMagicRange end");
        }

        public function addMagicRangeDD4th(name:String,
                                           feets:int,
                                           type:String,
                                           color:String,
                                           timeRange:int,
                                           createRound:Number,
                                           initiative:Number,
                                           info:String,
                                           characterPositionX:int,
                                           characterPositionY:int):void {
            Log.logging("GuiInputSender addMagicRange characterPositionX", characterPositionX);
            Log.logging("GuiInputSender addMagicRange characterPositionY", characterPositionY);
            Log.logging("timeRange", timeRange);
            Log.logging("createRound", createRound);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) ) {
                throw new Error("半径の入力値が不正です。1〜" + feetsLimit + "の整数を入力してください。");
            }
            
            if( type.length == 0 ) {
                throw new Error("魔法範囲種別を選択してください。");
            }
            
            if( color.length == 0 ) {
                throw new Error("色を選択してください");
            }
            
            if( (characterPositionX < 0) || (characterPositionY < 0) ) {
                throw new Error("設置X,Y座標が0未満の値になっています。");
            }
            
            var characterJsonData:Object =
                MagicRangeDD4th.getJsonData(name, feets, type, color,
                                            timeRange,
                                            createRound,
                                            initiative,
                                            info,
                                            characterPositionX, characterPositionY);
            Log.logging("addMagicRangeDD4th sender.addCharacter begin");
            sender.addCharacter(characterJsonData);
            Log.logging("addMagicRangeDD4th sender.addCharacter end");
            
            Log.logging("addMagicRange end");
        }

        public function addMagicTimer(name:String,
                                      timeRange:int,
                                      createRound:Number,
                                      initiative:Number,
                                      info:String):void {
            Log.logging("timeRange", timeRange);
            Log.logging("createRound", createRound);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            var characterJsonData:Object =
                MagicTimer.getJsonData(name,
                                       timeRange,
                                       createRound,
                                       initiative,
                                       info);
            sender.addCharacter(characterJsonData);
            
            Log.logging("addMagicTimer end");
        }
        
        public function changeCharacter(character:Character,
                                        name:String, imageUri:String, mirrored:Boolean,
                                        size:int, isHide:Boolean,
                                        initiative:Number, info:String,
                                        counters:Object, statusAlias:Object,
                                        url:String):void {
            Log.logging("changeCharacter start");
            Log.logging("name", name);
            Log.logging("imageUri", imageUri);
            Log.logging("size", size);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            if( imageUri.length == 0 ) {
                throw new Error("イメージ画像のURLを入力してください。");
            }
            
            if( ( size < 1 ) || ( size > 10 ) ) {
                throw new Error("サイズの入力値が不正です。1〜10の整数を入力してください。");
            }
            
            character.setName(name);
            character.setImageUrl(imageUri);
            character.setMirrored(mirrored);
            character.setSize(size);
            character.setHide(isHide);
            character.setInitiative(initiative);
            character.setInfo(info);
            character.setCounters(counters);
            character.setStatusAlias(statusAlias);
            character.setUrl(url);
            character.updateRefresh();
            
            sender.changeCharacter( character.getJsonData() );
            
            Log.logging("changeCharacter end");
        }
        
        public function changeMagicRange(magicRange:MagicRange,
                                         name:String,
                                         feets:int,
                                         rangeType:String,
                                         color:String,
                                         info:String,
                                         timeRange:int):void {
            Log.logging("changeMagicRange start");
            Log.logging("name", name);
            Log.logging("rangeType", rangeType);
            Log.logging("feet", feets);
            Log.logging("info", info);
            Log.logging("timeRange", timeRange);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) || ((feets % 5) != 0) ) {
                throw new Error("半径の入力値が不正です。1〜" + feetsLimit + "の整数で5の倍数を入力してください。");
            }
            
            if( rangeType.length == 0 ) {
                throw new Error("範囲タイプを選択してください。");
            }
            
            if( color.length == 0 ) {
                throw new Error("色を選択してください。");
            }
            
            if( timeRange < 1 ) {
                throw new Error("持続時間の値範囲が不正です。1以上の値を入力してください。");
            }
            
            magicRange.setName(name);
            magicRange.setFeets(feets);
            magicRange.setRangeType(rangeType);
            magicRange.setColor( parseInt(color) );
            magicRange.setInfo(info);
            magicRange.setTimeRange(timeRange);
            
            sender.changeCharacter( magicRange.getJsonData() );
            
            Log.logging("changeMagicRange end");
        }
        
        public function changeMagicRangeDD4th(magicRange:MagicRange,
                                         name:String,
                                         feets:int,
                                         rangeType:String,
                                         color:String,
                                         info:String,
                                         timeRange:int):void {
            Log.logging("changeMagicRangeDD4th start");
            Log.logging("name", name);
            Log.logging("rangeType", rangeType);
            Log.logging("feet", feets);
            Log.logging("info", info);
            Log.logging("timeRange", timeRange);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) ) {
                throw new Error("半径の入力値が不正です。1〜" + feetsLimit + "の整数で5の倍数を入力してください。");
            }
            
            if( rangeType.length == 0 ) {
                throw new Error("範囲タイプを選択してください。");
            }
            
            if( color.length == 0 ) {
                throw new Error("色を選択してください。");
            }
            
            if( timeRange < 1 ) {
                throw new Error("持続時間の値範囲が不正です。1以上の値を入力してください。");
            }
            
            magicRange.setName(name);
            magicRange.setFeets(feets);
            magicRange.setRangeType(rangeType);
            magicRange.setColor( parseInt(color) );
            magicRange.setInfo(info);
            magicRange.setTimeRange(timeRange);
            
            sender.changeCharacter( magicRange.getJsonData() );
            
            Log.logging("changeMagicRangeDD4th end");
        }
        
        public function changeMagicTimer(magicTimer:MagicTimer,
                                         name:String,
                                         timeRange:int,
                                         createRound:Number,
                                         initiative:Number,
                                         info:String):void {
            Log.logging("name", name);
            Log.logging("timeRange", timeRange);
            Log.logging("createRound", createRound);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error("名前を入力してください。");
            }
            
            magicTimer.setName(name);
            magicTimer.setInfo(info);
            magicTimer.setInitiative(initiative);
            magicTimer.setTimeRange(timeRange);
            magicTimer.setCreateRound(createRound);
            
            sender.changeCharacter( magicTimer.getJsonData() );
            
            Log.logging("addMagicTimer end");
        }
        
        public function resurrectCharacter(resurrectCharacterId:String, resultFunction:Function):void {
            Log.logging("resurrectCharacterId", resurrectCharacterId);
            
            if( resurrectCharacterId.length == 0 ) {
                throw new Error("復活させたいキャラクターのＩＤを入力してください。");
            }
            
            sender.resurrectCharacter(resurrectCharacterId, resultFunction);
            Log.logging("resurrectCharacter end");
        }
        
        public function clearGraveyard(resultFunction:Function):void {
            sender.clearGraveyard(resultFunction);
        }
        
        public function requestGraveyard(requestGraveyardResult:Function):void {
            sender.requestGraveyard(requestGraveyardResult);
        }
        
        public function getWaitingRoomInfo(resultFunction:Function):void {
            sender.getWaitingRoomInfo(resultFunction);
        }
        
        public function getPlayRoomStates(minRoom:int, maxRoom:int, resultFunction:Function):void {
            sender.getPlayRoomStates(minRoom, maxRoom, resultFunction);
        }
        
        public function getLoginInfo(resultFunction:Function, uniqueId:String = null):void {
            sender.getLoginInfo(resultFunction, uniqueId);
        }
        
        public function sendDiceBotChatMessage(chatSendData:ChatSendData,
                                               randomSeed:int, gameType:String, callBack:Function):void {
            sender.sendDiceBotChatMessage(chatSendData,
                                          randomSeed, gameType, callBack);
        }
        
        public function sendChatMessage(chatCharacterName:String, message:String,
                                        color:String, messageIndex:int,
                                        sendto:String = null,
                                        channel:int = 0):void {
            if( chatCharacterName.length == 0 ) {
                throw new Error("発言者を入力してください。");
            }
            if( message.length == 0 ) {
                //throw new Error("空メッセージは送信できません。");
                return;
            }
            
            var jsonData:Object = {
                "senderName": chatCharacterName,
                "message" : message,
                "color" : color,
                //"uniqueId" : sender.getUniqueId(),
                "uniqueId" : sender.getStrictlyUniqueId(),
                "messageIndex" : messageIndex,
                "channel": channel };
            
            if( ChatMessageTrader.isValidSendTo(sendto) ) {
                jsonData.sendto = sendto;
            }
            
            sender.sendChatMessage(jsonData);
        }
        
        public function sendChatMessageMany(chatCharacterName:String, chatMessage:String, color:String):void {
            if( chatCharacterName.length == 0 ) {
                throw new Error("発言者を入力してください。");
            }
            if( chatMessage.length == 0 ) {
                //throw new Error("空メッセージは送信できません。");
                return;
            }
            
            sender.sendChatMessageMany(chatCharacterName, chatMessage, color);
        }
        
        private function checkPlayRoom(playRoomName:String,
                                       playRoomPassword:String,
                                       chatChannelNames:Array):void {
            if( playRoomName == "" ) {
                throw new Error("プレイルーム名は必ず入力してください");
            }
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
            checkPlayRoom(playRoomName, playRoomPassword, chatChannelNames);
            sender.createPlayRoom(playRoomName, playRoomPassword, chatChannelNames, 
                                  canUseExternalImage, canVisit, gameType, viewStates, 
                                  playRoomIndex, resultFunction);
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
            checkPlayRoom(playRoomName, playRoomPassword, chatChannelNames);
            sender.changePlayRoom(playRoomName, playRoomPassword, chatChannelNames,
                                  canUseExternalImage, canVisit, backgroundImage,
                                  gameType, viewStates, 
                                  playRoomIndex, resultFunction);
        }
        
        public function setSaveDataDirIndex(roomNumber:int):void {
            sender.setSaveDataDirIndex(roomNumber);
        }
        
        /*
        public function requestImageList(result:Function):void {
            sender.requestImageList(result)
        }
        */
        
        public function uploadImageUrl(imageUrl:String, tagInfo:Object, resultFunction:Function):void {
            sender.uploadImageUrl(imageUrl, tagInfo, resultFunction);
        }
        
        public function removeCharacter(piece:Piece):void {
            sender.removeCharacter(piece);
        }
        
        public function removeCharacters(pieces:Array):void {
            sender.removeCharacters(pieces);
        }
        
        public function removePlayRoom(roomNumbers:Array, resultFunction:Function, ignoreLoginUser:Boolean):void {
            sender.removePlayRoom(roomNumbers, resultFunction, ignoreLoginUser);
        }
        
        public function removeReplayData(replayData:Object, resultFunction:Function):void {
            sender.removeReplayData(replayData, resultFunction);
        }
        
        public function addEffect(params:Object):void {
            sender.addEffect(params);
        }
        
        public function changeEffect(params:Object):void {
            sender.changeEffect(params);
        }
        
        public function removeEffect(effectId:String):void {
            sender.removeEffect(effectId);
        }
        
        public function getMountCardInfos(mountNameForDisplay:String, mountName:String, mountId:String, resultFunction:Function):void {
            sender.getMountCardInfos(mountNameForDisplay, mountName, mountId, resultFunction);
        }
        
        public function getTrushMountCardInfos(mountName:String, mountId:String, resultFunction:Function):void {
            sender.getTrushMountCardInfos(mountName, mountId, resultFunction);
        }
        
    }
}

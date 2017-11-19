//--*-coding:utf-8-*--
package {
    import mx.utils.StringUtil;
    import flash.net.FileReference;
    import flash.events.Event;
    
	public class GuiInputSender {
        
        private var sender:SharedDataSender;
        private var feetsLimit:int = 100;
        private var rangeLimit:int = 100;
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
        
        public function saveAllData(chatPalleteData:String, resultFunction:Function):void {
            sender.saveAllData(chatPalleteData, resultFunction);
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
        
        public function load(params:Object, resultFunction:Function):void {
            sender.load(params, resultFunction);
        }
        
        public function loadMap(params:Object):void {
            sender.loadMap(params);
        }
        
        public function checkRoomNumber(roomNumber:int):void {
            if( (roomNumber < 0) || (roomNumber > playRoomMaxNumber) ) {
                throw new Error( Language.text("checkRoomNumberWarning",
                                               playRoomMaxNumber) );
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
                                  mapMarks:Array, 
                                  mapMarksAlpha:Number):void {
            if( ( mapHeight < 1 ) ||
                ( mapHeight > ChangeMapWindow.getMapMaxHeigth() )) {
                throw new Error(Language.text("checkMapHeightWarning",
                                              ChangeMapWindow.getMapMaxHeigth()));
            }
                
            if( ( mapWidth < 1 ) ||
                ( mapWidth > ChangeMapWindow.getMapMaxWidth() )) {
                throw new Error(Language.text("checkMapWidthWarning",
                                              ChangeMapWindow.getMapMaxWidth()));
            }
            
            sender.changeMap(mapImageUrl, mirrored, mapWidth, mapHeight,
                             gridColor, gridInterval, isAlternately, mapMarks, mapMarksAlpha);
        }
        
        public function drawOnMap(data:Array):void {
            if( data == null ) {
                return;
            }
            if( data.length == 0 ) {
                return;
            }
            
            sender.drawOnMap(data);
        }
        
        public function clearDrawOnMap():void {
            sender.clearDrawOnMap();
        }
        
        public function undoDrawOnMap(resultFunction:Function):void {
            sender.undoDrawOnMap(resultFunction);
        }
        
        public function convertDrawToImage(fileData:Object):void {
            sender.convertDrawToImage(fileData);
        }
        
        public function deleteImage(imageUrlList:Array,
                                    resultFunction:Function):void {
            sender.deleteImage(imageUrlList, resultFunction);
        }
        
        public function getAndCheckAddCharacterParams(characterName:String,
                                                      imageUrl:String,
                                                      images:Array,
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
                throw new Error(Language.s.inputNameError);
            }
            
            if( imageUrl.length == 0 ) {
                throw new Error(Language.s.inputImageFileUrlError);
            }
            
            if( ( size < 1 ) || ( size > 10 ) ) {
                throw new Error(Language.s.sizeError);
            }
            
            if( counters == null ) {
                throw new Error(Language.s.counterValueError);
            }
            
            if( statusAlias == null ) {
                throw new Error(Language.s.statusAliasNameError);
            }
            
            Log.logging("createLoop");
            
            var createName:String = characterName;
            
            var characterParams:Object = new Object;
            characterParams.name = characterName;
            characterParams.imageUrl = imageUrl;
            characterParams.images = images;
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
        
        public function addCharacter(name:String,
                                     imageUri:String,
                                     images:Array,
                                     mirrored:Boolean,
                                     size:int, isHide:Boolean,
                                     initiative:Number, info:String,
                                     characterPositionX:int, characterPositionY:int,
                                     dogTag:String, counters:Object, statusAlias:Object,
                                     url:String):void {
            
            var characterJsonData:Object =
                Character.getJsonData(name,
                                      imageUri, 
                                      images,
                                      mirrored,
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
                throw new Error(Language.s.widthInvalidError);
            }
            
            if( height < 0 ) {
                throw new Error(Language.s.heightInvalidError);
            }
            
            if( (createPositionX < 0) || (createPositionY < 0) ) {
                throw new Error(Language.s.positionXYsmallerError);
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
                throw new Error(Language.s.inputMessageError);
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
                                      characterPositionX:int, characterPositionY:int,
                                      isHide:Boolean):void {
            Log.logging("GuiInputSender addMagicRange characterPositionX", characterPositionX);
            Log.logging("GuiInputSender addMagicRange characterPositionY", characterPositionY);
            Log.logging("timeRange", timeRange);
            Log.logging("createRound", createRound);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) || ((feets % 5) != 0) ) {
                throw new Error(Language.text("checkDD3rdRadiusWarning", feetsLimit));
            }
            
            if( type.length == 0 ) {
                throw new Error(Language.s.noMagirRangeErroro);
            }
            
            if( color.length == 0 ) {
                throw new Error(Language.s.noColorErro);
            }
            
            if( (characterPositionX < 0) || (characterPositionY < 0) ) {
                throw new Error(Language.s.positionXYsmallerError);
            }
            
            var characterJsonData:Object =
                MagicRange.getJsonData(name, feets, type, color,
                                       timeRange,
                                       createRound,
                                       initiative,
                                       info,
                                       characterPositionX, characterPositionY,
                                       isHide);
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
                                           characterPositionY:int,
                                           isHide:Boolean):void {
            Log.logging("GuiInputSender addMagicRange characterPositionX", characterPositionX);
            Log.logging("GuiInputSender addMagicRange characterPositionY", characterPositionY);
            Log.logging("timeRange", timeRange);
            Log.logging("createRound", createRound);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) ) {
                throw new Error(Language.text("checkDD4thRadiusWarning", feetsLimit));
            }
            
            if( type.length == 0 ) {
                throw new Error(Language.s.noMagirRangeError);
            }
            
            if( color.length == 0 ) {
                throw new Error(Language.s.noColorErro);
            }
            
            if( (characterPositionX < 0) || (characterPositionY < 0) ) {
                throw new Error(Language.s.positionXYsmallerError);
            }
            
            var characterJsonData:Object =
                MagicRangeDD4th.getJsonData(name, feets, type, color,
                                            timeRange,
                                            createRound,
                                            initiative,
                                            info,
                                            characterPositionX, characterPositionY,
                                            isHide);
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
                throw new Error(Language.s.inputNameError);
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
                                        name:String,
                                        imageUrl:String,
                                        images:Array,
                                        mirrored:Boolean,
                                        size:int, isHide:Boolean,
                                        initiative:Number, info:String,
                                        counters:Object, statusAlias:Object,
                                        url:String):void {
            Log.logging("changeCharacter start");
            Log.logging("name", name);
            Log.logging("imageUrl", imageUrl);
            Log.logging("size", size);
            Log.logging("initiative", initiative);
            Log.logging("info", info);
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            
            if( imageUrl.length == 0 ) {
                throw new Error(Language.s.noImageUrlError);
            }
            
            if( ( size < 1 ) || ( size > 10 ) ) {
                throw new Error(Language.s.sizeError);
            }
            
            character.setName(name);
            character.setImageUrl(imageUrl);
            character.setImages(images);
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
                                         timeRange:int,
                                         isHide:Boolean):void {
            Log.logging("changeMagicRange start");
            Log.logging("name", name);
            Log.logging("rangeType", rangeType);
            Log.logging("feet", feets);
            Log.logging("info", info);
            Log.logging("timeRange", timeRange);
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) || ((feets % 5) != 0) ) {
                throw new Error(Language.text("checkDD3rdRadiusWarning", feetsLimit));
            }
            
            if( rangeType.length == 0 ) {
                throw new Error(Language.s.noMagirRangeError);
            }
            
            if( color.length == 0 ) {
                throw new Error(Language.s.noColorErro);
            }
            
            if( timeRange < 1 ) {
                throw new Error(Language.s.invalidTimeRangeError);
            }
            
            magicRange.setName(name);
            magicRange.setFeets(feets);
            magicRange.setRangeType(rangeType);
            magicRange.setColor( parseInt(color) );
            magicRange.setInfo(info);
            magicRange.setTimeRange(timeRange);
            magicRange.setHide(isHide);
            
            magicRange.updateRefresh();
            
            sender.changeCharacter( magicRange.getJsonData() );
            
            Log.logging("changeMagicRange end");
        }
        
        public function changeMagicRangeDD4th(magicRange:MagicRange,
                                              name:String,
                                              feets:int,
                                              rangeType:String,
                                              color:String,
                                              info:String,
                                              timeRange:int,
                                              isHide:Boolean):void {
            Log.logging("changeMagicRangeDD4th start");
            Log.logging("name", name);
            Log.logging("rangeType", rangeType);
            Log.logging("feet", feets);
            Log.logging("info", info);
            Log.logging("timeRange", timeRange);
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            
            if( ( feets < 1 ) || ( feets > feetsLimit ) ) {
                throw new Error(Language.text("checkDD4thRadiusWarning", feetsLimit));
            }
            
            if( rangeType.length == 0 ) {
                throw new Error(Language.s.noMagirRangeError);
            }
            
            if( color.length == 0 ) {
                throw new Error(Language.s.noColorErro);
            }
            
            if( timeRange < 1 ) {
                throw new Error(Language.s.invalidTimeRangeError);
            }
            
            magicRange.setName(name);
            magicRange.setFeets(feets);
            magicRange.setRangeType(rangeType);
            magicRange.setColor( parseInt(color) );
            magicRange.setInfo(info);
            magicRange.setTimeRange(timeRange);
            magicRange.setHide(isHide);
            
            magicRange.updateRefresh();
            
            sender.changeCharacter( magicRange.getJsonData() );
            
            Log.logging("changeMagicRangeDD4th end");
        }
        
        public function changeLogHorizonRange(logHorizonRange:LogHorizonRange,
                                              name:String,
                                              range:int,
                                              color:String):void {
            Log.logging("changeLogHorizonRange begin");
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            
            if( ( range < 0 ) || ( range > rangeLimit ) ) {
                throw new Error(Language.text("checkDD4thRadiusWarning", rangeLimit));
            }
            
            if( color.length == 0 ) {
                throw new Error(Language.s.noColorErro);
            }
            
            logHorizonRange.setName(name);
            logHorizonRange.setRange(range)
            logHorizonRange.setColor( parseInt(color) );
            
            logHorizonRange.updateRefresh();
            
            sender.changeCharacter( logHorizonRange.getJsonData() );
            
            Log.logging("changeLogHorizonRange end");
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
                throw new Error(Language.s.inputNameError);
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
                throw new Error(Language.s.noCharacterIdWantToRessurectError);
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
        
        public function sendChatMessageAll(name:String, message:String, password:String):void {
            sender.sendChatMessageAll(name, message, password);
        }
        public function sendChatMessage(chatSendData:ChatSendData):void {
            var name:String = chatSendData.getNameAndState();
            var message:String = chatSendData.getMessage();
            var callBack:Function = chatSendData.getCallBack();
            
            if( name.length == 0 ) {
                throw new Error(Language.s.inputNameError);
            }
            if( message.length == 0 ) {
                return;
            }
            
            sender.sendChatMessage(chatSendData, callBack);
        }
        
        private function checkPlayRoom(playRoomName:String,
                                       playRoomPassword:String,
                                       chatChannelNames:Array):void {
            if( playRoomName == "" ) {
                throw new Error(Language.s.noPlayRoomError);
            }
        }
        
        private function checkChangePlayRoom(playRoomNameOriginal:String,
                                             playRoomName:String):void {
            if( playRoomNameOriginal == playRoomName ) {
                return;
            }
            
            var checker:Object = Config.getInstance().getWordChecker("changePlayRoomNameChecker");
            
            var targetText:String = playRoomName.replace(/(、|。|・|\/|\.|．|\t|　|_|＿)/g, '');
            
            for(var key:String in checker){
                if( targetText.search(key) != -1 ) {
                    var errorMessage:String = checker[key];
                    throw new Error( errorMessage );
                }
            }
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
            checkPlayRoom(playRoomName, playRoomPassword, chatChannelNames);
            sender.createPlayRoom(createPassword, playRoomName, playRoomPassword, chatChannelNames, 
                                  canUseExternalImage, canVisit, gameType, viewStates, 
                                  playRoomIndex, resultFunction);
        }
        
        public function changePlayRoom(playRoomNameOriginal:String,
                                       playRoomName:String,
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
            checkChangePlayRoom(playRoomNameOriginal, playRoomName);
            
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
        
        public function removePlayRoom(roomNumbers:Array, resultFunction:Function, ignoreLoginUser:Boolean,
                                       password:String, adminPassword:String,
                                       isForce:Boolean = false):void {
            sender.removePlayRoom(roomNumbers, resultFunction, ignoreLoginUser, password, adminPassword, isForce);
        }
        
        public function removeOldPlayRoom(resultFunction:Function):void {
            sender.removeOldPlayRoom(resultFunction);
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
        
        public function changeEffectsAll(params:Object):void {
            sender.changeEffectsAll(params);
        }
        
        public function removeEffect(effectIds:Array):void {
            sender.removeEffect(effectIds);
        }
        
        public function getMountCardInfos(mountNameForDisplay:String, mountName:String, mountId:String, resultFunction:Function):void {
            sender.getMountCardInfos(mountNameForDisplay, mountName, mountId, resultFunction);
        }
        
        public function getTrushMountCardInfos(mountName:String, mountId:String, resultFunction:Function):void {
            sender.getTrushMountCardInfos(mountName, mountId, resultFunction);
        }
        
        public function getCardList(mountName:String, resultFunction:Function):void {
            sender.getCardList(mountName, resultFunction);
        }
        
    }
}

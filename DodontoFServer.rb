#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
$LOAD_PATH << File.dirname(__FILE__) + "/src_bcdice"
$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

#CGI通信の主幹クラス用ファイル
#ファイルアップロード系以外は全てこのファイルへ通知が送られます。
#クライアント通知されたJsonデータからセーブデータ(.jsonテキスト)を読み出し・書き出しするのが主な作業。
#変更可能な設定は config.rb にまとめているため、環境設定のためにこのファイルを変更する必要は基本的には無いです。


#サーバCGIとクライアントFlashのバージョン一致確認用
$versionOnly = "Ver.1.47.22"
$versionDate = "2016/03/19"
$version = "#{$versionOnly}(#{$versionDate})"




if( RUBY_VERSION >= '1.9.0' )
  Encoding.default_external = 'utf-8'
else
  require 'jcode'
end

require 'kconv'
require 'cgi'
require 'stringio'
require 'logger'
require 'uri'
require 'fileutils'
require 'json/jsonParser'

if( $isFirstCgi )
  require 'cgiPatch_forFirstCgi'
end

require "config.rb"

begin
  require "config_local.rb"
rescue Exception
end


if( $loginCountFileFullPath.nil? )
  $loginCountFileFullPath = File.join($SAVE_DATA_DIR, 'saveData', $loginCountFile)
end

require "loggingFunction.rb"
require "FileLock.rb"
require "saveDirInfo.rb"


$dodontofWarning = nil

if( $isMessagePackInstalled )
  # gem install msgpack してる場合はこちら。
  begin
    require 'rubygems'
    require 'msgpack'
  rescue Exception
    $dodontofWarning = {"key" => "youNeedInstallMsgPack"}
  end
else
  if( RUBY_VERSION >= '1.9.0' )
    # msgpack のRuby1.9用
    require 'msgpack/msgpack19'
  else
    # MessagePackPure バージョン
    require 'msgpack/msgpackPure'
  end
end



$saveFileNames = File.join($saveDataTempDir, 'saveFileNames.json');
$imageUrlText = File.join($imageUploadDir, 'imageUrl.txt');

$chatMessageDataLogAll = 'chatLongLines.txt'

$loginUserInfo = 'login.json'
$playRoomInfo = 'playRoomInfo.json'
$playRoomInfoTypeName = 'playRoomInfo'

$saveFiles = {
  'chatMessageDataLog' => 'chat.json',
  'map' => 'map.json',
  'characters' => 'characters.json',
  'time' => 'time.json',
  'effects' => 'effects.json',
  $playRoomInfoTypeName => $playRoomInfo,
};

$recordKey = 'record'
$record = 'record.json'

$diceBotTableSaveKey = "diceBotTable"

class DodontoFServer
  
  def initialize(saveDirInfo, cgiParams)
    @cgiParams = cgiParams
    @saveDirInfo = saveDirInfo
    
    roomIndexKey = "room"
    initSaveFiles( getRequestData(roomIndexKey) )
    
    @isAddMarker = false
    @jsonpCallBack = nil
    @isWebIf = false
    @isJsonResult = true
    @isRecordEmpty = false
    
    @diceBotTablePrefix = 'diceBotTable_'
    @fullBackupFileBaseName = "DodontoFFullBackup"
    
    @allSaveDataFileExt = '.tar.gz'
    @defaultAllSaveData = 'default.sav'
    @defaultChatPallete = 'default.cpd'
    
    @card = nil
  end
  
  def initSaveFiles(roomNumber)
    @saveDirInfo.init(roomNumber, $saveDataMaxCount, $SAVE_DATA_DIR)
    
    @saveFiles = {}
    $saveFiles.each do |saveDataKeyName, saveFileName|
      logging(saveDataKeyName, "saveDataKeyName")
      logging(saveFileName, "saveFileName")
      @saveFiles[saveDataKeyName] = @saveDirInfo.getTrueSaveFileName(saveFileName)
    end
    
  end
  
  
  def getRequestData(key)
    logging(key, "getRequestData key")
    
    value = @cgiParams[key]
    # logging(@cgiParams, "@cgiParams")
    # logging(value, "getRequestData value")
    
    if( value.nil? )
      if( @isWebIf )
        @cgi ||= CGI.new
        value = @cgi.params[key].first
      end
    end
    
    
    # logging(value, "getRequestData result")
    
    return value
  end

  
  attr :isAddMarker
  attr :jsonpCallBack
  attr :isJsonResult
  
  def getCardsInfo
    require "card.rb"
    
    return @card unless( @card.nil? )
    
    @card = Card.new();
    
    
    return @card
  end
  
  def getSaveFileLockReadOnly(saveFileName)
    getSaveFileLock(saveFileName, true)
  end
  
  def getSaveFileLockReadOnlyRealFile(saveFileName)
    getSaveFileLockRealFile(saveFileName, true)
  end
  
  def self.getLockFileName(saveFileName)
    defaultLockFileName = (saveFileName + ".lock")
    
    if( $SAVE_DATA_LOCK_FILE_DIR.nil? )
      return defaultLockFileName;
    end
    
    if( saveFileName.index($SAVE_DATA_DIR) != 0 )
      return defaultLockFileName
    end
    
    subDirName = saveFileName[$SAVE_DATA_DIR.size .. -1]
    
    lockFileName = File.join($SAVE_DATA_LOCK_FILE_DIR, subDirName) + ".lock"
    return lockFileName
  end
  
  #override
  def getSaveFileLock(saveFileName, isReadOnly = false)
    getSaveFileLockRealFile(saveFileName, isReadOnly)
  end
  
  def getSaveFileLockRealFile(saveFileName, isReadOnly = false)
    begin
      lockFileName = self.class.getLockFileName(saveFileName)
      return FileLock.new(lockFileName);
      #return FileLock2.new(saveFileName + ".lock", isReadOnly)
    rescue => e
      loggingForce(@saveDirInfo, "when getSaveFileLock error : @saveDirInfo");
      raise e
    end
  end
  
  #override
  def isExist?(fileName)
    File.exist?(fileName)
  end
  
  #override
  def isExistDir?(dirName)
    File.exist?(dirName)
  end
  
  #override
  def readLines(fileName)
    File.readlines(fileName)
  end
  
  def loadSaveFileForLongChatLog(typeName, saveFileName)
    saveFileName = @saveDirInfo.getTrueSaveFileName($chatMessageDataLogAll)
    saveFileLock = getSaveFileLockReadOnly(saveFileName)
    
    lines = []
    saveFileLock.lock do
      if( isExist?(saveFileName) )
        lines = readLines(saveFileName)
      end
      
      @lastUpdateTimes[typeName] = getSaveFileTimeStampMillSecond(saveFileName);
    end
    
    if( lines.empty? )
      return {}
    end
    
    chatMessageDataLog = lines.collect{|line| getJsonDataFromText(line.chomp) }
    
    saveData = {"chatMessageDataLog" => chatMessageDataLog}
    
    return saveData
  end
  
  def loadSaveFile(typeName, saveFileName)
    logging("loadSaveFile begin")
    
    saveData = nil
    
    begin
      if( isLongChatLog(typeName) )
        saveData = loadSaveFileForLongChatLog(typeName, saveFileName)
      elsif( $isUseRecord and isCharacterType(typeName) )
        logging("isCharacterType")
        saveData = loadSaveFileForCharacter(typeName, saveFileName)
      else
        saveData = loadSaveFileForDefault(typeName, saveFileName)
      end
    rescue => e
      loggingException(e)
      raise e
    end
    
    logging(saveData, saveFileName)
    
    logging("loadSaveFile end")
    
    return saveData
  end
  
  def isLongChatLog(typeName)
    return ( $IS_SAVE_LONG_CHAT_LOG and isChatType(typeName) and @lastUpdateTimes[typeName] == 0 )
  end
  
  def isChatType(typeName)
    (typeName == 'chatMessageDataLog')
  end
  
  
  def isCharacterType(typeName)
    (typeName == "characters")
  end
  
  def loadSaveFileForCharacter(typeName, saveFileName)
    logging(@lastUpdateTimes, "loadSaveFileForCharacter begin @lastUpdateTimes")
    
    characterUpdateTime = getSaveFileTimeStampMillSecond(saveFileName);
    
    #後の操作順序に依存せずRecord情報が取得できるよう、ここでRecordをキャッシュしておく。
    #こうしないとRecordを取得する順序でセーブデータと整合性が崩れる場合があるため
    getRecordCache
    
    saveData = getRecordSaveDataFromCache()
    logging(saveData, "getRecordSaveDataFromCache saveData")
    
    if( saveData.nil? )
      saveData = loadSaveFileForDefault(typeName, saveFileName)
    else
      @lastUpdateTimes[typeName] = characterUpdateTime
    end
    
    @lastUpdateTimes['recordIndex'] = getLastRecordIndexFromCache
    
    logging(@lastUpdateTimes, "loadSaveFileForCharacter End @lastUpdateTimes")
    logging(saveData, "loadSaveFileForCharacter End saveData")
    
    return saveData
  end
  
  def getRecordSaveDataFromCache()
    recordIndex = @lastUpdateTimes['recordIndex']
    
    logging("getRecordSaveDataFromCache begin")
    logging(recordIndex, "recordIndex") 
    logging(@record, "@record")
    
    return nil if( recordIndex.nil? )
    return nil if( recordIndex == 0 )
    return nil if( @record.nil? )
    return nil if( @record.empty? )
    
    currentSender = getCommandSender
    isFound = false
    
    recordData = []
    
    @record.each do |params|
      index, command, _, sender = params
      
      logging(index, "@record.each index")
      
      if( index == recordIndex )
        isFound = true
        next
      end
      
      next unless( isFound )
      
      if( isSendReocrd?(sender, currentSender, command) )
        recordData << params
      end
      
    end
    
    saveData = nil
    if( isFound )
      logging(recordData, "recordData")
      saveData = {'record' => recordData}
    end
    
    return saveData
  end
  
  def isSendReocrd?(sender, currentSender, command)
    
    #自分のコマンドでも…Record送信して欲しいときはあるよねっ！
    return true if( @isGetOwnRecord )
    
    #自分が送ったコマンドであっても結果を取得しないといけないコマンド名はここに列挙
    #キャラクター追加なんかのコマンドは字自分のコマンドでも送信しないとダメなんだよね
    recordCommandsByForce = ['addCharacter']
    return true if( recordCommandsByForce.include?(command) )
    
    #でも基本的には、自分が送ったコマンドは受け取りたくないんですよ
    return false if( currentSender == sender )
    
    return true
  end
  
  def getLastRecordIndexFromCache
    recordIndex = 0
    
    record = getRecordCache
    
    last = record.last
    unless( last.nil? )
      recordIndex = last[0]
    end
    
    logging(recordIndex, "getLastRecordIndexFromCache recordIndex")
    
    return recordIndex
  end
  
  def getRecordCache
    unless( @record.nil? )
      return @record
    end
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($record)
    saveData = loadSaveFileForDefault($recordKey, trueSaveFileName)
    @record = getRecordFromSaveData(saveData)
    
    return @record
  end
  
  def loadSaveFileForDefault(typeName, saveFileName)
    saveFileLock = getSaveFileLockReadOnly(saveFileName)
    
    saveDataText = ""
    saveFileLock.lock do
      @lastUpdateTimes[typeName] = getSaveFileTimeStampMillSecond(saveFileName);
      saveDataText = getSaveTextOnFileLocked(saveFileName)
    end
    
    saveData = getJsonDataFromText(saveDataText)
    
    return saveData
  end
  
  def getSaveData(saveFileName)
    isReadOnly = true
    saveFileLock = getSaveFileLock(saveFileName, isReadOnly)
    
    text = nil
    saveFileLock.lock do
      text = getSaveTextOnFileLocked(saveFileName)
    end
    
    saveData = getJsonDataFromText(text)
    yield(saveData)
  end
  
  def changeSaveData(saveFileName)
    
    isCharacterSaveData = ( @saveFiles['characters'] == saveFileName )
    
    saveFileLock = getSaveFileLock(saveFileName)
    
    saveFileLock.lock do
      saveDataText = getSaveTextOnFileLocked(saveFileName)
      saveData = getJsonDataFromText(saveDataText)
      
      if( isCharacterSaveData )
        saveCharacterHsitory(saveData) do
          yield(saveData)
        end
      else
        yield(saveData)
      end
      
      saveDataText = getTextFromJsonData(saveData)
      createFile(saveFileName, saveDataText)
    end
  end
  
  def saveCharacterHsitory(saveData)
    logging("saveCharacterHsitory begin")
    
    before = deepCopy( saveData['characters'] )
    logging(before, "saveCharacterHsitory BEFORE")
    yield
    after = saveData['characters']
    logging(after, "saveCharacterHsitory AFTER")
    
    added   = getNotExistCharacters(after, before)
    removed = getNotExistCharacters(before, after)
    changed = getChangedCharacters(before, after)
    
    removedIds = removed.collect{|i| i['imgId']}
    
    saveCharacterHsitoryRecord(removedIds, added, changed)
  end
  
  def saveCharacterHsitoryRecord(removedIds, added, changed)
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($record)
    
    changeSaveData(trueSaveFileName) do |saveData|
      if( @isRecordEmpty )
        clearRecord(saveData)
      else
        writeRecord(saveData, 'removeCharacter', removedIds)
        writeRecord(saveData, 'addCharacter',    added)
        writeRecord(saveData, 'changeCharacter', changed)
      end
    end
    logging("saveCharacterHsitory end")
  end
  
  def deepCopy(obj)
    Marshal.load( Marshal.dump(obj) )
  end
  
  def getNotExistCharacters(first, second)
    result = []
    
    first.each do |a|
      same = second.find{|b| a['imgId'] == b['imgId']}
      if( same.nil? )
        result << a
      end
    end
    
    return result
  end
  
  def getChangedCharacters(before, after)
    result = []
    
    after.each do |a|
      logging(a, "getChangedCharacters find a")
      
      b = before.find{|i| a['imgId'] == i['imgId']}
      next if( b.nil? )
      
      logging(b, "getChangedCharacters find b")
      
      next if( a == b )
      
      result << a
    end
    
    logging(result, "getChangedCharacters result")
    
    return result
  end
  
  
  def writeRecord(saveData, key, list)
    logging("writeRecord begin")
    logging(list, "list")
    
    if( list.nil? or list.empty? )
      logging("list is empty.")
      return;
    end
    
    record = getRecordFromSaveData(saveData)
    logging(record, "before record")
    
    while( record.length >= $recordMaxCount )
      record.shift
      break if( record.length == 0 )
    end
    
    recordIndex = 1
    
    last = record.last
    unless( last.nil? )
      recordIndex = last[0].to_i + 1
    end
    
    sender = getCommandSender
    
    record << [recordIndex, key, list, sender]
    logging(record, "after record")
    
    logging("writeRecord end")
  end
  
  def clearRecord(saveData)
    logging("clearRecord Begin")
    record = getRecordFromSaveData(saveData)
    record.clear
    logging("clearRecord End")
  end
  
  def getCommandSender
    if( @commandSender.nil? )
      @commandSender = getRequestData('own')
    end
    
    logging(@commandSender, "@commandSender")
    
    return @commandSender
  end
  
  def setdNoBodyCommanSender
    @commandSender = "-\t-"
  end
  
  def setRecordWriteEmpty
    @isRecordEmpty = true
  end
  
  def getRecordFromSaveData(saveData)
    saveData ||= {}
    saveData['record'] ||= []
    record = saveData['record']
    return record
  end
  
  def createSaveFile(saveFileName, text)
    logging(saveFileName, 'createSaveFile saveFileName')
    existFiles = nil
    
    logging($saveFileNames, "$saveFileNames")
    changeSaveData($saveFileNames) do |saveData|
      existFiles = saveData["fileNames"]
      existFiles ||= []
      logging(existFiles, 'pre existFiles')
      
      unless( existFiles.include?(saveFileName) ) 
        existFiles << saveFileName
      end
      
      createFile(saveFileName, text)
      
      saveData["fileNames"] = existFiles
    end
    
    logging(existFiles, 'createSaveFile existFiles')
  end
  
  #override
  def createFile(saveFileName, text)
    begin
      File.open(saveFileName, "w+") do |file|
        file.write(text.toutf8)
      end
    rescue => e
      loggingException(e)
      raise e
    end
  end
  
  def getTextFromJsonData(jsonData)
    self.class.getTextFromJsonData(jsonData)
  end
  
  def self.getTextFromJsonData(jsonData)
    return JsonBuilder.new.build(jsonData)
  end
  
  def getDataFromMessagePack(data)
    self.class.getDataFromMessagePack(data)
  end  
  
  def self.getDataFromMessagePack(data)
      MessagePack.pack(data)
  end
  
  def getJsonDataFromText(text)
    self.class.getJsonDataFromText(text)
  end
  
  def self.getJsonDataFromText(text)
    jsonData = nil
    begin
      logging(text, "getJsonDataFromText start")
      begin
        jsonData = JsonParser.new.parse(text)
        logging("getJsonDataFromText 1 end")
      rescue => e
        text = CGI.unescape(text)
        jsonData = JsonParser.new.parse(text)
        logging("getJsonDataFromText 2 end")
      end
    rescue => e
      # loggingException(e)
      jsonData = {}
    end
    
    return jsonData
  end
  
  def getMessagePackFromData(data)
    self.class.getMessagePackFromData(data)
  end
  
  def self.getMessagePackFromData(data)
    logging("getMessagePackFromData Begin")
    
    messagePack = {}
    
    if( data.nil? )
      logging("data is nil")
      return messagePack 
    end
    
    begin
        messagePack = MessagePack.unpack(data)
    rescue Exception => e
      loggingForce("getMessagePackFromData Exception rescue")
      loggingException(e)
    end
    
    logging(messagePack, "messagePack")
    
    if( isWebIfMessagePack(messagePack) )
      logging(data, "data is webif.")
      messagePack = parseWebIfMessageData(data)
    end
    
    logging(messagePack, "getMessagePackFromData End messagePack")
    
    return messagePack
  end
  
  def self.isWebIfMessagePack(messagePack)
    logging(messagePack, "isWebif messagePack")
    
    unless( messagePack.kind_of?(Hash) )
      logging("messagePack is NOT Hash")
      return true
    end
    
    return false
  end
  
  def self.parseWebIfMessageData(data)
    params = CGI.parse(data)
    logging(params, "params")
    
    messagePack = {}
    params.each do |key, value|
      messagePack[key] = value.first
    end
    
    return messagePack
  end
  
  #override
  def getSaveTextOnFileLocked(fileName)
    empty = "{}"
    
    return empty  unless( isExist?(fileName) )
    
    text = ''
    open(fileName, 'r') do |file|
      text = file.read
    end
    
    return empty  if( text.empty? )
    
    return text
  end
  
  def analyzeCommand
    commandName = getRequestData('cmd')
    
    logging(commandName, "commandName")
    
    if( commandName.nil? or commandName.empty? )
      return getResponseTextWhenNoCommandName
    end
    
    hasReturn = "hasReturn";
    hasNoReturn = "hasNoReturn";
    
    commands = [
      ['refresh', hasReturn],
      
      ['getGraveyardCharacterData', hasReturn], 
      ['resurrectCharacter', hasReturn], 
      ['clearGraveyard', hasReturn], 
      ['getLoginInfo', hasReturn], 
      ['getPlayRoomStates', hasReturn], 
      ['deleteImage', hasReturn], 
      ['uploadImageUrl', hasReturn], 
      ['save', hasReturn], 
      ['saveMap', hasReturn], 
      ['saveAllData', hasReturn], 
      ['load', hasReturn], 
      ['loadAllSaveData', hasReturn], 
      ['getDiceBotInfos', hasReturn], 
      ['getBotTableInfos', hasReturn], 
      ['addBotTable', hasReturn], 
      ['changeBotTable', hasReturn], 
      ['removeBotTable', hasReturn], 
      ['requestReplayDataList', hasReturn], 
      ['uploadReplayData', hasReturn], 
      ['removeReplayData', hasReturn], 
      ['checkRoomStatus', hasReturn], 
      ['loginPassword', hasReturn], 
      ['uploadFile', hasReturn], 
      ['uploadImageData', hasReturn], 
      ['createPlayRoom', hasReturn], 
      ['changePlayRoom', hasReturn], 
      ['removePlayRoom', hasReturn], 
      ['removeOldPlayRoom', hasReturn], 
      ['getImageTagsAndImageList', hasReturn], 
      ['addCharacter', hasReturn],
      ['getWaitingRoomInfo', hasReturn], 
      ['exitWaitingRoomCharacter', hasReturn],
      ['enterWaitingRoomCharacter', hasReturn], 
      ['sendDiceBotChatMessage', hasReturn],
      ['deleteChatLog', hasReturn], 
      ['sendChatMessageAll', hasReturn],
      ['undoDrawOnMap', hasReturn],
      
      ['logout', hasNoReturn], 
      ['changeCharacter', hasNoReturn],
      ['removeCharacter', hasNoReturn],
      
      # Card Command Get
      ['getMountCardInfos', hasReturn],
      ['getTrushMountCardInfos', hasReturn],
      ['getCardList', hasReturn],
      
      # Card Command Set
      ['drawTargetCard', hasReturn],
      ['drawTargetTrushCard', hasReturn],
      ['drawCard', hasReturn],
      ['addCard', hasNoReturn],
      ['addCardZone', hasNoReturn],
      ['initCards', hasReturn],
      ['returnCard', hasNoReturn],
      ['shuffleCards', hasNoReturn],
      ['shuffleOnlyMountCards', hasNoReturn],
      ['shuffleForNextRandomDungeon', hasNoReturn],
      ['dumpTrushCards', hasNoReturn],
      ['returnCardToMount', hasNoReturn],
      
      ['clearCharacterByType', hasNoReturn],
      ['moveCharacter', hasNoReturn],
      ['changeMap', hasNoReturn],
      ['drawOnMap', hasNoReturn],
      ['clearDrawOnMap', hasNoReturn],
      ['sendChatMessage', hasNoReturn],
      ['changeRoundTime', hasNoReturn],
      ['addResource', hasNoReturn],
      ['changeResource', hasNoReturn],
      ['changeResourcesAll', hasNoReturn],
      ['removeResource', hasNoReturn],
      ['addEffect', hasNoReturn], 
      ['changeEffect', hasNoReturn], 
      ['changeEffectsAll', hasNoReturn], 
      ['removeEffect', hasNoReturn], 
      ['changeImageTags', hasNoReturn], 
    ]
    
    commands.each do |command, commandType|
      next unless( command == commandName )
      logging(commandType, "commandType")
      
      case commandType
      when hasReturn
        return eval( command )
      when hasNoReturn
        eval( command )
        return nil
      end
    end
    
    throw Exception.new("\"" + commandName.untaint + "\" is invalid command")
    
  end
  
  def getResponseTextWhenNoCommandName
    logging("getResponseTextWhenNoCommandName Begin")
    
    response = analyzeWebInterface 
    
    if( response.nil? )
      response =  getTestResponseText
    end
    
    return response
  end
  
  def analyzeWebInterface
    result = { 'result'=> 'NG' }
    
    begin
      result = analyzeWebInterfaceCatched
    rescue Exception => e
      result['result'] = e.to_s
    end
    
    setJsonpCallBack
    
    logging("analyzeWebInterfaceCatched end result", result)
    return result
  end
  
  def analyzeWebInterfaceCatched
    logging("analyzeWebInterfaceCatched begin")
    
    @isWebIf = true
    @isJsonResult = true
    
    commandName = getRequestData('webif')
    logging(commandName, 'commandName')
    
    if( isInvalidRequestParam(commandName) )
      return nil
    end
    
    marker = getRequestData('marker')
    if( isInvalidRequestParam(marker) )
      @isAddMarker = false
    end
    
    logging(commandName, "commandName")
    
    result = analyzeWebInterfaceNoLogin(commandName)
    return result unless result.nil?
    
    loginData = loginOnWebInterface()
    @isVisitorOnWebIf = loginData['visiterMode']
    
    result = analyzeWebInterfaceLogined(commandName)
    return result unless result.nil?
    
    return {'result'=> "command [#{commandName}] is NOT found"}
  end
  
  
  def analyzeWebInterfaceNoLogin(commandName)
    case commandName
    when 'getBusyInfo'
      getBusyInfo
    when 'getServerInfo'
      getWebIfServerInfo
    when 'getRoomList'
      getWebIfRoomList
    when 'getLoginInfo'
      getWebIfLoginInfo
    else
      nil
    end
  end  
  
  
  def analyzeWebInterfaceLogined(command)
    
    result = analyzeWebInterfaceLoginedEveryone(command)
    return result unless result.nil?
    
    return nil if( @isVisitorOnWebIf )
    
    result = analyzeWebInterfaceParticipant(command)
    return result unless result.nil?
  end
    
  def analyzeWebInterfaceLoginedEveryone(command)
    case command
    when 'chat'
      getWebIfChatText
    when 'talk'
      sendWebIfChatText
    when 'refresh'
      getWebIfRefresh
    when 'getRoomInfo'
      getWebIfRoomInfo
    when 'getLoginUserInfo'
      getWebIfLoginUserInfo
    when 'getChatColor'
      getChatColor
    else
      nil
    end
  end
  
  
  def analyzeWebInterfaceParticipant(command)
    case command
    when 'addCharacter'
      sendWebIfAddCharacter
    when 'changeCharacter'
      sendWebIfChangeCharacter
    when 'addMemo'
      sendWebIfAddMemo
    when 'changeMemo'
      sendWebIfChangeMemo
    when 'setRoomInfo'
      setWebIfRoomInfo
    else
      nil
    end
  end
  
  
  def getWebIfLoginInfo
    uniqueId = getRequestData('uniqueId')
    uniqueId ||= createUniqueId()
    return {'uniqueId' => uniqueId}
  end
  
  def getWebIfLoginUserInfo
    uniqueId = getWebIfRequestText('uniqueId')
    userName = getWebIfRequestText('name', '')
    isVisiter = getWebIfRequestBoolean('isVisiter', false)
    
    getLoginUserInfo(userName, uniqueId, isVisiter)
  end
  
  
  def loginOnWebInterface
    logging('loginOnWebInterface Begin')
    
    roomNumber = getRoomNumberOnWebInterface
    password = getRequestData('password')
    password ||= ''
    
    visiterMode = false
    
    checkResult = checkLoginPassword(roomNumber, password, visiterMode)
    
    resultText = checkResult['resultText']
    if( resultText != "OK" )
      logging(resultText, 'resultText')
      raise resultText
    end
    
    initSaveFiles(roomNumber)
    
    logging('loginOnWebInterface End')

    return checkResult
  end
  
  def getRoomNumberOnWebInterface
    roomNumberText = getRequestData('room')
    if( isInvalidRequestParam(roomNumberText) )
      raise "プレイルーム番号(room)を指定してください"
    end
    
    unless( /^\d+$/ === roomNumberText )
      raise "プレイルーム番号(room)には半角数字のみを指定してください"
    end
    
    roomNumber = roomNumberText.to_i
    return roomNumber
  end
  
  
  def isInvalidRequestParam(param)
    return ( param.nil? or param.empty? )
  end
  
  def setJsonpCallBack
    callBack = getRequestData('callback')
    
    logging('callBack', callBack)
    if( isInvalidRequestParam(callBack) )
      return
    end
    
    @jsonpCallBack = callBack
  end
  
  
  def getTestResponseText
    unless ( FileTest::directory?( $SAVE_DATA_DIR + '/saveData') )
      return "Error : saveData ディレクトリ(#{$SAVE_DATA_DIR + '/saveData'}) が存在しません。"
    end
    if ( Dir::mkdir( $SAVE_DATA_DIR + '/saveData/data_checkTestResponse') )
      Dir::rmdir($SAVE_DATA_DIR + '/saveData/data_checkTestResponse' )
    end
    unless ( FileTest::directory?( $imageUploadDir ) )
      return "Error : 画像保存用ディレクトリ #{$imageUploadDir} が存在しません。"
    end
    if ( Dir::mkdir( $imageUploadDir + '/data_checkTestResponse' ) )
      Dir::rmdir($imageUploadDir + '/data_checkTestResponse' )
    end
    return "「どどんとふ」の動作環境は正常に起動しています。"
  end
  
  
  def getCurrentSaveData()
    @saveFiles.each do |saveFileTypeName, saveFileName|
      logging(saveFileTypeName, "saveFileTypeName");
      logging(saveFileName, "saveFileName");
      
      targetLastUpdateTime = @lastUpdateTimes[saveFileTypeName];
      next if( targetLastUpdateTime == nil )
      
      logging(targetLastUpdateTime, "targetLastUpdateTime");
      
      if( isSaveFileChanged(targetLastUpdateTime, saveFileName) )
        logging(saveFileName, "saveFile is changed");
        targetSaveData = loadSaveFile(saveFileTypeName, saveFileName)
        yield(targetSaveData, saveFileTypeName)
      end
    end
  end
  
  
  def getWebIfChatText
    logging("getWebIfChatText begin")
    
    time= getWebIfRequestNumber('time', -1)
    if( time != -1 )
      saveData = getWebIfChatTextFromTime(time)
    else
      seconds = getRequestData('sec')
      saveData = getWebIfChatTextFromSecond(seconds)
    end
    
    saveData['result'] = 'OK'
    
    return saveData
  end
  
  
  def getWebIfChatTextFromTime(time)
    logging(time, 'getWebIfChatTextFromTime time')
    
    saveData = {}
    @lastUpdateTimes = {'chatMessageDataLog' => time}
    refreshLoop(saveData)
    
    deleteOldChatTextForWebIf(time, saveData)
    
    logging(saveData, 'getWebIfChatTextFromTime saveData')
    
    return saveData
  end
  
  
  def getWebIfChatTextFromSecond(seconds)
    logging(seconds, 'getWebIfChatTextFromSecond seconds')
    
    time = getTimeForGetWebIfChatText(seconds)
    logging(seconds, "seconds")
    logging(time, "time")
    
    saveData = {}
    @lastUpdateTimes = {'chatMessageDataLog' => time}
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      saveData.merge!(targetSaveData)
    end
    
    deleteOldChatTextForWebIf(time, saveData)
    
    logging("getCurrentSaveData end saveData", saveData)
    
    return saveData
  end
  
  def deleteOldChatTextForWebIf(time, saveData)
    logging(time, 'deleteOldChatTextForWebIf time')
    
    return if( time.nil? )
    
    chats = saveData['chatMessageDataLog']
    return if( chats.nil? )
    
    chats.delete_if do |writtenTime, data|
      ((writtenTime <= time) or (not data['sendto'].nil?))
    end
    
    logging('deleteOldChatTextForWebIf End')
  end
  
  
  def getTimeForGetWebIfChatText(seconds)
    case seconds
    when "all"
      return 0
    when nil
      return Time.now.to_i - $oldMessageTimeout
    end
    
    return Time.now.to_i - seconds.to_i
  end
  
  
  def getChatColor()
    name = getWebIfRequestText('name')
    logging(name, "name")
    if( isInvalidRequestParam(name) )
      raise "対象ユーザー名(name)を指定してください"
    end
    
    color = getChatColorFromChatSaveData(name)
    # color ||= getTalkDefaultColor
    if( color.nil? )
      raise "指定ユーザー名の発言が見つかりません"
    end
    
    result = {}
    result['result'] = 'OK'
    result['color'] = color
    
    return result
  end
  
  def getChatColorFromChatSaveData(name)
    seconds = 'all'
    saveData = getWebIfChatTextFromSecond(seconds)
    
    chats = saveData['chatMessageDataLog']
    chats.reverse_each do |time, data|
      senderName = data['senderName'].split(/\t/).first
      if( name == senderName )
        return data['color']
      end
    end
    
    return nil
  end
  
  def getTalkDefaultColor
    "000000"
  end
  
  def getBusyInfo()
    jsonData = {
      "loginCount" => File.readlines($loginCountFileFullPath).join.to_i,
      "maxLoginCount" => $aboutMaxLoginCount,
      "version" => $version,
      "result" => 'OK',
    }
    
    return jsonData
  end
  
  def getWebIfServerInfo()
    jsonData = {
      "maxRoom" => ($saveDataMaxCount - 1),
      'isNeedCreatePassword' => (not $createPlayRoomPassword.empty?),
      'result' => 'OK',
    }
    
    if( getWebIfRequestBoolean("card", false) )
      cardInfos = getCardsInfo.collectCardTypeAndTypeName()
      jsonData["cardInfos"] = cardInfos
    end
    
    if( getWebIfRequestBoolean("dice", false) )
      jsonData['diceBotInfos'] = getDiceBotInfos()
    end
    
    return jsonData
  end
  
  def getWebIfRoomList()
    logging("getWebIfRoomList Begin")
    minRoom = getWebIfRequestInt('minRoom', 0)
    maxRoom = getWebIfRequestInt('maxRoom', ($saveDataMaxCount - 1))
    
    playRoomStates = getPlayRoomStatesLocal(minRoom, maxRoom)
    
    jsonData = {
      "playRoomStates" => playRoomStates,
      "result" => 'OK',
    }
    
    logging("getWebIfRoomList End")
    return jsonData
  end
  
  def sendWebIfChatText
    logging("sendWebIfChatText begin")
    
    name = getWebIfRequestText('name')
    logging(name, "name")
    
    message = getWebIfRequestText('message')
    message.gsub!(/\r\n/, "\r")
    logging(message, "message")
    
    color = getWebIfRequestText('color', getTalkDefaultColor)
    logging(color, "color")
    
    channel = getWebIfRequestInt('channel')
    channel = getWebIfChatChannel(channel)
    
    gameType = getWebIfRequestText('bot')
    logging(gameType, 'gameType')
    
    isNeedResult = true
    uniqueId = '0'
    
    params = {
      'message' => message,
      'gameType' => gameType,
      'isNeedResult' => isNeedResult,
      'uniqueId' => uniqueId,
    }
    
    rolledMessage, = getRollDiceResult( params )
    
    chatData = {
      "senderName" => name,
      "message" => rolledMessage,
      "color" => color,
      "uniqueId" => uniqueId,
      "channel" => channel,
    }
    logging("sendWebIfChatText chatData", chatData)
    
    sendChatMessageByChatData(chatData)
    
    result = {}
    result['result'] = 'OK'
    return result
  end
  
  
  def getWebIfChatChannel(channel)
    logging(channel, "getWebIfChatChannel channel")
    
    return channel unless @isVisitorOnWebIf
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    
    getSaveData(trueSaveFileName) do |saveData|
      names = saveData['chatChannelNames']
      
      unless names.nil?
        channel = [0, (names.length - 1)].max
      end
    end
    
    logging(channel, 'channel visitor')
    
    return channel
  end
  
  
  def getWebIfRequestText(key, default = '')
    text = getRequestData(key)
    
    if( text.nil? or text.empty? )
      text = default
    end
    
    return text
  end
  
  def getWebIfRequestInt(key, default = 0)
    text = getWebIfRequestText(key, default.to_s)
    return text.to_i
  end
  
  def getWebIfRequestNumber(key, default = 0)
    text = getWebIfRequestText(key, default.to_s)
    return text.to_f
  end
  
  def getWebIfRequestBoolean(key, default = false)
    text = getWebIfRequestText(key)
    if( text.empty? )
      return default
    end
    
    return (text == "true")
  end
  
  def getWebIfRequestArray(key, empty = [], separator = ',')
    text = getWebIfRequestText(key, nil)
    
    if( text.nil? )
      return empty
    end
    
    return text.split(separator)
  end
  
  def getWebIfRequestHash(key, default = {}, separator1 = ':', separator2 = ',')
    logging("getWebIfRequestHash begin")
    logging(key, "key")
    logging(separator1, "separator1")
    logging(separator2, "separator2")
    
    array = getWebIfRequestArray(key, [], separator2)
    logging(array, "array")
    
    if( array.empty? )
      return default
    end
    
    hash = {}
    array.each do |value|
      logging(value, "array value")
      key, value = value.split(separator1)
      hash[key] = value
    end
    
    logging(hash ,"getWebIfRequestHash result")
    
    return hash
  end
  
  def sendWebIfAddMemo
    logging('sendWebIfAddMemo begin')
    
    result = {}
    result['result'] = 'OK'
    
    jsonData = {
      "message" => getWebIfRequestText('message', ''),
      "x" => 0,
      "y" => 0,
      "height" => 1,
      "width" => 1,
      "rotation" => 0,
      "isPaint" => true,
      "color" => 16777215,
      "draggable" => true,
      "type" => "Memo",
      "imgId" => createCharacterImgId(),
    }
    
    logging(jsonData, 'sendWebIfAddMemo jsonData')
    addCharacterData( [jsonData] )
    
    return result
  end
  
  
  def sendWebIfChangeMemo
    
    logging('sendWebIfChangeMemo begin')
    
    result = {}
    
    begin
      result['result'] = sendWebIfChangeMemoChatched
    rescue => e
      loggingException(e)
          result['result'] =  e.to_s
    end
    
    return result
  end
  
  def sendWebIfChangeMemoChatched
    targetId = getWebIfRequestText('targetId')
    
    return "no targetId" if(targetId.nil?)
    
    logging(targetId, "targetId")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      characters = getCharactersFromSaveData(saveData)
      data = characters.find{ |i| i['imgId'] == targetId }
      
      return "targetId Memo NOT found" if(data.nil?)
    
      data['message'] = getWebIfRequestAny(:getWebIfRequestText, 'message', data)
    end
    
    return "OK"
  end
  
  
  def sendWebIfAddCharacter
    logging("sendWebIfAddCharacter begin")
    
    result = {}
    result['result'] = 'OK'
    
    jsonData = {
      "name" => getWebIfRequestText('name'),
      "size" =>  getWebIfRequestInt('size', 1),
      "x" => getWebIfRequestInt('x', 0),
      "y" => getWebIfRequestInt('y', 0),
      "initiative" => getWebIfRequestNumber('initiative', 0),
      "counters" => getWebIfRequestHash('counters'),
      "info" => getWebIfRequestText('info'),
      "imageName" => getWebIfImageName('image', ".\/image\/defaultImageSet\/pawn\/pawnBlack.png"),
      "rotation" => getWebIfRequestInt('rotation', 0),
      "statusAlias" => getWebIfRequestHash('statusAlias'),
      "dogTag" => getWebIfRequestText('dogTag', ""),
      "draggable" => getWebIfRequestBoolean("draggable", true),
      "isHide" => getWebIfRequestBoolean("isHide", false),
      "type" => "characterData",
      "imgId" =>  createCharacterImgId(),
      "url" => getWebIfRequestText('url'),
    }
    
    logging(jsonData, 'sendWebIfAddCharacter jsonData')
    
    
    if( jsonData['name'].empty? )
      result['result'] = "キャラクターの追加に失敗しました。キャラクター名が設定されていません"
      return result
    end
    
    
    addResult = addCharacterData( [jsonData] )
    addFailedCharacterNames = addResult["addFailedCharacterNames"]
    logging(addFailedCharacterNames, 'addFailedCharacterNames')
    
    if( addFailedCharacterNames.length > 0 )
      result['result'] = "キャラクターの追加に失敗しました。同じ名前のキャラクターがすでに存在しないか確認してください。\"#{addFailedCharacterNames.join(' ')}\""
    end
    
    return result
  end
  
  def getWebIfImageName(key, default)
    logging("getWebIfImageName begin")
    logging(key, "key")
    logging(default, "default")
    
    image = getWebIfRequestText(key, default)
    logging(image, "image")
    
    if( image != default )
      image.gsub!('(local)', $imageUploadDir)
      image.gsub!('__LOCAL__', $imageUploadDir)
    end
    
    logging(image, "getWebIfImageName result")
      
    return image
  end
  
  
  def sendWebIfChangeCharacter
    logging("sendWebIfChangeCharacter begin")
    
    result = {}
    result['result'] = 'OK'
    
    begin
      sendWebIfChangeCharacterChatched
    rescue => e
      loggingException(e)
      result['result'] =  e.to_s
    end
    
    return result
  end
  
  def sendWebIfChangeCharacterChatched
    logging("sendWebIfChangeCharacterChatched begin")
    
    targetName = getWebIfRequestText('targetName')
    logging(targetName, "targetName")
    
    if( targetName.empty? )
      raise '変更するキャラクターの名前(\'target\'パラメータ）が正しく指定されていません'
    end
    
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      characterData = getCharacterDataByName(saveData, targetName)
      logging(characterData, "characterData")
      
      if( characterData.nil? )
        raise "「#{targetName}」という名前のキャラクターは存在しません"
      end
      
      name = getWebIfRequestAny(:getWebIfRequestText, 'name', characterData)
      logging(name, "name")
      
      if( characterData['name'] != name )
        failedName = isAlreadyExistCharacterInRoom?( saveData, {'name' => name})
        if( failedName )
          raise "「#{name}」という名前のキャラクターはすでに存在しています"
        end
      end
      
      characterData['name'] = name
      characterData['size'] = getWebIfRequestAny(:getWebIfRequestInt, 'size', characterData)
      characterData['x'] = getWebIfRequestAny(:getWebIfRequestNumber, 'x', characterData)
      characterData['y'] = getWebIfRequestAny(:getWebIfRequestNumber, 'y', characterData)
      characterData['initiative'] = getWebIfRequestAny(:getWebIfRequestNumber, 'initiative', characterData)
      characterData['counters'] = getWebIfRequestAny(:getWebIfRequestHash, 'counters', characterData)
      characterData['info'] = getWebIfRequestAny(:getWebIfRequestText, 'info', characterData)
      characterData['imageName'] = getWebIfRequestAny(:getWebIfImageName, 'image', characterData, 'imageName')
      characterData['rotation'] = getWebIfRequestAny(:getWebIfRequestInt, 'rotation', characterData)
      characterData['statusAlias'] = getWebIfRequestAny(:getWebIfRequestHash, 'statusAlias', characterData)
      characterData['dogTag'] = getWebIfRequestAny(:getWebIfRequestText, 'dogTag', characterData)
      characterData['draggable'] = getWebIfRequestAny(:getWebIfRequestBoolean, 'draggable', characterData)
      characterData['isHide'] = getWebIfRequestAny(:getWebIfRequestBoolean, 'isHide', characterData)
      # 'type' => 'characterData',
      # 'imgId' =>  createCharacterImgId(),
      
    end
    
  end
  
  def getCharacterDataByName(saveData, targetName)
    characters = getCharactersFromSaveData(saveData)
    
    characterData = characters.find do |i|
      (i['name'] == targetName)
    end
    
    return characterData
  end
  
  
  def getWebIfRoomInfo
    logging("getWebIfRoomInfo begin")
    
    result = {}
    result['result'] = 'OK'
    
    getSaveData(@saveFiles['time']) do |saveData|
      logging(saveData, "saveData")
      roundTimeData = getHashValue(saveData, 'roundTimeData', {})
      result['counter'] = getHashValue(roundTimeData, "counterNames", [])
    end
    
    roomInfo = getRoomInfoForWebIf
    result.merge!(roomInfo)
    
    logging(result, "getWebIfRoomInfo result")
    
    return result
  end
  
  def getRoomInfoForWebIf
    result = {}
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    
    getSaveData(trueSaveFileName) do |saveData|
      result['roomName'] = getHashValue(saveData, 'playRoomName', '')
      result['chatTab'] = getHashValue(saveData, 'chatChannelNames', [])
      result['outerImage'] = getHashValue(saveData, 'canUseExternalImage', false)
      result['visit'] = getHashValue(saveData, 'canVisit', false)
      result['game'] = getHashValue(saveData, 'gameType', '')
    end
    
    return result
  end
  
  def getHashValue(hash, key, default)
    value = hash[key]
    value ||= default
    return value
  end
  
  def setWebIfRoomInfo
    logging("setWebIfRoomInfo begin")
    
    result = {}
    result['result'] = 'OK'
    
    setWebIfRoomInfoCounterNames
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    
    roomInfo = getRoomInfoForWebIf
    changeSaveData(trueSaveFileName) do |saveData|
      saveData['playRoomName'] = getWebIfRequestAny(:getWebIfRequestText, 'roomName', roomInfo)
      saveData['chatChannelNames'] = getWebIfRequestAny(:getWebIfRequestArray, 'chatTab', roomInfo)
      saveData['canUseExternalImage'] = getWebIfRequestAny(:getWebIfRequestBoolean, 'outerImage', roomInfo)
      saveData['canVisit'] = getWebIfRequestAny(:getWebIfRequestBoolean, 'visit', roomInfo)
      saveData['gameType'] = getWebIfRequestAny(:getWebIfRequestText, 'game', roomInfo)
    end
    
    logging(result, "setWebIfRoomInfo result")
    
    return result
  end
  
  def setWebIfRoomInfoCounterNames
    counterNames = getWebIfRequestArray('counter', nil, ',')
    return if( counterNames.nil? )
    
    changeCounterNames(counterNames)
  end
  
  def changeCounterNames(counterNames)
    logging(counterNames, "changeCounterNames(counterNames)")
    changeSaveData(@saveFiles['time']) do |saveData|
      roundTimeData = getRoundTimeDataFromSaveData(saveData)
      roundTimeData['counterNames'] = counterNames
    end
  end
  
  def getWebIfRequestAny(functionName, key, defaultInfos, key2 = nil)
    key2 ||= key
    
    logging("getWebIfRequestAny begin")
    logging(key, "key")
    logging(key2, "key2")
    logging(defaultInfos, "defaultInfos")
    
    defaultValue = defaultInfos[key2]
    logging(defaultValue, "defaultValue")
    
    command = "#{functionName}( key, defaultValue )"
    logging(command, "getWebIfRequestAny command")
    
    result = eval( command )
    logging(result, "getWebIfRequestAny result")
    
    return result
  end
  
  
  def getWebIfRefresh
    logging("getWebIfRefresh Begin")
    
    @lastUpdateTimes = {
      'chatMessageDataLog' => getWebIfRequestNumber('chat', -1),
      'map' => getWebIfRequestNumber('map', -1),
      'characters' => getWebIfRequestNumber('characters', -1),
      'time' => getWebIfRequestNumber('time', -1),
      'effects' => getWebIfRequestNumber('effects', -1),
      $playRoomInfoTypeName => getWebIfRequestNumber('roomInfo', -1),
    }
    
    @lastUpdateTimes.delete_if{|type, time| time == -1}
    logging(@lastUpdateTimes, "getWebIfRefresh lastUpdateTimes")
    
    saveData = {}
    refreshLoop(saveData)
    
    chatLastTime = getWebIfRequestNumber('chatLastTime', nil)
    unless( chatLastTime.nil? )
      deleteOldChatTextForWebIf(chatLastTime, saveData)
    end
    
    result = {}
    ["chatMessageDataLog", "mapData", "characters", "graveyard", "effects"].each do |key|
      value = saveData.delete(key)
      next if( value.nil? )
      
      result[key] = value
    end
    
    result['roomInfo'] = saveData
    result['lastUpdateTimes'] = @lastUpdateTimes
    result['result'] = 'OK'
    
    logging("getWebIfRefresh End result", result)
    
    return result
  end
  
  
  def refresh()
    logging("==>Begin refresh");
    
    saveData = {}
    
    if( $isMentenanceNow )
      saveData["warning"] = {"key" => "canNotRefreshBecauseMentenanceNow", "params" => []}
    end
    
    params = getParamsFromRequestData()
    logging(params, "params")
    
    @lastUpdateTimes = params['times']
    logging(@lastUpdateTimes, "@lastUpdateTimes");
    
    isFirstChatRefresh = (@lastUpdateTimes['chatMessageDataLog'] == 0)
    logging(isFirstChatRefresh, "isFirstChatRefresh");
    
    refreshIndex = params['rIndex'];
    logging(refreshIndex, "refreshIndex");
    
    @isGetOwnRecord = params['isGetOwnRecord'];
    
    if( $isCommet )
      refreshLoop(saveData)
    else
      refreshOnce(saveData)
    end
    
    uniqueId = getCommandSender
    userName = params['name'];
    isVisiter = params['isVisiter'];
    
    loginUserInfo = getLoginUserInfo(userName, uniqueId, isVisiter)
    
    unless( saveData.empty? )
      saveData['lastUpdateTimes'] = @lastUpdateTimes
      saveData['refreshIndex'] = refreshIndex
      saveData['loginUserInfo'] = loginUserInfo
    end
    
    if( isFirstChatRefresh )
      saveData['isFirstChatRefresh'] = isFirstChatRefresh
    end
    
    logging(saveData, "refresh end saveData");
    logging("==>End refresh");
    
    return saveData
  end
  
  def getLoginUserInfo(userName, uniqueId, isVisiter)
    loginUserInfoSaveFile = @saveDirInfo.getTrueSaveFileName($loginUserInfo)
    loginUserInfo = updateLoginUserInfo(loginUserInfoSaveFile, userName, uniqueId, isVisiter)
    return loginUserInfo
  end
  
  
  def getParamsFromRequestData()
    params = getRequestData('params')
    logging(params, "params")
    return params
  end
  
  
  
  def refreshLoop(saveData)
    now = Time.now
    whileLimitTime = now + $refreshTimeout
    
    logging(now, "now")
    logging(whileLimitTime, "whileLimitTime")
    
    while( Time.now < whileLimitTime )
      
      refreshOnce(saveData)
      
      break unless( saveData.empty? )
      
      intalval = getRefreshInterval
      logging(intalval, "saveData is empty, sleep second");
      sleep( intalval )
      logging("awake.");
    end
  end
  
  def getRefreshInterval
    if( $isCommet )
      $refreshInterval
    else
      $refreshIntervalForNotCommet
    end
  end
  
  def refreshOnce(saveData)
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      saveData.merge!(targetSaveData)
    end
  end
  
  
  def updateLoginUserInfo(trueSaveFileName, userName = '', uniqueId = '', isVisiter = false)
    logging(uniqueId, 'updateLoginUserInfo uniqueId')
    logging(userName, 'updateLoginUserInfo userName')
    
    result = []
    
    return result if( uniqueId == -1 )
    
    nowSeconds = Time.now.to_i
    logging(nowSeconds, 'nowSeconds')
    
    
    isGetOnly = (userName.empty? and uniqueId.empty? )
    getDataFunction = nil;
    if( isGetOnly )
      getDataFunction = method(:getSaveData)
    else
      getDataFunction = method(:changeSaveData)
    end
    
    getDataFunction.call(trueSaveFileName) do |saveData|
      
      unless(isGetOnly)
        changeUserInfo(saveData, uniqueId, nowSeconds, userName, isVisiter)
      end
      
      saveData.delete_if do |existUserId, userInfo|
        isDeleteUserInfo?(existUserId, userInfo, nowSeconds)
      end
      
      saveData.keys.sort.each do |userId|
        userInfo = saveData[userId]
        data = {
          "userName" => userInfo['userName'],
          "userId" => userId, 
        }
        
        data['isVisiter'] = true  if( userInfo['isVisiter'] )
        
        result << data
      end
    end
    
    return result
  end
  
  def isDeleteUserInfo?(existUserId, userInfo, nowSeconds)
    isLogout = userInfo['isLogout']
    return true if(isLogout)
    
    timeSeconds = userInfo['timeSeconds']
    diffSeconds = nowSeconds - timeSeconds
    return ( diffSeconds > $loginTimeOut )
  end
  
  def changeUserInfo(saveData, uniqueId, nowSeconds, userName, isVisiter)
    return if( uniqueId.empty? )
    
    isLogout = false
    if( saveData.include?(uniqueId) )
      isLogout = saveData[uniqueId]['isLogout']
    end
    
    return if( isLogout )
    
    userInfo = {
      'userName'=>userName,
      'timeSeconds'=>nowSeconds,
    }
    
    userInfo['isVisiter'] = true  if( isVisiter )
    
    saveData[uniqueId] = userInfo
  end
  
  
  def getPlayRoomName(saveData, index)
    playRoomName = saveData['playRoomName']
    playRoomName ||= "プレイルームNo.#{index}"
    return playRoomName
  end
  
  def getLoginUserCountList( roomNumberRange )
    loginUserCountList = {}
    roomNumberRange.each{|i| loginUserCountList[i] = 0 }
    
    @saveDirInfo.each_with_index(roomNumberRange, $loginUserInfo) do |saveFiles, index|
      next unless( roomNumberRange.include?(index) )
      
      if( saveFiles.size != 1 )
        logging("emptry room")
        loginUserCountList[index] = 0
        next
      end
      
      trueSaveFileName = saveFiles.first
      
      loginUserInfo = updateLoginUserInfo(trueSaveFileName)
      loginUserCountList[index] = loginUserInfo.size
    end
    
    return loginUserCountList
  end
  
  def getLoginUserList( roomNumberRange )
    loginUserList = {}
    roomNumberRange.each{|i| loginUserList[i] = [] }
    
    @saveDirInfo.each_with_index(roomNumberRange, $loginUserInfo) do |saveFiles, index|
      next unless( roomNumberRange.include?(index) )
      
      if( saveFiles.size != 1 )
        logging("emptry room")
        #loginUserList[index] = []
        next
      end
      
      userNames = []
      trueSaveFileName = saveFiles.first
      loginUserInfo = updateLoginUserInfo(trueSaveFileName)
      loginUserInfo.each do |data|
        userNames << data["userName"]
      end
      
      loginUserList[index] = userNames
    end
    
    return loginUserList
  end
  
  
  def getSaveDataLastAccessTimes( roomNumberRange )
    @saveDirInfo.getSaveDataLastAccessTimes($saveFiles.values, roomNumberRange)
  end
  
  def getSaveDataLastAccessTime( fileName, roomNo )
    data = @saveDirInfo.getSaveDataLastAccessTime(fileName, roomNo)
    time = data[roomNo]
    return time
  end
  
  
  def removeOldPlayRoom()
    roomNumberRange = (0 .. $saveDataMaxCount)
    accessTimes = getSaveDataLastAccessTimes( roomNumberRange )
    result = removeOldRoomFromAccessTimes(accessTimes)
    return result
  end
  
  def removeOldRoomFromAccessTimes(accessTimes)
    logging("removeOldRoom Begin")
    if( $removeOldPlayRoomLimitDays <= 0 )
      return accessTimes
    end
    
    logging(accessTimes, "accessTimes")
    
    roomNumbers = getDeleteTargetRoomNumbers(accessTimes)
    
    ignoreLoginUser = true
    password = nil
    isForce = true
    result = removePlayRoomByParams(roomNumbers, ignoreLoginUser, password, isForce)
    logging(result, "removePlayRoomByParams result")
    
    return result
  end
  
  def getDeleteTargetRoomNumbers(accessTimes)
    logging(accessTimes, "getDeleteTargetRoomNumbers accessTimes")
    
    roomNumbers = []
    
    accessTimes.each do |index, time|
      logging(index, "index")
      logging(time, "time")
      
      next if( time.nil? ) 
      
      timeDiffSeconds = (Time.now - time)
      logging(timeDiffSeconds, "timeDiffSeconds")
      
      limitSeconds = $removeOldPlayRoomLimitDays * 24 * 60 * 60
      logging(limitSeconds, "limitSeconds")
      
      if( timeDiffSeconds > limitSeconds )
        logging( index, "roomNumbers added index")
        roomNumbers << index
      end
    end
    
    logging(roomNumbers, "roomNumbers")
    return roomNumbers
  end
  
  
  def findEmptyRoomNumber()
    emptyRoomNubmer = -1
    
    roomNumberRange = (0..$saveDataMaxCount)
    
    roomNumberRange.each do |roomNumber|
      @saveDirInfo.setSaveDataDirIndex(roomNumber)
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      
      next if( isExist?(trueSaveFileName) )
      
      emptyRoomNubmer = roomNumber
      break
    end
    
    return emptyRoomNubmer
  end
  
  def getPlayRoomStates()
    params = getParamsFromRequestData()
    logging(params, "params")
    
    minRoom = getMinRoom(params)
    maxRoom = getMaxRoom(params)
    playRoomStates = getPlayRoomStatesLocal(minRoom, maxRoom)
    
    result = {
      "minRoom" => minRoom,
      "maxRoom" => maxRoom,
      "playRoomStates" => playRoomStates,
    }
    
    logging(result, "getPlayRoomStatesLocal result");
    
    return result
  end
  
  def getPlayRoomStatesLocal(minRoom, maxRoom)
    roomNumberRange = (minRoom .. maxRoom)
    playRoomStates = []
    
    roomNumberRange.each do |roomNo|
      
      @saveDirInfo.setSaveDataDirIndex(roomNo)
      
      playRoomState = getPlayRoomState(roomNo)
      next if( playRoomState.nil? )
      
      playRoomStates << playRoomState
    end
    
    return playRoomStates;
  end
  
  def getPlayRoomState(roomNo)
    
    # playRoomState = nil
    playRoomState = {}
    playRoomState['passwordLockState'] = false
    playRoomState['index'] = sprintf("%3d", roomNo)
    playRoomState['playRoomName'] = "（空き部屋）"
    playRoomState['lastUpdateTime'] = ""
    playRoomState['canVisit'] = false
    playRoomState['gameType'] = ''
    playRoomState['loginUsers'] = []
    
    begin
      playRoomState = getPlayRoomStateLocal(roomNo, playRoomState)
    rescue Exception => e
      loggingForce("getPlayRoomStateLocal Exception rescue")
      loggingException(e)
    end
    
    return playRoomState
  end
  
  def getPlayRoomStateLocal(roomNo, playRoomState)
    playRoomInfoFile = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    
    return playRoomState unless( isExist?(playRoomInfoFile) )
    
    playRoomData = nil
    getSaveData(playRoomInfoFile) do |playRoomDataTmp|
      playRoomData = playRoomDataTmp
    end
    logging(playRoomData, "playRoomData")
    
    return playRoomState if( playRoomData.empty? )
    
    playRoomName = getPlayRoomName(playRoomData, roomNo)
    passwordLockState = (not playRoomData['playRoomChangedPassword'].nil?)
    canVisit = playRoomData['canVisit']
    gameType = playRoomData['gameType']
    timeStamp = getSaveDataLastAccessTime( $saveFiles['chatMessageDataLog'], roomNo )
    
    timeString = ""
    unless( timeStamp.nil? )
      timeString = "#{timeStamp.strftime('%Y/%m/%d %H:%M:%S')}"
    end
    
    loginUsers = getLoginUserNames()
    
    playRoomState['passwordLockState'] = passwordLockState
    playRoomState['playRoomName'] = playRoomName
    playRoomState['lastUpdateTime'] = timeString
    playRoomState['canVisit'] = canVisit
    playRoomState['gameType'] = gameType
    playRoomState['loginUsers'] = loginUsers
    
    return playRoomState
  end
  
  def getLoginUserNames()
    userNames = []
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($loginUserInfo)
    logging(trueSaveFileName, "getLoginUserNames trueSaveFileName")
    
    unless( isExist?(trueSaveFileName) )
      return userNames
    end
    
    @now_getLoginUserNames ||= Time.now.to_i
    
    getSaveData(trueSaveFileName) do |userInfos|
      userInfos.each do |uniqueId, userInfo|
        next if( isDeleteUserInfo?(uniqueId, userInfo, @now_getLoginUserNames) )
        userNames << userInfo['userName']
      end
    end
    
    logging(userNames, "getLoginUserNames userNames")
    return userNames
  end
  
  def getGameName(gameType)
    require 'diceBotInfos'
    diceBotInfos = DiceBotInfos.new.getInfos
    gameInfo = diceBotInfos.find{|i| i["gameType"] == gameType}
    
    return '--' if( gameInfo.nil? )
    
    return gameInfo["name"]
  end
  
  
  
  def getAllLoginCount()
    roomNumberRange = (0 .. $saveDataMaxCount)
    loginUserCountList = getLoginUserCountList( roomNumberRange )
    
    total = 0
    userList = []
    
    loginUserCountList.each do |key, value|
      next if( value == 0 ) 
      
      total += value
      userList << [key, value]
    end
    
    userList.sort!
    
    logging(total, "getAllLoginCount total")
    logging(userList, "getAllLoginCount userList")
    return total, userList
  end
  
  def getFamousGames
    roomNumberRange = (0 .. $saveDataMaxCount)
    gameTypeList = getGameTypeList( roomNumberRange )
    
    counts = {}
    gameTypeList.each do |roomNo, gameType|
      next if( gameType.empty? )
      
      counts[gameType] ||= 0
      counts[gameType] += 1
    end
    
    logging(counts, 'counts')
    
    countList = counts.collect{|gameType, count|[count, gameType]}
    countList.sort!
    countList.reverse!
    
    logging('countList', countList)
    
    famousGames = []
    
    countList.each_with_index do |info, index|
      # next if( index >= 3 )
      
      count, gameType = info
      famousGames << {"gameType" => gameType, "count" => count}
    end
    
    logging('famousGames', famousGames)
    
    return famousGames
  end
  
  
  def getMinRoom(params)
    [[ params['minRoom'], 0 ].max, ($saveDataMaxCount - 1)].min
  end
  
  def getMaxRoom(params)
    [[ params['maxRoom'], ($saveDataMaxCount - 1) ].min, 0].max
  end
  
  def getLoginInfo()
    logging("getLoginInfo begin")
    
    uniqueId ||= createUniqueId()
    
    allLoginCount, loginUserCountList = getAllLoginCount()
    writeAllLoginInfo( allLoginCount )
    
    loginMessage = getLoginMessage()
    cardInfos = getCardsInfo.collectCardTypeAndTypeName()
    diceBotInfos = getDiceBotInfos()
    
    result = {
      "loginMessage" => loginMessage,
      "cardInfos" => cardInfos,
      "isDiceBotOn" => $isDiceBotOn,
      "uniqueId" => uniqueId,
      "refreshTimeout" => $refreshTimeout,
      "refreshInterval" => getRefreshInterval(),
      "isCommet" => $isCommet,
      "version" => $version,
      "playRoomMaxNumber" => ($saveDataMaxCount - 1),
      "warning" => getLoginWarning(),
      "playRoomGetRangeMax" => $playRoomGetRangeMax,
      "allLoginCount" => allLoginCount.to_i,
      "limitLoginCount" => $limitLoginCount,
      "loginUserCountList" => loginUserCountList,
      "maxLoginCount" => $aboutMaxLoginCount.to_i,
      "skinImage" => $skinImage,
      "isPaformanceMonitor" => $isPaformanceMonitor,
      "fps" => $fps,
      "loginTimeLimitSecond" => $loginTimeLimitSecond,
      "removeOldPlayRoomLimitDays" => $removeOldPlayRoomLimitDays,
      "canTalk" => $canTalk,
      "retryCountLimit" => $retryCountLimit,
      "imageUploadDirInfo" => {$localUploadDirMarker => $imageUploadDir},
      "mapMaxWidth" => $mapMaxWidth,
      "mapMaxHeigth" => $mapMaxHeigth,
      'diceBotInfos' => diceBotInfos,
      'isNeedCreatePassword' => (not $createPlayRoomPassword.empty?),
      'defaultUserNames' => $defaultUserNames,
      'drawLineCountLimit' => $drawLineCountLimit,
      'logoutUrl' => $logoutUrl,
      'languages' => getLanguages(),
      'canUseExternalImageModeOn' => $canUseExternalImageModeOn,
      'characterInfoToolTipMax' => [$characterInfoToolTipMaxWidth, $characterInfoToolTipMaxHeight],
      'isAskRemoveRoomWhenLogout' => $isAskRemoveRoomWhenLogout,
    }
    
    logging(result, "result")
    logging("getLoginInfo end")
    return result
  end
  
  
  def getLanguages()
    languages = {}
    
    unless( $isMultilingualization )
      return languages 
    end
    
    dir = "languages"
    fileNames = Dir.glob("#{dir}/*.txt")
    fileNames = fileNames.collect{|i| i.untaint}
    
    fileNames.each do |fileName|
      next unless(/#{dir}\/(.+)\.txt$/ === fileName)
      name = $1
      
      # "_README.txt" のように _ で始まるファイルは対象外とします
      next if(/^_/ === name)
      
      lines = File.readlines(fileName).join
      params = {}
      lines.each_line do |line|
        
        line = line.chomp
        
        # 「#」で始まる行はコメント行として無効に
        next if(/^#/ === line)
        # 空白行もパス
        next if(/^\s*$/ === line)
        
        next unless( /^([^=]+?)\s*=\s?(.*)$/ === line )
        key = $1
        value = $2
        
        # \\n は \n に
        # \\\\n は \\n に
        value = value.gsub(/\\n/){"\n"}.gsub(/\\r/){"\r"}
        value = value.gsub(/\\\n/){"\\n"}.gsub(/\\\r/){"\\r"}
        
        params[key] = value
      end
      
      languages[name] = params
    end
    
    logging(languages, "languages")
    
    return languages
  end
  
  
  def createUniqueId
    # 識別子用の文字列生成。
    (Time.now.to_f * 1000).to_i.to_s(36)
  end
  
  def writeAllLoginInfo( allLoginCount )
    text = "#{allLoginCount}"
    
    saveFileName = $loginCountFileFullPath
    saveFileLock = getSaveFileLockReadOnlyRealFile(saveFileName)
    
    saveFileLock.lock do
      File.open(saveFileName, "w+") do |file|
        file.write( text.toutf8 )
      end
    end
  end
  
  
  def getLoginWarning
    unless( isExistDir?(getSmallImageDir) )
      return {
        "key" => "noSmallImageDir",
        "params" => [getSmallImageDir],
      }
    end
    
    if( $isMentenanceNow )
    return {
      "key" => "canNotLoginBecauseMentenanceNow",
    }
    end
    
    return nil
  end
  
  def getLoginMessage
    mesasge = ""
    mesasge << getLoginMessageHeader
    mesasge << getLoginMessageHistoryPart
    return mesasge
  end
  
  def getLoginMessageHeader
    loginMessage = ""
    
    if( File.exist?( $loginMessageFile ) )
      File.readlines($loginMessageFile).each do |line|
        loginMessage << line.chomp << "\n";
      end
      logging(loginMessage, "loginMessage")
    else
      logging("#{$loginMessageFile} is NOT found.")
    end
    
    return loginMessage
  end
  
  def getLoginMessageHistoryPart
    loginMessage = ""
    if( File.exist?( $loginMessageBaseFile ) )
      File.readlines($loginMessageBaseFile).each do |line|
        loginMessage << line.chomp << "\n";
      end
    else
      logging("#{$loginMessageFile} is NOT found.")
    end
    
    return loginMessage
  end
  
  def getDiceBotInfos()
    logging("getDiceBotInfos() Begin")
    
    require 'diceBotInfos'
    diceBotInfos = DiceBotInfos.new.getInfos
    
    commandInfos = getGameCommandInfos
    
    commandInfos.each do |commandInfo|
      logging(commandInfo, "commandInfos.each commandInfos")
      setDiceBotPrefix(diceBotInfos, commandInfo)
    end
    
    # logging(diceBotInfos, "getDiceBotInfos diceBotInfos")
    
    return diceBotInfos
  end
  
  def setDiceBotPrefix(diceBotInfos, commandInfo)
    gameType = commandInfo["gameType"]
    
    if( gameType.empty? )
      setDiceBotPrefixToAll(diceBotInfos, commandInfo)
      return
    end
    
    botInfo = diceBotInfos.find{|i| i["gameType"] == gameType}
    setDiceBotPrefixToOne(botInfo, commandInfo)
  end
  
  def setDiceBotPrefixToAll(diceBotInfos, commandInfo)
    diceBotInfos.each do |botInfo|
      setDiceBotPrefixToOne(botInfo, commandInfo)
    end
  end
  
  def setDiceBotPrefixToOne(botInfo, commandInfo)
    logging(botInfo, "botInfo")
    return if(botInfo.nil?)
    
    prefixs = botInfo["prefixs"]
    return if( prefixs.nil? )
    
    prefixs << commandInfo["command"]
  end
  
  def getGameCommandInfos
    logging('getGameCommandInfos Begin')
    
    if( @saveDirInfo.getSaveDataDirIndex == -1 )
      logging('getGameCommandInfos room is -1, so END')
      
      return []
    end
    
    require 'cgiDiceBot.rb'
    bot = CgiDiceBot.new
    dir = getDiceBotExtraTableDirName
    logging(dir, 'dir')
    
    commandInfos = bot.getGameCommandInfos(dir, @diceBotTablePrefix)
    logging(commandInfos, "getGameCommandInfos End commandInfos")
    
    return commandInfos
  end
  
  
  def createDir(playRoomIndex)
    @saveDirInfo.setSaveDataDirIndex(playRoomIndex)
    @saveDirInfo.createDir()
  end
  
  def createPlayRoom()
    logging('createPlayRoom begin')
    
    resultText = "OK"
    playRoomIndex = -1
    begin
      params = getParamsFromRequestData()
      logging(params, "params")
      
      checkCreatePlayRoomPassword(params['createPassword'])
      
      playRoomName = params['playRoomName']
      playRoomPassword = params['playRoomPassword']
      chatChannelNames = params['chatChannelNames']
      canUseExternalImage = params['canUseExternalImage']
      
      canVisit = params['canVisit']
      playRoomIndex = params['playRoomIndex']
      
      if( playRoomIndex == -1 )
        playRoomIndex = findEmptyRoomNumber()
        raise "noEmptyPlayRoom" if(playRoomIndex == -1)
        
        logging(playRoomIndex, "findEmptyRoomNumber playRoomIndex")
      end
      
      logging(playRoomName, 'playRoomName')
      logging('playRoomPassword is get')
      logging(playRoomIndex, 'playRoomIndex')
      
      initSaveFiles(playRoomIndex)
      checkSetPassword(playRoomPassword, playRoomIndex)
      
      logging("@saveDirInfo.removeSaveDir(playRoomIndex) Begin")
      @saveDirInfo.removeSaveDir(playRoomIndex)
      logging("@saveDirInfo.removeSaveDir(playRoomIndex) End")
      
      createDir(playRoomIndex)
      
      playRoomChangedPassword = getChangedPassword(playRoomPassword)
      logging(playRoomChangedPassword, 'playRoomChangedPassword')
      
      viewStates = params['viewStates']
      logging("viewStates", viewStates)
      
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      
      changeSaveData(trueSaveFileName) do |saveData|
        saveData['playRoomName'] = playRoomName
        saveData['playRoomChangedPassword'] = playRoomChangedPassword
        saveData['chatChannelNames'] = chatChannelNames
        saveData['canUseExternalImage'] = canUseExternalImage
        saveData['canVisit'] = canVisit
        saveData['gameType'] = params['gameType']
        
        addViewStatesToSaveData(saveData, viewStates)
      end
      
      sendRoomCreateMessage(playRoomIndex)
    rescue Exception => e
      resultText = getLanguageKey( e.to_s )
    end
    
    result = {
      "resultText" => resultText,
      "playRoomIndex" => playRoomIndex,
    }
    logging(result, 'result')
    logging('createDir finished')
    
    return result
  end
  
  def checkCreatePlayRoomPassword(password)
    logging('checkCreatePlayRoomPassword Begin')
    logging(password, 'password')
    
    return if( $createPlayRoomPassword.empty? )
    return if( $createPlayRoomPassword == password )
    
    raise "errorPassword"
  end
  
  
  def sendRoomCreateMessage(roomNo)
    chatData = {
      "senderName" => "どどんとふ",
      "message" => "＝＝＝＝＝＝＝　プレイルーム　【　No.　#{roomNo}　】　へようこそ！　＝＝＝＝＝＝＝",
      "color" => "cc0066",
      "uniqueId" => '0',
      "channel" => 0,
    }
    
    sendChatMessageByChatData(chatData)
  end
  
  
  def addViewStatesToSaveData(saveData, viewStates)
    viewStates['key'] = Time.now.to_f.to_s
    saveData['viewStateInfo'] = viewStates
  end
  
  def getChangedPassword(pass)
    return nil if( pass.empty? )
    
    salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
    return pass.crypt(salt)
  end
  
  def changePlayRoom()
    logging("changePlayRoom begin")
    
    resultText = "OK"
    
    begin
      params = getParamsFromRequestData()
      logging(params, "params")
      
      playRoomPassword = params['playRoomPassword']
      checkSetPassword(playRoomPassword)
      
      playRoomChangedPassword = getChangedPassword(playRoomPassword)
      logging('playRoomPassword is get')
      
      viewStates = params['viewStates']
      logging("viewStates", viewStates)
      
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      
      changeSaveData(trueSaveFileName) do |saveData|
        saveData['playRoomName'] = params['playRoomName']
        saveData['playRoomChangedPassword'] = playRoomChangedPassword
        saveData['chatChannelNames'] = params['chatChannelNames']
        saveData['canUseExternalImage'] = params['canUseExternalImage']
        saveData['canVisit'] = params['canVisit']
        saveData['backgroundImage'] = params['backgroundImage']
        saveData['gameType'] = params['gameType']
        
        preViewStateInfo = saveData['viewStateInfo']
        unless( isSameViewState(viewStates, preViewStateInfo) )
          addViewStatesToSaveData(saveData, viewStates)
        end
        
      end
    rescue Exception => e
      resultText = getLanguageKey( e.to_s )
    end
    
    result = {
      "resultText" => resultText,
    }
    logging(result, 'changePlayRoom result')
    
    return result
  end
  
  
  def checkSetPassword(playRoomPassword, roomNumber = nil)
    return if( playRoomPassword.empty? )
    
    if( roomNumber.nil? )
      roomNumber = @saveDirInfo.getSaveDataDirIndex
    end
    
    if( $noPasswordPlayRoomNumbers.include?(roomNumber) )
      raise "noPasswordPlayRoomNumber"
    end
  end
  
  
  def isSameViewState(viewStates, preViewStateInfo)
    result = true
    
    preViewStateInfo ||= {}
    
    viewStates.each do |key, value|
      unless( value == preViewStateInfo[key] )
        result = false
        break
      end
    end
    
    return result
  end
  
  
  def checkPassword(roomNumber, password)
    
    return true unless( $isPasswordNeedFroDeletePlayRoom )
    
    @saveDirInfo.setSaveDataDirIndex(roomNumber)
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    isExistPlayRoomInfo = ( isExist?(trueSaveFileName) ) 
    
    return true unless( isExistPlayRoomInfo )
    
    matched = false
    getSaveData(trueSaveFileName) do |saveData|
      changedPassword = saveData['playRoomChangedPassword']
      matched = isPasswordMatch?(password, changedPassword)
    end
    
    return matched
  end
  
  
  def removePlayRoom()
    params = getParamsFromRequestData()
    
    roomNumbers = params['roomNumbers']
    ignoreLoginUser = params['ignoreLoginUser']
    password = params['password']
    password ||= ""
    isForce = params['isForce']
    
    adminPassword = params["adminPassword"]
    logging(adminPassword, "removePlayRoom() adminPassword")
    if( isMentenanceMode(adminPassword) )
      password = nil
    end
    
    removePlayRoomByParams(roomNumbers, ignoreLoginUser, password, isForce)
  end
  
  def removePlayRoomByParams(roomNumbers, ignoreLoginUser, password, isForce)
    logging(ignoreLoginUser, 'removePlayRoomByParams Begin ignoreLoginUser')
    
    deletedRoomNumbers = []
    errorMessages = []
    passwordRoomNumbers = []
    askDeleteRoomNumbers = []
    
    roomNumbers.each do |roomNumber|
      roomNumber = roomNumber.to_i
      logging(roomNumber, 'roomNumber')
      
      resultText = checkRemovePlayRoom(roomNumber, ignoreLoginUser, password, isForce)
      logging(resultText, "checkRemovePlayRoom resultText")
      
      case resultText
      when "OK"
        removePlayRoomData(roomNumber)
        deletedRoomNumbers << roomNumber
      when "password"
        passwordRoomNumbers << roomNumber
      when "userExist"
        askDeleteRoomNumbers << roomNumber
      else
        errorMessages << resultText
      end
    end
    
    result = {
      "deletedRoomNumbers" => deletedRoomNumbers,
      "askDeleteRoomNumbers" => askDeleteRoomNumbers,
      "passwordRoomNumbers" => passwordRoomNumbers,
      "errorMessages" => errorMessages,
    }
    logging(result, 'result')
    
    return result
  end
  
  
  def removePlayRoomData(roomNumber)
    removeLocalImageTags(roomNumber)
    @saveDirInfo.removeSaveDir(roomNumber)
    removeLocalSpaceDir(roomNumber)
  end
  
  def removeLocalImageTags(roomNumber)
    tagInfos = getImageTags(roomNumber)
    deleteImages(tagInfos.keys)
  end
  
  
  def checkRemovePlayRoom(roomNumber, ignoreLoginUser, password, isForce)
    roomNumberRange = (roomNumber..roomNumber)
    logging(roomNumberRange, "checkRemovePlayRoom roomNumberRange")
    
    unless( ignoreLoginUser )
      userNames = getLoginUserNames()
      userCount = userNames.size
      logging(userCount, "checkRemovePlayRoom userCount");
      
      if( userCount > 0 )
        return "userExist"
      end
    end
    
    if( not password.nil? )
      if( not checkPassword(roomNumber, password) )
        return "password"
      end
    end
    
    if( $unremovablePlayRoomNumbers.include?(roomNumber) )
      return "unremovablePlayRoomNumber"
    end
    
    lastAccessTimes = getSaveDataLastAccessTimes( roomNumberRange )
    lastAccessTime = lastAccessTimes[roomNumber]
    lastAccessTime ||= 0
    logging(lastAccessTime, "lastAccessTime")
    
    lastAccessTime = 0 if isForce
    
    now = Time.now.to_f
    spendTimes = now - lastAccessTime.to_f
    logging(spendTimes, "spendTimes")
    logging(spendTimes / 60 / 60, "spendTimes / 60 / 60")
    if( spendTimes < $deletablePassedSeconds )
      return "プレイルームNo.#{roomNumber}の最終更新時刻から#{$deletablePassedSeconds}秒が経過していないため削除できません"
    end
    
    return "OK"
  end
  
  

  
  def removeLocalSpaceDir(roomNumber)
    dir = getRoomLocalSpaceDirNameByRoomNo(roomNumber)
    rmdir(dir)
  end
  
  def getTrueSaveFileName(fileName)
    @saveDirInfo.getTrueSaveFileName($saveFileTempName)
  end
  
  def saveAllData()
    logging("saveAllData begin")
    dir = getRoomLocalSpaceDirName
    makeDir(dir)
    
    params = getParamsFromRequestData()
    @saveAllDataBaseUrl = params['baseUrl']
    chatPaletteData = params['chatPaletteData']
    logging(@saveAllDataBaseUrl, "saveAllDataBaseUrl")
    logging(chatPaletteData, "chatPaletteData")
    
    saveDataAll = getAllSaveData
    saveDataAll = moveAllImagesToDir(dir, saveDataAll)
    makeChatPalletSaveFile(dir, chatPaletteData)
    makeDefaultSaveFileForAllSave(dir, saveDataAll)
    
    removeOldAllSaveFile(dir)
    baseName = getNewSaveFileBaseName(@fullBackupFileBaseName);
    allSaveDataFile = makeAllSaveDataFile(dir, baseName)
    
    result = {}
    result['result'] = "OK"
    result["saveFileName"] = allSaveDataFile
    
    logging(result, "saveAllData result")
    return result
  end
  
  def getAllSaveData
    selectTypes = $saveFiles.keys
    selectTypes.delete_if{|i| i == 'chatMessageDataLog'}
    
    isAddPlayRoomInfo = true
    saveDataAll = getSelectFilesData(selectTypes, isAddPlayRoomInfo)
    return saveDataAll
  end
  
  def moveAllImagesToDir(dir, saveDataAll)
    logging(saveDataAll, 'moveAllImagesToDir saveDataAll')
    
    moveMapImageToDir(dir, saveDataAll)
    moveEffectsImageToDir(dir, saveDataAll)
    moveCharactersImagesToDir(dir, saveDataAll)
    movePlayroomImagesToDir(dir, saveDataAll)
    
    logging(saveDataAll, 'moveAllImagesToDir result saveDataAll')
    
    return saveDataAll
  end
  
  def moveMapImageToDir(dir, saveDataAll)
    mapData = getLoadData(saveDataAll, 'map', 'mapData', {})
    imageSource = mapData['imageSource']
    
    changeFilePlace(imageSource, dir)
  end
  
  def moveEffectsImageToDir(dir, saveDataAll)
    effects = getLoadData(saveDataAll, 'effects', 'effects', [])
    
    effects.each do |effect|
      imageFile = effect['source']
      changeFilePlace(imageFile, dir)
    end
  end
  
  def moveCharactersImagesToDir(dir, saveDataAll)
    characters = getLoadData(saveDataAll, 'characters', 'characters', [])
    moveCharactersImagesToDirFromCharacters(dir, characters)
    
    characters = getLoadData(saveDataAll, 'characters', 'graveyard', [])
    moveCharactersImagesToDirFromCharacters(dir, characters)
    
    characters = getLoadData(saveDataAll, 'characters', 'waitingRoom', [])
    moveCharactersImagesToDirFromCharacters(dir, characters)
  end
  
  def moveCharactersImagesToDirFromCharacters(dir, characters)
    
    characters.each do |character|
      
      imageNames = []
      
      case character['type']
      when 'characterData'
        imageNames << character['imageName']
      when 'Card', 'CardMount', 'CardTrushMount'
        imageNames << character['imageName']
        imageNames << character['imageNameBack']
      when 'floorTile', 'chit'
        imageNames << character['imageUrl']
      end
      
      next if( imageNames.empty? )
      
      imageNames.each do |imageName|
        changeFilePlace(imageName, dir)
      end
    end
  end
  
  def movePlayroomImagesToDir(dir, saveDataAll)
    logging(dir, "movePlayroomImagesToDir dir")
    playRoomInfo = saveDataAll['playRoomInfo']
    return if( playRoomInfo.nil? )
    logging(playRoomInfo, "playRoomInfo")
    
    backgroundImage = playRoomInfo['backgroundImage'] 
    logging(backgroundImage, "backgroundImage")
    return if( backgroundImage.nil? )
    return if( backgroundImage.empty? )
    
    changeFilePlace(backgroundImage, dir)
  end
  
  def changeFilePlace(from ,to)
    logging(from, "changeFilePlace from")
    
    fromFileName, _ = from.split(/\t/)
    fromFileName ||= from
    
    result = copyFile(fromFileName ,to)
    logging(result, "copyFile result")
    
    return unless( result )
    
    from.gsub!(/.*\//, $imageUploadDirMarker + "/" )
    logging(from, "changeFilePlace result")
  end
  
  def copyFile(from ,to)
    logging("moveFile begin")
    logging(from, "from")
    logging(to, "to")
    
    logging(@saveAllDataBaseUrl, "@saveAllDataBaseUrl")
    from.gsub!(@saveAllDataBaseUrl, './')
    logging(from, "from2")
    
    return false if( from.nil? )
    return false unless( File.exist?(from) )
    
    fromDir =  File.dirname(from)
    logging(fromDir, "fromDir")
    if( fromDir == to )
      logging("from, to is equal dir")
      return true
    end
    
    toFileName = File.join(to, File.basename(from))
    if( File.exist?(toFileName) )
      loggingForce("toFileName(#{toFileName}) is exist")
      return true
    end
    
    logging("copying...")
    
    result = true
    begin
      FileUtils.cp(from, to)
    rescue
      result = false
    end
    
    return result
  end
  
  def makeChatPalletSaveFile(dir, chatPaletteData)
    logging("makeChatPalletSaveFile Begin")
    logging(dir, "makeChatPalletSaveFile dir")
    
    currentDir = FileUtils.pwd.untaint
    FileUtils.cd(dir)
    
    File.open(@defaultChatPallete, "w+") do |file|
      file.write(chatPaletteData)
    end
    
    FileUtils.cd(currentDir)
    logging("makeChatPalletSaveFile End")
  end
  
  def makeDefaultSaveFileForAllSave(dir, saveDataAll)
    logging("makeDefaultSaveFileForAllSave Begin")
    logging(dir, "makeDefaultSaveFileForAllSave dir")
    
    extension = "sav"
    result = saveSelectFilesFromSaveDataAll(saveDataAll, extension)
    
    from = result["saveFileName"]
    to = File.join(dir, @defaultAllSaveData)
    
    FileUtils.mv(from, to)
    
    logging("makeDefaultSaveFileForAllSave End")
  end
  
  
  def removeOldAllSaveFile(dir)
    fileNames = Dir.glob("#{dir}/#{@fullBackupFileBaseName}*#{@allSaveDataFileExt}")
    fileNames = fileNames.collect{|i| i.untaint}
    logging(fileNames, "removeOldAllSaveFile fileNames")
    
    fileNames.each do |fileName|
      File.delete(fileName)
    end
  end
  
  def makeAllSaveDataFile(dir, fileBaseName)
    logging("makeAllSaveDataFile begin")
    
    require 'zlib'
    require 'archive/tar/minitar'
    
    currentDir = FileUtils.pwd.untaint
    FileUtils.cd(dir)
    
    saveFile = fileBaseName + @allSaveDataFileExt
    tgz = Zlib::GzipWriter.new(File.open(saveFile, 'wb'))
    
    fileNames = Dir.glob('*')
    fileNames = fileNames.collect{|i| i.untaint}
    
    fileNames.delete_if{|i| i == saveFile}
    
    Archive::Tar::Minitar.pack(fileNames, tgz)
    
    FileUtils.cd(currentDir)
    
    return File.join(dir, saveFile)
  end
  
  
  def save()
    isAddPlayRoomInfo = true
    extension = getRequestData('extension')
    
    addInfos = {}
    addInfos[$diceBotTableSaveKey] = getDiceTableData()
    
    saveSelectFiles($saveFiles.keys, extension, isAddPlayRoomInfo, addInfos)
  end
  
  def getDiceTableData()
    dir = getDiceBotExtraTableDirName
    tableInfos = getBotTableInfosFromDir(dir)
    
    tableInfos.each{|i| i.delete('fileName') }
    
    return tableInfos
  end
  
  
  def saveMap()
    extension = getRequestData('extension')
    selectTypes = ['map', 'characters']
    saveSelectFiles( selectTypes, extension)
  end
  
  
  def saveSelectFiles(selectTypes, extension, isAddPlayRoomInfo = false, addInfos = {})
    saveDataAll = getSelectFilesData(selectTypes, isAddPlayRoomInfo)
    saveSelectFilesFromSaveDataAll(saveDataAll, extension, addInfos)
  end
  
  def saveSelectFilesFromSaveDataAll(saveDataAll, extension, addInfos = {})
    result = {}
    result["result"] = "unknown error"
    
    if( saveDataAll.empty? )
      result["result"] = "no save data"
      return result
    end
    
    deleteOldSaveFile
    
    saveData = {}
    saveData['saveDataAll'] = saveDataAll
    
    addInfos.each do |key, data|
      saveData[key] = data
    end
    
    text = getTextFromJsonData(saveData)
    saveFileName = getNewSaveFileName(extension)
    createSaveFile(saveFileName, text)
    
    result["result"] = "OK"
    result["saveFileName"] = saveFileName
    logging(result, "saveSelectFiles result")
    
    return result
  end
  
  
  def getSelectFilesData(selectTypes, isAddPlayRoomInfo = false)
    logging("getSelectFilesData begin")
    
    @lastUpdateTimes = {}
    selectTypes.each do |type|
      @lastUpdateTimes[type] = 0;
    end
    logging("dummy @lastUpdateTimes created")
    
    saveDataAll = {}
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      saveDataAll[saveFileTypeName] = targetSaveData
      logging(saveFileTypeName, "saveFileTypeName in save")
    end
    
    if( isAddPlayRoomInfo )
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      @lastUpdateTimes[$playRoomInfoTypeName] = 0;
      if( isSaveFileChanged(0, trueSaveFileName) )
        saveDataAll[$playRoomInfoTypeName] = loadSaveFile($playRoomInfoTypeName, trueSaveFileName)
      end
    end
    
    logging(saveDataAll, "saveDataAll tmp")
    
    return saveDataAll
  end
  
  #override
  def fileJoin(*parts)
    File.join(*parts)
  end
  
  def getNewSaveFileName(extension)
    baseName = getNewSaveFileBaseName("DodontoF");
    saveFileName = baseName + ".#{extension}"
    return fileJoin($saveDataTempDir, saveFileName).untaint
  end

  def getNewSaveFileBaseName(prefix);
    now = Time.now
    baseName = now.strftime(prefix + "_%Y_%m%d_%H%M%S_#{now.usec}")
    return baseName.untaint
  end

  
  def deleteOldSaveFile
    logging('deleteOldSaveFile begin')
    begin
      deleteOldSaveFileCatched
    rescue => e
      loggingException(e)
    end
    logging('deleteOldSaveFile end')
  end
  
  def deleteOldSaveFileCatched
    
    changeSaveData($saveFileNames) do |saveData|
      existSaveFileNames = saveData["fileNames"]
      existSaveFileNames ||= []
      logging(existSaveFileNames, 'existSaveFileNames')
      
      regExp = /DodontoF_[\d_]+.sav/
      
      deleteTargets = []
      
      existSaveFileNames.each do |saveFileName|
        logging(saveFileName, 'saveFileName')
        next unless(regExp === saveFileName)
        
        createdTime = getSaveFileTimeStamp(saveFileName)
        now = Time.now.to_i
        diff = ( now - createdTime )
        logging(diff, "createdTime diff")
        next if( diff < $oldSaveFileDelteSeconds )
        
        begin
          deleteFile(saveFileName)
        rescue => e
          loggingException(e)
        end
        
        deleteTargets << saveFileName
      end
      
      logging(deleteTargets, "deleteTargets")
      
      deleteTargets.each do |fileName|
        existSaveFileNames.delete_if{|i| i == fileName}
      end
      logging(existSaveFileNames, "existSaveFileNames")
      
      saveData["fileNames"] = existSaveFileNames
    end
    
  end
  
  
  def loggingException(e)
    self.class.loggingException(e)
  end
  
  def self.loggingException(e)
    loggingForce( e.to_s, "exception mean" )
    loggingForce( $@.join("\n"), "exception from" )
    loggingForce($!.inspect, "$!.inspect" )
  end
  
  
  def checkRoomStatus()
    deleteOldUploadFile()
    
    params = getParamsFromRequestData()
    logging(params, 'params')
    
    roomNumber = params['roomNumber']
    logging(roomNumber, 'roomNumber')
    
    @saveDirInfo.setSaveDataDirIndex(roomNumber)
    
    isMentenanceModeOn = false
    isWelcomeMessageOn = $isWelcomeMessageOn
    playRoomName = ''
    chatChannelNames = nil
    canUseExternalImage = false
    canVisit = false
    isPasswordLocked = false
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    isExistPlayRoomInfo = ( isExist?(trueSaveFileName) ) 
    
    if( isExistPlayRoomInfo )
      getSaveData(trueSaveFileName) do |saveData|
        playRoomName = getPlayRoomName(saveData, roomNumber)
        changedPassword = saveData['playRoomChangedPassword']
        chatChannelNames = saveData['chatChannelNames']
        canUseExternalImage = saveData['canUseExternalImage']
        canVisit = saveData['canVisit']
        unless( changedPassword.nil? )
          isPasswordLocked = true
        end
      end
    end
    
    adminPassword = params["adminPassword"]
    if( isMentenanceMode(adminPassword) )
      isPasswordLocked = false
      isWelcomeMessageOn = false
      isMentenanceModeOn = true
      canVisit = false
    end
    
    logging("isPasswordLocked", isPasswordLocked);
    
    result = {
      'isRoomExist' => isExistPlayRoomInfo,
      'roomName' => playRoomName,
      'roomNumber' => roomNumber,
      'chatChannelNames' => chatChannelNames,
      'canUseExternalImage' => canUseExternalImage,
      'canVisit' => canVisit,
      'isPasswordLocked' => isPasswordLocked,
      'isMentenanceModeOn' => isMentenanceModeOn,
      'isWelcomeMessageOn' => isWelcomeMessageOn,
    }
    
    logging(result, "checkRoomStatus End result")
    
    return result
  end
  
  def isMentenanceMode(adminPassword)
    return false if( $mentenanceModePassword.nil? )
    return ( adminPassword == $mentenanceModePassword )
  end
  
  def loginPassword()
    loginData = getParamsFromRequestData()
    logging(loginData, 'loginData')
    
    roomNumber = loginData['roomNumber']
    password = loginData['password']
    visiterMode = loginData['visiterMode']
    
    checkLoginPassword(roomNumber, password, visiterMode)
  end
  
  def checkLoginPassword(roomNumber, password, visiterMode)
    logging("checkLoginPassword roomNumber", roomNumber)
    @saveDirInfo.setSaveDataDirIndex(roomNumber)
    dirName = @saveDirInfo.getDirName()
    
    result = {
      'resultText' => '',
      'visiterMode' => false,
      'roomNumber' => roomNumber,
    }
    
    isRoomExist = ( isExistDir?(dirName) ) 
    
    unless( isRoomExist )
      result['resultText'] = "プレイルームNo.#{roomNumber}は作成されていません"
      return result
    end
    
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
    
    getSaveData(trueSaveFileName) do |saveData|
      
      playRoomChangedPassword = saveData['playRoomChangedPassword']
      passwordMatched = isPasswordMatch?(password, playRoomChangedPassword)
      
      if @isWebIf
        unless passwordMatched
          visiterMode = true 
        end
      end
      
      canVisit = saveData['canVisit']
      if( canVisit and visiterMode )
        result['resultText'] = "OK"
        result['visiterMode'] = true
      else
        if( passwordMatched )
          result['resultText'] = "OK"
        else
          result['resultText'] = "passwordMismatch"
        end
      end
    end
    
    return result
  end
  
  def isPasswordMatch?(password, changedPassword)
    return true if( changedPassword.nil? )
    return false if( password.nil? )
    ( password.crypt(changedPassword) == changedPassword )
  end
  
  
  def logout()
    logoutData = getParamsFromRequestData()
    logging(logoutData, 'logoutData')
    
    uniqueId = logoutData['uniqueId']
    logging(uniqueId, 'uniqueId');
    
    trueSaveFileName = @saveDirInfo.getTrueSaveFileName($loginUserInfo)
    changeSaveData(trueSaveFileName) do |saveData|
      saveData.each do |existUserId, userInfo|
        logging(existUserId, "existUserId in logout check")
        logging(uniqueId, 'uniqueId in logout check')
        
        if( existUserId == uniqueId )
          userInfo['isLogout'] = true
        end
      end
      
      logging(saveData, 'saveData in logout')
    end
  end
  
  
  def checkFileSizeOnMb(data, size_MB)
    error = false
    
    limit = (size_MB * 1024 * 1024)
    
    if( data.size > limit )
      error = true
    end
    
    if( error )
      return "ファイルサイズが最大値(#{size_MB}MB)以上のためアップロードに失敗しました。"
    end
    
    return ""
  end
  
  
  def getBotTableInfos()
    logging("getBotTableInfos Begin")
    result = {
      "resultText"=> "OK",
    }
    
    dir = getDiceBotExtraTableDirName
    result["tableInfos"] = getBotTableInfosFromDir(dir)
    
    logging(result, "result")
    logging("getBotTableInfos End")
    return result
  end
  
  def getBotTableInfosFromDir(dir)
    logging(dir, 'getBotTableInfosFromDir dir')
    
    require 'TableFileData'
    
    isLoadCommonTable = false
    tableFileData = TableFileData.new( isLoadCommonTable )
    tableFileData.setDir(dir, @diceBotTablePrefix)
    tableInfos = tableFileData.getAllTableInfo
    
    logging(tableInfos, "getBotTableInfosFromDir tableInfos")
    tableInfos.sort!{|a, b| a["command"].to_i <=> b["command"].to_i}
    
    logging(tableInfos, 'getBotTableInfosFromDir result tableInfos')
    
    return tableInfos
  end
  
  
  
  def addBotTable()
    result = {}
    
    params = getParamsFromRequestData()
    result['resultText'] = addBotTableMain(params)
    
    if( result['resultText'] != "OK" )
      return result
    end
    
    logging("addBotTableMain called")
    
    result = getBotTableInfos()
    logging(result, "addBotTable result")
    
    return result
  end
  
  def addBotTableMain(params)
    logging("addBotTableMain Begin")
    
    dir = getDiceBotExtraTableDirName
    makeDir(dir)
    
    require 'TableFileData'
    
    resultText = 'OK'
    begin
      creator = TableFileCreator.new(dir, @diceBotTablePrefix, params)
      creator.execute
    rescue Exception => e
      loggingException(e)
      resultText = getLanguageKey( e.to_s )
    end
    
    logging(resultText, "addBotTableMain End resultText")
    
    return resultText
  end
  
  
  
  def changeBotTable()
    result = {}
    result['resultText'] = changeBotTableMain()
    
    if( result['resultText'] != "OK" )
      return result
    end
    
    result = getBotTableInfos()
    return result
  end
  
  def changeBotTableMain()
    logging("changeBotTableMain Begin")
    
    dir = getDiceBotExtraTableDirName
    params = getParamsFromRequestData()
    
    require 'TableFileData'
    
    resultText = 'OK'
    begin
      creator = TableFileEditer.new(dir, @diceBotTablePrefix, params)
      creator.execute 
    rescue Exception => e
      loggingException(e)
      resultText = getLanguageKey( e.to_s )
    end
    
    logging(resultText, "changeBotTableMain End resultText")
    
    return resultText
  end
  
  
  
  def removeBotTable()
    removeBotTableMain()
    return getBotTableInfos()
  end
  
  def removeBotTableMain()
    logging("removeBotTableMain Begin")
    
    params = getParamsFromRequestData()
    command = params["command"]
    
    dir = getDiceBotExtraTableDirName
    
    require 'TableFileData'
    
    isLoadCommonTable = false
    tableFileData = TableFileData.new( isLoadCommonTable )
    tableFileData.setDir(dir, @diceBotTablePrefix)
    tableInfos = tableFileData.getAllTableInfo
    
    tableInfo = tableInfos.find{|i| i["command"] == command}
    logging(tableInfo, "tableInfo")
    return if( tableInfo.nil? )
    
    fileName = tableInfo["fileName"]
    logging(fileName, "fileName")
    return if( fileName.nil? )
    
    logging("isFile exist?")
    return unless( File.exist?(fileName) )
    
    begin
      File.delete(fileName)
    rescue Exception => e
      loggingException(e)
    end
    
    logging("removeBotTableMain End")
  end
  
  
  
  def requestReplayDataList()
    logging("requestReplayDataList begin")
    result = {
      "resultText"=> "OK",
    }
    
    result["replayDataList"] = getReplayDataList() #[{"title"=>x, "url"=>y}]
    
    logging(result, "result")
    logging("requestReplayDataList end")
    return result
  end
  
  def uploadReplayData()
    uploadFileBase($replayDataUploadDir, $UPLOAD_REPALY_DATA_MAX_SIZE) do |fileNameFullPath, fileNameOriginal, result|
      logging("uploadReplayData yield Begin")
      
      params = getParamsFromRequestData()
      
      ownUrl = params['ownUrl']
      replayUrl = ownUrl + "?replay=" + CGI.escape(fileNameFullPath)
      
      replayDataName = params['replayDataName']
      replayDataInfo = setReplayDataInfo(fileNameFullPath, replayDataName, replayUrl)
      
      result["replayDataInfo"] = replayDataInfo
      result["replayDataList"] = getReplayDataList() #[{"title"=>x, "url"=>y}]
      
      logging("uploadReplayData yield End")
    end
    
  end
  
  def getReplayDataList
    replayDataList = nil
    
    getSaveData( getReplayDataInfoFileName() ) do |saveData|
      replayDataList = saveData['replayDataList']
    end
    
    replayDataList ||= []
    
    return replayDataList
  end
  
  def getReplayDataInfoFileName
    infoFileName = fileJoin($replayDataUploadDir, 'replayDataInfo.json')
    return infoFileName
  end
  

  def setReplayDataInfo(fileName, title, url)
    
    replayDataInfo = {
      "fileName" => fileName,
      "title" => title,
      "url" => url,
    }
    
    changeSaveData( getReplayDataInfoFileName() ) do |saveData|
      saveData['replayDataList'] ||= []
      replayDataList = saveData['replayDataList']
      replayDataList << replayDataInfo
    end
    
    return replayDataInfo
  end
  

  def removeReplayData()
    logging("removeReplayData begin")
    
    result = {
      "resultText"=> "NG",
    }
    
    begin
      replayData = getParamsFromRequestData()
      
      logging(replayData, "replayData")
      
      replayDataList = []
      changeSaveData( getReplayDataInfoFileName() ) do |saveData|
        saveData['replayDataList'] ||= []
        replayDataList = saveData['replayDataList']
        
        replayDataList.delete_if do |i|
          if(( i['url'] == replayData['url'] ) and 
               ( i['title'] == replayData['title'] ))
            deleteFile(i['fileName'])
            true
          else
            false
          end
        end
      end
      
      logging("removeReplayData replayDataList", replayDataList)
      
      result = requestReplayDataList()
    rescue => e
      result["resultText"] = e.to_s
      loggingException(e)
    end
    
    return result
  end
  
  
  def uploadFile()
    uploadFileBase($fileUploadDir, $UPLOAD_FILE_MAX_SIZE) do |fileNameFullPath, fileNameOriginal, result|
      
      deleteOldUploadFile()
      
      params = getParamsFromRequestData()
      baseUrl = params['baseUrl']
      logging(baseUrl, "baseUrl")
      
      fileUploadUrl = baseUrl + fileNameFullPath
      
      result["uploadFileInfo"] = {
        "fileName" => fileNameOriginal,
        "fileUploadUrl" => fileUploadUrl,
      }
    end
  end
  
  
  def deleteOldUploadFile()
    deleteOldFile($fileUploadDir, $uploadFileTimeLimitSeconds, File.join($fileUploadDir, "dummy.txt"))
  end
  
  def deleteOldFile(saveDir, limitSecond, excludeFileName = nil)
    begin
      limitTime = (Time.now.to_i - limitSecond)
      fileNames = Dir.glob(File.join(saveDir, "*"))
      fileNames.delete_if{|i| i == excludeFileName }
      
      fileNames.each do |fileName|
        fileName = fileName.untaint
        timeStamp = File.mtime(fileName).to_i
        next if( timeStamp >= limitTime )
        
        File.delete(fileName)
      end
    rescue => e
      loggingException(e)
    end
  end
  
  
  def uploadFileBase(fileUploadDir, fileMaxSize, isChangeFileName = true)
    logging("uploadFile() Begin")
    
    result = {
      "resultText"=> "NG",
    }
    
    begin
      
      unless( File.exist?(fileUploadDir) )
        result["resultText"] = "#{fileUploadDir}が存在しないためアップロードに失敗しました。"
        return result;
      end
      
      params = getParamsFromRequestData()
      
      fileData = params['fileData']
      
      sizeCheckResult = checkFileSizeOnMb(fileData, fileMaxSize)
      if( sizeCheckResult != "" )
        result["resultText"] = sizeCheckResult
        return result;
      end
      
      fileNameOriginal = params['fileName'].toutf8
      
      fileName = fileNameOriginal
      if( isChangeFileName )
        fileName = getNewFileName(fileNameOriginal)
      end
      
      fileNameFullPath = fileJoin(fileUploadDir, fileName).untaint
      logging(fileNameFullPath, "fileNameFullPath")
      
      yield(fileNameFullPath, fileNameOriginal, result)
      
      open(fileNameFullPath, "w+") do |file|
        file.binmode
        file.write(fileData)
      end
      File.chmod(0666, fileNameFullPath)
      
      result["resultText"] = "OK"
      
    rescue => e
      logging(e, "error")
      result["resultText"] = getLanguageKey( e.to_s )
    end
    
    logging(result, "load result")
    logging("uploadFile() End")
    
    return result
  end
  
  
  def loadAllSaveData()
    logging("loadAllSaveData() Begin")
    checkLoad()
    
    setRecordWriteEmpty
    
    fileUploadDir = getRoomLocalSpaceDirName
    
    clearDir(fileUploadDir)
    makeDir(fileUploadDir)
    
    fileMaxSize = $allSaveDataMaxSize # Mbyte
    saveFile = nil
    isChangeFileName = false
    
    result = uploadFileBase(fileUploadDir, fileMaxSize, isChangeFileName) do |fileNameFullPath, fileNameOriginal, resultTmp|
      saveFile = fileNameFullPath
    end
    
    logging(result, "uploadFileBase result")
    
    unless( result["resultText"] == 'OK' )
      return result
    end
    
    beforeTime = getImageInfoFileTime()
    extendSaveData(saveFile, fileUploadDir)
    localizeImageInfo() if( getImageInfoFileTime() != beforeTime)
    
    
    chatPaletteSaveData = loadAllSaveDataDefaultInfo(fileUploadDir)
    result['chatPaletteSaveData'] = chatPaletteSaveData
    
    logging(result, 'loadAllSaveData result')
    
    return result
  end
  
  
  def getImageInfoFileTime()
    imageInfoFileName = getImageInfoFileNameLocal
    return 0 unless File.exist?(imageInfoFileName)
    return File.mtime(imageInfoFileName)
  end
  
  def localizeImageInfo()
    imageInfoFileName = getImageInfoFileNameLocal
    
    changeSaveData( imageInfoFileName ) do |saveData|
      imageTags = saveData['imageTags']
      return false if imageTags.nil?
      
      imageTags = localizeImageInfoSource(imageTags)
      imageTags = localizeImageInfoSmallImage(imageTags)
      
      saveData['imageTags'] = imageTags
    end
  end
  
  def localizeImageInfoSource(imageTags)
    
    keys = imageTags.keys
    
    keys.each do |source|
      tagInfo = imageTags.delete(source)
      next if tagInfo.nil?
      
      base = File.basename(source)
      dir = getRoomLocalSpaceDirName()
      newSource = File.join(dir, base)
      
      next unless File.exist?(newSource)
      
      imageTags[newSource] = tagInfo
    end
    
    return imageTags
  end
  
  def localizeImageInfoSmallImage(imageTags)
    imageTags.each do |source, tagInfo|
      next if tagInfo.nil?
      
      tagInfo.delete("smallImage")
    end
    
    return imageTags
  end
  
  
  def clearDir(dir)
    logging(dir, "clearDir dir")
    
    unless( File.exist?(dir) )
      return
    end
    
    unless( File.directory?(dir) )
      File.delete(dir)
      return
    end
    
    files = Dir.glob( File.join(dir, "*") )
    files.each do |file|
      File.delete( file.untaint )
    end
  end
  
  def extendSaveData(allSaveDataFile, fileUploadDir)
    logging(allSaveDataFile, 'allSaveDataFile')
    logging(fileUploadDir, 'fileUploadDir')
    
    require 'zlib'
    require 'archive/tar/minitar'
    
    readTar(allSaveDataFile) do |tar|
      logging("begin read scenario tar file")
      
      Archive::Tar::Minitar.unpackWithCheck(tar, fileUploadDir) do |fileName, isDirectory|
        checkUnpackFile(fileName, isDirectory)
      end
    end
    
    File.delete(allSaveDataFile)
    
    logging("archive extend !")
  end
  
  def readTar(allSaveDataFile)
    
    begin
      File.open(allSaveDataFile, 'rb') do |file|
        tar = file
        tar = Zlib::GzipReader.new(file)
        
        logging("allSaveDataFile is gzip")
        yield(tar)
        
      end
    rescue
      File.open(allSaveDataFile, 'rb') do |file|
        tar = file
        
        logging("allSaveDataFile is tar")
        yield(tar)
        
      end
    end
  end
  
  
  #直下のファイルで許容する拡張子の場合かをチェック
  def checkUnpackFile(fileName, isDirectory)
    logging(fileName, 'checkUnpackFile fileName')
    logging(isDirectory, 'checkUnpackFile isDirectory')
    
    if( isDirectory )
      logging('isDirectory!')
      return false
    end
    
    result = isAllowdUnpackFile(fileName)
    logging(result, 'checkUnpackFile result')
    
    return result
  end
  
  def isAllowdUnpackFile(fileName)
    
    if( /\// =~ fileName )
      loggingForce(fileName, 'NG! checkUnpackFile /\// paturn')
      return false
    end
    
    if( isAllowedFileExt(fileName) )
      return true
    end
    
    # loggingForce(fileName, 'NG! checkUnpackFile else paturn')
    
    return false
  end
  
  def isAllowedFileExt(fileName)
    extName = getAllowedFileExtName(fileName)
    return ( not extName.nil? )
  end
  
  def getAllowedFileExtName(fileName)
    rule = /\.(jpg|jpeg|gif|png|bmp|pdf|doc|txt|html|htm|xls|rtf|zip|lzh|rar|swf|flv|avi|mp4|mp3|wmv|wav|sav|cpd|rec|json)$/i
    
    return nil unless( rule === fileName )
    
    extName = "." + $1
    return extName
  end
  
  def getRoomLocalSpaceDirName
    roomNo = @saveDirInfo.getSaveDataDirIndex
    getRoomLocalSpaceDirNameByRoomNo(roomNo)
  end
  
  def getRoomLocalSpaceDirNameByRoomNo(roomNo)
    dir = $imageUploadDir
    unless roomNo.nil?
      dir = File.join($imageUploadDir, "room_#{roomNo}")
    end
    return dir
  end
  
  def makeDir(dir)
    logging(dir, "makeDir dir")
    
    if( File.exist?(dir) )
      if( File.directory?(dir) )
        return
      end
      
      File.delete(dir)
    end
    
    Dir::mkdir(dir)
    File.chmod(0777, dir)
  end
  
  def rmdir(dir)
    SaveDirInfo.removeDir(dir)
  end
  
  def loadAllSaveDataDefaultInfo(dir)
    loadAllSaveDataDefaultSaveData(dir)
    chatPaletteSaveData = loadAllSaveDataDefaultChatPallete(dir)
    
    return chatPaletteSaveData
  end
  
  def loadAllSaveDataDefaultSaveData(dir)
    logging('loadAllSaveDataDefaultSaveData begin')
    saveFile = File.join(dir, @defaultAllSaveData)
    
    unless( File.exist?(saveFile) )
      logging(saveFile, 'saveFile is NOT exist')
      return
    end
    
    jsonDataString = File.readlines(saveFile).join
    loadFromJsonDataString(jsonDataString)
    
    logging('loadAllSaveDataDefaultSaveData end')
  end
  
  
  def loadAllSaveDataDefaultChatPallete(dir)
    file = File.join(dir, @defaultChatPallete)
    logging(file, 'loadAllSaveDataDefaultChatPallete file')
    
    return nil unless( File.exist?(file) )
    
    buffer = File.readlines(file).join
    logging(buffer, 'loadAllSaveDataDefaultChatPallete buffer')
    
    return buffer
  end
  
  
  def load()
    logging("load() Begin")
    
    result = {}
    
    begin
      checkLoad()
      
      setRecordWriteEmpty
      
      params = getParamsFromRequestData()
      logging(params, 'load params')
      
      jsonDataString = params['fileData']
      logging(jsonDataString, 'jsonDataString')
      
      result = loadFromJsonDataString(jsonDataString)
      
    rescue => e
      result["resultText"] = e.to_s
    end
    
    logging(result, "load result")
    
    return result
  end
  

  def checkLoad()
    roomNumber = @saveDirInfo.getSaveDataDirIndex
    
    if( $unloadablePlayRoomNumbers.include?(roomNumber) )
      raise "unloadablePlayRoomNumber"
    end
  end
  
  

  
  def changeLoadText(text)
    text = changeTextForLocalSpaceDir(text)
    return text
  end
  
  def changeTextForLocalSpaceDir(text)
    #プレイルームにローカルなファイルを置く場合の特殊処理用ディレクトリ名変換
    dir = getRoomLocalSpaceDirName
    dirJsonText = JsonBuilder.new.build(dir)
    changedDir = dirJsonText[2...-2]
    
    logging(changedDir, 'localSpace name')
    
    text = text.gsub($imageUploadDirMarker, changedDir)
    return text
  end
  
  
  def loadFromJsonDataString(jsonDataString)
    jsonDataString = changeLoadText(jsonDataString)
    
    jsonData = getJsonDataFromText(jsonDataString)
    loadFromJsonData(jsonData)
  end
  
  def loadFromJsonData(jsonData)
    logging(jsonData, 'loadFromJsonData jsonData')
    
    params = getParamsFromRequestData()
    
    removeCharacterDataList = params['removeCharacterDataList']
    if( removeCharacterDataList != nil )
      removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
    end
    
    targets = params['targets']
    logging(targets, "targets")
    
    if( targets.nil? ) 
      logging("loadSaveFileDataAll(jsonData)")
      loadSaveFileDataAll(jsonData)
    else
      logging("loadSaveFileDataFilterByTargets(jsonData, targets)")
      loadSaveFileDataFilterByTargets(jsonData, targets)
    end
    
    result = {
      "resultText"=> "OK"
    }
    
    logging(result, "loadFromJsonData result")
    
    return result
  end
  
  def getSaveDataAllFromSaveData(jsonData)
    jsonData['saveDataAll']
  end
  
  def getLoadData(saveDataAll, fileType, key, defaultValue)
    saveFileData = saveDataAll[fileType]
    return defaultValue if(saveFileData.nil?)
    
    data = saveFileData[key]
    return defaultValue if(data.nil?)
    
    return data.clone
  end
  
  def loadCharacterDataList(saveDataAll, type)
    characterDataList = getLoadData(saveDataAll, 'characters', 'characters', [])
    logging(characterDataList, "characterDataList")
    
    characterDataList = characterDataList.delete_if{|i| (i["type"] != type)}
    addCharacterData( characterDataList )
  end
  
  def loadSaveFileDataFilterByTargets(jsonData, targets)
    saveDataAll = getSaveDataAllFromSaveData(jsonData)
    
    targets.each do |target|
      logging(target, 'loadSaveFileDataFilterByTargets each target')
      
      case target
      when "map"
        mapData = getLoadData(saveDataAll, 'map', 'mapData', {})
        changeMapSaveData(mapData)
      when "characterData", "mapMask", "mapMarker", "floorTile", "magicRangeMarker", "magicRangeMarkerDD4th", "Memo", getCardType()
        loadCharacterDataList(saveDataAll, target)
      when "characterWaitingRoom"
        logging("characterWaitingRoom called")
        waitingRoom = getLoadData(saveDataAll, 'characters', 'waitingRoom', [])
        setWaitingRoomInfo(waitingRoom)
      when "standingGraphicInfos"
        effects = getLoadData(saveDataAll, 'effects', 'effects', [])
        effects = effects.delete_if{|i| (i["type"] != target)}
        logging(effects, "standingGraphicInfos effects");
        addEffectData(effects)
      when "cutIn"
        effects = getLoadData(saveDataAll, 'effects', 'effects', [])
        effects = effects.delete_if{|i| (i["type"] != nil)}
        addEffectData(effects)
      when "initiative"
        roundTimeData = getLoadData(saveDataAll, 'time', 'roundTimeData', {})
        changeInitiativeData(roundTimeData)
      when "resource"
        resource = getLoadData(saveDataAll, 'time', 'resource', [])
        changeResourcesAllByParam(resource)
      when "diceBotTable"
        loadDiceBotTable(jsonData)
      else
        loggingForce(target, "invalid load target type")
      end
    end
  end
  
  def loadSaveFileDataAll(jsonData)
    saveDataAll = getSaveDataAllFromSaveData(jsonData)
    
    logging("loadSaveFileDataAll(saveDataAll) begin")
    
    @saveFiles.each do |fileTypeName, trueSaveFileName|
      logging(fileTypeName, "fileTypeName")
      logging(trueSaveFileName, "trueSaveFileName")
      
      saveDataForType = saveDataAll[fileTypeName]
      saveDataForType ||= {}
      logging(saveDataForType, "saveDataForType")
      
      loadSaveFileDataForEachType(fileTypeName, trueSaveFileName, saveDataForType)
    end
    
    if( saveDataAll.include?($playRoomInfoTypeName) )
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      saveDataForType = saveDataAll[$playRoomInfoTypeName]
      loadSaveFileDataForEachType($playRoomInfoTypeName, trueSaveFileName, saveDataForType)
    end
    
    loadDiceBotTable(jsonData)
    
    logging("loadSaveFileDataAll(saveDataAll) end")
  end
  
  
  def loadSaveFileDataForEachType(fileTypeName, trueSaveFileName, saveDataForType)
    
    changeSaveData(trueSaveFileName) do |saveDataCurrent|
      logging(saveDataCurrent, "before saveDataCurrent")
      saveDataCurrent.clear
      
      saveDataForType.each do |key, value|
        logging(key, "saveDataForType.each key")
        logging(value, "saveDataForType.each value")
        saveDataCurrent[key] = value
      end
      logging(saveDataCurrent, "after saveDataCurrent")
    end
    
  end
  
  
  def loadDiceBotTable(jsonData)
    
    data = jsonData[$diceBotTableSaveKey]
    return if( data.nil? )
    
    data.each do |info|
      info['table'] = getDiceBotTableString(info['table'])
      addBotTableMain(info)
    end
  
  end
  
  def getDiceBotTableString(table)
    
    lines = []
    table.each do |line|
      lines << line.join(":")
    end
    
    return lines.join("\n")
  end
  
  def getSmallImageDir
    saveDir = $imageUploadDir
    smallImageDirName = "smallImages"
    smallImageDir = fileJoin(saveDir, smallImageDirName);
    
    return smallImageDir
  end
  
  def saveSmallImage(smallImageData, imageFileNameBase, uploadImageFileName)
    logging("saveSmallImage begin")
    logging(imageFileNameBase, "imageFileNameBase")
    logging(uploadImageFileName, "uploadImageFileName")
    
    smallImageDir = getSmallImageDir
    uploadSmallImageFileName = fileJoin(smallImageDir, imageFileNameBase)
    uploadSmallImageFileName += ".png";
    uploadSmallImageFileName.untaint
    logging(uploadSmallImageFileName, "uploadSmallImageFileName")
    
    open( uploadSmallImageFileName, "wb+" ) do |file|
      file.write( smallImageData )
    end
    logging("small image create successed.")
    
    params = getParamsFromRequestData()
    tagInfo = params['tagInfo']
    logging(tagInfo, "saveSmallImage tagInfo")
    
    tagInfo["smallImage"] = uploadSmallImageFileName
    logging(tagInfo, "saveSmallImage tagInfo smallImage url added")
    
    margeTagInfo(tagInfo, uploadImageFileName)
    logging(tagInfo, "saveSmallImage margeTagInfo tagInfo")
    changeImageTagsLocal(uploadImageFileName, tagInfo)
    
    logging("saveSmallImage end")
  end
  
  def margeTagInfo(tagInfo, source)
    logging(source, "margeTagInfo source")
    imageTags = getImageTags()
    tagInfo_old = imageTags[source]
    logging(tagInfo_old, "margeTagInfo tagInfo_old")
    return if( tagInfo_old.nil? )
    
    tagInfo_old.keys.each do |key|
      tagInfo[key] = tagInfo_old[key]
    end
    
    logging(tagInfo, "margeTagInfo tagInfo")
  end
  
  def uploadImageData()
    logging("uploadImageData load Begin")
    
    result = {
      "resultText"=> "OK"
    }
    
    begin
      params = getParamsFromRequestData()
      
      imageFileName = params["imageFileName"]
      logging(imageFileName, "imageFileName")
      
      imageData = getImageDataFromParams(params, "imageData")
      smallImageData = getImageDataFromParams(params, "smallImageData")
      
      if( imageData.nil? )
        logging("createSmallImage is here")
        imageFileNameBase = File.basename(imageFileName)
        saveSmallImage(smallImageData, imageFileNameBase, imageFileName)
        return result
      end
      
      saveDir = getUploadImageDataUploadDir(params)
      imageFileNameBase = getNewFileName(imageFileName, "img")
      logging(imageFileNameBase, "imageFileNameBase")
      
      uploadImageFileName = fileJoin(saveDir, imageFileNameBase)
      logging(uploadImageFileName, "uploadImageFileName")
      
      open( uploadImageFileName, "wb+" ) do |file|
        file.write( imageData )
      end
      
      saveSmallImage(smallImageData, imageFileNameBase, uploadImageFileName)
      
    rescue => e
      result["resultText"] = getLanguageKey( e.to_s )
    end
    
    logging(result, "uploadImageData result")
    logging("uploadImageData load End")
    
    return result
  end
  
  def getUploadImageDataUploadDir(params)
    tagInfo = params['tagInfo']
    tagInfo ||= {}
    roomNumber = tagInfo["roomNumber"]
    saveDir = getRoomLocalSpaceDirNameByRoomNo(roomNumber)
    makeDir(saveDir)
    
    return saveDir
  end
  
  def getImageDataFromParams(params, key)
    value = params[key]
    
    sizeCheckResult = checkFileSizeOnMb(value, $UPLOAD_IMAGE_MAX_SIZE)
    raise sizeCheckResult unless( sizeCheckResult.empty? )
    
    return value
  end
  
  
  #新規ファイル名。reqにroomNumberを持っていた場合、ファイル名に付加するようにする
  def getNewFileName(fileName, preFix = "")
    @newFileNameIndex ||= 0
    
    extName = getAllowedFileExtName(fileName)
    
    if( extName.nil? )
      raise "invalidFileNameExtension\t#{fileName}"
    end
    
    logging(extName, "extName")
    
    roomNumber  = getRequestData('roomNumber')
    if( roomNumber.nil? )
      roomNumber  = getRequestData('room')
    end
    
    result = nil
    if( roomNumber.is_a?(Integer) )
      result = 'room_' + roomNumber.to_s + '_' + preFix + Time.now.to_f.to_s.gsub(/\./, '_') + "_" + @newFileNameIndex.to_s + extName
    else
      result = preFix + Time.now.to_f.to_s.gsub(/\./, '_') + "_" + @newFileNameIndex.to_s + extName
    end
    
    return result.untaint
  end
  
  def deleteImage()
    logging("deleteImage begin")
    
    imageData = getParamsFromRequestData()
    logging(imageData, "imageData")
    
    imageUrlList = imageData['imageUrlList']
    logging(imageUrlList, "imageUrlList")
    
    deleteImages(imageUrlList)
  end
    
  def deleteImages(imageUrlList)
    imageFiles = getAllImageFileNameFromTagInfoFile()
    addLocalImageToList(imageFiles)
    logging(imageFiles, "imageFiles")
    
    imageUrlFileName = $imageUrlText
    logging(imageUrlFileName, "imageUrlFileName")
    
    deleteCount = 0
    resultText = ""
    imageUrlList.each do |imageUrl|
      if( isProtectedImage(imageUrl) )
        warningMessage = "#{imageUrl}は削除できない画像です。"
        next
      end
      
      imageUrl.untaint
      deleteResult1 = deleteImageTags(imageUrl)
      deleteResult2 = deleteTargetImageUrl(imageUrl, imageFiles, imageUrlFileName)
      deleteResult = (deleteResult1 or deleteResult2)
      
      if( deleteResult )
        deleteCount += 1
      else
        warningMessage = "不正な操作です。あなたが削除しようとしたファイル(#{imageUrl})はイメージファイルではありません。"
        loggingForce(warningMessage)
        resultText += warningMessage
      end
    end
    
    resultText += "#{deleteCount}個のファイルを削除しました。"
    result = {"resultText" => resultText}
    logging(result, "result")
    
    logging("deleteImage end")
    return result
  end
  
  def isProtectedImage(imageUrl)
    $protectImagePaths.each do |url|
      if( imageUrl.index(url) == 0 )
        return true
      end
    end
    
    return false
  end
  
  def deleteTargetImageUrl(imageUrl, imageFiles, imageUrlFileName)
    logging(imageUrl, "deleteTargetImageUrl(imageUrl)")
    
    if( imageFiles.include?(imageUrl) )
      if( isExist?(imageUrl) )
        deleteFile(imageUrl)
        return true
      end
    end
    
    locker = getSaveFileLock(imageUrlFileName)
    locker.lock do 
      lines = readLines(imageUrlFileName)
      logging(lines, "lines")
      
      deleteResult = lines.reject!{|i| i.chomp == imageUrl }
      
      unless( deleteResult )
        return false
      end
      
      logging(lines, "lines deleted")
      createFile(imageUrlFileName, lines.join)
    end
    
    return true
  end
  
  #override
  def addTextToFile(fileName, text)
    File.open(fileName, "a+") do |file|
      file.write(text);
    end
  end
  
  def uploadImageUrl()
    logging("uploadImageUrl begin")
    
    imageData = getParamsFromRequestData()
    logging(imageData, "imageData")
    
    imageUrl = imageData['imageUrl']
    logging(imageUrl, "imageUrl")
    
    imageUrlFileName = $imageUrlText
    logging(imageUrlFileName, "imageUrlFileName")
    
    resultText = "画像URLのアップロードに失敗しました。"
    locker = getSaveFileLock(imageUrlFileName)
    locker.lock do 
      alreadyExistUrls = readLines(imageUrlFileName).collect{|i| i.chomp }
      if( alreadyExistUrls.include?(imageUrl) )
        resultText = "すでに登録済みの画像URLです。"
      else
        addTextToFile(imageUrlFileName, (imageUrl + "\n"))
        resultText = "画像URLのアップロードに成功しました。"
      end
    end
    
    tagInfo = imageData['tagInfo']
    logging(tagInfo, 'uploadImageUrl.tagInfo')
    changeImageTagsLocal(imageUrl, tagInfo)
    
    logging("uploadImageUrl end")
    
    result = {"resultText" => resultText}
    return result
  end
  
  
  
  def getGraveyardCharacterData()
    logging("getGraveyardCharacterData start.")
    result = []
    
    getSaveData(@saveFiles['characters']) do |saveData|
      graveyard = saveData['graveyard']
      graveyard ||= []
      
      result = graveyard.reverse;
    end
    
    return result;
  end
  
  def getWaitingRoomInfo()
    logging("getWaitingRoomInfo start.")
    result = []
    
    getSaveData(@saveFiles['characters']) do |saveData|
      waitingRoom = getWaitinigRoomFromSaveData(saveData)
      result = waitingRoom
    end
    
    return result;
  end
  
  def setWaitingRoomInfo(data)
    changeSaveData(@saveFiles['characters']) do |saveData|
      waitingRoom = getWaitinigRoomFromSaveData(saveData)
      waitingRoom.concat(data)
    end
  end
  
  def getImageList()
    logging("getImageList start.")
    
    imageList = getAllImageFileNameFromTagInfoFile()
    logging(imageList, "imageList all result")
    
    addTextsCharacterImageList(imageList, $imageUrlText)
    addLocalImageToList(imageList)
    
    deleteInvalidImageFileName(imageList)
    
    imageList.sort!
    
    return imageList
  end
    
  def addTextsCharacterImageList(imageList, *texts)
    texts.each do |text|
      next unless( isExist?(text) )
      
      lines = readLines(text)
      lines.each do |line|
        line.chomp!
        
        next if(line.empty?)
        next if(imageList.include?(line))
        
        imageList << line
      end
    end
  end
  
  def addLocalImageToList(imageList)
    dir = "#{$imageUploadDir}/public"
    addLocalImageToListByDir(imageList, dir)
    
    dir = getRoomLocalSpaceDirName
    if( File.exist?(dir) )
      addLocalImageToListByDir(imageList, dir)
    end
  end
  
  def addLocalImageToListByDir(imageList, dir)
    makeDir(dir)
    
    files = Dir.glob("#{dir}/*")
    
    files.each do |fileName|
      file = file.untaint
      
      next if( imageList.include?(fileName) )
      next unless( isImageFile(fileName) )
      next unless( isAllowedFileExt(fileName) )
      
      imageList << fileName
      logging(fileName, "added local image")
    end
    
    return imageList
  end
  
  
  def isImageFile(fileName)
    rule = /.(jpg|jpeg|gif|png|bmp|swf)$/i
    (rule === fileName)
  end
  
  
  def deleteInvalidImageFileName(imageList)
    imageList.delete_if{|i| (/\.txt$/===i)}
    imageList.delete_if{|i| (/\.lock$/===i)}
    imageList.delete_if{|i| (/\.json$/===i)}
    imageList.delete_if{|i| (/\.json~$/===i)}
    imageList.delete_if{|i| (/^.svn$/===i)}
    imageList.delete_if{|i| (/\.db$/===i)}
  end
  
  
  def sendDiceBotChatMessage
    logging('sendDiceBotChatMessage')
    
    params = getParamsFromRequestData()
    
    repeatCount = getDiceBotRepeatCount(params)
    
    results = []
    
    repeatCount.times do |i|
      
      paramsClone = params.clone
      paramsClone['message'] += " \##{ i + 1 }" if( repeatCount > 1 )
      
      result = sendDiceBotChatMessageOnece( paramsClone )
      logging(result, "sendDiceBotChatMessageOnece result")
      
      next if( result.nil? )
      
      results << result
    end
    
    logging(results, "sendDiceBotChatMessage results")
    
    return results
  end
  
  def getDiceBotRepeatCount(params)
    repeatCountLimit = 20
    
    repeatCount = params['repeatCount']
    
    repeatCount ||= 1
    repeatCount = 1 if( repeatCount < 1 )
    repeatCount = repeatCountLimit if( repeatCount > repeatCountLimit )
    
    return repeatCount
  end
  
  
  def sendDiceBotChatMessageOnece(params)
    
    rolledMessage, isSecret, secretMessage = getRollDiceResult( params )
    
    senderName = params['name']
    unless /\t/ === senderName
      state = params['state']
      senderName += ("\t" + state)  unless( state.empty? )
    end
    
    chatData = {
      "senderName" => senderName,
      "message" => rolledMessage,
      "color" => params['color'],
      "uniqueId" => '0',
      "channel" => params['channel']
    }
    
    sendto = params['sendto']
    unless( sendto.nil? )
      chatData['sendto'] = sendto
    end
    
    logging(chatData, 'sendDiceBotChatMessageOnece chatData')
    
    sendChatMessageByChatData(chatData)
    
    
    result = nil
    if( isSecret )
      params['isSecret'] = isSecret
      params['message'] = secretMessage
      result = params
    end
    
    return result
  end
  
  def getRollDiceResult( params )
    
    rollResult, isSecret, randResults = rollDice(params)
    
    secretMessage = ""
    if( isSecret )
      secretMessage = params['message'] + rollResult
    else
      params['message'] += rollResult
    end
    
    rolledMessage = getRolledMessage(params, isSecret, randResults)
    
    return rolledMessage, isSecret, secretMessage
  end
  
  
  def rollDice(params)
    require 'cgiDiceBot.rb'
    
    message = params['message']
    gameType = params['gameType']
    isNeedResult = params['isNeedResult']
    
    logging(message, 'rollDice message')
    logging(gameType, 'rollDice gameType')
    
    bot = CgiDiceBot.new
    dir = getDiceBotExtraTableDirName
    
    result, randResults = bot.roll(message, gameType, dir, @diceBotTablePrefix, isNeedResult)
    
    result.gsub!(/＞/, '→')
    result.sub!(/\r?\n?\Z/m, '')
    
    logging(result, 'rollDice result')
    logging(randResults, 'rollDice randResults')
    
    return result, bot.isSecret, randResults
  end
  
  def getDiceBotExtraTableDirName
    getRoomLocalSpaceDirName
  end
  
  
  def getRolledMessage(params, isSecret, randResults)
    logging("getRolledMessage Begin")

    logging(isSecret, "isSecret")
    logging(randResults, "randResults")
    
    if( isSecret )
      params['message'] = getLanguageKey('secretDice')
      randResults = randResults.collect{|value, max| [0, 0] }
    end
    
    message = params['message']
    
    if( randResults.nil? )
      logging("randResults is nil")
      return message
    end
    
    
    data = {
      "chatMessage" => message,
      "randResults" => randResults,
      "uniqueId" => params['uniqueId'],
      "power" => getDiceBotPower(params),
    }
    
    text = "###CutInCommand:rollVisualDice###" + getTextFromJsonData(data)
    logging(text, "getRolledMessage End text")
    
    return text
  end
  
  def getDiceBotPower(params)
    message = params['message']
    
    power = 0
    if /((!|！)+)$/ === message
      power = $1.length
    end
    
    return power
  end
  
  
  def getLanguageKey(key)
    '###Language:' + key + '###'
  end
  
  
  def sendChatMessageAll
    logging("sendChatMessageAll Begin")
    
    result = {'result' => "NG" }
    
    return result if( $mentenanceModePassword.nil? )
    chatData = getParamsFromRequestData()
    
    password = chatData["password"]
    return result unless( password == $mentenanceModePassword )
    
    logging("adminPoassword check OK.")
    
    rooms = []
    
    $saveDataMaxCount.times do |roomNumber|
      logging(roomNumber, "loop roomNumber")
      
      initSaveFiles(roomNumber)
      
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      next unless( isExist?(trueSaveFileName) )
      
      logging(roomNumber, "sendChatMessageAll to No.")
      sendChatMessageByChatData(chatData)
      
      rooms << roomNumber
    end
    
    result['result'] = "OK"
    result['rooms'] = rooms
    logging(result, "sendChatMessageAll End, result")
    
    return result
  end
  
  def sendChatMessage
    chatData = getParamsFromRequestData()
    sendChatMessageByChatData(chatData)
  end
  
  def sendChatMessageByChatData(chatData)
    
    chatMessageData = nil
    
    changeSaveData(@saveFiles['chatMessageDataLog']) do |saveData|
      chatMessageDataLog = getChatMessageDataLog(saveData)
      
      deleteOldChatMessageData(chatMessageDataLog);
      
      now = Time.now.to_f
      chatMessageData = [now, chatData]
      
      chatMessageDataLog.push(chatMessageData)
      chatMessageDataLog.sort!
      
      logging(chatMessageDataLog, "chatMessageDataLog")
      logging(saveData['chatMessageDataLog'], "saveData['chatMessageDataLog']");
    end
    
    if( $IS_SAVE_LONG_CHAT_LOG )
      saveAllChatMessage(chatMessageData)
    end
  end
  
  def deleteOldChatMessageData(chatMessageDataLog)
    now = Time.now.to_f
    
    chatMessageDataLog.delete_if do |chatMessageData|
      writtenTime, = chatMessageData
      timeDiff = now - writtenTime
      
      ( timeDiff > ($oldMessageTimeout) )
    end
  end
  
  
  def deleteChatLog
    trueSaveFileName = @saveFiles['chatMessageDataLog']
    deleteChatLogBySaveFile(trueSaveFileName)
    
    result = {'result' => "OK" }
    return result
  end
  
  def deleteChatLogBySaveFile(trueSaveFileName)
    changeSaveData(trueSaveFileName) do |saveData|
      chatMessageDataLog = getChatMessageDataLog(saveData)
      chatMessageDataLog.clear
    end
    
    deleteChatLogAll()
  end
  
  def deleteChatLogAll()
    logging("deleteChatLogAll Begin")
    
    file = @saveDirInfo.getTrueSaveFileName($chatMessageDataLogAll)
    logging(file, "file")
    
    if( File.exist?(file) )
      locker = getSaveFileLock(file)
      locker.lock do 
        File.delete(file)
      end
    end
      
    logging("deleteChatLogAll End")
  end
  
    
  def getChatMessageDataLog(saveData)
    getArrayInfoFromHash(saveData, 'chatMessageDataLog')
  end
  
  
  def saveAllChatMessage(chatMessageData)
    logging(chatMessageData, 'saveAllChatMessage chatMessageData')
    
    if( chatMessageData.nil? )
      return
    end
    
    saveFileName = @saveDirInfo.getTrueSaveFileName($chatMessageDataLogAll)
    
    locker = getSaveFileLock(saveFileName)
    locker.lock do 
      
      lines = []
      if( isExist?(saveFileName) )
        lines = readLines(saveFileName)
      end
      lines << getTextFromJsonData(chatMessageData)
      lines << "\n"
      
      while( lines.size > $chatMessageDataLogAllLineMax )
        lines.shift
      end
      
      createFile(saveFileName, lines.join())
    end
    
  end
  
  def changeMap()
    mapData = getParamsFromRequestData()
    logging(mapData, "mapData")
    
    changeMapSaveData(mapData)
  end
  
  def changeMapSaveData(mapData)
    logging("changeMap start.")
    
    changeSaveData(@saveFiles['map']) do |saveData|
      draws = getDraws(saveData)
      setMapData(saveData, mapData)
      draws.each{|i| setDraws(saveData, i)}
    end
  end
  
  
  def setMapData(saveData, mapData)
    saveData['mapData'] ||= {}
    saveData['mapData'] = mapData
  end
  
  def getMapData(saveData)
    saveData['mapData'] ||= {}
    return saveData['mapData']
  end
  
  
  def drawOnMap
    logging('drawOnMap Begin')
    
    params = getParamsFromRequestData()
    data = params['data']
    logging(data, 'data')
    
    changeSaveData(@saveFiles['map']) do |saveData|
      setDraws(saveData, data)
    end
    
    logging('drawOnMap End')
  end
  
  def setDraws(saveData, data)
    return if( data.nil? )
    return if( data.empty? )
    
    info = data.first
    if( info['imgId'].nil? )
      info['imgId'] = createCharacterImgId('draw_')
    end
    
    draws = getDraws(saveData)
    draws << data
  end
  
  def getDraws(saveData)
    mapData = getMapData(saveData)
    mapData['draws'] ||= []
    return mapData['draws']
  end
  
  def clearDrawOnMap
    changeSaveData(@saveFiles['map']) do |saveData|
      draws = getDraws(saveData)
      draws.clear
    end
  end
  
  def undoDrawOnMap
    result = {
      'data' => nil
    }
    
    changeSaveData(@saveFiles['map']) do |saveData|
      draws = getDraws(saveData)
      result['data'] = draws.pop
    end
    
    return result
  end
  
  
  def addEffect()
    effectData = getParamsFromRequestData()
    effectDataList = [effectData]
    addEffectData(effectDataList)
  end
  
  def findEffect(effects, keys, data)
    found = nil
    
    effects.find do |effect|
      allMatched = true
      
      keys.each do |key|
        if( effect[key] != data[key] )
          allMatched = false
          break
        end
      end
      
      if( allMatched )
        found = effect
        break
      end
    end
    
    return found
  end
  
  def addEffectData(effectDataList)
    changeSaveData(@saveFiles['effects']) do |saveData|
      effects = getArrayInfoFromHash(saveData, 'effects')
      
      effectDataList.each do |effectData|
        logging(effectData, "addEffectData target effectData")
        
        if( effectData['type'] == 'standingGraphicInfos' )
          keys = ['type', 'name', 'state']
          found = findEffect(effects, keys, effectData)
          
          if( found )
            logging(found, "addEffectData is already exist, found data is => ")
            next 
          end
        end
        
        effectData['effectId'] = createCharacterImgId("effects_")
        effects << effectData
      end
    end
  end
  
  def changeEffect
    changeSaveData(@saveFiles['effects']) do |saveData|
      effectData = getParamsFromRequestData()
      targetCutInId = effectData['effectId']
      
      effects = getArrayInfoFromHash(saveData, 'effects')
      
      findIndex = -1
      effects.each_with_index do |i, index|
        if( targetCutInId == i['effectId'] )
          findIndex = index
        end
      end
      
      if( findIndex == -1 )
        return
      end
      
      effects[findIndex] = effectData
    end
  end
  
  def changeEffectsAll
    paramEffects = getParamsFromRequestData()
    return if( paramEffects.nil? )
    return if( paramEffects.empty? )
    
    logging(paramEffects, "changeEffectsAll paramEffects")
    
    type = paramEffects.first['type']
    
    changeSaveData(@saveFiles['effects']) do |saveData|
      effects = getArrayInfoFromHash(saveData, 'effects')
      
      effects.delete_if{|i| (type == i['type'])}
      
      paramEffects.each do |param|
        effects << param
      end
    end
  end
  
  
  def removeEffect()
    logging('removeEffect Begin')
    
    changeSaveData(@saveFiles['effects']) do |saveData|
      params = getParamsFromRequestData()
      
      effectIds = params['effectIds']
      logging(effectIds, 'effectIds')
      
      effects = getArrayInfoFromHash(saveData, 'effects')
      logging(effects, 'effects')
      
      effects.delete_if{|i|
        effectIds.include?(i['effectId'])
      }
    end
    
    logging('removeEffect End')
  end
  
  
  
  def getImageInfoFileNameLocal
    roomNo = @saveDirInfo.getSaveDataDirIndex
    imageInfoFileName = getImageInfoFileName(roomNo)
    return imageInfoFileName
  end
  
  def getImageInfoFileName(roomNumber)
    
    dir = $imageUploadDir
    
    unless roomNumber.nil?
      dir = getRoomLocalSpaceDirName
      makeDir(dir)
    end
    
    imageInfoFileName = fileJoin(dir, 'imageInfo.json')
    logging(imageInfoFileName, 'imageInfoFileName')
    
    return imageInfoFileName
  end
  
  def changeImageTags()
    effectData = getParamsFromRequestData()
    source = effectData['source']
    tagInfo = effectData['tagInfo']
    
    changeImageTagsLocal(source, tagInfo)
  end
  
  def getAllImageFileNameFromTagInfoFile()
    imageTags = getImageTags()
    imageFileNames = imageTags.keys
    
    return imageFileNames
  end
  
  def changeImageTagsLocal(source, tagInfo)
    return if( tagInfo.nil? )
    
    roomNumber = tagInfo["roomNumber"]
    
    changeSaveData( getImageInfoFileName(roomNumber) ) do |saveData|
      saveData['imageTags'] ||= {}
      imageTags = saveData['imageTags']
      
      imageTags[source] = tagInfo
    end
  end
  
  def deleteImageTags(source)
    roomNumber = @saveDirInfo.getSaveDataDirIndex
    isDeleted = deleteImageTagsByRoomNo(source, roomNumber)
    return true if( isDeleted )
    
    return deleteImageTagsByRoomNo(source, nil)
  end
  
  def deleteImageTagsByRoomNo(source, roomNumber)
    
    changeSaveData( getImageInfoFileName(roomNumber) ) do |saveData|
      
      imageTags = saveData['imageTags']
      return false if imageTags.nil?
      
      tagInfo = imageTags.delete(source)
      return false if tagInfo.nil?
      
      smallImage = tagInfo["smallImage"]
      begin
        deleteFile(smallImage)
      rescue => e
        loggingException(e)
      end
    end
    
    return true
  end
  
  def deleteFile(file)
    return unless File.exist?(file)
    File.delete(file)
  end
  
  def getImageTagsAndImageList
    result = {}
    
    result['tagInfos'] = getImageTags()
    result['imageList'] = getImageList()
    result['imageDir'] = $imageUploadDir
    
    logging("getImageTagsAndImageList result", result)
    
    return result
  end
  
  def getImageTags(*roomNoList)
    logging('getImageTags start')
    
    imageTags = {}
    
    if roomNoList.empty? 
      roomNoList = [nil, @saveDirInfo.getSaveDataDirIndex]
    end
    
    roomNoList.each do |roomNumber|
      getSaveData( getImageInfoFileName(roomNumber) ) do |saveData|
        tmpTags = saveData['imageTags']
        tmpTags ||= {}
        
=begin
        unless( roomNumber.nil? )
          tmpTags.each do |key, value|
            next if value.nil?
            value.delete("roomNumber")
          end
        end
=end
        
        imageTags.merge!( tmpTags )
      end
    end
    
    logging(imageTags, 'getImageTags imageTags')
    
    return imageTags
  end
  
  
  def createCharacterImgId(prefix = "character_")
    @imgIdIndex ||= 0;
    @imgIdIndex += 1;
    
    #return (prefix + Time.now.to_f.to_s + "_" + @imgIdIndex.to_s);
    return (prefix + sprintf("%.4f_%04d", Time.now.to_f, @imgIdIndex));
  end
  
  
  def addCharacter()
    characterData = getParamsFromRequestData()
    characterDataList = [characterData]
    
    addCharacterData( characterDataList )
  end
  
  
  def isAlreadyExistCharacter?(characters, characterData)
    return false if( characterData['name'].nil? )
    return false if( characterData['name'].empty? )
    
    alreadyExist = characters.find do |i|
      (i['imgId'] == characterData['imgId']) or
        (i['name'] == characterData['name'])
    end
    
    return false if( alreadyExist.nil? )
    
    logging("target characterData is already exist. no creation.", "isAlreadyExistCharacter?")
    return characterData['name']
  end
  
  def addCharacterData(characterDataList)
    result = {
      "addFailedCharacterNames" => []
    }
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      saveData['characters'] ||= []
      characters = getCharactersFromSaveData(saveData)
      
      characterDataList.each do |characterData|
        logging(characterData, "characterData")
        
        characterData['imgId'] = createCharacterImgId()
        
        failedName = isAlreadyExistCharacterInRoom?( saveData, characterData )
        
        if( failedName )
          result["addFailedCharacterNames"] << failedName
          next
        end
        
        logging("add characterData to characters")
        characters << characterData
      end
    end
    
    return result
  end
  
  def isAlreadyExistCharacterInRoom?( saveData, characterData )
    characters = getCharactersFromSaveData(saveData)
    waitingRoom = getWaitinigRoomFromSaveData(saveData)
    allCharacters = (characters + waitingRoom)
    
    failedName = isAlreadyExistCharacter?( allCharacters, characterData )
    return failedName
  end
  
  
  def changeCharacter()
    characterData = getParamsFromRequestData()
    logging(characterData, "characterData")
    
    changeCharacterData(characterData)
  end
  
  def changeCharacterData(characterData)
    changeSaveData(@saveFiles['characters']) do |saveData|
      logging("changeCharacterData called")
      
      characters = getCharactersFromSaveData(saveData)
      
      index = nil
      characters.each_with_index  do |item, targetIndex|
        if(item['imgId'] == characterData['imgId'])
          index = targetIndex
          break;
        end
      end
      
      if( index.nil? )
        logging("invalid character name")
        return
      end
      
      unless( characterData['name'].nil? or characterData['name'].empty? )
        alreadyExist = characters.find do |character|
          ( (character['name'] == characterData['name']) and
              (character['imgId'] != characterData['imgId']) )
        end
        
        if( alreadyExist ) 
          logging("same name character alread exist");
          return;
        end
      end
      
      logging(characterData, "character data change")
      characters[index] = characterData
    end
  end
  
  def getCardType
    "Card"
  end
  
  def getCardMountType
    "CardMount"
  end
  
  def getRandomDungeonCardMountType
    "RandomDungeonCardMount";
  end
  
  def getCardTrushMountType
    "CardTrushMount"
  end
  
  def getRandomDungeonCardTrushMountType
    "RandomDungeonCardTrushMount"
  end
  
  def getRotation(isUpDown)
    rotation = 0
    
    if( isUpDown )
      if( rand(2) == 0 )
        rotation = 180
      end
    end
    
    return rotation
  end
  
  def getCardData(isText, imageName, imageNameBack, mountName, isUpDown = false, canDelete = false, canRewrite = false)
    
    cardData = {
      "imageName" => imageName,
      "imageNameBack" => imageNameBack,
      "isBack" => true,
      "rotation" => getRotation(isUpDown),
      "isUpDown" => isUpDown,
      "isText" => isText,
      "isOpen" => false,
      "owner" => "",
      "ownerName" => "",
      "mountName" => mountName,
      "canDelete" => canDelete,
      "canRewrite" => canRewrite,
      
      "name" => "",
      "imgId" =>  createCharacterImgId(),
      "type" => getCardType(),
      "x" => 0,
      "y" => 0,
      "draggable" => true,
    }
    
    return cardData
  end
  


  def addCardZone()
    logging("addCardZone Begin");
    
    data = getParamsFromRequestData()
    
    x = data['x']
    y = data['y']
    owner = data['owner']
    ownerName = data['ownerName']
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      characters = getCharactersFromSaveData(saveData)
      logging(characters, "addCardZone characters")
      
      cardData = getCardZoneData(owner, ownerName, x, y)
      characters << cardData
    end
    
    logging("addCardZone End");
  end
  
  
  def initCards
    logging("initCards Begin");
    
    setRecordWriteEmpty
    
    clearCharacterByTypeLocal(getCardType)
    clearCharacterByTypeLocal(getCardMountType)
    clearCharacterByTypeLocal(getRandomDungeonCardMountType)
    clearCharacterByTypeLocal(getCardZoneType)
    clearCharacterByTypeLocal(getCardTrushMountType)
    clearCharacterByTypeLocal(getRandomDungeonCardTrushMountType)
    
    
    params = getParamsFromRequestData()
    cardTypeInfos = params['cardTypeInfos']
    logging(cardTypeInfos, "cardTypeInfos")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      saveData['cardTrushMount'] = {}
      
      saveData['cardMount'] = {}
      cardMounts = saveData['cardMount']
      
      characters = getCharactersFromSaveData(saveData)
      logging(characters, "initCards saveData.characters")
      
      cardTypeInfos.each_with_index do |cardTypeInfo, index|
        mountName = cardTypeInfo['mountName']
        logging(mountName, "initCards mountName")
        
        cardMount, cardMountData, cardTrushMountData = getInitCardMountInfos(cardTypeInfo, mountName, index)
        
        cardMounts[mountName] = cardMount
        characters << cardMountData
        characters << cardTrushMountData
      end
      
      waitForRefresh = 0.2
      sleep( waitForRefresh )
    end
    
    logging("initCards End");
    
    cardExist = (not cardTypeInfos.empty?)
    return {"result" => "OK", "cardExist" => cardExist }
  end
  
  
  def getInitCardMountInfos(cardTypeInfo, mountName, index)
    cardData, imageNameBack, cardsList = getCardsDataFromMountName(mountName)
    
    isText = cardData.include?("text")
    isUpDown = cardData.include?("upDown")
    
    cardsList, isSorted = getInitCardSet(cardsList, cardTypeInfo)
    cardMount = getInitedCardMount(cardsList, mountName, isText, isUpDown, imageNameBack, isSorted)
    
    cardMountData = createCardMountData(cardMount, isText, imageNameBack, mountName, index, isUpDown, cardTypeInfo, cardsList)
    cardTrushMountData = getCardTrushMountData(isText, mountName, index, cardTypeInfo)
    
    return cardMount, cardMountData, cardTrushMountData
  end
  
  def getCardsDataFromMountName(mountName)
    cardsListFileName = getCardsInfo.getCardFileName(mountName);
    logging(cardsListFileName, "initCards cardsListFileName");
    
    cardsList = []
    readLines(cardsListFileName).each_with_index  do |i, lineIndex|
      cardsList << i.chomp.toutf8
    end
    
    logging(cardsList, "initCards cardsList")
    
    cardData = cardsList.shift.split(/,/)
    imageNameBack = cardsList.shift
    
    return cardData, imageNameBack, cardsList
  end
  
  def getInitedCardMount(cardsList, mountName, isText, isUpDown, imageNameBack, isSorted)
    cardMount = []
    
    cardsList.each do |imageName|
      if( /^###Back###(.+)/ === imageName  )
        imageNameBack = $1
        next
      end
      
      logging(imageName, "initCards imageName")
      cardData = getCardData(isText, imageName, imageNameBack, mountName, isUpDown)
      cardMount << cardData
    end
    
    if( isSorted )
      cardMount = cardMount.reverse
    else
      cardMount = cardMount.sort_by{rand}
    end
    
    return cardMount
  end
  
  
  def addCard()
    logging("addCard begin");
    
    addCardData = getParamsFromRequestData()
    
    isText = addCardData['isText']
    imageName = addCardData['imageName']
    imageNameBack = addCardData['imageNameBack']
    mountName = addCardData['mountName']
    isUpDown = addCardData['isUpDown']
    canDelete = addCardData['canDelete']
    canRewrite = addCardData['canRewrite']
    isOpen = addCardData['isOpen']
    isBack = addCardData['isBack']
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardData = getCardData(isText, imageName, imageNameBack, mountName, isUpDown, canDelete, canRewrite)
      cardData["x"] = addCardData['x']
      cardData["y"] = addCardData['y']
      cardData["isOpen"] = isOpen unless( isOpen.nil? )
      cardData["isBack"] = isBack unless( isBack.nil? )
      
      characters = getCharactersFromSaveData(saveData)
      characters << cardData
    end
    
    logging("addCard end");
    
  end
  
  #トランプのジョーカー枚数、使用デッキ数の指定
  def getInitCardSet(cardsList, cardTypeInfo)
    if( isRandomDungeonTrump(cardTypeInfo) )
      cardsListTmp = getInitCardSetForRandomDungenTrump(cardsList, cardTypeInfo)
      return cardsListTmp, true
    end
    
    useLineCount = cardTypeInfo['useLineCount']
    useLineCount ||= cardsList.size
    logging(useLineCount, 'useLineCount')
    
    deckCount = cardTypeInfo['deckCount']
    deckCount ||= 1
    logging(deckCount, 'deckCount')
    
    cardsListTmp = []
    deckCount.to_i.times do
      cardsListTmp += cardsList[0...useLineCount]
    end
    
    return cardsListTmp, false
  end
  
  def getInitCardSetForRandomDungenTrump(cardList, cardTypeInfo)
    logging("getInitCardSetForRandomDungenTrump start")
    
    logging(cardList.length, "cardList.length")
    logging(cardTypeInfo, "cardTypeInfo")
    
    useCount = cardTypeInfo['cardCount']
    jorkerCount = cardTypeInfo['jorkerCount']
    
    useLineCount = 13 * 4 + jorkerCount
    cardList = cardList[0...useLineCount]
    logging(cardList.length, "cardList.length")
    
    aceList = []
    noAceList = []
    
    cardList.each_with_index do |card, index|
      if( (index % 13) == 0 )
        if( aceList.length < 4 )
          aceList << card
          next
        end
      end
      
      noAceList << card
    end
    
    logging(aceList, "aceList");
    logging(aceList.length, "aceList.length");
    logging(noAceList.length, "noAceList.length");
    
    cardTypeInfo['aceList'] = aceList.clone
    
    result = []
    
    aceList = aceList.sort_by{rand}
    result << aceList.shift
    logging(aceList, "aceList shifted");
    logging(result, "result");
    
    noAceList = noAceList.sort_by{rand}
    
    while( result.length < useCount )
      result << noAceList.shift
      break if( noAceList.length <= 0 )
    end
    
    result = result.sort_by{rand}
    logging(result, "result.sorted");
    logging(noAceList, "noAceList is empty? please check");
    
    while(aceList.length > 0)
      result << aceList.shift
    end
    
    while(noAceList.length > 0)
      result << noAceList.shift
    end
    
    logging(result, "getInitCardSetForRandomDungenTrump end, result")
    
    return result
  end
  
  
  def getCardZoneType
    "CardZone"
  end
  
  def getCardZoneData(owner, ownerName, x, y)
    # cardMount, isText, imageNameBack, mountName, index, isUpDown)
    isText = true
    cardText = ""
    cardMountData = getCardData(isText, cardText, cardText, "noneMountName")
    
    cardMountData['type'] = getCardZoneType
    cardMountData['owner'] = owner
    cardMountData['ownerName'] = ownerName
    cardMountData['x'] = x
    cardMountData['y'] = y
    
    return cardMountData
  end
  
  
  def createCardMountData(cardMount, isText, imageNameBack, mountName, index, isUpDown, cardTypeInfo, cards)
    cardMountData = getCardData(isText, imageNameBack, imageNameBack, mountName)
    
    cardMountData['type'] = getCardMountType
    setCardCountAndBackImage(cardMountData, cardMount);
    cardMountData['mountName'] = mountName
    cardMountData['isUpDown'] = isUpDown
    cardMountData['x'] = getInitCardMountX(index)
    cardMountData['y'] = getInitCardMountY(0)
    
    unless( cards.first.nil? )
      cardMountData['nextCardId'] = cards.first['imgId']
    end
    
    if( isRandomDungeonTrump(cardTypeInfo) )
      cardCount = cardTypeInfo['cardCount']
      cardMountData['type'] = getRandomDungeonCardMountType
      cardMountData['cardCountDisplayDiff'] = cards.length - cardCount
      cardMountData['useCount'] = cardCount
      cardMountData['aceList'] = cardTypeInfo['aceList']
    end
    
    return cardMountData
  end
  
  def getInitCardMountX(index)
    (50 + index * 150)
  end
  
  def getInitCardMountY(index)
    (50 + index * 200)
  end
  
  def isRandomDungeonTrump(cardTypeInfo)
    ( cardTypeInfo['mountName'] == 'randomDungeonTrump' )
  end
  
  def getCardTrushMountData(isText, mountName, index, cardTypeInfo)
    imageName, imageNameBack, isText = getCardTrushMountImageName(mountName)
    cardTrushMountData = getCardData(isText, imageName, imageNameBack, mountName)
    
    cardTrushMountData['type'] = getCardTrushMountTypeFromCardTypeInfo(cardTypeInfo)
    cardTrushMountData['cardCount'] = 0
    cardTrushMountData['mountName'] = mountName
    cardTrushMountData['x'] = getInitCardMountX(index)
    cardTrushMountData['y'] = getInitCardMountY( 1 )
    cardTrushMountData['isBack'] = false
    
    return cardTrushMountData
  end
  
  def setTrushMountDataCardsInfo(saveData, cardMountData, cards)
    characters = getCharactersFromSaveData(saveData)
    mountName = cardMountData['mountName']
    
    imageName, _, isText = getCardTrushMountImageName(mountName, cards)
    
    cardMountImageData = findCardMountDataByType(characters, mountName, getCardTrushMountType)
    return if( cardMountImageData.nil? )
    
    cardMountImageData['cardCount'] = cards.size
    cardMountImageData["imageName"] = imageName
    cardMountImageData["imageNameBack"] = imageName
    cardMountImageData["isText"] = isText
  end
  
  def getCardTrushMountImageName(mountName, cards = [])
    cardData = cards.last
    
    imageName = ""
    imageNameBack = ""
    isText = true
    
    if( cardData.nil? )
      cardTitle = getCardsInfo.getCardTitleName( mountName )
      
      isText = true
      imageName = "<font size=\"40\">#{cardTitle}用<br>カード捨て場</font>"
      imageNameBack = imageName
    else
      isText = cardData["isText"]
      imageName = cardData["imageName"]
      imageNameBack = cardData["imageNameBack"]
      
      if( cardData["owner"] == "nobody" )
        imageName = imageNameBack
      end
    end
    
    return imageName, imageNameBack, isText
  end
  
  def getCardTrushMountTypeFromCardTypeInfo(cardTypeInfo)
    if( isRandomDungeonTrump(cardTypeInfo) )
      return getRandomDungeonCardTrushMountType
    end
    
    return getCardTrushMountType
  end
  
  
  def returnCard
    logging("returnCard Begin");
    
    setdNoBodyCommanSender
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    logging(mountName, "mountName")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      _, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
      cardData = trushCards.pop
      logging(cardData, "cardData")
      if( cardData.nil? )
        logging("returnCard trushCards is empty. END.")
        return
      end
      
      cardData['x'] = params['x'] + 150
      cardData['y'] = params['y'] + 10
      logging('returned cardData', cardData)
      
      characters = getCharactersFromSaveData(saveData)
      characters.push( cardData )
      
      trushMountData = findCardData( characters, params['imgId'] )
      logging(trushMountData, "returnCard trushMountData")
      
      return if( trushMountData.nil?) 
      
      setTrushMountDataCardsInfo(saveData, trushMountData, trushCards)
    end
    
    logging("returnCard End");
  end
  
  def drawCard
    logging("drawCard Begin")
    
    setdNoBodyCommanSender
    
    params = getParamsFromRequestData()
    logging(params, 'params')
    
    result = {
      "result" => "NG"
    }
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      count = params['count']
      cardDataList = []
      
      count.times do
        cardData = drawCardDataOne(params, saveData)
        cardDataList << cardData unless( cardData.nil? )
      end
      
      result["cardDataList"] = cardDataList
      result["result"] = "OK"
    end
    
    logging("drawCard End")
    
    return result
  end
  
  def drawCardDataOne(params, saveData)
    cardMount = getCardMountFromSaveData(saveData)
    
    mountName = params['mountName']
    cards = getCardsFromCardMount(cardMount, mountName)
    
    cardMountData = findCardMountData(saveData, params['imgId'])
    return nil if( cardMountData.nil? )
    
    cardCountDisplayDiff = cardMountData['cardCountDisplayDiff']
    unless( cardCountDisplayDiff.nil? )
      return nil if( cardCountDisplayDiff >= cards.length )
    end
    
    cardData = cards.pop
    return nil if( cardData.nil? )
    
    cardData['x'] = params['x']
    cardData['y'] = params['y']
    
    isOpen = params['isOpen']
    cardData['isOpen'] = isOpen
    cardData['isBack'] = false
    cardData['owner'] = params['owner']
    cardData['ownerName'] = params['ownerName']
    
    characters = getCharactersFromSaveData(saveData)
    characters << cardData
    
    logging(cards.size, 'cardMount[mountName].size')
    setCardCountAndBackImage(cardMountData, cards)
    
    return cardData
  end
  

  def drawTargetTrushCard
    logging("drawTargetTrushCard Begin");
    
    setdNoBodyCommanSender
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    logging(mountName, "mountName")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      _, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
      cardData = removeFromArray(trushCards) {|i| i['imgId'] === params['targetCardId']}
      logging(cardData, "cardData")
      return if( cardData.nil? )
      
      cardData['x'] = params['x']
      cardData['y'] = params['y']
      
      characters = getCharactersFromSaveData(saveData)
      characters.push( cardData )
      
      trushMountData = findCardData( characters, params['mountId'] )
      logging(trushMountData, "returnCard trushMountData")
      
      return if( trushMountData.nil?) 
      
      setTrushMountDataCardsInfo(saveData, trushMountData, trushCards)
    end
    
    logging("drawTargetTrushCard End");
    
    return {"result" => "OK"}
  end
  
  def drawTargetCard
    logging("drawTargetCard Begin")
    
    setdNoBodyCommanSender
    
    params = getParamsFromRequestData()
    logging(params, 'params')
    
    mountName = params['mountName']
    logging(mountName, 'mountName')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardMount = getCardMountFromSaveData(saveData)
      cards = getCardsFromCardMount(cardMount, mountName)
      cardData = cards.find{|i| i['imgId'] === params['targetCardId'] }
      
      if( cardData.nil? )
        logging(params['targetCardId'], "not found params['targetCardId']")
        return
      end
      
      cards.delete(cardData)
      
      cardData['x'] = params['x']
      cardData['y'] = params['y']
      
      cardData['isOpen'] = false
      cardData['isBack'] = false
      cardData['owner'] = params['owner']
      cardData['ownerName'] = params['ownerName']
      
      saveData['characters'] ||= []
      characters = getCharactersFromSaveData(saveData)
      characters << cardData
      
      cardMountData = findCardMountData(saveData, params['mountId'])
      if( cardMountData.nil?) 
        logging(params['mountId'], "not found params['mountId']")
        return
      end
      
      logging(cards.size, 'cardMount[mountName].size')
      setCardCountAndBackImage(cardMountData, cards)
    end
    
    logging("drawTargetCard End")
    
    return {"result" => "OK"}
  end
  
  def findCardMountData(saveData, mountId)
    characters = getCharactersFromSaveData(saveData)
    cardMountData = characters.find{|i| i['imgId'] === mountId }
    
    return cardMountData
  end
  
  
  def setCardCountAndBackImage(cardMountData, cards)
    cardMountData['cardCount'] = cards.size
    
    card = cards.last
    return if( card.nil? )
    
    image = card["imageNameBack"];
    return if( image.nil? ) 
    
    cardMountData["imageNameBack"] = image;
  end
  
  
  
  def returnCardToMount()
    logging("returnCardToMount Begin")
    
    setdNoBodyCommanSender
    
    params = getParamsFromRequestData()
    logging(params, 'params')
    
    mountName = params['mountName']
    logging(mountName, 'mountName')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      cardMount = getCardMountFromSaveData(saveData)
      mountCards = getCardsFromCardMount(cardMount, mountName)
      
      characters = getCharactersFromSaveData(saveData)
      
      returnCardId = params['returnCardId']
      logging( returnCardId, "returnCardId")
      
      logging(characters.size, "characters.size before")
      cardData = deleteFindOne(characters) {|i| i['imgId'] === returnCardId }
      mountCards << cardData
      logging(characters.size, "characters.size after")
      
      cardMountData = characters.find{|i| i['imgId'] === params['cardMountId'] }
      return if( cardMountData.nil?) 
      
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    logging("dumpTrushCards End")
  end
  
  
  
  def dumpTrushCards()
    logging("dumpTrushCards Begin")
    
    setdNoBodyCommanSender
    
    dumpTrushCardsData = getParamsFromRequestData()
    logging(dumpTrushCardsData, 'dumpTrushCardsData')
    
    mountName = dumpTrushCardsData['mountName']
    logging(mountName, 'mountName')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
      characters = getCharactersFromSaveData(saveData)
      
      dumpedCardId = dumpTrushCardsData['dumpedCardId']
      logging( dumpedCardId, "dumpedCardId")
      
      logging(characters.size, "characters.size before")
      cardData = deleteFindOne(characters) {|i| i['imgId'] === dumpedCardId }
      trushCards << cardData
      logging(characters.size, "characters.size after")
      
      trushMountData = characters.find{|i| i['imgId'] === dumpTrushCardsData['trushMountId'] }
      if( trushMountData.nil?) 
        return
      end
      
      logging(trushMount, 'trushMount')
      logging(mountName, 'mountName')
      logging(trushMount[mountName], 'trushMount[mountName]')
      logging(trushMount[mountName].size, 'trushMount[mountName].size')
      
      setTrushMountDataCardsInfo(saveData, trushMountData, trushCards)
    end
    
    logging("dumpTrushCards End")
  end
  
  def deleteFindOne(array)
    findIndex = nil
    array.each_with_index do |i, index|
      if( yield(i) )
        findIndex = index
      end
    end
    
    if( findIndex.nil? )
      raise "deleteFindOne target is NOT found"
    end
    
    logging(array.size, "array.size before")
    item = array.delete_at(findIndex)
    logging(array.size, "array.size before")
    return item
  end
  
  
  
  def shuffleOnlyMountCards
    logging("shuffleOnlyMountCards Begin")
    
    setRecordWriteEmpty
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    cardMountId = params['mountId']
    
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      cardMount = getCardMountFromSaveData(saveData)
      mountCards = getCardsFromCardMount(cardMount, mountName)
      
      characters = getCharactersFromSaveData(saveData)
      
      cardMountData = findCardMountDataByType(characters, mountName, getCardMountType)
      return if( cardMountData.nil?) 
      
      
      isUpDown = cardMountData['isUpDown']
      mountCards = getShuffledMount(mountCards, isUpDown)
      
      cardMount[mountName] = mountCards
      saveData['cardMount'] = cardMount
      
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    logging("shuffleOnlyMountCards End")
  end
  
  
  
  def shuffleCards
    logging("shuffleCard Begin")
    
    setRecordWriteEmpty
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    trushMountId = params['mountId']
    isShuffle = params['isShuffle']
    
    logging(mountName, 'mountName')
    logging(trushMountId, 'trushMountId')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      _, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
      cardMount = getCardMountFromSaveData(saveData)
      mountCards = getCardsFromCardMount(cardMount, mountName)
      
      while( trushCards.size > 0 )
        cardData = trushCards.pop
        initTrushCardForReturnMount(cardData)
        mountCards << cardData
      end
      
      characters = getCharactersFromSaveData(saveData)
      
      trushMountData = findCardData( characters, trushMountId )
      return if( trushMountData.nil?) 
      setTrushMountDataCardsInfo(saveData, trushMountData, trushCards)
      
      cardMountData = findCardMountDataByType(characters, mountName, getCardMountType)
      return if( cardMountData.nil?) 
      
      if( isShuffle )
        isUpDown = cardMountData['isUpDown']
        mountCards = getShuffledMount(mountCards, isUpDown)
      end
      
      cardMount[mountName] = mountCards
      saveData['cardMount'] = cardMount
      
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    logging("shuffleCard End")
  end
  
  
  def shuffleForNextRandomDungeon
    logging("shuffleForNextRandomDungeon Begin")
    
    setRecordWriteEmpty
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    trushMountId = params['mountId']
    
    logging(mountName, 'mountName')
    logging(trushMountId, 'trushMountId')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      _, trushCards = findTrushMountAndTrushCards(saveData, mountName) 
      logging(trushCards.length, "trushCards.length")
     
      saveData['cardMount'] ||= {}
      cardMount = saveData['cardMount']
      cardMount[mountName] ||= []
      mountCards = cardMount[mountName]
      
      characters = getCharactersFromSaveData(saveData)
      cardMountData = findCardMountDataByType(characters, mountName, getRandomDungeonCardMountType)
      return if( cardMountData.nil?) 
      
      aceList = cardMountData['aceList']
      logging(aceList, "aceList")
      
      aceCards = []
      aceCards += deleteAceFromCards(trushCards, aceList)
      aceCards += deleteAceFromCards(mountCards, aceList)
      aceCards += deleteAceFromCards(characters, aceList)
      aceCards = aceCards.sort_by{rand}
      
      logging(aceCards, "aceCards")
      logging(trushCards.length, "trushCards.length")
      logging(mountCards.length, "mountCards.length")
      
      useCount = cardMountData['useCount']
      if( (mountCards.size + 1) < useCount )
        useCount = (mountCards.size + 1)
      end
      
      mountCards = mountCards.sort_by{rand}
      
      insertPoint = rand(useCount)
      logging(insertPoint, "insertPoint")
      mountCards[insertPoint, 0] = aceCards.shift
      
      while( aceCards.length > 0 )
        mountCards[useCount, 0] = aceCards.shift
        logging(useCount, "useCount")
      end
      
      mountCards = mountCards.reverse
      
      cardMount[mountName] = mountCards
      saveData['cardMount'] = cardMount
      
      newDiff = mountCards.size - useCount
      newDiff = 3 if( newDiff < 3 )
      logging(newDiff, "newDiff")
      cardMountData['cardCountDisplayDiff'] = newDiff
      
      
      trushMountData = findCardData( characters, trushMountId )
      return if( trushMountData.nil?) 
      setTrushMountDataCardsInfo(saveData, trushMountData, trushCards)
      
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    logging("shuffleForNextRandomDungeon End")
  end
  
  def deleteAceFromCards(cards, aceList)
    result = cards.select {|i| aceList.include?( i['imageName']) }
    cards.delete_if{|i| aceList.include?( i['imageName']) }
    
    return result
  end
  
  def findCardData(characters, cardId)
    cardData = characters.find{|i| i['imgId'] === cardId }
    return cardData
  end
  
  def findCardMountDataByType(characters, mountName, cardMountType)
    cardMountData = characters.find do |i| 
      ((i['type'] === cardMountType) && (i['mountName'] == mountName))
    end
    
    return cardMountData
  end
  
  def getShuffledMount(mountCards, isUpDown)
    mountCards = mountCards.sort_by{rand}
    mountCards.each do |i|
      i["rotation"] = getRotation(isUpDown)
    end
    
    return mountCards
  end
  
  def initTrushCardForReturnMount(cardData)
    cardData['isOpen'] = false
    cardData['isBack'] = true
    cardData['owner'] = ""
    cardData['ownerName'] = ""
  end
  
  
  def findTrushMountAndTrushCards(saveData, mountName)
    saveData['cardTrushMount'] ||= {}
    trushMount = saveData['cardTrushMount']
    
    trushMount[mountName] ||= []
    trushCards = trushMount[mountName]
    
    return trushMount, trushCards
  end
  
  def getMountCardInfos
    params = getParamsFromRequestData()
    logging(params, 'getTrushMountCardInfos params')
    
    mountName = params['mountName']
    mountId = params['mountId']
    
    cards = []
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardMount = getCardMountFromSaveData(saveData)
      cards = getCardsFromCardMount(cardMount, mountName)
      
      cardMountData = findCardMountData(saveData, mountId)
      cardCountDisplayDiff = cardMountData['cardCountDisplayDiff']
      
      logging(cardCountDisplayDiff, "cardCountDisplayDiff")
      logging(cards.length, "before cards.length")
      
      unless( cardCountDisplayDiff.nil? )
        unless( cards.empty? )
          cards = cards[cardCountDisplayDiff .. -1]
        end
      end
      
    end
    
    logging(cards.length, "getMountCardInfos cards.length")
    
    return cards
  end
  
  def getTrushMountCardInfos
    params = getParamsFromRequestData()
    logging(params, 'getTrushMountCardInfos params')
    
    mountName = params['mountName']
    
    cards = []
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      _, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      cards = trushCards
    end
    
    return cards
  end
  
  
  def getCardList
    params = getParamsFromRequestData()
    logging(params, 'getCardList params')
    
    mountName = params['mountName']
    cardTypeInfo = {'mountName' => mountName}
    index = 0
    
    cardMount, = getInitCardMountInfos(cardTypeInfo, mountName, index)
    
    logging(cardMount, 'cardMount')
    
    return cardMount
  end
  
  
  def clearCharacterByType()
    logging("clearCharacterByType Begin")
    
    setRecordWriteEmpty
    
    clearData = getParamsFromRequestData()
    logging(clearData, 'clearData')
    
    targetTypes = clearData['types']
    logging(targetTypes, 'targetTypes')
    
    targetTypes.each do |targetType|
      clearCharacterByTypeLocal(targetType)
    end
    
    logging("clearCharacterByType End")
  end
  
  def clearCharacterByTypeLocal(targetType)
    logging(targetType, "clearCharacterByTypeLocal targetType")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      characters = getCharactersFromSaveData(saveData)
      
      characters.delete_if do |i|
        (i['type'] == targetType)
      end
    end
    
    logging("clearCharacterByTypeLocal End")
  end
  
  
  def removeCharacter()
    removeCharacterDataList = getParamsFromRequestData()
    removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
  end
  
  
  def removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
    logging(removeCharacterDataList, "removeCharacterDataList")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      characters = getCharactersFromSaveData(saveData)
      
      removeCharacterDataList.each do |removeCharacterData|
        logging(removeCharacterData, "removeCharacterData")
        
        removeCharacterId = removeCharacterData['imgId']
        logging(removeCharacterId, "removeCharacterId")
        isGotoGraveyard = removeCharacterData['isGotoGraveyard']
        logging(isGotoGraveyard, "isGotoGraveyard")
        
        characters.delete_if do |i|
          deleted = (i['imgId'] == removeCharacterId)
          
          if( deleted and isGotoGraveyard )
            moveCharacterToGraveyard(i, saveData)
          end
          
          deleted
        end
      end
      
      logging(characters, "character deleted result")
    end
  end
  
  def moveCharacterToGraveyard(character, saveData)
    saveData['graveyard'] ||= []
    graveyard = saveData['graveyard']
    
    graveyard << character
    
    while(graveyard.size > $graveyardLimit)
      graveyard.shift
    end
  end
  

  def enterWaitingRoomCharacter
    
    setRecordWriteEmpty
    
    params = getParamsFromRequestData()
    characterId = params['characterId']
    index = params['index']
    
    logging(characterId, "enterWaitingRoomCharacter characterId")
    
    result = {"result" => "NG"}
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      characters = getCharactersFromSaveData(saveData)
      waitingRoom = getWaitinigRoomFromSaveData(saveData)
      
      target = removeFromArray(characters) {|i| (i['imgId'] == characterId) }
      
      #待合室内をソートしている場合はこちらが適用されます
      target ||= removeFromArray(waitingRoom) {|i| (i['imgId'] == characterId) }
      
      return result if( target.nil? )
      
      addWaitingRoom(waitingRoom, target, index)
    end
    
    return getWaitingRoomInfo()
  end
  
  def addWaitingRoom(waitingRoom, target, index)
    logging(index, "index")
    
    if (index >= 0) and (waitingRoom.length > index)
      logging("waitingRoom insert!")
      waitingRoom.insert(index, target)
    else
      logging("waitingRoom << only")
      waitingRoom << target
    end
  end
  
  
  
  def resurrectCharacter
    params = getParamsFromRequestData()
    resurrectCharacterId = params['imgId']
    logging(resurrectCharacterId, "resurrectCharacterId")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      graveyard = getGraveyardFromSaveData(saveData)
      
      characterData = removeFromArray(graveyard) do |character|
        character['imgId'] == resurrectCharacterId
      end
      
      logging(characterData, "resurrectCharacter CharacterData");
      return if( characterData.nil? )
      
      characters = getCharactersFromSaveData(saveData)
      characters << characterData
    end
    
    return nil
  end
  
  def clearGraveyard
    logging("clearGraveyard begin")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      graveyard = getGraveyardFromSaveData(saveData)
      graveyard.clear
    end
    
    return nil
  end
  
  
  def getGraveyardFromSaveData(saveData)
    return getArrayInfoFromHash(saveData, 'graveyard')
  end
  
  def getWaitinigRoomFromSaveData(saveData)
    return getArrayInfoFromHash(saveData, 'waitingRoom')
  end
  
  def getCharactersFromSaveData(saveData)
    return getArrayInfoFromHash(saveData, 'characters')
  end
  
  def getCardsFromCardMount(cardMount, mountName)
    return getArrayInfoFromHash(cardMount, mountName)
  end
  
  def getResourceFromSaveData(saveData)
    return getArrayInfoFromHash(saveData, 'resource')
  end
  
  
  def getArrayInfoFromHash(hash, key)
    hash[key] ||= []
    return hash[key]
  end
  
  
  def getCardMountFromSaveData(saveData)
    return getHashInfoFromHash(saveData, 'cardMount')
  end
  
  def getRoundTimeDataFromSaveData(saveData)
    return getHashInfoFromHash(saveData, 'roundTimeData')
  end
  
  
  def getHashInfoFromHash(hash, key)
    hash[key] ||= {}
    return hash[key]
  end
  
  
  
  def exitWaitingRoomCharacter
    
    setRecordWriteEmpty
    
    params = getParamsFromRequestData()
    targetCharacterId = params['characterId']
    x = params['x']
    y = params['y']
    logging(targetCharacterId, 'exitWaitingRoomCharacter targetCharacterId')
    
    result = {"result" => "NG"}
    changeSaveData(@saveFiles['characters']) do |saveData|
      waitingRoom = getWaitinigRoomFromSaveData(saveData)
      
      characterData = removeFromArray(waitingRoom) do |character|
        character['imgId'] == targetCharacterId
      end
      
      logging(characterData, "exitWaitingRoomCharacter CharacterData");
      return result if( characterData.nil? )
      
      characterData['x'] = x
      characterData['y'] = y
      
      characters = getCharactersFromSaveData(saveData)
      characters << characterData
    end
    
    result["result"] = "OK"
    return result
  end
  
  
  def removeFromArray(array)
    index = nil
    
    array.each_with_index do |i, targetIndex|
      logging(i, "i")
      logging(targetIndex, "targetIndex")
      b = yield(i)
      logging(b, "yield(i)")
      if( b )
        index = targetIndex
        break
      end
    end
    
    return nil if( index.nil? )
    
    item = array.delete_at(index)
    return item
  end
  
  
  def changeRoundTime
    roundTimeData = getParamsFromRequestData()
    changeInitiativeData(roundTimeData)
  end
  
  def changeInitiativeData(roundTimeData)
    changeSaveData(@saveFiles['time']) do |saveData|
      
      #要素に日本語を入れないと一部中国語(装甲の中国語表記)で文字化けするためダーティーハック。
      #原因は不明。調査挫折。
      saveData['_'] = 'あ'
      
      saveData['roundTimeData'] = roundTimeData
    end
  end
  
  
  
  def addResource()
    params = getParamsFromRequestData()
    
    changeSaveData(@saveFiles['time']) do |saveData|
      resource = getResourceFromSaveData(saveData)
      
      params['resourceId'] = createCharacterImgId("resource_")
      resource << params
    end
  end
  
  def changeResource()
    params = getParamsFromRequestData()
    
    editResource(params) do |resource, index|
      resource[index] = params
    end
  end
  
  def changeResourcesAll()
    params = getParamsFromRequestData()
    changeResourcesAllByParam(params)
  end
  
  def changeResourcesAllByParam(params)
    return if( params.nil? )
    return if( params.empty? )
    
    changeSaveData(@saveFiles['time']) do |saveData|
      resource = getResourceFromSaveData(saveData)
      
      resource.clear
      
      params.each do |param|
        resource << param
      end
      
    end
  end
  
  def removeResource()
    params = getParamsFromRequestData()
    
    editResource(params) do |resource, index|
      resource.delete_at(index)
    end
  end
  
  
  def editResource(params)
    changeSaveData(@saveFiles['time']) do |saveData|
      resource = getResourceFromSaveData(saveData)
      
      resourceId = params['resourceId']
      
      index = findIndexFromArray(resource) do |i|
        i['resourceId'] == resourceId
      end
      
      if( index.nil? )
        return
      end
      
      yield(resource, index)
    end
  end
  
  
  def findIndexFromArray(array)
    array.each_with_index  do |item, index|
      if( yield(item) )
        return index
      end
    end
    
    return nil
  end
  
  
  
  def moveCharacter()
    changeSaveData(@saveFiles['characters']) do |saveData|

      characterMoveData = getParamsFromRequestData()
      logging(characterMoveData, "moveCharacter() characterMoveData")
      
      logging(characterMoveData['imgId'], "character.imgId")
      
      characters = getCharactersFromSaveData(saveData)
      
      characters.each do |characterData|
        next unless( characterData['imgId'] == characterMoveData['imgId'] )
        
        characterData['x'] = characterMoveData['x']
        characterData['y'] = characterMoveData['y']
        
        break
      end
      
      logging(characters, "after moved characters")
      
    end
  end
  
  #override
  def getSaveFileTimeStamp(saveFileName)
    unless( isExist?(saveFileName) ) 
      return 0
    end
    
    timeStamp = File.mtime(saveFileName).to_f
    return timeStamp
  end
  
  def getSaveFileTimeStampMillSecond(saveFileName)
    (getSaveFileTimeStamp(saveFileName) * 1000).to_i
  end
  
  def isSaveFileChanged(lastUpdateTime, saveFileName)
    lastUpdateTime = lastUpdateTime.to_i
    saveFileTimeStamp = getSaveFileTimeStampMillSecond(saveFileName);
    changed = (saveFileTimeStamp != lastUpdateTime)
    
    logging(saveFileName, "saveFileName")
    logging(saveFileTimeStamp, "saveFileTimeStamp")
    logging(lastUpdateTime,    "lastUpdateTime   ")
    logging(changed, "changed")
    
    return changed
  end
  
  def getResponse
    
    response = nil
    
    if( $dodontofWarning.nil? )
      response = analyzeCommand
    else
      response = {}
      response["warning"] = $dodontofWarning
    end
    
    if( isJsonResult )
      return getTextFromJsonData(response)
    else
      return getDataFromMessagePack(response)
    end
  end
  
end


def getErrorResponseText(e)
  errorMessage = ""
  errorMessage << "e.to_s : " << e.to_s << "\n"
  errorMessage << "e.inspect : " << e.inspect << "\n"
  errorMessage << "$@ : " << $@.join("\n") << "\n"
  errorMessage << "$! : " << $!.to_s << "\n"
  
  return errorMessage
end


def isGzipTarget(result, server)
  return false if( $gzipTargetSize <= 0)
  return false if( server.jsonpCallBack )
  
  return ( (/gzip/ =~ ENV["HTTP_ACCEPT_ENCODING"]) and (result.length > $gzipTargetSize) )
end

def getGzipResult(result)
  require 'zlib'
  require 'stringio'
  
  stringIo = StringIO.new
  Zlib::GzipWriter.wrap(stringIo) do |gz|
    gz.write(result)
    gz.flush
    gz.finish
  end
  
  gzipResult = stringIo.string
  logging(gzipResult.length.to_s, "CGI response zipped length  ")
  
  return gzipResult
end


def main(cgiParams)
  logging("main called")
  server = DodontoFServer.new(SaveDirInfo.new(), cgiParams)
  logging("server created")
  printResult(server)
  logging("printResult called")
end

def getInitializedHeaderText(server)
  header = ""
  
  if( $isModRuby )
    #Apache::request.content_type = "text/plain; charset=utf-8"
    #Apache::request.send_header
  else
    if( server.isJsonResult )
      header = "Content-Type: text/plain; charset=utf-8\n"
    else
      header = "Content-Type: application/x-msgpack; charset=x-user-defined\n"
    end
  end
  
  return header
end

def printResult(server)
  logging("========================================>CGI begin.")
  
  text = "empty"
  
  header = getInitializedHeaderText(server)
  
  begin
    result = server.getResponse
    
    if( server.isAddMarker )
      result = "#D@EM>#" + result + "#<D@EM#";
    end
    
    if( server.jsonpCallBack )
      result = "#{server.jsonpCallBack}(" + result + ");";
    end
    
    logging(result.length.to_s, "CGI response original length")
    
    if ( isGzipTarget(result, server) )
      if( $isModRuby )
        Apache.request.content_encoding = 'gzip'
      else
        header << "Content-Encoding: gzip\n"
        
        if( server.jsonpCallBack )
          header << "Access-Control-Allow-Origin: *\n"
        end
      end
      
      text = getGzipResult(result)
    else
      text = result
    end
  rescue Exception => e
    errorMessage = getErrorResponseText(e)
    loggingForce(errorMessage, "errorMessage")
    
    text = "\n= ERROR ====================\n"
    text << errorMessage
    text << "============================\n"
  end
  
  logging(header, "RESPONSE header")
  
  output = $stdout
  output.binmode if( defined?(output.binmode) )
  
  output.print( header + "\n")
  
  output.print( text )
  
  logging("========================================>CGI end.")
end


def getCgiParams()
  logging("getCgiParams Begin")

  logging(ENV['REQUEST_METHOD'], "ENV[REQUEST_METHOD]")
  input = nil
  messagePackedData = {}
  if( ENV['REQUEST_METHOD'] == "POST" )
    length = ENV['CONTENT_LENGTH'].to_i
    logging(length, "getCgiParams length")

    input = $stdin.read(length)
    logging(input, "getCgiParams input")
    messagePackedData = DodontoFServer.getMessagePackFromData( input )
  end

  logging(messagePackedData, "messagePackedData")
  logging("getCgiParams End")
  
  return messagePackedData
end


def executeDodontoServerCgi()
  initLog();
  
  cgiParams = getCgiParams()
  
  case $dbType
  when "mysql"
    #mod_ruby でも再読み込みするようにloadに
    require 'DodontoFServerMySql.rb'
    mainMySql(cgiParams)
  else
    #通常のテキストファイル形式
    main(cgiParams)
  end
  
end
  
if( $0 === __FILE__ )
  executeDodontoServerCgi()
end

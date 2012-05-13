#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
$LOAD_PATH << File.dirname(__FILE__) + "/src_bcdice"

#CGI通信の主幹クラス用ファイル
#ファイルアップロード系以外は全てこのファイルへ通知が送られます。
#クライアント通知されたJsonデータからセーブデータ(.jsonテキスト)を読み出し・書き出しするのが主な作業。
#変更可能な設定は config.rb にまとめているため、環境設定のためにこのファイルを変更する必要は基本的には無いです。




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
require 'tempfile'
require 'json/jsonParser'

if( $isFirstCgi )
  require 'cgiPatch_forFirstCgi'
end

require "config.rb"

require "loggingFunction.rb"
require "FileLock.rb"
# require "FileLock2.rb"
require "saveDirInfo.rb"
require "card.rb"

$card = Card.new();



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


class DodontoFServer
  
  def getRequestData(key)
    logging(key, "getRequestData key")
    
    content_type = @content_type
    logging(content_type, "@cgi.content_type")
    
    #if( content_type == 'application/octet-stream')
    if( %r|^multipart/form-data| === content_type )
      logging("content_type is fileUploader")
      return getRequestDataForFileUploader(key)
    end
    
    logging("content_type is NOT fileUploader")
    value = @cgi[key]
    
    return value
  end

  def getRequestDataJsonData(key)
    jsonData = getRequestData(key)
    return getJsonDataFromText(jsonData)
  end
  
  def getStringFromStringOrStringIoOrFile(input)
    logging(input, 'input')
    logging(input.class, 'input.class')
    
    if( input.instance_of?( StringIO ) )
      return input.string
    end
    
    if( input.instance_of?( File ) or input.instance_of?( Tempfile ) )
      output = input.readlines().join
      logging(output, "getStringFromStringOrStringIoOrFile output")
      result = URI.unescape(output)
      logging(result, "getStringFromStringOrStringIoOrFile result")
      return result
    end
    
    return input
  end
  
  def setCgiParams
    @cgiParams ||= @cgi.params
  end
  
  def getRequestDataForFileUploader(key)
    logging(key, "getRequestDataForFileUploader key")
    
    setCgiParams
    logging(@cgiParams, "SaveFileUploader cgi.params")
    
    if( @cgiParams.include?(key) )
      value = @cgi[key]
      return value if( key == 'Filedata' )
      
      return getStringFromStringOrStringIoOrFile(value)
    end
    
    @jsonDataForFileUploader ||= getJsonDataForFileUploader
    logging(@jsonDataForFileUploader, "@jsonDataForFileUploader")
    
    return @jsonDataForFileUploader[key]
  end
  
  def getJsonDataForFileUploader
    logging("get @cgi['__jsonDataForFileUploader__']");
    jsonDataIo = @cgi['__jsonDataForFileUploader__']
    logging(jsonDataIo, "jsonDataIo");
    
    jsonDataString = getStringFromStringOrStringIoOrFile(jsonDataIo)
    logging(jsonDataString, "jsonDataString in getRequestData")
    
    logging("getJsonDataFromText(jsonDataString)")
    jsonDataForFileUploader = getJsonDataFromText(jsonDataString)
    logging(jsonDataForFileUploader, "jsonDataForFileUploader");
    
    return jsonDataForFileUploader
  end
  
  def initialize(saveDirInfo, cgi, content_type)
    @cgi = cgi
    @content_type = content_type
    @saveDirInfo = saveDirInfo
    
    initSaveFiles( getRequestData("saveDataDirIndex") )
    
    @isAddMarker = true
    @jsonpCallBack = nil
    @isRecordEmpty = false
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
  
  attr :isAddMarker
  attr :jsonpCallBack
  
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
      loggingForce(@saveDirInfo.inspect, "when getSaveFileLock error : @saveDirInfo.inspect");
      raise
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
    lines = File.readlines(fileName)
  end
  
  def loadSaveFileForLongChatLog(typeName, saveFileName)
    saveFileName = @saveDirInfo.getTrueSaveFileName($chatMessageDataLogAll)
    saveFileLock = getSaveFileLockReadOnly(saveFileName)
    
    lines = []
    saveFileLock.lock do
      if( isExist?(saveFileName) )
        lines = readLines(saveFileName)
      end
      
      @lastUpdateTimes[typeName] = getSaveFileTimeStamp(saveFileName);
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
      elsif( isCharacterType(typeName) )
        logging("isCharacterType")
        saveData = loadSaveFileForCharacter(typeName, saveFileName)
      else
        saveData = loadSaveFileForDefault(typeName, saveFileName)
      end 
    rescue => e
      loggingException(e)
      raise e
    end
    
    logging(saveData.inspect, saveFileName)
    
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
    
    characterUpdateTime = getSaveFileTimeStamp(saveFileName);
    
    #後の操作順序に依存せずRecord情報が取得できるよう、ここでRecordをキャッシュしておく。
    #こうしないとRecordを取得する順序でセーブデータと整合性が崩れる場合があるため
    getRecordCash
    
    saveData = getRecordSaveDataFromCash()
    logging(saveData, "getRecordSaveDataFromCash saveData")
    
    if( saveData.nil? )
      saveData = loadSaveFileForDefault(typeName, saveFileName)
    else
      @lastUpdateTimes[typeName] = characterUpdateTime
    end
    
    @lastUpdateTimes['recordIndex'] = getLastRecordIndexFromCash
    
    logging(@lastUpdateTimes, "loadSaveFileForCharacter End @lastUpdateTimes")
    logging(saveData, "loadSaveFileForCharacter End saveData")
    
    return saveData
  end
  
  #自分が送ったコマンドであっても結果を取得したい場合にはここに記載する
  @@recordCommandsByForce = ['addCharacter']
  
  def getRecordSaveDataFromCash()
    recordIndex = @lastUpdateTimes['recordIndex']
    
    logging("getRecordSaveDataFromCash begin")
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
      index, command, list, sender = params
      
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
    
    #キャラクター追加なんかのコマンドは字自分のコマンドでも送信しないとダメなんだよね
    return true if( @@recordCommandsByForce.include?(command) )
    
    #基本、自分が送ったコマンドは受け取りたくないんだけどね
    return false if( currentSender == sender )
    
    return true
  end
  
  def getLastRecordIndexFromCash
    recordIndex = 0
    
    record = getRecordCash
    
    last = record.last
    unless( last.nil? )
      recordIndex = last[0]
    end
    
    logging(recordIndex, "getLastRecordIndexFromCash recordIndex")
    
    return recordIndex
  end
  
  def getRecordCash
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
      @lastUpdateTimes[typeName] = getSaveFileTimeStamp(saveFileName);
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
      @commandSender = getRequestData('commandSender')
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
    commandName = getRequestData('Command')
    
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
      ['saveScenario', hasReturn], 
      ['load', hasReturn], 
      ['loadScenario', hasReturn], 
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
      ['uploadImageFile', hasReturn], 
      ['uploadImageData', hasReturn], 
      ['createPlayRoom', hasReturn], 
      ['changePlayRoom', hasReturn], 
      ['removePlayRoom', hasReturn], 
      ['getImageTagsAndImageList', hasReturn], 
      ['addCharacter', hasReturn],
      ['getWaitingRoomInfo', hasReturn], 
      ['exitWaitingRoomCharacter', hasReturn],
      ['enterWaitingRoomCharacter', hasReturn], 
      ['sendDiceBotChatMessage', hasReturn],
      
      ['logout', hasNoReturn], 
      ['changeCharacter', hasNoReturn],
      ['removeCharacter', hasNoReturn],
      
      # Card Command Get
      ['getMountCardInfos', hasReturn],
      ['getTrushMountCardInfos', hasReturn],
      
      # Card Command Set
      ['drawTargetCard', hasReturn],
      ['drawTargetTrushCard', hasReturn],
      ['drawCard', hasReturn],
      ['addCard', hasNoReturn],
      ['addCardZone', hasNoReturn],
      ['initCards', hasReturn],
      ['returnCard', hasNoReturn],
      ['shuffleCards', hasNoReturn],
      ['shuffleForNextRandomDungeon', hasNoReturn],
      ['dumpTrushCards', hasNoReturn],
      
      ['clearCharacterByType', hasNoReturn],
      ['moveCharacter', hasNoReturn],
      ['changeMap', hasNoReturn],
      ['sendChatMessage', hasNoReturn],
      ['sendChatMessageMany', hasNoReturn],
      ['changeRoundTime', hasNoReturn],
      ['addEffect', hasNoReturn], 
      ['changeEffect', hasNoReturn], 
      ['removeEffect', hasNoReturn], 
      ['changeImageTags', hasNoReturn], 
    ]
    
    commands.each do |command, commandType|
      next unless( command == commandName )
      logging(command, "command")
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
      logging("analyzeWebInterfaceCatched end result", result)
      setJsonpCallBack
    rescue => e
      result['result'] = e.to_s
    end
    
    return result
  end
  
  def analyzeWebInterfaceCatched
    logging("analyzeWebInterfaceCatched begin")
    
    commandName = getRequestData('webif')
    logging('commandName', commandName)
    if( isInvalidRequestParam(commandName) )
      return nil
    end
    
    marker = getRequestData('marker')
    if( isInvalidRequestParam(marker) )
      @isAddMarker = false
    end
    
    case commandName
    when 'getBusyInfo'
      return getBusyInfo
    end
    
    loginWebInterface
    
    case commandName
    when 'chat'
      return getWebIfChatText
    when 'talk'
      return sendWebIfChatText
    when 'addCharacter'
      return sendWebIfAddCharacter
    when 'changeCharacter'
      return sendWebIfChangeCharacter
    when 'addMemo'
      return sendWebIfAddMemo
    when 'getRoomInfo'
      return getWebIfRoomInfo
    when 'setRoomInfo'
      return setWebIfRoomInfo
    when 'getChatColor'
      return getChatColor
    end
    
    return {'result'=> "command [#{commandName}] is NOT found"}
  end
  
  
  def loginWebInterface
    roomNumberText = getRequestData('room')
    if( isInvalidRequestParam(roomNumberText) )
      raise "プレイルーム番号(room)を指定してください"
    end
    
    unless( /^\d+$/ === roomNumberText )
      raise "プレイルーム番号(room)には半角数字のみを指定してください"
    end
    
    roomNumber = roomNumberText.to_i
    
    password = getRequestData('password')
    visiterMode = true
    
    checkResult = checkLoginPassword(roomNumber, password, visiterMode)
    if( checkResult['resultText'] != "OK" )
      result['result'] = result['resultText']
      return result
    end
    
    initSaveFiles(roomNumber)
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
    "「どどんとふ」の動作環境は正常に起動しています。";
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
    
    seconds = getRequestData('sec')
    saveData = getWebIfChatTextFromSecond(seconds)
    saveData['result'] = 'OK'
    
    return saveData
  end
  
  def getWebIfChatTextFromSecond(seconds)
    
    targetTime = getTargetTimeForGetWebIfChatText(seconds)
    logging(seconds, "seconds")
    logging(targetTime, "targetTime")
    
    saveData = {}
    @lastUpdateTimes = {'chatMessageDataLog' => targetTime}
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      saveData.merge!(targetSaveData)
    end
    
    logging("getCurrentSaveData end saveData", saveData)
    
    return saveData
  end
  
  
  def getTargetTimeForGetWebIfChatText(seconds)
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
      :loginCount => File.readlines($loginCountFile).join.to_i,
      :maxLoginCount => $aboutMaxLoginCount,
      :version => $version,
      :result => 'OK',
    }
    
    return jsonData
  end
  
  
  def sendWebIfChatText
    logging("sendWebIfChatText begin")
    saveData = {}
    
    name = getWebIfRequestText('name')
    logging(name, "name")
    
    message = getWebIfRequestText('message')
    logging(message, "message")
    
    color = getWebIfRequestText('color', getTalkDefaultColor)
    logging(color, "color")
    
    channel = getWebIfRequestInt('channel')
    logging(channel, "channel")
    
    gameType = getWebIfRequestText('bot')
    logging(gameType, 'gameType')
    
    rollResult, isSecret = rollDice(message, gameType)
    message = message + rollResult
    logging(message, "diceRolled message")
    
    chatData = {
      "senderName" => name,
      "message" => message,
      "color" => color,
      "uniqueId" => '0',
      "channel" => channel,
    }
    logging("sendWebIfChatText chatData", chatData)
    
    sendChatMessageByChatData(chatData)
    
    result = {}
    result['result'] = 'OK'
    return result
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
    addResult = addCharacterData( [jsonData] )
    
    return result
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
    
    changeSaveData(@saveFiles['time']) do |saveData|
      saveData['roundTimeData'] ||= {}
      roundTimeData = saveData['roundTimeData']
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
  
  
  def refresh
    logging("==>Begin refresh");
    
    saveData = {}
    
    if( $isMentenanceNow )
      saveData["warning"] = {"key" => "canNotRefreshBecauseMentenanceNow"}
      return saveData
    end
    
    refreshData = getParamsFromRequestData()
    
    @lastUpdateTimes = refreshData['lastUpdateTimes']
    logging(@lastUpdateTimes, "@lastUpdateTimes");
    
    isFirstChatRefresh = (@lastUpdateTimes['chatMessageDataLog'] == 0)
    logging(isFirstChatRefresh, "isFirstChatRefresh");
    
    refreshIndex = refreshData['refreshIndex'];
    logging(refreshIndex, "refreshIndex");
    
    @isGetOwnRecord = refreshData['isGetOwnRecord'];
    
    if( $isCommet )
      refreshLoop(saveData)
    else
      refreshOnce(saveData)
    end
    
    uniqueId = refreshData['uniqueId'];
    userName = refreshData['userName'];
    isVisiter = refreshData['isVisiter'];
    loginUserInfoSaveFile = @saveDirInfo.getTrueSaveFileName($loginUserInfo)
    
    loginUserInfo = updateLoginUserInfo(loginUserInfoSaveFile, userName, uniqueId, isVisiter)
    
    saveData['lastUpdateTimes'] = @lastUpdateTimes;
    saveData['refreshIndex'] = refreshIndex;
    saveData['loginUserInfo'] = loginUserInfo;
    if( isFirstChatRefresh )
      saveData['isFirstChatRefresh'] = isFirstChatRefresh
    end
    
    logging(saveData, "refresh end saveData");
    logging(loginUserInfo, "loginUserInfo");
    logging("==>End refresh");
    
    return saveData
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
  
  
  def getPlayRoomPasswordLockStates( roomNumberRange )
    passwordLockStates = {}
    roomNumberRange.each{|i| passwordLockStates[i] = false}
    logging(passwordLockStates, 'passwordLockStates')
    
    @saveDirInfo.each_with_index(roomNumberRange, $playRoomInfo) do |saveFiles, index|
      next unless( roomNumberRange.include?(index) )
      
      if( saveFiles.size != 1 )
        loggingForce("[#{index}](getPlayRoomPasswordLockStates) invalid playRoomInfo saveFiles:#{saveFiles.inspect}")
        next
      end
      
      trueSaveFileName = saveFiles.first
      
      getSaveData(trueSaveFileName) do |saveData|
        password = saveData['playRoomChangedPassword']
        unless( password.nil? )
          passwordLockStates[index] = true
        end
      end
    end
    
    logging(passwordLockStates, 'passwordLockStates')
    
    return passwordLockStates
  end
  
  def getCanVisitList( roomNumberRange )
    defaultValue = false
    saveDataKey = 'canVisit'
    return getPlayRoomInfoList( roomNumberRange, defaultValue, saveDataKey )
  end
  
  def getGameTypeList( roomNumberRange )
    defaultValue = ''
    saveDataKey = 'gameType'
    return getPlayRoomInfoList( roomNumberRange, defaultValue, saveDataKey )
  end
  
  def getPlayRoomInfoList( roomNumberRange, defaultValue, saveDataKey )
    infoList = {}
    roomNumberRange.each{|i| infoList[i] = defaultValue}
    
    @saveDirInfo.each_with_index(roomNumberRange, $playRoomInfo) do |saveFiles, index|
      next unless( roomNumberRange.include?(index) )
      
      if( saveFiles.size != 1 )
        loggingForce("[#{index}](infoList) invalid playRoomInfo saveFiles:#{saveFiles.inspect}")
        next
      end
      
      trueSaveFileName = saveFiles.first
      
      getSaveData(trueSaveFileName) do |saveData|
        unless( saveData[saveDataKey].nil? )
          infoList[index] = saveData[saveDataKey]
        end
      end
    end
    
    return infoList
  end
  
  def getPlayRoomNames( saveDataLastAccesTimes, roomNumberRange )
    logging(saveDataLastAccesTimes, "getPlayRoomNames saveDataLastAccesTimes")
    
    emptyRoomName = "（空き部屋）"
    playRoomNames = {}
    roomNumberRange.each{|i| playRoomNames[i] = emptyRoomName}
    logging(playRoomNames, 'playRoomNames')
    
    @saveDirInfo.each_with_index(roomNumberRange, $playRoomInfo) do |saveFiles, index|
      next unless( roomNumberRange.include?(index) )
      
      logging(index, "getPlayRoomNames each_with_index index")
      logging(saveFiles, "getPlayRoomNames each_with_index saveFiles")
      
      if( saveDataLastAccesTimes[index].to_i == 0 )
        logging("(saveDataLastAccesTimes[index].to_i == 0)")
        next
      end
      
      if( saveFiles.size != 1 )
        loggingForce("[#{index}](getPlayRoomNames) invalid playRoomInfo saveFiles:#{saveFiles.inspect}")
        next
      end
      
      @saveDirInfo.setSaveDataDirIndex(index)
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      logging(trueSaveFileName, "getPlayRoomNames trueSaveFileName")
      
      getSaveData(trueSaveFileName) do |saveData|
        playRoomName = getPlayRoomName(saveData, index)
        playRoomNames[index] = playRoomName
      end
    end
    logging(playRoomNames, 'playRoomNames result')
    
    return playRoomNames
  end
  
  def getPlayRoomName(saveData, index)
    playRoomName = saveData['playRoomName']
    playRoomName ||= "プレイルームNo.#{index}"
    return playRoomName
  end
  
  def getLoginUserCountList( roomNumberRange, limitTime = nil )
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
      
      unless( limitTime.nil? )
        accessTimes = getSaveDataLastAccessTimes( index .. index )
        accessTime = accessTimes[index].to_f
        
        if( accessTime < limitTime )
          next
        end
      end
      
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
    jsonData = getRequestData('params')
    logging(jsonData, "jsonData")
    
    params = getJsonDataFromText(jsonData)
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
    
    loginUserCountList = getLoginUserCountList( roomNumberRange )
    loginUsersList = getLoginUserList( roomNumberRange )
    playRoomPasswordLockStates = getPlayRoomPasswordLockStates( roomNumberRange )
    saveDataLastAccesTimes = getSaveDataLastAccessTimes( roomNumberRange )
    playRoomNames = getPlayRoomNames( saveDataLastAccesTimes, roomNumberRange )
    canVisitList = getCanVisitList( roomNumberRange )
    gameTypeList = getGameTypeList( roomNumberRange )
    
    roomNumberRange.each do |i|
      createdState = false
      loginUserCount = loginUserCountList[i]
      loginUsers = loginUsersList[i];
      logging("loginUsers", loginUsers);
      playRoomName = playRoomNames[i]
      passwordLockState = (playRoomPasswordLockStates[i] ? "有り" : "--")
      canVisit = (canVisitList[i] ? "可" : "--")
      timeStamp = saveDataLastAccesTimes[i]
      gameName = getGameName( gameTypeList[i] )
      
      timeString = ""
      unless( timeStamp.nil? )
        timeString = "#{timeStamp.strftime('%Y/%m/%d %H:%M:%S')}"
      end
      
      playRoomState = {
        'passwordLockState' => passwordLockState,
        'index' => sprintf("%3d", i),
        'playRoomName' => playRoomName,
        'loginUserCount' => loginUserCount,
        'loginUsers' => loginUsers,
        'lastUpdateTime' => timeString,
        'canVisit' => canVisit,
        'gameName' => gameName,
      }
      
      playRoomStates << playRoomState
    end
    
    return playRoomStates;
  end
  
  def getGameName(gameType)
    require 'diceBotInfos'
    gameInfo = $diceBotInfos.find{|i| i[:gameType] == gameType}
    
    return '--' if( gameInfo.nil? )
    
    return gameInfo[:name]
  end
  
  def getAllLoginCount()
    # limitTime = (Time.now.to_f - (60 * 60 * 24))
    roomNumberRange = (0 .. $saveDataMaxCount)
    loginUserCountList = getLoginUserCountList( roomNumberRange) #, limitTime )
    
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
      famousGames << {:gameType => gameType, :count => count}
    end
    
    logging('famousGames', famousGames)
    
    return famousGames
  end
  
  
  def getMinRoom(params)
    minRoom = [[ params['minRoom'], 0 ].max, ($saveDataMaxCount - 1)].min
  end
  
  def getMaxRoom(params)
    maxRoom = [[ params['maxRoom'], ($saveDataMaxCount - 1) ].min, 0].max
  end
  
  def getLoginInfo()
    logging("getLoginInfo begin")
    
    params = getParamsFromRequestData()
    
    uniqueId = params['uniqueId'];
    uniqueId ||= Time.now.to_f.to_s;
    
    allLoginCount, loginUserCountList = getAllLoginCount()
    writeAllLoginInfo( allLoginCount )
    
    loginMessage = getLoginMessage()
    cardInfos = $card.collectCardTypeAndTypeName()
    
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
      "loginUserCountList" => loginUserCountList,
      "maxLoginCount" => $aboutMaxLoginCount.to_i,
      "skinImage" => $skinImage,
      "isPaformanceMonitor" => $isPaformanceMonitor,
      "fps" => $fps,
      "canTalk" => $canTalk,
      "retryCountLimit" => $retryCountLimit,
      "imageUploadDirInfo" => {$localUploadDirMarker => $imageUploadDir},
      "mapMaxWidth" => $mapMaxWidth,
      "mapMaxHeigth" => $mapMaxHeigth,
    }
    
    logging(result, "result")
    logging("getLoginInfo end")
    return result
  end
  
  def writeAllLoginInfo( allLoginCount )
    text = "#{allLoginCount}"
    
    saveFileName = $loginCountFile
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
    diceBotInfos = deepCopy( $diceBotInfos )
    
    commandInfos = getGameCommandInfos
    
    commandInfos.each do |commandInfo|
      logging(commandInfo, "commandInfos.each commandInfos")
      setDiceBotPrefix(diceBotInfos, commandInfo)
    end
    
    logging(diceBotInfos, "getDiceBotInfos diceBotInfos")
    logging($diceBotInfos, "getDiceBotInfos $diceBotInfos")
    
    return diceBotInfos
  end
  
  def setDiceBotPrefix(diceBotInfos, commandInfo)
    gameType = commandInfo[:gameType]
    
    if( gameType.empty? )
      setDiceBotPrefixToAll(diceBotInfos, commandInfo)
      return
    end
    
    botInfo = diceBotInfos.find{|i| i[:gameType] == gameType}
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
    
    prefixs = botInfo[:prefixs]
    return if( prefixs.nil? )
    
    prefixs << commandInfo[:command]
  end
  
  @@diceBotTablePrefix = 'diceBotTable_'
  
  def getGameCommandInfos
    logging('getGameCommandInfos Begin')
    require 'customDiceBot.rb'
    
    bot = CgiDiceBot.new
    dir = getDiceBotExtraTableDirName
    logging(dir, 'dir')
    
    commandInfos = bot.getGameCommandInfos(dir, @@diceBotTablePrefix)
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
      
      playRoomName = params['playRoomName']
      playRoomPassword = params['playRoomPassword']
      chatChannelNames = params['chatChannelNames']
      canUseExternalImage = params['canUseExternalImage']
      
      canVisit = params['canVisit']
      playRoomIndex = params['playRoomIndex']
      
      if( playRoomIndex == -1 )
        playRoomIndex = findEmptyRoomNumber()
        raise Exception.new("空きプレイルームが見つかりませんでした") if(playRoomIndex == -1)
        loggingForce(playRoomIndex, "findEmptyRoomNumber playRoomIndex")
      end
      logging(playRoomName, 'playRoomName')
      logging('playRoomPassword is get')
      logging(playRoomIndex, 'playRoomIndex')
      
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
    rescue => e
      loggingException(e)
      resultText = e.inspect + "$@ : " + $@.join("\n")
    rescue Exception => errorMessage
      resultText = errorMessage.to_s
    end
    
    result = {
      "resultText" => resultText,
      "playRoomIndex" => playRoomIndex,
    }
    logging(result, 'result')
    logging('createDir finished')
    
    return result
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
    rescue => e
      loggingException(e)
      resultText = e.to_s
    end
    
    result = {
      "resultText" => resultText,
    }
    logging(result, 'changePlayRoom result')
    
    return result
  end
  
  
  def checkSetPassword(playRoomPassword)
    return if( playRoomPassword.empty? )
    
    roomNumber = @saveDirInfo.getSaveDataDirIndex
    
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
  
  
  def checkRemovePlayRoom(roomNumber, ignoreLoginUser)
    roomNumberRange = (roomNumber..roomNumber)
    logging(roomNumberRange, "checkRemovePlayRoom roomNumberRange")
    
    unless( ignoreLoginUser )
      loginUserCountList = getLoginUserCountList( roomNumberRange )
      logging(loginUserCountList, "checkRemovePlayRoom loginUserCountList");
      
      if( loginUserCountList[roomNumber] > 0 )
        return "userExist"
      end
    end
    
    if( $unremovablePlayRoomNumbers.include?(roomNumber) )
      return "unremovablePlayRoomNumber"
    end
    
    lastAccessTimes = getSaveDataLastAccessTimes( roomNumberRange )
    logging(lastAccessTimes, "lastAccessTimes")
    lastAccessTime = lastAccessTimes[roomNumber]
    logging(lastAccessTime, "lastAccessTime")
    now = Time.now
    logging(now, "now")
    spendTimes = now - lastAccessTime
    logging(spendTimes, "spendTimes")
    logging(spendTimes / 60 / 60, "spendTimes / 60 / 60")
    if( spendTimes < $deletablePassedSeconds )
      return "プレイルームNo.#{roomNumber}の最終更新時刻から#{$deletablePassedSeconds}秒が経過していないため削除できません"
    end
    
    return "OK"
  end
  
  def removePlayRoom()
    params = getParamsFromRequestData()
    
    roomNumbers = params['roomNumbers']
    ignoreLoginUser = params['ignoreLoginUser']
    logging(ignoreLoginUser, 'ignoreLoginUser')
    
    deletedRoomNumbers = []
    #部屋に人がまだる場合はこの配列に入れて、後で確認を取ってから削除します。
    askDeleteRoomNumbers = []
    errorMessages = []
    
    roomNumbers.each do |roomNumber|
      roomNumber = roomNumber.to_i
      logging(roomNumber, 'roomNumber')
      
      resultText = checkRemovePlayRoom(roomNumber, ignoreLoginUser)
      case resultText
      when "OK"
        @saveDirInfo.removeSaveDir(roomNumber)
        removeLocalSpaceDir(roomNumber)
        deletedRoomNumbers << roomNumber
      when "userExist"
        askDeleteRoomNumbers << roomNumber
      else
        errorMessages << resultText
      end
    end
    
    result = {
      "deletedRoomNumbers" => deletedRoomNumbers,
      "askDeleteRoomNumbers" => askDeleteRoomNumbers,
      "errorMessages" => errorMessages,
    }
    logging(result, 'result')
    
    return result
  end
  
  def removeLocalSpaceDir(roomNumber)
    dir = getRoomLocalSpaceDirNameByRoomNo(roomNumber)
    rmdir(dir)
  end
  
  def getTrueSaveFileName(fileName)
    saveFileName = @saveDirInfo.getTrueSaveFileName($saveFileTempName)
  end
  
  @@fullBackupFileBaseName = "DodontoFFullBackup"
  @@scenarioFIleExtName = '.tar.gz'
  
  def saveScenario()
    logging("saveScenario begin")
    dir = getRoomLocalSpaceDirName
    makeDir(dir)
    
    params = getParamsFromRequestData()
    @saveScenarioBaseUrl = params['baseUrl']
    chatPaletteSaveDataString = params['chatPaletteSaveData']
    
    saveDataAll = getSaveDataAllForScenario
    saveDataAll = moveAllImagesToDir(dir, saveDataAll)
    makeChatPalletSaveFile(dir, chatPaletteSaveDataString)
    makeScenariDefaultSaveFile(dir, saveDataAll)
    
    removeOldScenarioFile(dir)
    baseName = getNewSaveFileBaseName(@@fullBackupFileBaseName);
    scenarioFile = makeScenarioFile(dir, baseName)
    
    result = {}
    result['result'] = "OK"
    result["saveFileName"] = scenarioFile
    
    logging(result, "saveScenario result")
    return result
  end
  
  def getSaveDataAllForScenario
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
    
    fromFileName, text = from.split(/\t/)
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
    
    logging(@saveScenarioBaseUrl, "@saveScenarioBaseUrl")
    from.gsub!(@saveScenarioBaseUrl, './')
    logging(from, "from2")
    
    return false if( from.nil? )
    return false unless( File.exist?(from) )
    
    fromDir =  File.dirname(from)
    logging(fromDir, "fromDir")
    if( fromDir == to )
      logging("from, to is equal dir")
      return true
    end
    
    logging("copying...")
    
    result = true
    begin
      FileUtils.cp(from, to)
    rescue => e
      result = false
    end
    
    return result
  end
  
  def makeChatPalletSaveFile(dir, chatPaletteSaveDataString)
    logging("makeChatPalletSaveFile Begin")
    logging(dir, "makeChatPalletSaveFile dir")
    
    currentDir = FileUtils.pwd.untaint
    FileUtils.cd(dir)
    
    File.open($scenarioDefaultChatPallete, "a+") do |file|
      file.write(chatPaletteSaveDataString)
    end
    
    FileUtils.cd(currentDir)
    logging("makeChatPalletSaveFile End")
  end
  
  def makeScenariDefaultSaveFile(dir, saveDataAll)
    logging("makeScenariDefaultSaveFile Begin")
    logging(dir, "makeScenariDefaultSaveFile dir")
    
    extension = "sav"
    result = saveSelectFilesFromSaveDataAll(saveDataAll, extension)
    
    from = result["saveFileName"]
    to = File.join(dir, $scenarioDefaultSaveData)
    
    FileUtils.mv(from, to)
    
    logging("makeScenariDefaultSaveFile End")
  end
  
  
  def removeOldScenarioFile(dir)
    fileNames = Dir.glob("#{dir}/#{@@fullBackupFileBaseName}*#{@@scenarioFIleExtName}")
    fileNames = fileNames.collect{|i| i.untaint}
    logging(fileNames, "removeOldScenarioFile fileNames")
    
    fileNames.each do |fileName|
      File.delete(fileName)
    end
  end
  
  def makeScenarioFile(dir, fileBaseName = "scenario")
    logging("makeScenarioFile begin")
    
    require 'zlib'
    require 'archive/tar/minitar'
    
    currentDir = FileUtils.pwd.untaint
    FileUtils.cd(dir)
    
    scenarioFile = fileBaseName + @@scenarioFIleExtName
    tgz = Zlib::GzipWriter.new(File.open(scenarioFile, 'wb'))
    
    fileNames = Dir.glob('*')
    fileNames = fileNames.collect{|i| i.untaint}
    
    fileNames.delete_if{|i| i == scenarioFile}
    
    Archive::Tar::Minitar.pack(fileNames, tgz)
    
    FileUtils.cd(currentDir)
    
    return File.join(dir, scenarioFile)
  end
  
  
  def save()
    isAddPlayRoomInfo = true
    extension = getRequestData('extension')
    saveSelectFiles($saveFiles.keys, extension, isAddPlayRoomInfo)
  end
  
  def saveMap()
    extension = getRequestData('extension')
    selectTypes = ['map', 'characters']
    saveSelectFiles( selectTypes, extension)
  end
  
  
  def saveSelectFiles(selectTypes, extension, isAddPlayRoomInfo = false)
    saveDataAll = getSelectFilesData(selectTypes, isAddPlayRoomInfo)
    saveSelectFilesFromSaveDataAll(saveDataAll, extension)
  end
    
  def saveSelectFilesFromSaveDataAll(saveDataAll, extension)
    result = {}
    result["result"] = "unknown error"
    
    if( saveDataAll.empty? )
      result["result"] = "no save data"
      return result
    end
    
    deleteOldSaveFile
    
    saveData = {}
    saveData['saveDataAll'] = saveDataAll
    
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
    loggingForce($!.inspect )
    loggingForce(e.inspect )
  end
  
  
  def checkRoomStatus()
    deleteOldUploadFile()
    
    checkRoomStatusData = getRequestDataJsonData('checkRoomStatusData')
    logging(checkRoomStatusData, 'checkRoomStatusData')
    
    roomNumber = checkRoomStatusData['roomNumber']
    logging(roomNumber, 'roomNumber')
    
    @saveDirInfo.setSaveDataDirIndex(roomNumber)
    
    isMentenanceModeOn = false;
    isWelcomeMessageOn = $isWelcomeMessageOn;
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
    
    unless( $mentenanceModePassword.nil? )
      if( checkRoomStatusData["adminPassword"] == $mentenanceModePassword )
        isPasswordLocked = false
        isWelcomeMessageOn = false
        isMentenanceModeOn = true
      end
    end
    
    diceBotInfos = getDiceBotInfos()
    
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
      'diceBotInfos' => diceBotInfos,
    }
    
    logging(result, "checkRoomStatus End result")
    
    return result
  end
  
  def loginPassword()
    loginData = getRequestDataJsonData('loginData')
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
      canVisit = saveData['canVisit']
      if( canVisit and visiterMode )
        result['resultText'] = "OK"
        result['visiterMode'] = true
      else
        changedPassword = saveData['playRoomChangedPassword']
        if( changedPassword.nil? or password.crypt(changedPassword) == changedPassword )
          result['resultText'] = "OK"
        else
          result['resultText'] = "パスワードが違います"
        end
      end
    end
    
    return result
  end
  
  def logout()
    logoutData = getRequestDataJsonData('logoutData')
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
  
  
  def checkFileSizeOnMb(fileIO, size_MB)
    unless( fileIO.instance_of?( File ) or fileIO.instance_of?( Tempfile ) )
      return ""
    end
    
    if( fileIO.stat.size < (size_MB * 1024 * 1024) )
      return ""
    end
    
    return "ファイルサイズが最大値(#{size_MB}MB)以上のためアップロードに失敗しました。"
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
    tableFileData.setDir(dir, @@diceBotTablePrefix)
    tableInfos = tableFileData.getAllTableInfo
    
    logging(tableInfos, "getBotTableInfosFromDir tableInfos")
    tableInfos.sort!{|a, b| a[:command].to_i <=> b[:command].to_i}
    
    logging(tableInfos, 'getBotTableInfosFromDir result tableInfos')
    
    return tableInfos
  end
  
  
  
  def addBotTable()
    result = {}
    result['resultText'] = addBotTableMain()
    
    if( result['resultText'] != "OK" )
      return result
    end
    
    result = getBotTableInfos()
    return result
  end
  
  def addBotTableMain()
    logging("addBotTableMain Begin")
    
    dir = getDiceBotExtraTableDirName
    makeDir(dir)
    params = getParamsFromRequestData()
    
    require 'TableFileData'
    
    resultText = 'OK'
    begin
      creator = TableFileCreator.new(dir, @@diceBotTablePrefix, params)
      creator.execute
    rescue Exception => e
      loggingException(e)
      resultText = e.to_s
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
      creator = TableFileEditer.new(dir, @@diceBotTablePrefix, params)
      creator.execute 
    rescue Exception => e
      loggingException(e)
      resultText = e.to_s
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
    tableFileData.setDir(dir, @@diceBotTablePrefix)
    tableInfos = tableFileData.getAllTableInfo
    
    tableInfo = tableInfos.find{|i| i[:command] == command}
    logging(tableInfo, "tableInfo")
    return if( tableInfo.nil? )
    
    fileName = tableInfo[:fileName]
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
      ownUrl = getRequestData('ownUrl');
      replayUrl = ownUrl + "?replay=" + CGI.escape(fileNameFullPath)
      
      replayDataName = getRequestData('replayDataName');
      replayDataInfo = setReplayDataInfo(fileNameFullPath, replayDataName, replayUrl)
      
      result["replayDataInfo"] = replayDataInfo
      result["replayDataList"] = getReplayDataList() #[{"title"=>x, "url"=>y}]
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
  

  #getImageInfoFileName() ) do |saveData|
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
      jsonDataString = getRequestData('replayData')
      replayData = getJsonDataFromText(jsonDataString)
      
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
      
      baseUrl = getRequestData('baseUrl');
      logging(baseUrl, "baseUrl")
      
      fileUploadUrl = baseUrl + fileNameFullPath
      
      result["uploadFileInfo"] = {
        "fileName" => fileNameOriginal,
        "fileUploadUrl" => fileUploadUrl,
      }
    end
  end
  
  
  def deleteOldUploadFile()
    oneHour = (1 * 60 * 60)
    deleteOldFile($fileUploadDir, oneHour, File.join($fileUploadDir, "dummy.txt"))
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
      
      fileIO = getRequestData('Filedata')
      logging(fileIO, 'fileIO')
      
      sizeCheckResult = checkFileSizeOnMb(fileIO, fileMaxSize)
      if( sizeCheckResult != "" )
        result["resultText"] = sizeCheckResult
        return result;
      end
      
      fileNameOriginal = fileIO.original_filename.toutf8
      
      fileName = fileNameOriginal
      if( isChangeFileName )
        fileName = getNewFileName(fileNameOriginal)
      end
      
      fileNameFullPath = fileJoin(fileUploadDir, fileName).untaint
      logging(fileNameFullPath, "fileNameFullPath")
      
      yield(fileNameFullPath, fileNameOriginal, result)
      
      open(fileNameFullPath, "w+") do |file|
        file.binmode
        file.write(fileIO.read)
      end
      File.chmod(0666, fileNameFullPath)
      
      result["resultText"] = "OK"
    rescue => e
      logging(e, "error")
      result["resultText"] = e.to_s
    end
    
    logging(result, "load result")
    logging("uploadFile() End")
    
    return result
  end
  
  
  def loadScenario()
    logging("loadScenario() Begin")
    checkLoad()
    
    setRecordWriteEmpty
    
    fileUploadDir = getRoomLocalSpaceDirName
    
    clearDir(fileUploadDir)
    makeDir(fileUploadDir)
    
    fileMaxSize = $scenarioDataMaxSize # Mbyte
    scenarioFile = nil
    isChangeFileName = false
    
    result = uploadFileBase(fileUploadDir, fileMaxSize, isChangeFileName) do |fileNameFullPath, fileNameOriginal, result|
      scenarioFile = fileNameFullPath
    end
    
    logging(result, "uploadFileBase result")
    
    unless( result["resultText"] == 'OK' )
      return result
    end
    
    extendSaveData(scenarioFile, fileUploadDir)
    
    chatPaletteSaveData = loadScenarioDefaultInfo(fileUploadDir)
    result['chatPaletteSaveData'] = chatPaletteSaveData
    
    logging(result, 'loadScenario result')
    
    return result
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
  
  def extendSaveData(scenarioFile, fileUploadDir)
    logging(scenarioFile, 'scenarioFile')
    logging(fileUploadDir, 'fileUploadDir')
    
    require 'zlib'
    require 'archive/tar/minitar'
    
    readScenarioTar(scenarioFile) do |tar|
      logging("begin read scenario tar file")
      
      Archive::Tar::Minitar.unpackWithCheck(tar, fileUploadDir) do |fileName, isDirectory|
        checkUnpackFile(fileName, isDirectory)
      end
    end
    
    File.delete(scenarioFile)
    
    logging("archive extend !")
  end
  
  def readScenarioTar(scenarioFile)
    
    begin
      File.open(scenarioFile, 'rb') do |file|
        tar = file
        tar = Zlib::GzipReader.new(file)
        
        logging("scenarioFile is gzip")
        yield(tar)
        
      end
    rescue
      File.open(scenarioFile, 'rb') do |file|
        tar = file
        
        logging("scenarioFile is tar")
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
    
    loggingForce(fileName, 'NG! checkUnpackFile else paturn')
    
    return false
  end
  
  def isAllowedFileExt(fileName)
    extName = getAllowedFileExtName(fileName)
    return ( not extName.nil? )
  end
  
  def getAllowedFileExtName(fileName)
    rule = /\.(jpg|jpeg|gif|png|bmp|pdf|doc|txt|html|htm|xls|rtf|zip|lzh|rar|swf|flv|avi|mp4|mp3|wmv|wav|sav|cpd)$/
    
    return nil unless( rule === fileName )
    
    extName = "." + $1
    return extName
  end
  
  def getRoomLocalSpaceDirName
    roomNo = @saveDirInfo.getSaveDataDirIndex
    getRoomLocalSpaceDirNameByRoomNo(roomNo)
  end
  
  def getRoomLocalSpaceDirNameByRoomNo(roomNo)
    dir = File.join($imageUploadDir, "room_#{roomNo}")
    return dir
  end
  
  def makeDir(dir)
    loggingForce(dir, "makeDir dir")
    
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
  
  $scenarioDefaultSaveData = 'default.sav'
  $scenarioDefaultChatPallete = 'default.cpd'
  
  def loadScenarioDefaultInfo(dir)
    loadScenarioDefaultSaveData(dir)
    chatPaletteSaveData = loadScenarioDefaultChatPallete(dir)
    
    return chatPaletteSaveData
  end
  
  def loadScenarioDefaultSaveData(dir)
    logging('loadScenarioDefaultSaveData begin')
    saveFile = File.join(dir, $scenarioDefaultSaveData)
    
    unless( File.exist?(saveFile) )
      logging(saveFile, 'saveFile is NOT exist')
      return
    end
    
    jsonDataString = File.readlines(saveFile).join
    loadFromJsonDataString(jsonDataString)
    
    logging('loadScenarioDefaultSaveData end')
  end
  
  
  def loadScenarioDefaultChatPallete(dir)
    file = File.join(dir, $scenarioDefaultChatPallete)
    logging(file, 'loadScenarioDefaultChatPallete file')
    
    return nil unless( File.exist?(file) )
    
    buffer = File.readlines(file).join
    logging(buffer, 'loadScenarioDefaultChatPallete buffer')
    
    return buffer
  end
  
  
  def load()
    logging("saveData load() Begin")
    checkLoad()
    
    setRecordWriteEmpty
    
    result = {}
    
    begin
      fileIO = getRequestData('Filedata')
      logging(fileIO, 'fileIO')
      
      jsonDataString = fileIO.read
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
    
    logging(jsonData, 'loadFromJsonData jsonData')
    
    saveDataAll = getSaveDataAllFromSaveData(jsonData)
    logging(saveDataAll, 'saveDataAll')
    
    removeCharacterDataList = getRequestData('removeCharacterDataList');
    if( removeCharacterDataList != nil )
      removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
    end
    
    targets = getRequestData('targets');
    logging(targets, "targets")
    
    if( targets.nil? ) 
      logging("loadSaveFileDataAll(saveDataAll)")
      loadSaveFileDataAll(saveDataAll)
    else
      logging("loadSaveFileDataFilterByTargets(saveDataAll, targets)")
      loadSaveFileDataFilterByTargets(saveDataAll, targets)
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
  
  def loadSaveFileDataFilterByTargets(saveDataAll, targets)
    targets.each do |target|
      case target
      when "map"
        mapData = getLoadData(saveDataAll, 'map', 'mapData', {})
        changeMapSaveData(mapData)
      when "characterData", "mapMask", "mapMarker", "magicRangeMarker", "magicRangeMarkerDD4th", "Memo", getCardType()
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
      else
        loggingForce(target, "invalid load target type")
      end
    end
  end
  
  def loadSaveFileDataAll(saveDataAll)
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
  
  
  def getRequestData_forUploadImageData(key)
    setCgiParams
    
    values = @cgiParams[key]
    return nil if( values.nil? )
    
    value = values.first
    
    return value if( value.nil? )
    return value.string if( value.instance_of?(StringIO) )
    
    sizeCheckResult = checkFileSizeOnMb(value, $UPLOAD_IMAGE_MAX_SIZE)
    raise sizeCheckResult unless( sizeCheckResult.empty? )
    
    return value.read if( value.instance_of?(Tempfile) )
    return value.read if( value.instance_of?(File) )
    
    return value
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
    
    jsonDataString = getRequestData('tagInfo')
    logging(jsonDataString, "jsonDataString")
    
    tagInfo = getJsonDataFromText(jsonDataString)
    logging(tagInfo, "uploadImageData tagInfo")
    
    tagInfo["smallImage"] = uploadSmallImageFileName
    logging(tagInfo, "uploadImageData tagInfo smallImage url added")
    
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
      imageFileName = getRequestData("imageFileName")
      logging(imageFileName, "imageFileName")
      
      imageData = getRequestData_forUploadImageData("imageData")
      smallImageData = getRequestData_forUploadImageData("smallImageData")
      
      if( imageData.nil? )
        logging("createSmallImage is here")
        imageFileNameBase = File.basename(imageFileName)
        saveSmallImage(smallImageData, imageFileNameBase, imageFileName)
        return result
      end
      
      saveDir = $imageUploadDir
      imageFileNameBase = getNewFileName(imageFileName, "img")
      logging(imageFileNameBase, "imageFileNameBase")
      
      uploadImageFileName = fileJoin(saveDir, imageFileNameBase)
      logging(uploadImageFileName, "uploadImageFileName")
      
      open( uploadImageFileName, "wb+" ) do |file|
        file.write( imageData )
      end
      
      saveSmallImage(smallImageData, imageFileNameBase, uploadImageFileName)
    rescue => e
      result["resultText"] = e.to_s
    end
    
    return result
  end
  
  
  def uploadImageFile()
    logging("uploadImageFile load Begin")
    
    result = {
      "resultText"=> "OK"
    }
    
    fileIO = getRequestData('Filedata')
    logging(fileIO, 'fileIO')
    
    sizeCheckResult = checkFileSizeOnMb(fileIO, $UPLOAD_IMAGE_MAX_SIZE)
    if( sizeCheckResult != "" )
      result["resultText"] = sizeCheckResult
      return result;
    end
    
    saveDir = $imageUploadDir
    
    fileName = fileIO.original_filename.toutf8
    logging(fileName, "fileName original")
    fileName = getNewFileName(fileName, "img")
    logging(fileName, "fileName")
    
    result["originalFileName"] = fileIO.original_filename
    result["imageFileName"] = fileName
    
    uploadImageFileName = fileJoin(saveDir, fileName)
    logging(uploadImageFileName, "uploadImageFileName")
    
    open(uploadImageFileName, "w+") do |file|
      file.binmode
      file.write(fileIO.read)
    end
    
    tagInfo = getRequestData('tagInfo')
    changeImageTagsLocal(uploadImageFileName, tagInfo)
    
    logging(result, "uploadImageFile result")
    
    return result
  end
  
  def getNewFileName(fileName, preFix = "")
    @newFileNameIndex ||= 0
    
    extName = getAllowedFileExtName(fileName)
    extName ||= ""
    logging(extName, "extName")
    
    result = preFix + Time.now.to_f.to_s.gsub(/\./, '_') + "_" + @newFileNameIndex.to_s + extName
    
    return result.untaint
  end
  
  def deleteImage()
    logging("deleteImage begin")
    
    jsonData = getRequestData('imageData')
    logging(jsonData, "jsonData")
    
    imageData = getJsonDataFromText(jsonData)
    logging(imageData, "imageData")
    
    imageUrlList = imageData['imageUrlList']
    logging(imageUrlList, "imageUrlList")
    
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
        deleteFile(imageUrl);
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
    
    jsonData = getRequestData('imageData')
    logging(jsonData, "jsonData")
    
    imageData = getJsonDataFromText(jsonData)
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
    imageDataJsonString = getRequestData('imageData')
    logging(imageDataJsonString, "imageDataJsonString")
    
    imageData = getJsonDataFromText(imageDataJsonString)
    logging(imageData, "imageData")
    
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
    files = Dir.glob( "#{$imageUploadDir}/*")
    
    files.each do |fileName|
      file = file.untaint
      
      next if( imageList.include?(fileName) )
      next unless( isAllowedFileExt(fileName) )
      
      imageList << fileName
      logging(fileName, "added local image")
    end
  end
  
  def deleteInvalidImageFileName(imageList)
    imageList.delete_if{|i| (/\.txt$/===i)}
    imageList.delete_if{|i| (/\.lock$/===i)}
    imageList.delete_if{|i| (/\.json$/===i)}
    imageList.delete_if{|i| (/\.json~$/===i)}
    imageList.delete_if{|i| (/^.svn$/===i)}
    imageList.delete_if{|i| (/.db$/===i)}
  end
  
  
  
  def sendDiceBotChatMessage
    logging('sendDiceBotChatMessage')
    
    params = getParamsFromRequestData()
    
    name = params['name']
    state = params['state']
    message = params['message']
    color = params['color']
    channel = params['channel']
    sendto = params['sendto']
    gameType = params['gameType']
    
    rollResult, isSecret = rollDice(message, gameType)
    logging(rollResult, 'rollResult')
    logging(isSecret, 'isSecret')
    
    secretResult = ""
    if( isSecret )
      secretResult = message + rollResult
    else
      message = message + rollResult
    end
    
    senderName = name
    senderName << ("\t" + state) unless( state.empty? )
    
    chatData = {
      "senderName" => senderName,
      "message" => message,
      "color" => color,
      "uniqueId" => '0',
      "channel" => channel
    }
    
    unless( sendto.nil? )
      chatData['sendto'] = sendto
    end
    
    logging(chatData, 'sendDiceBotChatMessage chatData')
    
    sendChatMessageByChatData(chatData)
    
    
    result = nil
    if( isSecret )
      params['isSecret'] = isSecret
      params['message'] = secretResult
      result = params
    end
    
    return result
  end
  
  def rollDice(message, gameType)
    logging(message, 'rollDice message')
    logging(gameType, 'rollDice gameType')
    
    require 'customDiceBot.rb'
    bot = CgiDiceBot.new
    dir = getDiceBotExtraTableDirName
    result = bot.roll(message, gameType, dir, @@diceBotTablePrefix)
    
    result.gsub!(/＞/, '→')
    result.sub!(/\r?\n?\Z/, '')
    
    logging(result, 'rollDice result')
    
    return result, bot.isSecret
  end
  
  def getDiceBotExtraTableDirName
    getRoomLocalSpaceDirName
  end
  
  def sendChatMessageMany
    100.times{ sendChatMessage }
  end
  
  def sendChatMessage
    chatData = getParamsFromRequestData()
    sendChatMessageByChatData(chatData)
  end
  
  def sendChatMessageByChatData(chatData)
    
    chatMessageData = nil
    
    changeSaveData(@saveFiles['chatMessageDataLog']) do |saveData|
      
      chatMessageDataLog = saveData['chatMessageDataLog']
      chatMessageDataLog ||= []
      
      deleteOldChatMessageData(chatMessageDataLog);
      
      now = Time.now.to_f
      chatMessageData = [now, chatData]
      
      chatMessageDataLog.push(chatMessageData)
      chatMessageDataLog.sort!
      logging(chatMessageDataLog, "chatMessageDataLog")
      saveData['chatMessageDataLog'] = chatMessageDataLog
      logging(saveData['chatMessageDataLog'], "saveData['chatMessageDataLog']");
    end
    
    if( $IS_SAVE_LONG_CHAT_LOG )
      saveAllChatMessage(chatMessageData)
    end
  end
  
  def deleteOldChatMessageData(chatMessageDataLog)
    now = Time.now.to_f
    
    chatMessageDataLog.delete_if do |chatMessageData|
      writtenTime, chatMessage, *dummy = chatMessageData
      timeDiff = now - writtenTime
      
      ( timeDiff > ($oldMessageTimeout) )
    end
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
  
  def changeMap
    mapData = getRequestDataJsonData('mapData')
    logging(mapData, "mapData")
    
    changeMapSaveData(mapData)
  end
  
  def changeMapSaveData(mapData)
    logging("changeMap start.")
    
    changeSaveData(@saveFiles['map']) do |saveData|
      
      saveData['mapData'] ||= {}
      logging(saveData['mapData'], "saveData['mapData']")
      
      saveData['mapData'] = mapData
    end
  end
  
  def addEffect
    effectData = getRequestDataJsonData('effectData')
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
      saveData['effects'] ||= []
      effects = saveData['effects']
      
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
      effectData = getRequestDataJsonData('effectData')
      targetCutInId = effectData['effectId']
      
      saveData['effects'] ||= []
      effects = saveData['effects']
      
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
  
  def removeEffect
    changeSaveData(@saveFiles['effects']) do |saveData|
      effectData = getRequestDataJsonData('effectData')
      effectId = effectData['effectId']
      saveData['effects'] ||= []
      effects = saveData['effects']
      effects.delete_if{|i| (effectId == i['effectId'])}
    end
  end
  
  
  
  def getImageInfoFileName
    imageInfoFileName = fileJoin($imageUploadDir, 'imageInfo.json')
    
    logging(imageInfoFileName, 'imageInfoFileName')
    
    return imageInfoFileName
  end
  
  def changeImageTags
    effectData = getRequestDataJsonData('tagsData')
    source = effectData['source']
    tagInfo = effectData['tagInfo']
    
    changeImageTagsLocal(source, tagInfo)
  end
  
  def getAllImageFileNameFromTagInfoFile()
    imageFileNames = []
    
    getSaveData( getImageInfoFileName() ) do |saveData|
      imageTags = saveData['imageTags']
      imageTags ||= {}
      imageFileNames = imageTags.keys
    end
    
    return imageFileNames
  end
  
  def changeImageTagsLocal(source, tagInfo)
    return if( tagInfo.nil? )
    
    changeSaveData( getImageInfoFileName() ) do |saveData|
      saveData['imageTags'] ||= {}
      imageTags = saveData['imageTags']
      
      imageTags[source] = tagInfo
    end
  end
  
  def deleteImageTags(source)
    
    changeSaveData( getImageInfoFileName() ) do |saveData|
      
      imageTags = saveData['imageTags']
      
      tagInfo = imageTags.delete(source)
      return false if( tagInfo.nil? )
      
      smallImage = tagInfo["smallImage"]
      begin
        deleteFile(smallImage)
      rescue => e
        errorMessage = getErrorResponseText(e)
        loggingException(e)
      end
    end
    
    return true
  end
  
  def deleteFile(file)
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
  
  def getImageTags
    logging('getImageTags start')
    imageTags = nil
    
    getSaveData( getImageInfoFileName() ) do |saveData|
      imageTags = saveData['imageTags']
    end
    
    imageTags ||= {}
    logging(imageTags, 'getImageTags imageTags')
    
    return imageTags
  end
  
  def createCharacterImgId(prefix = "character_")
    @imgIdIndex ||= 0;
    @imgIdIndex += 1;
    
    #return (prefix + Time.now.to_f.to_s + "_" + @imgIdIndex.to_s);
    return (prefix + sprintf("%.4f_%04d", Time.now.to_f, @imgIdIndex));
  end
  
  def addCharacter
    jsCharacterData = getRequestData('characterData')
    characterData = getJsonDataFromText(jsCharacterData)
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
    logging(characterData.inspect, "characterData")
    
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
      
      logging(characterData.inspect, "character data change")
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
  
  def getCardData(isText, imageName, imageNameBack, mountName, isUpDown = false, canDelete = false)
    
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
      
      "name" => "",
      "imgId" =>  createCharacterImgId(),
      "type" => getCardType(),
      "x" => 0,
      "y" => 0,
      "draggable" => true,
    }
    
    return cardData
  end
  


  def addCardZone
    logging("addCardZone Begin");
    
    jsData = getRequestData('data')
    data = getJsonDataFromText(jsData)
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
        
        cardsListFileName = $card.getCardFileName(mountName);
        logging(cardsListFileName, "initCards cardsListFileName");
        
        cardsList = []
        readLines(cardsListFileName).each_with_index  do |i, lineIndex|
          cardsList << i.chomp.toutf8
        end
        
        logging(cardsList, "initCards cardsList")
        
        cardData = cardsList.shift.split(/,/)
        isText = (cardData.shift == "text")
        isUpDown = (cardData.shift == "upDown")
        logging("isUpDown", isUpDown)
        imageNameBack = cardsList.shift
        
        cardsList, isSorted = getInitCardSet(cardsList, cardTypeInfo)
        cardMounts[mountName] = getInitedCardMount(cardsList, mountName, isText, isUpDown, imageNameBack, isSorted)
        
        cardMountData = createCardMountData(cardMounts, isText, imageNameBack, mountName, index, isUpDown, cardTypeInfo, cardsList)
        characters << cardMountData
        
        cardTrushMountData = getCardTrushMountData(isText, mountName, index, cardTypeInfo)
        characters << cardTrushMountData
      end
      
      waitForRefresh = 0.2
      sleep( waitForRefresh )
    end
    
    logging("initCards End");
    
    cardExist = (not cardTypeInfos.empty?)
    return {"result" => "OK", "cardExist" => cardExist }
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
    
    jsAddCardData = getRequestData('addCardData')
    addCardData = getJsonDataFromText(jsAddCardData)
    
    isText = addCardData['isText']
    imageName = addCardData['imageName']
    imageNameBack = addCardData['imageNameBack']
    mountName = addCardData['mountName']
    isUpDown = addCardData['isUpDown']
    canDelete = addCardData['canDelete']
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardData = getCardData(isText, imageName, imageNameBack, mountName, isUpDown, canDelete)
      cardData["x"] = addCardData['x']
      cardData["y"] = addCardData['y']
      
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
    setCardCountAndBackImage(cardMountData, cardMount[mountName]);
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
    
    imageName, imageNameBack, isText = getCardTrushMountImageName(mountName, cards)
    
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
      cardTitle = $card.getCardTitleName( mountName )
      
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
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
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
      
      count.times do
        drawCardDataOne(params, saveData)
      end
      
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
    return if( cardMountData.nil? )
    
    cardCountDisplayDiff = cardMountData['cardCountDisplayDiff']
    unless( cardCountDisplayDiff.nil? )
      return if( cardCountDisplayDiff >= cards.length )
    end
    
    cardData = cards.pop
    return if( cardData.nil? )
    
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
  end
  

  def drawTargetTrushCard
    logging("drawTargetTrushCard Begin");
    
    setdNoBodyCommanSender
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    logging(mountName, "mountName")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
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
  
  def dumpTrushCards
    logging("dumpTrushCards Begin")
    
    setdNoBodyCommanSender
    
    jsData = getRequestData('data')
    dumpTrushCardsData = getJsonDataFromText(jsData)
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
      throw Exception.new("deleteFindOne target is NOT found inspect:" ) #+ array.inspect)
    end
    
    logging(array.size, "array.size before")
    item = array.delete_at(findIndex)
    logging(array.size, "array.size before")
    return item
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
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
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
    
    jsParams = getRequestData('params')
    params = getJsonDataFromText(jsParams)
    mountName = params['mountName']
    trushMountId = params['mountId']
    
    logging(mountName, 'mountName')
    logging(trushMountId, 'trushMountId')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName) 
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
    mountId = params['mountId']
    
    cards = []
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      cards = trushCards
    end
    
    return cards
  end
  
  
  def clearCharacterByType
    logging("clearCharacterByType Begin")
    
    setRecordWriteEmpty
    
    jsData = getRequestData('clearData')
    clearData = getJsonDataFromText(jsData)
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
  
  def removeCharacter
    jsRemoveCharacterData = getRequestData('removeCharacterData')
    removeCharacterDataList = getJsonDataFromText(jsRemoveCharacterData)
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
  

  def getParamsFromRequestData()
    preParams = getRequestData('params')
    params = getJsonDataFromText(preParams)
    return params
  end
  
  def enterWaitingRoomCharacter
    
    setRecordWriteEmpty
    
    params = getParamsFromRequestData()
    characterId = params['characterId']
    
    logging(characterId, "enterWaitingRoomCharacter characterId")
    
    result = {"result" => "NG"}
    changeSaveData(@saveFiles['characters']) do |saveData|
      characters = getCharactersFromSaveData(saveData)
      
      enterCharacterData = removeFromArray(characters) {|i| (i['imgId'] == characterId) }
      return result if( enterCharacterData.nil? )
      
      waitingRoom = getWaitinigRoomFromSaveData(saveData)
      waitingRoom << enterCharacterData
    end
    
    result["result"] = "OK"
    return result
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
  
  def getArrayInfoFromHash(hash, key)
    hash[key] ||= []
    return hash[key]
  end
  
  def getCardMountFromSaveData(saveData)
    return getHashInfoFromHash(saveData, 'cardMount')
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
      end
    end
    
    return nil if( index.nil? )
    
    item = array.delete_at(index)
    return item
  end
  
  
  def changeRoundTime
    changeSaveData(@saveFiles['time']) do |saveData|
      jsRoundTimeData = getRequestData('roundTimeData')
      roundTimeData = getJsonDataFromText(jsRoundTimeData)
      
      saveData['roundTimeData'] = roundTimeData;
    end
  end
  
  def moveCharacter
    changeSaveData(@saveFiles['characters']) do |saveData|

      characterMoveData = getRequestDataJsonData('characterData')
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
  
  def isSaveFileChanged(lastUpdateTime, saveFileName)
    saveFileTimeStamp = getSaveFileTimeStamp(saveFileName);
    changed = (saveFileTimeStamp != lastUpdateTime)
    
    logging(saveFileName, "saveFileName")
    logging(saveFileTimeStamp.inspect, "saveFileTimeStamp")
    logging(lastUpdateTime.inspect, "lastUpdateTime")
    logging(changed, "changed")
    
    return changed
  end
  
  def getResponse
    response = analyzeCommand
    return getTextFromJsonData(response)
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


def main(cgi)
  server = DodontoFServer.new(SaveDirInfo.new(), cgi, cgi.content_type)
  printResult(server)
end

def getInitializedHeaderText()
  header = ""
  
  if( $isModRuby )
    #Apache::request.content_type = "text/plain; charset=utf-8"
    #Apache::request.send_header
  else
    header << "Content-Type: text/plain; charset=utf-8\n"
  end
  
  return header
end

def printResult(server)
  logging("========================================>CGI begin.")
  
  text = "empty"
  
  header = getInitializedHeaderText()
  
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


def getCgi()
  cgi = CGI.new
end


def executeDodontoServerCgi()
  cgi = getCgi()
  
  initLog();
  
  case $dbType
  when "mysql"
    #mod_ruby でも再読み込みするようにloadに
    require 'DodontoFServerMySql.rb'
    mainMySql(cgi)
  else
    #通常のテキストファイル形式
    main(cgi)
  end
  
end
  
if( $0 === __FILE__ )
  executeDodontoServerCgi()
end

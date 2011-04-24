#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"

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

#mod_ruby でも再読み込みするようにloadに
load "config.rb"

require "loggingFunction.rb"
require "FileLock.rb"
# require "FileLock2.rb"
require "saveDirInfo.rb"
require "card.rb"

$card = Card.new();



#サーバCGIとクライアントFlashのバージョン一致確認用
$version = "Ver.1.30.05.01(2011/04/24)"

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
  'playRoomInfo' => $playRoomInfo,
};



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
    
    logging('pass1')
    
    if( @cgiParams.include?(key) )
      value = @cgi[key]
      return value if( key == 'Filedata' )
      
      return getStringFromStringOrStringIoOrFile(value)
    end
    
    logging('pass2')
    
    @jsonDataForFileUploader ||= getJsonDataForFileUploader
    logging(@jsonDataForFileUploader, "@jsonDataForFileUploader")
    
    logging('pass4')
    
    return @jsonDataForFileUploader[key]
  end
  
  def getJsonDataForFileUploader
    logging("get @cgi['__jsonDataForFileUploader__']");
    jsonDataIo = @cgi['__jsonDataForFileUploader__']
    logging(jsonDataIo, "jsonDataIo");
    
    jsonDataString = getStringFromStringOrStringIoOrFile(jsonDataIo)
    logging(jsonDataString, "jsonDataString in getRequestData")
    
    logging('pass3')
    
    logging("getJsonDataFromText(jsonDataString)")
    jsonDataForFileUploader = getJsonDataFromText(jsonDataString)
    logging(jsonDataForFileUploader, "jsonDataForFileUploader");
    
    return jsonDataForFileUploader
  end
  
  def initialize(saveDirInfo, cgi, content_type)
    @cgi = cgi
    @content_type = content_type
    @saveDirInfo = saveDirInfo
    
    @saveDirInfo.init(getRequestData("saveDataDirIndex"), $saveDataMaxCount, $SAVE_DATA_DIR)
    
    @saveFiles = {}
    $saveFiles.each do |saveDataKeyName, saveFileName|
      logging(saveDataKeyName, "saveDataKeyName")
      logging(saveFileName, "saveFileName")
      @saveFiles[saveDataKeyName] = @saveDirInfo.getTrueSaveFileName(saveFileName)
    end
  end
  
  #override
  def getSaveFileLockReadOnly(saveFileName)
    getSaveFileLock(saveFileName, true)
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
  
  def getSaveFileLock(saveFileName, isReadOnly = false)
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
  
  def loadSaveFileForLongChatLog(typeName, saveFileName, lastUpdateTimes)
    saveFileName = @saveDirInfo.getTrueSaveFileName($chatMessageDataLogAll)
    saveFileLock = getSaveFileLockReadOnly(saveFileName)
    
    lines = []
    saveFileLock.lock do
      if( isExist?(saveFileName) )
        lines = readLines(saveFileName)
      end
      
      lastUpdateTimes[typeName] = getSaveFileTimeStamp(saveFileName);
    end
    
    if( lines.empty? )
      return {}
    end
    
    chatMessageDataLog = lines.collect{|line| getJsonDataFromText(line.chomp) }
    
    saveData = {"chatMessageDataLog" => chatMessageDataLog}
    
    return saveData
  end
  
  def loadSaveFileForDefault(typeName, saveFileName, lastUpdateTimes)
    saveFileLock = getSaveFileLockReadOnly(saveFileName)
    
    saveDataText = ""
    saveFileLock.lock do
      lastUpdateTimes[typeName] = getSaveFileTimeStamp(saveFileName);
      saveDataText = getSaveTextOnFileLocked(saveFileName)
    end
    
    saveData = getJsonDataFromText(saveDataText)
    
    return saveData
  end
  
  def isChatType(typeName)
    return (typeName == 'chatMessageDataLog')
  end
  
  def isLongChatLog(typeName, lastUpdateTimes)
    return ( $IS_SAVE_LONG_CHAT_LOG and isChatType(typeName) and lastUpdateTimes[typeName] == 0 )
  end
  
  def loadSaveFile(typeName, saveFileName, lastUpdateTimes)
    saveData = nil
    
    begin
      if( isLongChatLog(typeName, lastUpdateTimes) )
        saveData = loadSaveFileForLongChatLog(typeName, saveFileName, lastUpdateTimes)
      else
        saveData = loadSaveFileForDefault(typeName, saveFileName, lastUpdateTimes)
      end 
    rescue => e
      loggingException(e)
      raise e
    end
    
    logging(saveData.inspect, saveFileName)
    
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
    
    saveFileLock = getSaveFileLock(saveFileName)
    
    saveFileLock.lock do
      saveDataText = getSaveTextOnFileLocked(saveFileName)
      saveData = getJsonDataFromText(saveDataText)
      
      yield(saveData)
      
      saveDataText = getTextFromJsonData(saveData)
      createFile(saveFileName, saveDataText)
    end
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
  
  def escapeHtmlDataFromJson(jsonData)
    if( jsonData.kind_of?(String) )
      escapedString = CGI.escapeHTML(jsonData)
      jsonData.gsub!(/\A.*\z/, escapedString);
    elsif( jsonData.kind_of?(Hash) )
      jsonData.each do |key, value|
        escapeHtmlDataFromJson(value)
      end
    elsif( jsonData.kind_of?(Array) )
      jsonData.each do |item|
        escapeHtmlDataFromJson(item)
      end
    else
      # do nothing
    end
    
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
      return getTestResponseText
    end
    
    hasReturn = "hasReturn";
    hasNoReturn = "hasNoReturn";
    
    commands = [
      ['refresh', hasReturn],
      
      ['getGraveyardCharacterData', hasReturn], 
      ['getLoginInfo', hasReturn], 
      ['getPlayRoomStates', hasReturn], 
      ['deleteImage', hasReturn], 
      ['uploadImageUrl', hasReturn], 
      ['save', hasReturn], 
      ['saveMap', hasReturn], 
      ['load', hasReturn], 
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
      ['getMountCardInfos', hasReturn],
      ['drawTargetCard', hasReturn],
      ['drawCard', hasReturn],
      
      ['logout', hasNoReturn], 
      ['addCard', hasNoReturn],
      ['changeCharacterData', hasNoReturn],
      ['removeCharacter', hasNoReturn],
      ['addCardZone', hasNoReturn],
      ['initCards', hasNoReturn],
      ['returnCard', hasNoReturn],
      ['shuffleCards', hasNoReturn],
      ['shuffleForNextRandomDungeon', hasNoReturn],
      ['dumpTrushCards', hasNoReturn],
      ['clearCharacterByType', hasNoReturn],
      ['resurrectCharacter', hasNoReturn],
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
  
  def getTestResponseText
    "「どどんとふ」の動作環境は正常に起動しています。";
  end
  
  
  def getCurrentSaveData(lastUpdateTimes)
    @saveFiles.each do |saveFileTypeName, saveFileName|
      logging(saveFileTypeName, "saveFileTypeName");
      logging(saveFileName, "saveFileName");
      
      targetLastUpdateTime = lastUpdateTimes[saveFileTypeName];
      next if( targetLastUpdateTime == nil )
      
      logging(targetLastUpdateTime, "targetLastUpdateTime");
      
      if( isSaveFileChanged(targetLastUpdateTime, saveFileName) )
        logging(saveFileName, "saveFile is changed");
        targetSaveData = loadSaveFile(saveFileTypeName, saveFileName, lastUpdateTimes)
        yield(targetSaveData, saveFileTypeName)
      end
    end
  end
  
  def refresh
    logging("==>Begin refresh");
    
    saveData = {}
    
    if( $isMentenanceNow )
      saveData["warning"] = {"key" => "canNotRefreshBecauseMentenanceNow"}
      return saveData
    end
    
    refreshDataJsonString = getRequestData('refreshData')
    logging(refreshDataJsonString, "refreshDataJsonString");
    refreshData = getJsonDataFromText(refreshDataJsonString)
    
    lastUpdateTimes = refreshData['lastUpdateTimes']
    logging(lastUpdateTimes, "lastUpdateTimes");
    
    isFirstChatRefresh = (lastUpdateTimes['chatMessageDataLog'] == 0);
    logging(isFirstChatRefresh, "isFirstChatRefresh");
    
    refreshIndex = refreshData['refreshIndex'];
    logging(refreshIndex, "refreshIndex");
    
    now = Time.now
    whileLimitTime = now + $refreshTimeout
    logging(now, "now")
    logging($refreshTimeout, "refreshTimeout")
    logging(whileLimitTime, "whileLimitTime")
    
    while( Time.now < whileLimitTime )
      getCurrentSaveData(lastUpdateTimes) do |targetSaveData, saveFileTypeName|
        saveData.merge!(targetSaveData)
      end
      
      logging(saveData, "saveData is empty?");
      break unless( saveData.empty? )
      logging("saveData is empty!");
      
      logging("sleep...");
      sleep( $refreshInterval )
      logging("awake.");
    end
    
    logging("refresh BREAK");
    
    uniqueId = refreshData['uniqueId'];
    userName = refreshData['userName'];
    isVisiter = refreshData['isVisiter'];
    loginUserInfoSaveFile = @saveDirInfo.getTrueSaveFileName($loginUserInfo)
    
    loginUserInfo = updateLoginUserInfo(loginUserInfoSaveFile, userName, uniqueId, isVisiter)
    
    saveData['lastUpdateTimes'] = lastUpdateTimes;
    saveData['refreshIndex'] = refreshIndex;
    saveData['loginUserInfo'] = loginUserInfo;
    if( isFirstChatRefresh )
      saveData['isFirstChatRefresh'] = isFirstChatRefresh
    end
    
    logging("==>End refresh");
    
    logging(loginUserInfo, "loginUserInfo");
    
    return saveData
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
    canVisitList = {}
    roomNumberRange.each{|i| canVisitList[i] = false}
    
    @saveDirInfo.each_with_index(roomNumberRange, $playRoomInfo) do |saveFiles, index|
      next unless( roomNumberRange.include?(index) )
      
      if( saveFiles.size != 1 )
        loggingForce("[#{index}](getCanVisitList) invalid playRoomInfo saveFiles:#{saveFiles.inspect}")
        next
      end
      
      trueSaveFileName = saveFiles.first
      
      getSaveData(trueSaveFileName) do |saveData|
        unless( saveData['canVisit'].nil? )
          canVisitList[index] = saveData['canVisit']
        end
      end
    end
    
    return canVisitList
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
    
    roomNumberRange.each do |i|
      createdState = false
      loginUserCount = loginUserCountList[i]
      loginUsers = loginUsersList[i];
      logging("loginUsers", loginUsers);
      playRoomName = playRoomNames[i]
      passwordLockState = (playRoomPasswordLockStates[i] ? "有り" : "--")
      canVisit = (canVisitList[i] ? "可" : "--")
      timeStamp = saveDataLastAccesTimes[i]
      
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
      }
      
      playRoomStates << playRoomState
    end
    
    return playRoomStates;
  end
  
  def getAllLoginCount()
    limitTime = (Time.now.to_f - (60 * 60 * 24))
    
    roomNumberRange = (0 .. $saveDataMaxCount)
    loginUserCountList = getLoginUserCountList( roomNumberRange, limitTime )
    
    total = 0
    loginUserCountList.each do |key, value|
      total += value
    end
    
    return total
  end
  
  def getMinRoom(params)
    minRoom = [[ params['minRoom'], 0 ].max, ($saveDataMaxCount - 1)].min
  end
  
  def getMaxRoom(params)
    maxRoom = [[ params['maxRoom'], ($saveDataMaxCount - 1) ].min, 0].max
  end
  
  def getLoginInfo()
    logging("getLoginInfo begin")
    
    allLoginCount = getAllLoginCount()
    loginMessage = getLoginMessage()
    cardInfos = $card.collectCardTypeAndTypeName()
    
    result = {
      "loginMessage" => loginMessage,
      "cardInfos" => cardInfos,
      "isDiceBotOn" => $isDiceBotOn,
      "uniqueId" => Time.now.to_f.to_s,
      "refreshTimeout" => $refreshTimeout,
      "version" => $version,
      "playRoomMaxNumber" => ($saveDataMaxCount - 1),
      "diceBoxCgiUrl" => $diceBoxCgiUrl,
      "warning" => getLoginWarning(),
      "playRoomGetRangeMax" => $playRoomGetRangeMax,
      "allLoginCount" => allLoginCount,
    }
    
    logging(result, "result")
    logging("getLoginInfo end")
    return result
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
    loginMessage = ""
    
    if( File.exist?( $loginMessageFile ) )
      File.readlines($loginMessageFile).each do |line|
        #        loginMessage << line.chomp.toutf8 << "\n";
        loginMessage << line.chomp << "\n";
      end
      logging(loginMessage, "loginMessage")
    else
      logging("#{$loginMessageFile} is NOT found.")
    end
    
    return loginMessage
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
      jsonData = getRequestData('createPlayRoomData')
      logging(jsonData, "jsonData")
      
      createPlayRoomData = getJsonDataFromText(jsonData)
      logging(createPlayRoomData, "createPlayRoomData")
      
      playRoomName = createPlayRoomData['playRoomName']
      playRoomPassword = createPlayRoomData['playRoomPassword']
      chatChannelNames = createPlayRoomData['chatChannelNames']
      canUseExternalImage = createPlayRoomData['canUseExternalImage']
      canVisit = createPlayRoomData['canVisit']
      playRoomIndex = createPlayRoomData['playRoomIndex']
      loggingForce(playRoomIndex, "playRoomIndex")
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
      
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      changeSaveData(trueSaveFileName) do |saveData|
        saveData['playRoomName'] = playRoomName
        saveData['playRoomChangedPassword'] = playRoomChangedPassword
        saveData['chatChannelNames'] = chatChannelNames
        saveData['canUseExternalImage'] = canUseExternalImage
        saveData['canVisit'] = canVisit
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
  
  def getChangedPassword(pass)
    return nil if( pass.empty? )
    
    salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
    return pass.crypt(salt)
  end
  
  def changePlayRoom()
    logging("changePlayRoom begin")
    
    resultText = "OK"
    
    begin
      jsonData = getRequestData('changePlayRoomData')
      logging(jsonData, "jsonData")
      
      changePlayRoomData = getJsonDataFromText(jsonData)
      logging(changePlayRoomData, "changePlayRoomData")
      
      playRoomName = changePlayRoomData['playRoomName']
      playRoomPassword = changePlayRoomData['playRoomPassword']
      chatChannelNames = changePlayRoomData['chatChannelNames']
      canUseExternalImage = changePlayRoomData['canUseExternalImage']
      canVisit = changePlayRoomData['canVisit']
      logging(playRoomName, 'playRoomName')
      logging('playRoomPassword is get')
      
      playRoomChangedPassword = getChangedPassword(playRoomPassword)
      
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      
      changeSaveData(trueSaveFileName) do |saveData|
        saveData['playRoomName'] = playRoomName
        saveData['playRoomChangedPassword'] = playRoomChangedPassword
        saveData['chatChannelNames'] = chatChannelNames
        saveData['canUseExternalImage'] = canUseExternalImage
        saveData['canVisit'] = canVisit
      end
    rescue => e
      loggingException(e)
      resultText = e.inspect
    end
    
    result = {
      "resultText" => resultText,
    }
    logging(result, 'changePlayRoom result')
    
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
      return "プレイルームの最終アクセス時間から#{$deletablePassedSeconds}秒が経過していないため削除できません"
    end
    
    return "OK"
  end
  
  def removePlayRoom()
    removePlayRoomData = getRequestDataJsonData('removePlayRoomData')
    logging(removePlayRoomData, 'removePlayRoomData')
    
    roomNumber = removePlayRoomData['roomNumber'].to_i
    logging(roomNumber, 'roomNumber')
    
    ignoreLoginUser = removePlayRoomData['ignoreLoginUser']
    logging(ignoreLoginUser, 'ignoreLoginUser')
    
    resultText = checkRemovePlayRoom(roomNumber, ignoreLoginUser)
    if( resultText == "OK" )
      @saveDirInfo.removeSaveDir(roomNumber)
    end
    
    result = {
      "resultText" => resultText,
      "roomNumber" => roomNumber
    }
    logging(result, 'result')
    
    return result
  end
  
  def getTrueSaveFileName(fileName)
    saveFileName = @saveDirInfo.getTrueSaveFileName($saveFileTempName)
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
    logging("save() begin")
    
    lastUpdateTimes = {}
    selectTypes.each do |type|
      lastUpdateTimes[type] = 0;
    end
    logging("dummy lastUpdateTimes created")
    
    saveDataAll = {}
    getCurrentSaveData(lastUpdateTimes) do |targetSaveData, saveFileTypeName|
      saveDataAll[saveFileTypeName] = targetSaveData
      logging(saveFileTypeName, "saveFileTypeName in save")
    end
    
    if( isAddPlayRoomInfo )
      trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)
      lastUpdateTimes[$playRoomInfoTypeName] = 0;
      if( isSaveFileChanged(0, trueSaveFileName) )
        saveDataAll[$playRoomInfoTypeName] = loadSaveFile($playRoomInfoTypeName, trueSaveFileName, lastUpdateTimes)
      end
    end
    
    logging(saveDataAll, "saveDataAll tmp")
    
    result = {}
    
    if( saveDataAll.empty? )
      return result
    end
    
    
    saveFileName = getNewSaveFileName(extension)
    
    deleteOldSaveFile
    
    saveData = {}
    saveData['saveDataAll'] = saveDataAll
    text = getTextFromJsonData(saveData)
    
    createSaveFile(saveFileName, text)
    
    result["saveFileName"] = saveFileName
    logging(result, "save result")
    
    logging("save() end")
    
    return result
  end
  
  #override
  def fileJoin(*parts)
    File.join(*parts)
  end
  
  def getNewSaveFileName(extension)
    now = Time.now
    saveFileName = now.strftime("DodontoF_%Y_%m%d_%H%M%S_#{now.usec}.#{extension}")
    return fileJoin($saveDataTempDir, saveFileName)
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
    
    logging("isPasswordLocked", isPasswordLocked);
    
    #ダイスボットの情報読み出し
    require 'diceBotInfos'
    
    
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
      'diceBotInfos' => $diceBotInfos,
    }
    
    return result
  end
  
  def loginPassword()
    loginData = getRequestDataJsonData('loginData')
    logging(loginData, 'loginData')
    
    roomNumber = loginData['roomNumber']
    logging(roomNumber, 'roomNumber')
    password = loginData['password']
    visiterMode = loginData['visiterMode']
    
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
        "fileName"=>fileNameOriginal,
        "fileUploadUrl"=>fileUploadUrl,
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
  
  
  def uploadFileBase(fileUploadDir, fileMaxSize, isReplayData = false)
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
      fileName = getNewFileName(fileNameOriginal)
      fileNameFullPath = fileJoin(fileUploadDir, fileName).untaint
      logging(fileNameFullPath, "fileNameFullPath")
      
      yield(fileNameFullPath, fileNameOriginal, result)
      
      open(fileNameFullPath, "w+") do |file|
        file.binmode
        file.write(fileIO.read)
      end
      
      result["resultText"] = "OK"
    rescue => e
      logging(e, "error")
      result["resultText"] = e.to_s
    end
    
    logging(result, "load result")
    logging("uploadFile() End")
    
    return result
  end
  
  
  def load()
    logging("saveData load() Begin")
    
    fileIO = getRequestData('Filedata')
    logging(fileIO, 'fileIO')
    
    jsonDataString = fileIO.read
    logging(jsonDataString, 'jsonDataString')
    
    loadFromJsonDataString(jsonDataString)
  end
  
  def loadFromJsonDataString(jsonDataString)
    jsonData = getJsonDataFromText(jsonDataString)
    logging(jsonData, 'jsonData')
    saveDataAll = jsonData['saveDataAll']
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
    logging(result, "load result")
    
    return result
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
  
  def removeAllCharacters
    logging("removeAllCharacters")
    
    isRemoveTarget = true
    isGotoGraveyard = false
    removeCharacters{|i| [isRemoveTarget, isGotoGraveyard] }
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
    extName = ""
    if( /\.(.+)$/ =~ fileName )
      extName = $1
    end
    logging(extName, "extName")
    
    result = preFix + Time.now.to_f.to_s + "_" + @newFileNameIndex.to_s + "." + extName
    
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
      deleteResult = (deleteResult1 and deleteResult2)
      
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
    logging("getGraveyardInfo start.")
    result = []
    
    getSaveData(@saveFiles['characters']) do |saveData|
      graveyard = saveData['graveyard']
      graveyard ||= []
      
      result = graveyard.reverse;
    end
    
    return result;
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
    
    imageList.delete_if{|i| (/\.txt$/===i)}
    imageList.delete_if{|i| (/\.lock$/===i)}
    imageList.delete_if{|i| (/\.json$/===i)}
    imageList.delete_if{|i| (/\.json~$/===i)}
    imageList.delete_if{|i| (/^.svn$/===i)}
    imageList.delete_if{|i| (/.db$/===i)}
    imageList.sort!
    
    return imageList
  end
  
  def deleteOldChatMessageData(chatMessageDataLog)
    now = Time.now.to_f
    
    chatMessageDataLog.delete_if do |chatMessageData|
      writtenTime, chatMessage, *dummy = chatMessageData
      timeDiff = now - writtenTime
      
      ( timeDiff > ($oldMessageTimeout) )
    end
  end
  
  def sendChatMessageMany
    100.times{ sendChatMessage }
  end
  
  def sendChatMessage
    chatMessageData = nil
    
    changeSaveData(@saveFiles['chatMessageDataLog']) do |saveData|
      
      jsonData = getRequestData('chatMessageData')
      logging(jsonData, "jsonData")
      chatMessageData = getJsonDataFromText(jsonData)
      logging(chatMessageData, "chatMessageData")
      
      chatMessageDataLog = saveData['chatMessageDataLog']
      chatMessageDataLog ||= []
      
      deleteOldChatMessageData(chatMessageDataLog);
      
      now = Time.now.to_f
      chatMessageData = [now, chatMessageData]
      
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
  
  def saveAllChatMessage(chatMessageData)
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
      return nil if( tagInfo.nil? )
      
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
      characters = saveData['characters']
      
      characterDataList.each do |characterData|
        logging(characterData, "characterData")
        
        characterData['imgId'] = createCharacterImgId()
        
        failedName = isAlreadyExistCharacter?(characters, characterData)
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
  
  def changeCharacterData
    changeSaveData(@saveFiles['characters']) do |saveData|
      logging("changeCharacterData called")
      
      jsCharacterData = getRequestData('characterData')
      characterData = getJsonDataFromText(jsCharacterData)
      logging(characterData.inspect, "characterData")
      
      characters = saveData['characters']
      
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
      characters = saveData['characters']
      logging(characters, "addCardZone characters")
      
      cardData = getCardZoneData(owner, ownerName, x, y)
      characters << cardData
    end
    
    logging("addCardZone End");
  end
  
  
  def initCards
    logging("initCards Begin");
    
    clearCharacterByTypeLocal(getCardType)
    clearCharacterByTypeLocal(getCardMountType)
    clearCharacterByTypeLocal(getRandomDungeonCardMountType)
    clearCharacterByTypeLocal(getCardZoneType)
    clearCharacterByTypeLocal(getCardTrushMountType)
    clearCharacterByTypeLocal(getRandomDungeonCardTrushMountType)
    
    jsData = getRequestData('initCardsData')
    initCardData = getJsonDataFromText(jsData)
    cardTypeInfos = initCardData['cardTypeInfos']
    logging(cardTypeInfos, "cardTypeInfos")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      saveData['cardTrushMount'] = {}
      
      saveData['cardMount'] = {}
      cardMounts = saveData['cardMount']
      
      characters = saveData['characters']
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
        
        cardMountData = createCardMountData(cardMounts, isText, imageNameBack, mountName, index, isUpDown, cardTypeInfo, cardsList.length)
        characters << cardMountData
        
        cardTrushMountData = getCardTrushMountData(isText, mountName, index, cardTypeInfo)
        characters << cardTrushMountData
      end
    end
    
    logging("initCards End");
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
      
      characters = saveData['characters']
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
  
  
  def createCardMountData(cardMount, isText, imageNameBack, mountName, index, isUpDown, cardTypeInfo, allCardCount)
    cardMountData = getCardData(isText, imageNameBack, imageNameBack, mountName)
    
    cardMountData['type'] = getCardMountType
    setCardCountAndBackImage(cardMountData, cardMount[mountName]);
    cardMountData['mountName'] = mountName
    cardMountData['isUpDown'] = isUpDown
    cardMountData['x'] = 30 + index * 150
    cardMountData['y'] = 30;
    
    if( isRandomDungeonTrump(cardTypeInfo) )
      cardCount = cardTypeInfo['cardCount']
      cardMountData['type'] = getRandomDungeonCardMountType
      cardMountData['cardCountDisplayDiff'] = allCardCount - cardCount
      cardMountData['useCount'] = cardCount
      cardMountData['aceList'] = cardTypeInfo['aceList']
    end
    
    return cardMountData
  end
  
  def isRandomDungeonTrump(cardTypeInfo)
    ( cardTypeInfo['mountName'] == 'randomDungeonTrump' )
  end
  
  def getCardTrushMountData(isText, mountName, index, cardTypeInfo)
    cardTitle = $card.getCardTitleName(mountName);
    trushPrintName = "<font size=\"40\">#{cardTitle}用<br>カード捨て場</font>"
    
    isText = true
    
    cardTrushMountData = getCardData(isText, trushPrintName, trushPrintName, mountName)
    
    cardTrushMountData['type'] = 
      if( isRandomDungeonTrump(cardTypeInfo) )
        getRandomDungeonCardTrushMountType
      else
        getCardTrushMountType
      end
      
    cardTrushMountData['cardCount'] = 0
    cardTrushMountData['mountName'] = mountName
    cardTrushMountData['x'] = 30 + index * 150
    cardTrushMountData['y'] = 230;
    
    return cardTrushMountData
  end
  
  
  def returnCard
    logging("returnCard Begin");
    
    jsData = getRequestData('data')
    params = getJsonDataFromText(jsData)
    
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
      
      characters = saveData['characters']
      characters.push( cardData )
      
      trushMountData = findCardData( characters, params['imgId'] )
      logging(trushMountData, "returnCard trushMountData")
      
      return if( trushMountData.nil?) 
      
      trushMountData['cardCount'] = trushCards.size
    end
    
    logging("returnCard End");
  end
  
  def drawCard
    logging("drawCard Begin")
    
    jsData = getRequestData('drawCardData')
    drawCardData = getJsonDataFromText(jsData)
    logging(drawCardData, 'drawCardData')
    
    mountName = drawCardData['mountName']
    logging(mountName, 'mountName')
    
    result = {
      "result" => "NG"
    }
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardMount = saveData['cardMount']
      cardMount ||= {}
      
      cards = cardMount[mountName]
      cards ||= []
      
      cardMountData = findCardMountData(saveData, drawCardData['imgId'])
      return if( cardMountData.nil? )
      
      cardCountDisplayDiff = cardMountData['cardCountDisplayDiff']
      unless( cardCountDisplayDiff.nil? )
        return if( cardCountDisplayDiff >= cards.length )
      end
      
      cardData = cards.pop
      if( cardData.nil? )
        return
      end
      
      cardData['x'] = drawCardData['x']
      cardData['y'] = drawCardData['y']
      
      isOpen = drawCardData['isOpen']
      cardData['isOpen'] = isOpen
      cardData['isBack'] = false
      cardData['owner'] = drawCardData['owner']
      cardData['ownerName'] = drawCardData['ownerName']
      
      saveData['characters'] ||= []
      characters = saveData['characters']
      characters << cardData
      
      logging(cards.size, 'cardMount[mountName].size')
      setCardCountAndBackImage(cardMountData, cards)
      
      result["result"] = "OK"
    end
    
    logging("drawCard End")
    
    return result
  end
  

  def drawTargetCard
    logging("drawTargetCard Begin")
    
    jsData = getRequestData('data')
    data = getJsonDataFromText(jsData)
    logging(data, 'data')
    
    mountName = data['mountName']
    logging(mountName, 'mountName')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardMount = saveData['cardMount']
      cardMount ||= {}
      
      cards = cardMount[mountName]
      cards ||= []
      
      
      cardData = cards.find{|i| i['imgId'] === data['targetCardId'] }
      
      if( cardData.nil? )
        logging(data['targetCardId'], "not found data['targetCardId']")
        return
      end
      
      cards.delete(cardData)
      
      cardData['x'] = data['x']
      cardData['y'] = data['y']
      
      cardData['isOpen'] = false
      cardData['isBack'] = false
      cardData['owner'] = data['owner']
      cardData['ownerName'] = data['ownerName']
      
      saveData['characters'] ||= []
      characters = saveData['characters']
      characters << cardData
      
      cardMountData = findCardMountData(saveData, data['mountId'])
      if( cardMountData.nil?) 
        logging(data['mountId'], "not found data['mountId']")
        return
      end
      
      logging(cards.size, 'cardMount[mountName].size')
      setCardCountAndBackImage(cardMountData, cards)
    end
    
    logging("drawTargetCard End")
    
    result = {
      "result" => "OK"
    }
    
    return result
  end
  
  def findCardMountData(saveData, mountId)
    characters = saveData['characters']
    return nil if( characters.nil? )
    
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
    
    jsData = getRequestData('data')
    dumpTrushCardsData = getJsonDataFromText(jsData)
    logging(dumpTrushCardsData, 'dumpTrushCardsData')
    
    mountName = dumpTrushCardsData['mountName']
    logging(mountName, 'mountName')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
      characters = saveData['characters']
      
      dumpedCardId = dumpTrushCardsData['dumpedCardId']
      logging( dumpedCardId, "dumpedCardId")
      
      logging(characters.size, "characters.size before")
      cardData = deleteFindOne(characters) {|i| i['imgId'] === dumpedCardId }
      trushCards << cardData
      logging(characters.size, "characters.size after")
      
      trushMountCharacter = characters.find{|i| i['imgId'] === dumpTrushCardsData['trushMountId'] }
      if( trushMountCharacter.nil?) 
        return
      end
      
      logging(trushMount, 'trushMount')
      logging(mountName, 'mountName')
      logging(trushMount[mountName], 'trushMount[mountName]')
      logging(trushMount[mountName].size, 'trushMount[mountName].size')
      trushMountCharacter['cardCount'] = trushMount[mountName].size
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
    
    jsData = getRequestData('data')
    params = getJsonDataFromText(jsData)
    mountName = params['mountName']
    trushMountId = params['mountId']
    isShuffle = params['isShuffle']
    
    logging(mountName, 'mountName')
    logging(trushMountId, 'trushMountId')
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      trushMount, trushCards = findTrushMountAndTrushCards(saveData, mountName)
      
      saveData['cardMount'] ||= {}
      cardMount = saveData['cardMount']
      cardMount[mountName] ||= []
      mountCards = cardMount[mountName]
      
      while( trushCards.size > 0 )
        cardData = trushCards.pop
        initTrushCardForReturnMount(cardData)
        mountCards << cardData
      end
      
      characters = saveData['characters']
      
      trushMountData = findCardData( characters, trushMountId )
      return if( trushMountData.nil?) 
      trushMountData['cardCount'] = trushCards.size
      
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
      
      characters = saveData['characters']
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
      trushMountData['cardCount'] = trushCards.size
      
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
    jsData = getRequestData('data')
    requestData = getJsonDataFromText(jsData)
    logging(requestData, 'getMountCardInfos requestData')
    
    mountName = requestData['mountName']
    mountId = requestData['mountId']
    
    cards = []
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      cardMount = saveData['cardMount']
      cardMount ||= {}
      
      cards = cardMount[mountName]
      cards ||= []
      
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
  
  
  def clearCharacterByType
    jsData = getRequestData('clearData')
    clearData = getJsonDataFromText(jsData)
    logging(clearData, 'clearData')
    
    targetTypes = clearData['types']
    logging(targetTypes, 'targetTypes')
    
    targetTypes.each do |targetType|
      clearCharacterByTypeLocal(targetType)
    end
  end
  
  def clearCharacterByTypeLocal(targetType)
    logging(targetType, "clearCharacterByTypeLocal targetType")
    
    changeSaveData(@saveFiles['characters']) do |saveData|
      characters = saveData['characters']
      
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
      characters = saveData['characters']
      
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
  

  def resurrectCharacter
    changeSaveData(@saveFiles['characters']) do |saveData|
      
      jsResurrectCharacterData = getRequestData('resurrectCharacterData')
      resurrectCharacterData = getJsonDataFromText(jsResurrectCharacterData)
      logging(resurrectCharacterData, "resurrectCharacterData")
      
      resurrectCharacterId = resurrectCharacterData['imgId']
      logging(resurrectCharacterId, "resurrectCharacterId")
      
      graveyard = saveData['graveyard']
      graveyard ||= []
      
      index = nil
      graveyard.each_with_index do |i, targetIndex|
        logging(i, "characterData");
        if( i['imgId'] == resurrectCharacterId )
          index = targetIndex
        end
      end
      
      logging(index, "resurrected index:")
      
      if( index )
        characterData = graveyard.delete_at(index)
        logging(characterData, "resurrectedCharacterData");
        
        saveData['characters'] ||= []
        characters = saveData['characters']
        characters << characterData
      end
    end
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

      jsCharacterData = getRequestData('characterData')
      characterMoveData = getJsonDataFromText(jsCharacterData)
      logging(characterMoveData, "moveCharacter() characterMoveData")
      
      logging(characterMoveData['imgId'], "character.imgId")
      
      characters = saveData['characters']
      
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
    jsonDataForResponse = analyzeCommand
    #escapeHtmlDataFromJson(jsonDataForResponse)
    
    return getTextFromJsonData(jsonDataForResponse)
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


def isGzipTarget(result)
  return false if( $gzipTargetSize <= 0)
  
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


def main()
  cgi = CGI.new
  server = DodontoFServer.new(SaveDirInfo.new(), cgi, cgi.content_type)
  printResult(server)
end

def getInitializedHeaderText()
  header = ""
  
  unless( $isModRuby )
    header << "Content-Type: text/plain; charset=utf-8\n"
  end
  
  return header
end

def printResult(server)
  logging("========================================>CGI begin.")
  
  text = "empty"
  header = "empty";
  begin
    result = server.getResponse
    
    result = "#D@EM>#" + result + "#<D@EM#";
    logging(result.length.to_s, "CGI response original length")
    
    if ( isGzipTarget(result) )
      header = getInitializedHeaderText()
      
      if( $isModRuby )
        Apache.request.content_encoding = 'gzip'
      else
        header << "Content-Encoding: gzip\n"
      end
      
      text = getGzipResult(result)
    else
      header = getInitializedHeaderText()
      text = result
    end
  rescue => e
    errorMessage = getErrorResponseText(e)
    loggingForce(errorMessage, "errorMessage")
    
    header = getInitializedHeaderText()
    text = "\n= ERROR ====================\n"
    text << errorMessage
    text << "============================\n"
  end
  
  logging(header, "RESPONSE header")
  
  output = $stdout
  output.binmode if( defined?(output.binmode) )
  unless( header.empty? )
    output.print( header + "\n")
  end
  output.print( text )
  
  logging("========================================>CGI end.")
end



if( $0 === __FILE__ )
  initLog();
  
  case $dbType
  when "mysql"
    #mod_ruby でも再読み込みするようにloadに
    load 'DodontoFServerMySql.rb'
    mainMySql()
  else
    #通常のテキストファイル形式
    main()
  end
  
end

#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby/ruby-mysql"
$LOAD_PATH << File.dirname(__FILE__) + "/src_bcdice"
$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

#CGI通信の主幹クラス用ファイル
#ファイルアップロード系以外は全てこのファイルへ通知が送られます。
#DB(MySQL)から各種データを読み出し・書き出しするのが主な作業。
#変更可能な設定は config.rb にまとめているため、環境設定のためにこのファイルを変更する必要は基本的には無いです。

# どどんとふ名前空間
module DodontoF
  # バージョン
  VERSION = '1.48.32.1'
  # リリース日
  RELEASE_DATE = '2017/11/19'

  # バージョンとリリース日を含む文字列
  #
  # サーバ CGI とクライアント Flash のバージョン一致確認用
  FULL_VERSION_STRING = "Ver.#{VERSION}(#{RELEASE_DATE})"
end

if( RUBY_VERSION >= '1.9.0' )
  Encoding.default_external = 'utf-8'
else
  require 'jcode'
end

require 'kconv'
require 'cgi'
require 'stringio'
require 'uri'
require 'fileutils'
require 'json/jsonParser'

require 'mysql'

require 'dodontof/logger'
require 'dodontof/utils'
require 'dodontof/dice_adapter'

require 'dodontof_mysqlkai/play_room'
require 'dodontof_mysqlkai/image'

# require "configMysqlKai.rb"
require "config.rb"

begin
  require "config_local.rb"
rescue Exception
end

if $isTestMode
  require "config_test.rb"
end


require "FileLock.rb"
require "saveDirInfoMysql.rb"

require 'dodontof/msgpack_loader'


$saveFileNames = File.join($saveDataTempDir, 'saveFileNames.json');

$tableNames = {
  'chatMessageDataLog' => 'chats',
  'map' => 'maps',
  'characters' => 'characters',
  'time' => 'times',
  'effects' => 'effects',
  'playRoomInfo' => "rooms",
};

$diceBotTableSaveKey = "diceBotTable"

# characterStateList
# state => 0:delete, 1:nomal, 2:graveyard, 3:waitingRoom, 4:cardMount, 5:cardTrushMount

$characterStateDeleted = 0
$characterStateNomal = 1
$characterStateGraveyard = 2
$characterStateWaitingRoom = 3
$characterStateCardMount= 4
$characterStateCardTrushMount= 5


class Mysql::Stmt
  def hasResult
    (not @result.nil?)
  end
end

class DodontoFServer_MySqlKai
  include DodontoF::Utils

  def self.getMessagePackFromData(data)
    logger = DodontoF::Logger.instance

    logger.debug("getMessagePackFromData Begin")

    messagePack = {}

    if( data.nil? )
      logger.debug("data is nil")
      return messagePack 
    end

    begin
      messagePack = MessagePack.unpack(data)
    rescue Exception => e
      logger.error("getMessagePackFromData Exception rescue")
      logger.exception(e)
    end

    logger.debug(messagePack, "messagePack")

    if( isWebIfMessagePack(messagePack) )
      logger.debug(data, "data is webif.")
      messagePack = parseWebIfMessageData(data)
    end

    logger.debug(messagePack, "getMessagePackFromData End messagePack")

    return messagePack
  end

  def self.isWebIfMessagePack(messagePack)
    logger = DodontoF::Logger.instance

    logger.debug(messagePack, "isWebif messagePack")

    unless( messagePack.kind_of?(Hash) )
      logger.debug("messagePack is NOT Hash")
      return true
    end

    return false
  end

  def self.parseWebIfMessageData(data)
    logger = DodontoF::Logger.instance

    params = CGI.parse(data)
    logger.debug(params, "params")

    messagePack = {}
    params.each do |key, value|
      messagePack[key] = value.first
    end

    return messagePack
  end

  # セーブデータディレクトリの情報
  # @return [SaveDirInfo]
  attr_reader :saveDirInfo

  def initialize(saveDirInfo, cgiParams)
    @cgiParams = cgiParams
    @saveDirInfo = saveDirInfo

    @logger = DodontoF::Logger.instance
    @cgi = nil

    @jsonpCallBack = nil
    @isWebIf = false

    initSaveFiles(getRequestData('room'))
    @dice_adapter = DodontoF::DiceAdapter.new(getDiceBotExtraTableDirName, 'diceBotTable_')

    @fullBackupFileBaseName = "DodontoFFullBackup"

    @allSaveDataFileExt = '.tar.gz'
    @defaultAllSaveData = 'default.sav'
    @defaultChatPallete = 'default.cpd'

    @card = nil
  end
  
  def initSaveFiles(roomNumber)
    @saveDirInfo.init(roomNumber, $saveDataMaxCount, $SAVE_DATA_DIR)
  end

  # CGI のクエリ文字列から指定したキーの値を取得する
  # @param [String] key キー
  # @return [String] キーが存在する場合
  # @return [nil] キーが存在しない場合
  def getRawCGIValue(key)
    @cgi = CGI.new if @cgi.nil?

    # CGI#params[] では配列または nil が返るため、キーが含まれているか
    # どうかのチェックが必要
    if @cgi.params.key?(key)
      @cgi.params[key].first
    else
      nil
    end
  end

  # 指定したキーの値を返す
  #
  # Web インターフェースの場合はクエリ文字列からの値の取得を試みる
  # @param [String] key キー
  # @return [Object]
  # @return [nil]
  def getRequestData(key)
    @logger.debug(key, "getRequestData key")

    valueFromCgiParams = @cgiParams[key]
    @logger.debug(@cgiParams, "@cgiParams")
    @logger.debug(valueFromCgiParams, "getRequestData valueFromCgiParams")

    unless valueFromCgiParams.nil?
      @logger.debug(valueFromCgiParams, "getRequestData result cgiParams")
      return valueFromCgiParams
    end

    return nil unless @isWebIf

    # Web インターフェースの場合
    valueWebIf = getRawCGIValue(key)

    @logger.debug(valueWebIf, "getRequestData result WebIF")
    return valueWebIf
  end

  attr :jsonpCallBack
  
  def getCardsInfo
    require "card.rb"
    
    return @card unless( @card.nil? )
    
    @card = Card.new(@logger);
    
    
    return @card
  end
  
  def getSaveFileLockReadOnly(saveFileName)
    getSaveFileLock(saveFileName, true)
  end
  
  def getSaveFileLockReadOnlyRealFile(saveFileName)
    getSaveFileLockRealFile(saveFileName, true)
  end

  def getLockFileName(saveFileName)
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
      lockFileName = getLockFileName(saveFileName)
      return FileLock.new(lockFileName);
      #return FileLock2.new(saveFileName + ".lock", isReadOnly)
    rescue => e
      @logger.error(@saveDirInfo, "when getSaveFileLock error : @saveDirInfo");
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
  
  
  def getSaveData(saveFileName)
    isReadOnly = true
    saveFileLock = getSaveFileLock(saveFileName, isReadOnly)
    
    text = nil
    saveFileLock.lock do
      text = getSaveTextOnFileLocked(saveFileName)
    end
    
    saveData = getObjectFromJsonString(text)
    yield(saveData)
  end
  
  def changeSaveData(saveFileName)
    
    saveFileLock = getSaveFileLock(saveFileName)
    
    saveFileLock.lock do
      saveDataText = getSaveTextOnFileLocked(saveFileName)
      saveData = getObjectFromJsonString(saveDataText)
      
      yield(saveData)
      
      saveDataText = getJsonString(saveData)
      createFile(saveFileName, saveDataText)
    end
  end
  
  
  
  def getCommandSender
    if( @commandSender.nil? )
      @commandSender = getRequestData('own')
    end
    
    @logger.debug(@commandSender, "@commandSender")
    
    return @commandSender
  end
  
  
  def createSaveFile(saveFileName, text)
    @logger.debug(saveFileName, 'createSaveFile saveFileName')
    existFiles = nil
    
    @logger.debug($saveFileNames, "$saveFileNames")
    changeSaveData($saveFileNames) do |saveData|
      existFiles = saveData["fileNames"]
      existFiles ||= []
      @logger.debug(existFiles, 'pre existFiles')
      
      unless( existFiles.include?(saveFileName) ) 
        existFiles << saveFileName
      end
      
      createFile(saveFileName, text)
      
      saveData["fileNames"] = existFiles
    end
    
    @logger.debug(existFiles, 'createSaveFile existFiles')
  end
  
  #override
  def createFile(saveFileName, text)
    begin
      File.open(saveFileName, "w+") do |file|
        file.write(text.toutf8)
      end
    rescue => e
      @logger.exception(e)
      raise e
    end
  end
  
  def getMessagePackFromData(data)
    self.class.getMessagePackFromData(data)
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

    @logger.debug(commandName, "commandName")

    if( commandName.nil? or commandName.empty? )
      return getResponseTextWhenNoCommandName
    end

    commands = {
      'refresh' => :hasReturn,

      'getGraveyardCharacterData' => :hasReturn,
      'resurrectCharacter' => :hasReturn,
      'clearGraveyard' => :hasReturn,
      'getLoginInfo' => :hasReturn,
      'getPlayRoomStates' => :hasReturn,
      'deleteImage' => :hasReturn,
      'uploadImageUrl' => :hasReturn,
      'save' => :hasReturn,
      'saveMap' => :hasReturn,
      'saveAllData' => :hasReturn,
      'load' => :hasReturn,
      'loadAllSaveData' => :hasReturn,
      'getDiceBotInfos' => :hasReturn,
      'getBotTableInfos' => :hasReturn,
      'addBotTable' => :hasReturn,
      'changeBotTable' => :hasReturn,
      'removeBotTable' => :hasReturn,
      'requestReplayDataList' => :hasReturn,
      'uploadReplayData' => :hasReturn,
      'removeReplayData' => :hasReturn,
      'checkRoomStatus' => :hasReturn,
      'loginPassword' => :hasReturn,
      'uploadFile' => :hasReturn,
      'uploadImageData' => :hasReturn,
      'createPlayRoom' => :hasReturn,
      'changePlayRoom' => :hasReturn,
      'removePlayRoom' => :hasReturn,
      'removeOldPlayRoom' => :hasReturn,
      'getImageTagsAndImageList' => :hasReturn,
      'addCharacter' => :hasReturn,
      'getWaitingRoomInfo' => :hasReturn,
      'exitWaitingRoomCharacter' => :hasReturn,
      'enterWaitingRoomCharacter' => :hasReturn,
      'sendDiceBotChatMessage' => :hasReturn,
      'deleteChatLog' => :hasReturn,
      'sendChatMessageAll' => :hasReturn,
      'undoDrawOnMap' => :hasReturn,

      'logout' => :hasNoReturn,
      'changeCharacter' => :hasNoReturn,
      'removeCharacter' => :hasNoReturn,

      # Card Command Get
      'getMountCardInfos' => :hasReturn,
      'getTrushMountCardInfos' => :hasReturn,
      'getCardList' => :hasReturn,

      # Card Command Set
      'drawTargetCard' => :hasReturn,
      'drawTargetTrushCard' => :hasReturn,
      'drawCard' => :hasReturn,
      'addCard' => :hasNoReturn,
      'addCardZone' => :hasNoReturn,
      'initCards' => :hasReturn,
      'returnCard' => :hasNoReturn,
      'shuffleCards' => :hasNoReturn,
      'shuffleForNextRandomDungeon' => :hasNoReturn,
      'dumpTrushCards' => :hasNoReturn,

      'clearCharacterByType' => :hasNoReturn,
      'moveCharacter' => :hasNoReturn,
      'changeMap' => :hasNoReturn,
      'drawOnMap' => :hasNoReturn,
      'clearDrawOnMap' => :hasNoReturn,
      'sendChatMessage' => :hasNoReturn,
      'changeRoundTime' => :hasNoReturn,
      'addResource' => :hasNoReturn,
      'changeResource' => :hasNoReturn,
      'changeResourcesAll' => :hasNoReturn,
      'removeResource' => :hasNoReturn,
      'addEffect' => :hasNoReturn,
      'changeEffect' => :hasNoReturn,
      'changeEffectsAll' => :hasNoReturn,
      'removeEffect' => :hasNoReturn,
      'changeImageTags' => :hasNoReturn,

      'dropAllDb' => :hasNoReturn,
    }

    commandType = commands[commandName]
    @logger.debug(commandType, "commandType")

    begin
      case commandType
      when :hasReturn
        return self.send( commandName )
      when :hasNoReturn
        self.send( commandName )
        return nil
      else
        throw Exception.new("\"" + commandName.untaint + "\" is invalid command")
      end
    ensure
      begin
        @db.close unless( @db.nil? )
      rescue Exception
        # @logger.error("close Exception")
        # @logger.exception(e)
      end
    end
  end

  def getResponseTextWhenNoCommandName
    @logger.debug("getResponseTextWhenNoCommandName Begin")
    
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
      @logger.debug("analyzeWebInterfaceCatched end result", result)
      setJsonpCallBack
    rescue => e
      result['result'] = e.to_s
    end
    
    return result
  end
  
  def analyzeWebInterfaceCatched
    @logger.debug("analyzeWebInterfaceCatched begin")
    
    @isWebIf = true
    
    commandName = getRequestData('webif')
    @logger.debug(commandName, 'commandName')
    
    if( isInvalidRequestParam(commandName) )
      return nil
    end
    
    @logger.debug(commandName, "commandName")
    
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
    when 'addMessageCard'
      sendWebIfAddMessageCard
    when 'changeCharacter'
      sendWebIfChangeCharacter
    when 'addMemo'
      sendWebIfAddMemo
    when 'changeMemo'
      sendWebIfChangeMemo
    when 'setRoomInfo'
      setWebIfRoomInfo
    when 'uploadImageData'
      uploadImageDataWebIf
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
    
    @logger.debug('callBack', callBack)
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
    return "「どどんとふ(MySQL-Kai)」の動作環境は正常に起動しています。"
  end
  
  def getCurrentSaveData()
    if @getCurrentSaveDataMethods.nil?
      @getCurrentSaveDataMethods = {
        'chatMessageDataLog' => method(:getCurrentSaveDataForDbChat),
        "characters" => method(:getCurrentSaveDataForDbCharacter),
        "map" => method(:getCurrentSaveDataForDbMap),
        "time" => method(:getCurrentSaveDataForDbTime),
        "effects" => method(:getCurrentSaveDataForDbEffects),
        "playRoomInfo" => method(:getCurrentSaveDataForDbPlayRoom),
      }
    end
    
    $tableNames.each do |saveFileTypeName, dummy|
      @logger.debug(saveFileTypeName, "saveFileTypeName")
      
      func = @getCurrentSaveDataMethods[saveFileTypeName]
      
      next if func.nil?
      
      func.call do |targetSaveData|
        yield(targetSaveData, saveFileTypeName)
      end
    end
  end
  
  
  
  def getCurrentSaveDataForDbCharacter()
    @logger.debug("getCurrentSaveDataForDbCharacter Begin")
    
    update_index = @lastUpdateTimes['characters']
    @logger.debug(update_index, "characters update_index")
    
    lastTime = getLastUpdate('characters', update_index)
    @logger.debug(lastTime, "lastTime")
    
    # 最終更新が0の場合は結果が空の証拠なので取得無し
    if lastTime == 0
      @logger.debug("characters has NO change")
      return 
    end
    
    result = getAllCharacters()
    @logger.debug(result.size, "characters get result.size")
    @logger.debug(result, "characters get result")
    
    @logger.debug("New characters.")
    
    saveData = {}
    result.each do |row|
      saveData["characters"] ||= []
      saveData["characters"] << row["json"] # getObjectFromJsonString( row["json"] )
    end
    
    @lastUpdateTimes['characters'] = lastTime
    
    yield(saveData)
    
    @logger.debug("getCurrentSaveDataForDbCharacter End")
  end
  
  def getLastUpdate(tableName, update_index)
    lastUpdateResult = readDb( "SELECT MAX(update_index)",
                               :from => tableName,
                               :where => {'update_index > ? ' => update_index} )
    
    lastTime = lastUpdateResult.first['MAX(update_index)'].to_i
    @logger.debug(lastTime, "lastTime")
    return lastTime
  end
  
  
  
  def getAllCharacters(state = $characterStateNomal,
                       isOrderByUpdate = false)
    order = isOrderByUpdate ? " ORDER BY update_index" : ""
    result = readDb( "SELECT *",
                     :from => 'characters',
                     :where => {'state = ? ' => state},
                     :others => [order] )
    shapeUpDbResult(result)
  end
  
  
  def getCurrentSaveDataForDbChat()
    @logger.debug("getCurrentSaveDataForDbChat Begin")
    
    lastId = @lastUpdateTimes['chatMessageDataLog']
    
    result = readDb( "SELECT *",
                     :from => 'chats',
                     :where => {'id > ? ' => lastId} )
    @logger.debug(result, "chats get result")
    
    return if result.empty?
    
    @logger.debug("New chats message.")
    
    shapeUpDbResult(result)
    
    saveData = {}
    result.each do |row|
      time = row.delete('created_at')
      row['color'] = row['color'].to_s(16)
      saveData['chatMessageDataLog'] ||= []
      saveData['chatMessageDataLog'] << [time, row]
    end
    
    @lastUpdateTimes['chatMessageDataLog'] = result.last['id']
    
    yield(saveData)
    
    @logger.debug(saveData, "getCurrentSaveDataForDbChat saveData")
    @logger.debug("getCurrentSaveDataForDbChat End")
  end
  
  
  def getCurrentSaveDataForDbMap()
    @logger.debug("getCurrentSaveDataForDbMap Begin")
    
    getCurrentSaveDataForDbJsonType('map', 'maps') do |data|
      saveData = {}
      saveData['mapData'] = data
      yield(saveData)
    end
    
    @logger.debug("getCurrentSaveDataForDbMap End")
  end
  
  
  def getCurrentSaveDataForDbTime()
    @logger.debug("getCurrentSaveDataForDbTime Begin")
    
    getCurrentSaveDataForDbJsonType('time', 'times') do |data|
      saveData = {}
      saveData['roundTimeData'] = data['roundTimeData']
      yield(saveData)
    end
    
    @logger.debug("getCurrentSaveDataForDbTime End")
  end
  
  
  def getCurrentSaveDataForDbEffects()
    @logger.debug("getCurrentSaveDataForDbEffects Begin")
    
    getCurrentSaveDataForDbJsonType('effects', 'effects') do |data|
      saveData = {}
      saveData['effects'] = data['effects']
      yield(saveData)
    end
    
    @logger.debug("getCurrentSaveDataForDbTime End")
  end
  
  
  def getCurrentSaveDataForDbPlayRoom()
    @logger.debug("getCurrentSaveDataForDbPlayRoom Begin")
    
    getCurrentSaveDataForDbJsonType('playRoomInfo', 'rooms') do |data|
      @logger.debug(data, 'getCurrentSaveDataForDbPlayRoom data')
      
      saveData = data
      yield(saveData)
    end
    
    @logger.debug("getCurrentSaveDataForDbPlayRoom End")
  end
  
  
  def getCurrentSaveDataForDbJsonType(type, tableName)
    roomNo = getRoomNo()
    
    func = Proc.new do |lastTime|
      readDb( "SELECT *",
              :from => tableName,
              :where => {"update_index > ? " => lastTime, 
                "roomNo = ? " => roomNo })
      
    end
    
    getCurrentSaveDataForDbJsonTypeCommon(type, tableName, func) do |data|
      yield(data)
    end
  end
  
  
  def getCurrentSaveDataForDbJsonTypeCommon(type, tableName, func)
    lastTime = @lastUpdateTimes[type]
    
    result = func.call(lastTime)
    shapeUpDbResult(result)
    
    row = result.first
    return if row.nil?
    
    time = row.delete('update_index')
    data = getObjectFromJsonString( row["json"] )
    
    yield(data)
    
    @lastUpdateTimes[type] = time
  end
  
  
  def getPlayRoomData()
    data = getDbJsonData('rooms')
    return data
  end
  
  def getPlayRoomDataList(minRoom, maxRoom)
    result = readDb( "SELECT roomNo, json ",
                     :from => 'rooms',
                     :where => {
                       "roomNo >= ? " => minRoom,
                       "roomNo <= ? " => maxRoom})
    shapeUpDbResult(result)
    
    list = {}
    result.each do |row|
      roomNo = row['roomNo'].to_i
      list[roomNo] = getObjectFromJsonString( row["json"] )
    end
    
    return list
  end
  
  
  def getDbJsonData(tableName)
    roomNo = getRoomNo
    result = readDb( "SELECT *",
                     :from => tableName,
                     :where => {"roomNo = ? " => roomNo})
    shapeUpDbResult(result)
    
    row = result.first
    return {} if row.nil?
    
    data = getObjectFromJsonString( row["json"] )
    data ||= {}

    return data
  end
  
  def getRoomNo()
    @saveDirInfo.getSaveDataDirIndex
  end

  
  
  def readDb(command, options = {})
    connectDb
    
    from = getFromDbOptions(options)
    where, params = getWhereDbOptions(options)
    others = getOtherDbOptions(options)
    
    commandText = "#{command} #{from} #{where} #{others}"
    @logger.debug(commandText, "readDbCommon commandText")
    
    result = query(commandText, *params)
    
    return result
  end
  
  
  
  def updateDb(options = {})
    connectDb
    
    table = options[:table]
    setData, params = getSetDbOptions(options)
    where, params = getWhereDbOptions(options, params)
    others = getOtherDbOptions(options)
    
    if isHasUpdateIndexTable(table)
      # 更新時に update_index を最大値に変更。これで変更があったかを把握しています。
      commandText = "UPDATE #{table}, (SELECT MAX(update_index) AS update_index_max FROM #{table}) max_ref SET update_index=(max_ref.update_index_max+1), #{setData} #{where} #{others}"
    else
      # update_index が無いテーブルの場合はシンプルなこちらでUPDATE実施。
      commandText = "UPDATE #{table} SET #{setData} #{where} #{others}"
    end
    
    @logger.debug(commandText, "readDbCommon commandText")
    
    result = query(commandText, *params)
    return result
  end
  

  def isHasUpdateIndexTable(table)
    noUpdateIndexTables = ['chats', 'users']
    return ( not noUpdateIndexTables.include?(table) )
  end
  
  
  def query(commandText, *params)
    
    begin
      result = queryCatched(commandText, *params)
    rescue => e
      @logger.exception(e)
      @logger.error([commandText, params].inspect)
      @logger.error("commandText : #{commandText}")
      throw e
    end
    
    return result
  end
  
  def queryCatched(commandText, *params)
    @logger.debug("\n\n" + commandText + "\n", "query commandText")
    @logger.debug(params, "query params")
    
    sqlResult = nil
    
    statement = @db.prepare(commandText)
    sqlResult = statement.execute(*params)
    
    result = []
    return result if sqlResult.nil?
    return result unless sqlResult.hasResult
    
    sqlResult.each_hash do |row|
      result << row
    end
    
    @logger.debug(result, "query end result")
    return result
  end
  
  
  def getFromDbOptions(options)
    from = options[:from]
    return '' if from.nil?
    
    return "FROM #{from}"
  end
  
  
  def getWhereDbOptions(options, values = [])
    text = ''
    
    where = options[:where]
    where ||= {}
    
    unless options[:noRoom]
      if where.keys.find{|i|/^\s*roomNo/ === i}.nil?
        where['roomNo = ? '] = getRoomNo()
      end
    end
    
    if where.empty?
      return text, values
    end
    
    keys = where.keys
    text = 'WHERE ' + keys.join(" and ")
    values += keys.collect{|i| where[i]}
    
    return text, values
  end
  
  def getOtherDbOptions(options)
    others = options[:others]
    return '' if others.nil?
    
    return others.join(" ")
  end
  
  
  def getSetDbOptions(options)
    data = options[:set]
    
    if data.empty?
      return '', [] 
    end
    
    keys = data.keys
    setText = keys.collect{|i| i + "=?"}.join(", ")
    values = keys.collect{|i| data[i]}
    
    return setText, values
  end
    
  
  def connectDb
    return unless @db.nil?
    
    @db = connectDbCommon(@db)
    
    initDb unless isTableExist('rooms')
  end
  
  def connectDbCommon(db)
    @logger.debug("connectDbCommon Begin")
    
    return db unless( db.nil? )
    
    db = Mysql::new($databaseHostName, $databaseUserName, $databasePassword, $databaseName)
    
    @logger.debug("connectDbCommon End")
    return db
  end
  
  def isTableExist(tableName)
    connectDb
    
    result = @db.query("SHOW TABLES FROM #{$databaseName} LIKE '#{tableName}'")
    count = result.num_rows()
    return ( count != 0 )
  end
  
  
  def initDb
    
    @logger.debug("initDb Begin")
    
    dropAllDb()
    
    begin
      initChatDb
      initCharacterDb
      initMapDb
      initTimeDb
      initEffectDb
      initLoginUserDb
      initPlayRoomDb
    rescue => e
      @logger.exception(e)
      throw e
    end
    
    @logger.debug("initDb End")
  end

  def dropAllDb
    %w{chats characters maps times effects users rooms}.each do |target|
      
      @logger.debug("dropAllDb #{target}")
      
      next unless isTableExist(target)
      
      @logger.debug("dropAllDb #{target} DROP EXECUTE!")
      query("DROP TABLE #{target}")
    end
  end

  
  def initChatDb
    tableName = 'chats'
    
    sql = <<SQL_TEXT
CREATE TABLE #{tableName} (
    roomNo      INTEGER  NOT NULL,
    id          INTEGER  PRIMARY KEY AUTO_INCREMENT NOT NULL,
    uniqueId    VARCHAR(255)  NOT NULL,
    senderName  TEXT      NOT NULL,
    message     LONGTEXT  NOT NULL,
    color       INTEGER   NOT NULL,
    channel     INTEGER,
    created_at  DOUBLE(17, 6) );
SQL_TEXT
    
    query(sql)
    
    addIndexToTable(tableName, "roomNo, id")
  end
  
  
  def addIndexToTable(tableName, target)
    query("ALTER TABLE #{tableName} ADD INDEX (#{target})")
  end
  
  
  def addRoomIndexToTable(tableName)
    query("ALTER TABLE #{tableName} ADD INDEX (roomNo)")
  end
  
  
  def initCharacterDb
    
    tableName = 'characters'
    
    sql = <<SQL_TEXT
CREATE TABLE #{tableName} (
    roomNo       INTEGER  NOT NULL,
    id           INTEGER  PRIMARY KEY AUTO_INCREMENT NOT NULL,
    json         LONGTEXT  NOT NULL,
    type         TEXT      NOT NULL,
    state        INTEGER,
    update_index INTEGER);
SQL_TEXT
# about "state", search word => characterStateList
    
    query(sql)
    
    addIndexToTable(tableName, "roomNo, update_index")
    addIndexToTable(tableName, "roomNo, id")
  end
  
  
  def initMapDb
    tableName = 'maps'
    createJsonBaseDb(tableName)
  end
  
  def insertFirstMap
    tableName = 'maps'
    json = '{"yMax":20.0,"mapType":"imageGraphic","imageSource":"./image/defaultImageSet/feeld001.gif","xMax":20.0}'
    insertFirstData(tableName, json)
  end
  
  def createJsonBaseDb(tableName)
    sql = <<SQL_TEXT
CREATE TABLE #{tableName} (
    roomNo       INTEGER  NOT NULL,
    id           INTEGER  PRIMARY KEY AUTO_INCREMENT NOT NULL,
    json         LONGTEXT  NOT NULL,
    update_index INTEGER);
SQL_TEXT
    
    query(sql)
    
    addIndexToTable(tableName, "roomNo, update_index")
  end
  
  
  def initPlayRoomDb
    tableName = 'rooms'
    createRoomJsonBaseDb(tableName)
  end
  
  
  def createRoomJsonBaseDb(tableName)
    sql = <<SQL_TEXT
CREATE TABLE #{tableName} (
    roomNo       INTEGER  PRIMARY KEY NOT NULL,
    json         TEXT  NOT NULL,
    update_index INTEGER);
SQL_TEXT
    
    query(sql)
    
    addRoomIndexToTable(tableName)
  end
  
  
  def insertFirstData(tableName, json)
    roomNo = getRoomNo
    query("INSERT INTO #{tableName} (roomNo, id, json, update_index) VALUES (?, ?, ?, ?)",
          roomNo, nil, json, 1)
  end
  
  
  
  def initTimeDb
    tableName = 'times'
    createJsonBaseDb(tableName)
  end
  
  def insertFirstTime
    tableName = 'times'
    json = '{"_":"あ","roundTimeData":{"initiative":0.0,"round":1.0,"counterNames":["HP", "*転倒"]}}'
    insertFirstData(tableName, json)
  end
  
  
  def initEffectDb
    tableName = 'effects'
    createJsonBaseDb(tableName)
  end
  
  def insertFirstEffect
    tableName = 'effects'
    json = getFirstEffects()
    insertFirstData(tableName, json)
  end
  
  def getFirstEffects()
    '{"effects":[{"position":"center","soundSource":"","isSoundLoop":false,"isEnable":true,"effectId":"1228488734.998","cutInTag":"","mx_internal_uid":"15FFDD34-8CE0-D566-B1D2-554377C7411F","volume":0.1,"height":0,"displaySeconds":0,"source":".\/.\/movie\/shout.flv","message":"驚愕","width":0},{"isTail":true,"effectId":"1228623756.228","mx_internal_uid":"8DE523DC-0945-543A-0167-01934FCDC887","displaySeconds":4,"height":0,"source":".\/image\/stand\/glass_smile.png","message":"眼鏡さん","width":0},{"name":"スポーツ娘","effectId":"1228825137.001","type":"standingGraphicInfos","source":"image\/stand\/sports_normal.png","state":"通常"},{"name":"スポーツ娘","effectId":"1228825151.579","mx_internal_uid":"61763FB4-46A9-4EE4-589B-212E023F5699","type":"standingGraphicInfos","source":"image\/stand\/sports_angry.png","state":"怒り"},{"name":"スポーツ娘","effectId":"1228825163.501","mx_internal_uid":"50B8206F-06D3-DBD4-8181-656628D104B7","type":"standingGraphicInfos","source":"image\/stand\/sports_smile.png","state":"笑い"},{"name":"眼鏡娘","effectId":"1228825190.126","type":"standingGraphicInfos","source":"image\/stand\/glass_normal.png","state":"通常"},{"name":"眼鏡娘","effectId":"1228825199.048","type":"standingGraphicInfos","source":"image\/stand\/glass_angry.png","state":"怒り"},{"name":"眼鏡娘","effectId":"1228825208.673","mx_internal_uid":"C0FD3367-4195-FD03-BE07-1EF9217B6B57","type":"standingGraphicInfos","source":"image\/stand\/glass_smile.png","state":"笑い"},{"position":"up,left","soundSource":".\/movie\/nonoshiri_1.mp3","isTail":false,"isSoundLoop":false,"cutInTag":"","effectId":"effects_1332867326.7834_0001","mx_internal_uid":"787E1503-6AC7-DA05-FA34-55444196C6E2","volume":0.17,"displaySeconds":3,"height":150,"message":" → 自動失敗","source":".\/image\/defaultImageSet\/gothic_smile.png","width":150},{"position":"up,left","soundSource":".\/movie\/nonoshiri_2.mp3","isSoundLoop":false,"isTail":false,"effectId":"effects_1332868276.0071_0001","cutInTag":"","mx_internal_uid":"4BB549B8-842D-A4D1-3EB9-55530F32F8CA","volume":0.1,"height":150,"displaySeconds":3,"source":".\/image\/defaultImageSet\/gothic_smile.png","message":"→ 2[1,1]＋0 → 2 → 自動失敗","width":150}]}'
  end
  
  
  def initLoginUserDb
    tableName = 'users'
    
    sql = <<SQL_TEXT
CREATE TABLE #{tableName} (
    roomNo     INTEGER  NOT NULL,
    uniqueId   VARCHAR(255) PRIMARY KEY NOT NULL,
    userName   TEXT     NOT NULL,
    isVisiter  INTEGER,
    update_at  INTEGER  NOT NULL);
SQL_TEXT
    
    query(sql)
    
    query("ALTER TABLE #{tableName} ADD INDEX (uniqueId, roomNo)")
  end
  
  
  
  def shapeUpDbResult(result)
    result.each do |row|
      shapeUpDbItem(row)
    end
    return result
  end
  
  def shapeUpDbItem(row)
    row.delete_if{|k,v| k.kind_of?(Integer)}
    return row
  end
  
  
  
  def getWebIfChatText
    @logger.debug("getWebIfChatText begin")
    
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
    @logger.debug(time, 'getWebIfChatTextFromTime time')
    
    saveData = {}
    @lastUpdateTimes = {'chatMessageDataLog' => time}
    refreshLoop(saveData)
    
    deleteOldChatTextForWebIf(time, saveData)
    
    @logger.debug(saveData, 'getWebIfChatTextFromTime saveData')
    
    return saveData
  end
  
  
  def getWebIfChatTextFromSecond(seconds)
    @logger.debug(seconds, 'getWebIfChatTextFromSecond seconds')
    
    time = getTimeForGetWebIfChatText(seconds)
    @logger.debug(seconds, "seconds")
    @logger.debug(time, "time")
    
    saveData = {}
    @lastUpdateTimes = {'chatMessageDataLog' => time}
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      saveData.merge!(targetSaveData)
    end
    
    deleteOldChatTextForWebIf(time, saveData)
    
    @logger.debug("getCurrentSaveData end saveData", saveData)
    
    return saveData
  end
  
  def deleteOldChatTextForWebIf(time, saveData)
    @logger.debug(time, 'deleteOldChatTextForWebIf time')
    
    return if( time.nil? )
    
    chats = saveData['chatMessageDataLog']
    return if( chats.nil? )
    
    chats.delete_if do |writtenTime, data|
      ((writtenTime <= time) or (not data['sendto'].nil?))
    end
    
    @logger.debug('deleteOldChatTextForWebIf End')
  end
  
  
  def getTimeForGetWebIfChatText(seconds)
    case seconds
    when "all"
      return 0
    when nil
      return 0
    end
    
    return Time.now.to_i - seconds.to_i
  end
  
  
  def getChatColor()
    name = getWebIfRequestText('name')
    @logger.debug(name, "name")
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
      "loginCount" => getLoginCount(),
      "maxLoginCount" => $aboutMaxLoginCount,
      "version" => DodontoF::FULL_VERSION_STRING,
      "result" => 'OK',
    }
    
    return jsonData
  end
  
  
  def getLoginCount()
    
    result = readDb( "SELECT COUNT(*) ",
                     :from => "users",
                     :where => {"update_at >= ? " => getLoginTimeLimit() },
                     :noRoom => true)
    
    row = result.first
    row ||= {}
    count = row['COUNT(*)'].to_i
    
    return count
  end
  
  
  def getWebIfServerInfo()
    jsonData = {
      "maxRoom" => ($saveDataMaxCount - 1),
      'isNeedCreatePassword' => (not $createPlayRoomPassword.empty?),
      'result' => 'OK',
    }
    
    if( getWebIfRequestBoolean("card", false) )
      cardInfos = getCardsInfo.collectCardTypeAndTypeName($cardOrder)
      jsonData["cardInfos"] = cardInfos
    end
    
    if( getWebIfRequestBoolean("dice", false) )
      jsonData['diceBotInfos'] = getDiceBotInfos()
    end
    
    return jsonData
  end

  def getWebIfRoomList()
    @logger.debug("getWebIfRoomList Begin")
    minRoom = getWebIfRequestInt('minRoom', 0)
    maxRoom = getWebIfRequestInt('maxRoom', ($saveDataMaxCount - 1))

    room = DodontoF_MySqlKai::PlayRoom.new(self)
    playRoomStates = room.getStates(minRoom, maxRoom)

    jsonData = {
      "playRoomStates" => playRoomStates,
      "result" => 'OK',
    }

    @logger.debug("getWebIfRoomList End")
    return jsonData
  end

  def sendWebIfChatText
    @logger.debug("sendWebIfChatText begin")
    
    name = getWebIfRequestText('name')
    @logger.debug(name, "name")
    
    message = getWebIfRequestText('message')
    message.gsub!(/\r\n/, "\r")
    @logger.debug(message, "message")
    
    color = getWebIfRequestText('color', getTalkDefaultColor)
    @logger.debug(color, "color")
    
    channel = getWebIfRequestInt('channel')
    @logger.debug(channel, "channel")
    
    gameType = getWebIfRequestText('bot')
    @logger.debug(gameType, 'gameType')
    
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
    @logger.debug("sendWebIfChatText chatData", chatData)
    
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
    @logger.debug("getWebIfRequestHash begin")
    @logger.debug(key, "key")
    @logger.debug(separator1, "separator1")
    @logger.debug(separator2, "separator2")
    
    array = getWebIfRequestArray(key, [], separator2)
    @logger.debug(array, "array")
    
    if( array.empty? )
      return default
    end
    
    hash = {}
    array.each do |value|
      @logger.debug(value, "array value")
      key, value = value.split(separator1)
      hash[key] = value
    end
    
    @logger.debug(hash ,"getWebIfRequestHash result")
    
    return hash
  end
  
  def sendWebIfAddMemo
    @logger.debug('sendWebIfAddMemo begin')
    
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
    
    @logger.debug(jsonData, 'sendWebIfAddMemo jsonData')
    addCharacterData( [jsonData] )
    
    return result
  end
  
  
  def sendWebIfAddCharacter
    @logger.debug("sendWebIfAddCharacter begin")
    
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
    
    @logger.debug(jsonData, 'sendWebIfAddCharacter jsonData')
    
    
    if( jsonData['name'].empty? )
      result['result'] = "キャラクターの追加に失敗しました。キャラクター名が設定されていません"
      return result
    end
    
    
    addResult = addCharacterData( [jsonData] )
    addFailedCharacterNames = addResult["addFailedCharacterNames"]
    @logger.debug(addFailedCharacterNames, 'addFailedCharacterNames')
    
    if( addFailedCharacterNames.length > 0 )
      result['result'] = "キャラクターの追加に失敗しました。同じ名前のキャラクターがすでに存在しないか確認してください。\"#{addFailedCharacterNames.join(' ')}\""
    end
    
    return result
  end
  
  def getWebIfImageName(key, default)
    @logger.debug("getWebIfImageName begin")
    @logger.debug(key, "key")
    @logger.debug(default, "default")
    
    image = getWebIfRequestText(key, default)
    @logger.debug(image, "image")
    
    if( image != default )
      image.gsub!('(local)', $imageUploadDir)
      image.gsub!('__LOCAL__', $imageUploadDir)
    end
    
    @logger.debug(image, "getWebIfImageName result")
      
    return image
  end
  
  
  def sendWebIfChangeCharacter
    @logger.debug("sendWebIfChangeCharacter begin")
    
    result = {}
    result['result'] = 'OK'
    
    begin
      sendWebIfChangeCharacterChatched
    rescue => e
      result['result'] =  e.to_s
    end
    
    return result
  end
  
  def sendWebIfChangeCharacterChatched
    @logger.debug("sendWebIfChangeCharacterChatched begin")
    
    targetName = getWebIfRequestText('targetName')
    @logger.debug(targetName, "targetName")
    
    if( targetName.empty? )
      raise '変更するキャラクターの名前(\'target\'パラメータ）が正しく指定されていません'
    end
    
    changeDb do
      
      result = getAllCharacters()
      
      characterData = nil
      result.each do |row|
        data = getObjectFromJsonString( row["json"] )
        
        if data['name'] == targetName
          characterData = data
          break
        end
      end
      
      if( characterData.nil? )
        raise "「#{targetName}」という名前のキャラクターは存在しません"
      end
      
      name = getWebIfRequestAny(:getWebIfRequestText, 'name', characterData)
      @logger.debug(name, "name")
      
=begin
      if( characterData['name'] != name )
        failedName = isAlreadyExistCharacterInRoom?( saveData, {'name' => name})
        if( failedName )
          raise "「#{name}」という名前のキャラクターはすでに存在しています"
        end
      end
=end
      
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
      
      updateCharacters(characterData)

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
    @logger.debug("getWebIfRoomInfo begin")
    
    result = {}
    result['result'] = 'OK'
    
    changeTimerData do |saveData|
      roundTimeData = getHashValue(saveData, 'roundTimeData', {})
      result['counter'] = getHashValue(roundTimeData, "counterNames", [])
      saveData
    end
    
    roomInfo = getRoomInfoForWebIf
    result.merge!(roomInfo)
    
    @logger.debug(result, "getWebIfRoomInfo result")
    
    return result
  end
  
  
  def changeTimerData
    changeDbJsonData('times') do |data|
      yield(data)
    end
  end
  
  
  
  def getRoomInfoForWebIf
    result = {}
    
    saveData = getPlayRoomData()
    
    result['roomName'] = getHashValue(saveData, 'playRoomName', '')
    result['chatTab'] = getHashValue(saveData, 'chatChannelNames', [])
    result['outerImage'] = getHashValue(saveData, 'canUseExternalImage', false)
    result['visit'] = getHashValue(saveData, 'canVisit', false)
    result['game'] = getHashValue(saveData, 'gameType', '')
    
    return result
  end
  
  def getHashValue(hash, key, default)
    value = hash[key]
    value ||= default
    return value
  end
  
  def setWebIfRoomInfo
    @logger.debug("setWebIfRoomInfo begin")
    
    result = {}
    result['result'] = 'OK'
    
    setWebIfRoomInfoCounterNames
    
    saveData = getPlayRoomData()
    roomInfo = getRoomInfoForWebIf
    
    saveData['playRoomName'] = getWebIfRequestAny(:getWebIfRequestText, 'roomName', roomInfo)
    saveData['chatChannelNames'] = getWebIfRequestAny(:getWebIfRequestArray, 'chatTab', roomInfo)
    saveData['canUseExternalImage'] = getWebIfRequestAny(:getWebIfRequestBoolean, 'outerImage', roomInfo)
    saveData['canVisit'] = getWebIfRequestAny(:getWebIfRequestBoolean, 'visit', roomInfo)
    saveData['gameType'] = getWebIfRequestAny(:getWebIfRequestText, 'game', roomInfo)
    
    @logger.debug(result, "setWebIfRoomInfo result")
    
    return result
  end
  
  def setWebIfRoomInfoCounterNames
    counterNames = getWebIfRequestArray('counter', nil, ',')
    return if( counterNames.nil? )
    
    changeCounterNames(counterNames)
  end
  
  def changeCounterNames(counterNames)
    @logger.debug(counterNames, "changeCounterNames(counterNames)")
    
    changeTimerData do |saveData|
      roundTimeData = getRoundTimeDataFromSaveData(saveData)
      roundTimeData['counterNames'] = counterNames
      saveData
    end
  end
  
  
  def uploadImageDataWebIf()
    @logger.debug("uploadImageDataWebIf begin")
    
    require 'base64'
    
    fileData = getRequestData('fileData')
    raise "no fileData param" if fileData.nil?
    imageFileName = fileData.original_filename
    imageData = fileData.read
    
    smallImageData = getRequestData('smallImageData')
    smallImageData = Base64.decode64( smallImageData )  unless smallImageData.nil?
    
    imagePassword = getWebIfRequestText('imagePassword', "")
    tags = getWebIfRequestText('tags', "").split(/[\s　]/)
    roomNumber = getRequestData('room')
    
    params = {
      "tagInfo" => {
        "tags" => tags,
        "roomNumber" => roomNumber,
        "password" => imagePassword },
      "imageFileName" => imageFileName,
      "imageData"=> imageData,
      "smallImageData"=> smallImageData,
    }
    
    image = DodontoF::Image.new(self)
    result = image.uploadImageData(params)
    result['result'] = result.delete('resultText')
    
    @logger.debug(result, "uploadImageDataWebIf result")
    return result
  end
  
  
  def getWebIfRequestAny(functionName, key, defaultInfos, key2 = nil)
    key2 ||= key
    
    @logger.debug("getWebIfRequestAny begin")
    @logger.debug(key, "key")
    @logger.debug(key2, "key2")
    @logger.debug(defaultInfos, "defaultInfos")
    
    defaultValue = defaultInfos[key2]
    @logger.debug(defaultValue, "defaultValue")
    
    command = "#{functionName}( key, defaultValue )"
    @logger.debug(command, "getWebIfRequestAny command")
    
    result = eval( command )
    @logger.debug(result, "getWebIfRequestAny result")
    
    return result
  end
  
  
  def getWebIfRefresh
    @logger.debug("getWebIfRefresh Begin")
    
    @lastUpdateTimes = {
      'chatMessageDataLog' => getWebIfRequestNumber('chat', -1),
      'map' => getWebIfRequestNumber('map', -1),
      'characters' => getWebIfRequestNumber('characters', -1),
      'time' => getWebIfRequestNumber('time', -1),
      'effects' => getWebIfRequestNumber('effects', -1),
      'playRoomInfo' => getWebIfRequestNumber('roomInfo', -1),
    }
    
    @lastUpdateTimes.delete_if{|type, time| time == -1}
    @logger.debug(@lastUpdateTimes, "getWebIfRefresh lastUpdateTimes")
    
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
    
    @logger.debug("getWebIfRefresh End result", result)
    
    return result
  end
  
  
  def refresh()
    @logger.debug("==>Begin refresh");
    
    saveData = {}
    
    if( $isMentenanceNow )
      saveData["warning"] = {"key" => "canNotRefreshBecauseMentenanceNow", "params" => []}
    end
    
    params = getParamsFromRequestData()
    @logger.debug(params, "params")
    
    @lastUpdateTimes = params['times']
    @logger.debug(@lastUpdateTimes, "@lastUpdateTimes");
    
    isFirstChatRefresh = (@lastUpdateTimes['chatMessageDataLog'] == 0)
    @logger.debug(isFirstChatRefresh, "isFirstChatRefresh");
    
    refreshIndex = params['rIndex'];
    @logger.debug(refreshIndex, "refreshIndex");
    
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
    
    @logger.debug(saveData, "refresh end saveData");
    @logger.debug("==>End refresh");
    
    return saveData
  end
  
  def getLoginUserInfo(userName, uniqueId, isVisiter)
    updateLoginUserInfo(userName, uniqueId, isVisiter)
    return getAllUsersData()
  end
  
  
  def getParamsFromRequestData()
    params = getRequestData('params')
    @logger.debug(params, "params")
    return params
  end
  
  
  
  def refreshLoop(saveData)
    now = Time.now
    whileLimitTime = now + $refreshTimeout
    
    @logger.debug(now, "now")
    @logger.debug(whileLimitTime, "whileLimitTime")
    
    while( Time.now < whileLimitTime )
      
      refreshOnce(saveData)
      
      break unless( saveData.empty? )
      
      intalval = getRefreshInterval
      @logger.debug(intalval, "saveData is empty, sleep second");
      sleep( intalval )
      @logger.debug("awake.");
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
  
  
  def updateLoginUserInfo(userName = '', uniqueId = '', isVisiter = false)
    @logger.debug(uniqueId, 'updateLoginUserInfo uniqueId')
    @logger.debug(userName, 'updateLoginUserInfo userName')
    
    isGetOnly = (userName.empty? and uniqueId.empty? )
    
    return if isGetOnly
    
    params = getUserInfoParams(uniqueId, userName,isVisiter)
    
    result = readDb( "SELECT COUNT(*)",
                     :from => 'users',
                     :where => {'uniqueId = ? ' => uniqueId})
    row = result.first
    count = row['COUNT(*)'].to_i
    
    if count == 0
      addNewUserData(params)
    else
      updateUserData(params)
    end
    
    deleteUserInfo()
    
    @logger.debug("updateLoginUserInfo END")
  end
  
  def getUserInfoParams(uniqueId, userName,isVisiter)
    
    isVisiterValue = (isVisiter ? 1 : 0)
    
    params = {
      :uniqueId   => uniqueId,
      :userName   => userName,
      :isVisiter  => isVisiterValue,
      :update_at  => Time.now.to_i,
    }
    
    return params
  end
  
  
  def addNewUserData(params)
    
    changeDb do
      query("INSERT INTO users (roomNo, uniqueId, userName, isVisiter, update_at) VALUES (?, ?, ?, ?, ?)",
            getRoomNo(), params[:uniqueId], params[:userName], params[:isVisiter], params[:update_at])
            
    end
  end
  
  def updateUserData(params)
    
    changeDb do
      updateDb(:table => "users",
               :set => {"userName" => params[:userName],
                        "isVisiter" => params[:isVisiter],
                        "update_at" => params[:update_at] },
               :where => {"uniqueId=? " => params[:uniqueId]} )
    end
  end
  
  def deleteUserInfo(roomNo = nil)
    roomNo ||= getRoomNo()
    
    if @deleteUserInfo_limitTime.nil?
      now = Time.now.to_i
      @deleteUserInfo_limitTime = (now - $loginTimeOut)
    end
    
    changeDb do
      query("DELETE FROM users WHERE update_at < ? AND roomNo = ?", 
            getLoginTimeLimit(), roomNo )
    end
  end
  
  def getLoginTimeLimit()
    now = Time.now.to_i
    return (now - $loginTimeOut)
  end

  def getLoginUserCountList( roomNumberRange )
    loginUserCountList = {}
    roomNumberRange.each{|i| loginUserCountList[i] = 0 }
    
    roomNumberRange.each do |index|
      loginUserInfo = getAllUsersData(index)
      loginUserCountList[index] = loginUserInfo.size
    end
    
    return loginUserCountList
  end
  
  def getLoginUserList( roomNumberRange )
    loginUserList = {}
    roomNumberRange.each{|i| loginUserList[i] = [] }
    
    roomNumberRange.each do |roomNo|
      
      next unless existRoom?(roomNo)
      
      userNames = []
      loginUserInfo = getAllUsersData()
      loginUserInfo.each do |data|
        userNames << data["userName"]
      end
      
      loginUserList[index] = userNames
    end
    
    return loginUserList
  end

  def removeOldPlayRoom()
    DodontoF_MySqlKai::PlayRoom.new(self).removeOlds
  end

  def getPlayRoomStates()
    @logger.debug("getPlayRoomStates Begin");

    params = getParamsFromRequestData()
    @logger.debug(params, "params")

    DodontoF_MySqlKai::PlayRoom.new(self).getStatesByParams(params)
  end

  def getRoomTimeStamp(where = nil)
    result = readDb("SELECT MAX(created_at)",
                    :from => "chats",
                    :where => where)
    
    row = result.first
    row ||= {}
    
    created_at = row['MAX(created_at)'].to_i
    return nil if created_at == 0
    
    timeStamp = Time.at(created_at)
    
    return timeStamp
  end

  def existRoom?(roomNo = nil)
    
    roomNo ||= getRoomNo()
    tableName = 'rooms'
    result = readDb( "SELECT roomNo ",
                     :from => tableName, 
                     :where => {"roomNo = ? " => roomNo})
    return (not result.empty?)
  end

  def getAllUsersData(roomNo = nil)
    tableName = 'users'
    
    where = nil
    unless roomNo.nil?
      where = {"roomNo = ? " => roomNo}
    end
    
    result = readDb( "SELECT *",
                     :from => tableName,
                     :where => where)
    
    shapeUpDbResult(result)
    
    result.each do |row|
      row.delete('update_at')
      row['isVisiter'] = (row['isVisiter'] == 1)
    end
    
    return result
  end
  
  def getAllLoginCount()
    total = 0
    userList = []
    
    result = readDb( "SELECT COUNT(*), roomNo",
                     :from => "users",
                     :where => {"update_at >= ? " => getLoginTimeLimit() },
                     :others => ["GROUP BY roomNo"],
                     :noRoom => true)
    @logger.debug(result, "result")
    
    result.each do |row|
      roomNo = row["roomNo"].to_i
      count = row["COUNT(*)"].to_i
      
      total += count
      userList << [roomNo, count]
    end
    
    userList.sort!
    
    @logger.debug(total, "getAllLoginCount total")
    @logger.debug(userList, "getAllLoginCount userList")
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
    
    @logger.debug(counts, 'counts')
    
    countList = counts.collect{|gameType, count|[count, gameType]}
    countList.sort!
    countList.reverse!
    
    @logger.debug('countList', countList)
    
    famousGames = []
    
    countList.each_with_index do |info, index|
      # next if( index >= 3 )
      
      count, gameType = info
      famousGames << {"gameType" => gameType, "count" => count}
    end
    
    @logger.debug('famousGames', famousGames)
    
    return famousGames
  end

  def getLoginInfo()
    @logger.debug("getLoginInfo begin")
    
    params = getParamsFromRequestData()
    uniqueId = params['uniqueId']
    uniqueId ||= createUniqueId()
    
    allLoginCount, loginUserCountList = getAllLoginCount()
    
    loginMessage = getLoginMessage()
    cardInfos = getCardsInfo.collectCardTypeAndTypeName($cardOrder)
    diceBotInfos = getDiceBotInfos()
    
    result = {
      "loginMessage" => loginMessage,
      "cardInfos" => cardInfos,
      "isDiceBotOn" => $isDiceBotOn,
      "uniqueId" => uniqueId,
      "refreshTimeout" => $refreshTimeout,
      "refreshInterval" => getRefreshInterval(),
      "isCommet" => $isCommet,
      "version" => DodontoF::FULL_VERSION_STRING,
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
      'wordChecker' => $wordChecker,
      'errorMessage' => $globalErrorMessage,
    }
    
    @logger.debug(result, "result")
    @logger.debug("getLoginInfo end")
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
    
    return languages
  end
  
  
  def createUniqueId
    # 識別子用の文字列生成。
    (Time.now.to_f * 1000).to_i.to_s(36)
  end
  
  
  def getLoginWarning
    image = DodontoF_MySqlKai::Image.new(self)
    smallImageDir = image.getSmallImageDir()
    unless( isExistDir?(smallImageDir) )
      return {
        "key" => "noSmallImageDir",
        "params" => [smallImageDir],
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
      @logger.debug(loginMessage, "loginMessage")
    else
      @logger.debug("#{$loginMessageFile} is NOT found.")
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
      @logger.debug("#{$loginMessageFile} is NOT found.")
    end
    
    return loginMessage
  end
  
  # ダイスボットの情報を返す
  # @return [Array<Hash>]
  #
  # 部屋番号が指定されていた場合、テーブルのコマンドも含める。
  def getDiceBotInfos
    @logger.debug("getDiceBotInfos() Begin")
    
    require 'diceBotInfos'
    
    orderedGameNames = $diceBotOrder.split("\n")
    
    if @saveDirInfo.getSaveDataDirIndex != -1
      DiceBotInfos.withTableCommands(orderedGameNames,
                                     $isDisplayAllDice,
                                     @dice_adapter.getGameCommandInfos)
    else
      DiceBotInfos.get(orderedGameNames, $isDisplayAllDice)
    end
  end
  
  def createDir(playRoomIndex)
    @logger.debug("createDir BEGIN")
    
    @saveDirInfo.setSaveDataDirIndex(playRoomIndex)
    @saveDirInfo.createDir()
    
    initPlayRoomData(playRoomIndex)
    insertFirstMap
    insertFirstTime
    insertFirstEffect
    
    @logger.debug("createDir END")
  end
  
  
  def initPlayRoomData(roomNo)
    
    connectDb
    
    json = '{"canVisit":false,"gameType":"DiceBot","chatChannelNames":["メイン","雑談"],"canUseExternalImage":false,"playRoomChangedPassword":null,"playRoomName":"プレイルームNo.0"}'
    
    tableName = 'rooms'
    
    query("INSERT INTO #{tableName} (roomNo, json, update_index) VALUES (?, ?, ?)", 
           roomNo, json, 1)
  end
  
  
  def createPlayRoom()
    params = getParamsFromRequestData()
    DodontoF_MySqlKai::PlayRoom.new(self).create(params)
  end

  
  def changePlayRoomData
    changeRoomDbJsonData() do |data|
      yield(data)
    end
  end

  def changePlayRoom()
    params = getParamsFromRequestData()
    DodontoF_MySqlKai::PlayRoom.new(self).change(params)
  end

  def removePlayRoom()
    params = getParamsFromRequestData()
    DodontoF_MySqlKai::PlayRoom.new(self).remove(params)
  end

  def removeSaveDir(roomNo)
    @saveDirInfo.removeSaveDir(roomNo)
    
    changeDb do 
      %w{chats characters maps times effects users rooms}.each do |target|
        query("DELETE FROM #{target} WHERE roomNo=?", roomNo)
      end
    end
  end

  def getTrueSaveFileName(fileName)
    @saveDirInfo.getTrueSaveFileName($saveFileTempName)
  end
  
  def saveAllData()
    @logger.debug("saveAllData begin")
    dir = getRoomLocalSpaceDirName
    makeDir(dir)
    
    params = getParamsFromRequestData()
    @saveAllDataBaseUrl = params['baseUrl']
    chatPaletteData = params['chatPaletteData']
    @logger.debug(@saveAllDataBaseUrl, "saveAllDataBaseUrl")
    @logger.debug(chatPaletteData, "chatPaletteData")
    
    saveDataAll = getAllSaveData()
    saveDataAll = moveAllImagesToDir(dir, saveDataAll)
    makeChatPalletSaveFile(dir, chatPaletteData)
    makeDefaultSaveFileForAllSave(dir, saveDataAll)
    
    removeOldAllSaveFile(dir)
    baseName = getNewSaveFileBaseName(@fullBackupFileBaseName);
    allSaveDataFile = makeAllSaveDataFile(dir, baseName)
    
    result = {}
    result['result'] = "OK"
    result["saveFileName"] = allSaveDataFile
    
    @logger.debug(result, "saveAllData result")
    return result
  end
  
  def getAllSaveData()
    selectTypes = $tableNames.keys
    selectTypes.delete_if{|i| i == 'chatMessageDataLog'}
    
    isAddPlayRoomInfo = true
    saveDataAll = getSelectFilesData(selectTypes, isAddPlayRoomInfo)
    return saveDataAll
  end
  
  def moveAllImagesToDir(dir, saveDataAll)
    @logger.debug(saveDataAll, 'moveAllImagesToDir saveDataAll')
    
    moveMapImageToDir(dir, saveDataAll)
    moveEffectsImageToDir(dir, saveDataAll)
    moveCharactersImagesToDir(dir, saveDataAll)
    movePlayroomImagesToDir(dir, saveDataAll)
    
    @logger.debug(saveDataAll, 'moveAllImagesToDir result saveDataAll')
    
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
    @logger.debug(dir, "movePlayroomImagesToDir dir")
    playRoomInfo = saveDataAll['playRoomInfo']
    return if( playRoomInfo.nil? )
    @logger.debug(playRoomInfo, "playRoomInfo")
    
    backgroundImage = playRoomInfo['backgroundImage'] 
    @logger.debug(backgroundImage, "backgroundImage")
    return if( backgroundImage.nil? )
    return if( backgroundImage.empty? )
    
    changeFilePlace(backgroundImage, dir)
  end
  
  def changeFilePlace(from ,to)
    @logger.debug(from, "changeFilePlace from")
    
    fromFileName, = from.split(/\t/)
    fromFileName ||= from
    
    result = copyFile(fromFileName ,to)
    @logger.debug(result, "copyFile result")
    
    return unless( result )
    
    from.gsub!(/.*\//, $imageUploadDirMarker + "/" )
    @logger.debug(from, "changeFilePlace result")
  end
  
  def copyFile(from ,to)
    @logger.debug("moveFile begin")
    @logger.debug(from, "from")
    @logger.debug(to, "to")
    
    @logger.debug(@saveAllDataBaseUrl, "@saveAllDataBaseUrl")
    from.gsub!(@saveAllDataBaseUrl, './')
    @logger.debug(from, "from2")
    
    return false if( from.nil? )
    return false unless( File.exist?(from) )
    
    fromDir =  File.dirname(from)
    @logger.debug(fromDir, "fromDir")
    if( fromDir == to )
      @logger.debug("from, to is equal dir")
      return true
    end
    
    @logger.debug("copying...")
    
    result = true
    begin
      FileUtils.cp(from, to)
    rescue
      result = false
    end
    
    return result
  end
  
  def makeChatPalletSaveFile(dir, chatPaletteData)
    @logger.debug("makeChatPalletSaveFile Begin")
    @logger.debug(dir, "makeChatPalletSaveFile dir")
    
    currentDir = FileUtils.pwd.untaint
    FileUtils.cd(dir)
    
    File.open(@defaultChatPallete, "w+") do |file|
      file.write(chatPaletteData)
    end
    
    FileUtils.cd(currentDir)
    @logger.debug("makeChatPalletSaveFile End")
  end
  
  def makeDefaultSaveFileForAllSave(dir, saveDataAll)
    @logger.debug("makeDefaultSaveFileForAllSave Begin")
    @logger.debug(dir, "makeDefaultSaveFileForAllSave dir")
    
    extension = @@saveFileExtension
    result = saveSelectFilesFromSaveDataAll(saveDataAll, extension)
    
    from = result["saveFileName"]
    to = File.join(dir, @defaultAllSaveData)
    
    FileUtils.mv(from, to)
    
    @logger.debug("makeDefaultSaveFileForAllSave End")
  end
  
  
  def removeOldAllSaveFile(dir)
    fileNames = Dir.glob("#{dir}/#{@fullBackupFileBaseName}*#{@allSaveDataFileExt}")
    fileNames = fileNames.collect{|i| i.untaint}
    @logger.debug(fileNames, "removeOldAllSaveFile fileNames")
    
    fileNames.each do |fileName|
      File.delete(fileName)
    end
  end
  
  def makeAllSaveDataFile(dir, fileBaseName)
    @logger.debug("makeAllSaveDataFile begin")
    
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
  
  
  @@saveFileExtension = "sav"
  @@mapSaveFileExtension = "msv"
  
  def save()
    isAddPlayRoomInfo = true
    extension = @@saveFileExtension
    
    addInfos = {}
    addInfos[$diceBotTableSaveKey] = getDiceTableData()
    
    saveSelectFiles($tableNames.keys, extension, isAddPlayRoomInfo, addInfos)
  end
  
  def getDiceTableData()
    tableInfos = @dice_adapter.getBotTableInfosFromDir
    
    tableInfos.each{|i| i.delete('fileName') }
    
    return tableInfos
  end
  
  
  def saveMap()
    extension = @@mapSaveFileExtension
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
    
    text = getJsonString(saveData)
    saveFileName = getNewSaveFileName(extension)
    createSaveFile(saveFileName, text)
    
    result["result"] = "OK"
    result["saveFileName"] = saveFileName
    @logger.debug(result, "saveSelectFiles result")
    
    return result
  end
  
  
  def getSelectFilesData(selectTypes, isAddPlayRoomInfo = false)
    @logger.debug(selectTypes, "getSelectFilesData begin selectTypes")
    
    @lastUpdateTimes = {}
    selectTypes.each do |type|
      @lastUpdateTimes[type] = 0;
    end
    @logger.debug("dummy @lastUpdateTimes created")
    
    saveDataAll = {}
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      
      if saveFileTypeName == 'characters'
        jsons = targetSaveData["characters"]
        characters = jsons.collect {|i| getObjectFromJsonString(i) }
        targetSaveData["characters"] = characters
      end
      
      saveDataAll[saveFileTypeName] = targetSaveData
      @logger.debug(saveFileTypeName, "saveFileTypeName in save")
    end
    
    if( isAddPlayRoomInfo )
      @lastUpdateTimes['playRoomInfo'] = 0;
      saveDataAll['playRoomInfo'] = getPlayRoomData()
    end
    
    @logger.debug(saveDataAll, "saveDataAll tmp")
    
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
    @logger.debug('deleteOldSaveFile begin')
    begin
      deleteOldSaveFileCatched
    rescue => e
      @logger.exception(e)
    end
    @logger.debug('deleteOldSaveFile end')
  end
  
  def deleteOldSaveFileCatched
    
    changeSaveData($saveFileNames) do |saveData|
      existSaveFileNames = saveData["fileNames"]
      existSaveFileNames ||= []
      @logger.debug(existSaveFileNames, 'existSaveFileNames')
      
      regExp = /DodontoF_[\d_]+.sav/
      
      deleteTargets = []
      
      existSaveFileNames.each do |saveFileName|
        @logger.debug(saveFileName, 'saveFileName')
        next unless(regExp === saveFileName)
        
        createdTime = getSaveFileTimeStamp(saveFileName)
        now = Time.now.to_i
        diff = ( now - createdTime )
        @logger.debug(diff, "createdTime diff")
        next if( diff < $oldSaveFileDelteSeconds )
        
        begin
          deleteFile(saveFileName)
        rescue => e
          @logger.exception(e)
        end
        
        deleteTargets << saveFileName
      end
      
      @logger.debug(deleteTargets, "deleteTargets")
      
      deleteTargets.each do |fileName|
        existSaveFileNames.delete_if{|i| i == fileName}
      end
      @logger.debug(existSaveFileNames, "existSaveFileNames")
      
      saveData["fileNames"] = existSaveFileNames
    end
    
  end

  def checkRoomStatus()
    deleteOldUploadFile()

    params = getParamsFromRequestData()
    @logger.debug(params, 'params')
    DodontoF_MySqlKai::PlayRoom.new(self).check(params)
  end

  def loginPassword()
    loginData = getParamsFromRequestData()
    @logger.debug(loginData, 'loginData')
    
    roomNumber = loginData['roomNumber']
    password = loginData['password']
    visiterMode = loginData['visiterMode']
    
    checkLoginPassword(roomNumber, password, visiterMode)
  end
  
  def checkLoginPassword(roomNumber, password, visiterMode)
    @logger.debug("checkLoginPassword roomNumber", roomNumber)
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
    
    saveData = getPlayRoomData()
    
    canVisit = saveData['canVisit']
    if( canVisit and visiterMode )
      result['resultText'] = "OK"
      result['visiterMode'] = true
    else
      playRoomChangedPassword = saveData['playRoomChangedPassword']
      if( DodontoF::Utils.isPasswordMatch?(password, playRoomChangedPassword) )
        result['resultText'] = "OK"
      else
        result['resultText'] = "passwordMismatch"
      end
    end
    
    return result
  end

  def logout()
    logoutData = getParamsFromRequestData()
    @logger.debug(logoutData, 'logoutData')
    
    uniqueId = logoutData['uniqueId']
    @logger.debug(uniqueId, 'uniqueId');
    
    changeDb do
      query("DELETE FROM users WHERE uniqueId = ?",
            uniqueId)
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
    @logger.debug("getBotTableInfos Begin")
    result = {
      "resultText"=> "OK",
    }
    
    result["tableInfos"] = @dice_adapter.getBotTableInfosFromDir
    
    @logger.debug(result, "result")
    @logger.debug("getBotTableInfos End")
    return result
  end
 
  def addBotTable()
    result = {}
    
    params = getParamsFromRequestData()
    result['resultText'] = @dice_adapter.addBotTableMain(params)
    
    if( result['resultText'] != "OK" )
      return result
    end
    
    @logger.debug("addBotTableMain called")
    
    result = getBotTableInfos()
    @logger.debug(result, "addBotTable result")
    
    return result
  end
  
  def changeBotTable()
    params = getParamsFromRequestData()

    result = {}
    result['resultText'] = @dice_adapter.changeBotTableMain(params)

    if( result['resultText'] != "OK" )
      return result
    end

    result = getBotTableInfos()
    return result
  end
  
  def removeBotTable()
    params = getParamsFromRequestData()
    @dice_adapter.removeBotTableMain(params)
    return getBotTableInfos()
  end

  def requestReplayDataList()
    @logger.debug("requestReplayDataList begin")
    result = {
      "resultText"=> "OK",
    }
    
    result["replayDataList"] = getReplayDataList() #[{"title"=>x, "url"=>y}]
    
    @logger.debug(result, "result")
    @logger.debug("requestReplayDataList end")
    return result
  end
  
  def uploadReplayData()
    uploadFileBase($replayDataUploadDir, $UPLOAD_REPALY_DATA_MAX_SIZE) do |fileNameFullPath, fileNameOriginal, result|
      @logger.debug("uploadReplayData yield Begin")
      
      params = getParamsFromRequestData()
      
      ownUrl = params['ownUrl']
      replayUrl = ownUrl + "?replay=" + CGI.escape(fileNameFullPath)
      
      replayDataName = params['replayDataName']
      replayDataInfo = setReplayDataInfo(fileNameFullPath, replayDataName, replayUrl)
      
      result["replayDataInfo"] = replayDataInfo
      result["replayDataList"] = getReplayDataList() #[{"title"=>x, "url"=>y}]
      
      @logger.debug("uploadReplayData yield End")
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
    @logger.debug("removeReplayData begin")
    
    result = {
      "resultText"=> "NG",
    }
    
    begin
      replayData = getParamsFromRequestData()
      
      @logger.debug(replayData, "replayData")
      
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
      
      @logger.debug("removeReplayData replayDataList", replayDataList)
      
      result = requestReplayDataList()
    rescue => e
      result["resultText"] = e.to_s
      @logger.exception(e)
    end
    
    return result
  end
  
  
  def uploadFile()
    uploadFileBase($fileUploadDir, $UPLOAD_FILE_MAX_SIZE) do |fileNameFullPath, fileNameOriginal, result|
      
      deleteOldUploadFile()
      
      params = getParamsFromRequestData()
      baseUrl = params['baseUrl']
      @logger.debug(baseUrl, "baseUrl")
      
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
      @logger.exception(e)
    end
  end
  
  
  def uploadFileBase(fileUploadDir, fileMaxSize, isChangeFileName = true)
    @logger.debug("uploadFile() Begin")
    
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
      @logger.debug(fileNameFullPath, "fileNameFullPath")
      
      yield(fileNameFullPath, fileNameOriginal, result)
      
      open(fileNameFullPath, "w+") do |file|
        file.binmode
        file.write(fileData)
      end
      File.chmod(0666, fileNameFullPath)
      
      result["resultText"] = "OK"
      
    rescue => e
      @logger.debug(e, "error")
      result["resultText"] = getLanguageKey( e.to_s )
    end
    
    @logger.debug(result, "load result")
    @logger.debug("uploadFile() End")
    
    return result
  end
  
  
  def loadAllSaveData()
    @logger.debug("loadAllSaveData() Begin")
    checkLoad()
    
    fileUploadDir = getRoomLocalSpaceDirName
    
    clearDir(fileUploadDir)
    makeDir(fileUploadDir)
    
    fileMaxSize = $allSaveDataMaxSize # Mbyte
    saveFile = nil
    isChangeFileName = false
    
    result = uploadFileBase(fileUploadDir, fileMaxSize, isChangeFileName) do |fileNameFullPath, fileNameOriginal, resultTmp|
      saveFile = fileNameFullPath
    end
    
    @logger.debug(result, "uploadFileBase result")
    
    unless( result["resultText"] == 'OK' )
      return result
    end
    
    beforeTime = getImageInfoFileTime()
    extendSaveData(saveFile, fileUploadDir)
    localizeImageInfo() if( getImageInfoFileTime() != beforeTime)
    
    
    chatPaletteSaveData = loadAllSaveDataDefaultInfo(fileUploadDir)
    result['chatPaletteSaveData'] = chatPaletteSaveData
    
    @logger.debug(result, 'loadAllSaveData result')
    
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
    @logger.debug(dir, "clearDir dir")
    
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
    @logger.debug(allSaveDataFile, 'allSaveDataFile')
    @logger.debug(fileUploadDir, 'fileUploadDir')
    
    require 'zlib'
    require 'archive/tar/minitar'
    
    readTar(allSaveDataFile) do |tar|
      @logger.debug("begin read scenario tar file")
      
      Archive::Tar::Minitar.unpackWithCheck(tar, fileUploadDir) do |fileName, isDirectory|
        checkUnpackFile(fileName, isDirectory)
      end
    end
    
    File.delete(allSaveDataFile)
    
    @logger.debug("archive extend !")
  end
  
  def readTar(allSaveDataFile)
    
    begin
      File.open(allSaveDataFile, 'rb') do |file|
        tar = file
        tar = Zlib::GzipReader.new(file)
        
        @logger.debug("allSaveDataFile is gzip")
        yield(tar)
        
      end
    rescue
      File.open(allSaveDataFile, 'rb') do |file|
        tar = file
        
        @logger.debug("allSaveDataFile is tar")
        yield(tar)
        
      end
    end
  end
  
  
  #直下のファイルで許容する拡張子の場合かをチェック
  def checkUnpackFile(fileName, isDirectory)
    @logger.debug(fileName, 'checkUnpackFile fileName')
    @logger.debug(isDirectory, 'checkUnpackFile isDirectory')
    
    if( isDirectory )
      @logger.debug('isDirectory!')
      return false
    end
    
    result = isAllowdUnpackFile(fileName)
    @logger.debug(result, 'checkUnpackFile result')
    
    return result
  end
  
  def isAllowdUnpackFile(fileName)
    
    if( /\// =~ fileName )
      @logger.error(fileName, 'NG! checkUnpackFile /\// paturn')
      return false
    end
    
    if( isAllowedFileExt(fileName) )
      return true
    end
    
    # @logger.error(fileName, 'NG! checkUnpackFile else paturn')
    
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
    dir = File.join($imageUploadDir, "room_#{roomNo}")
    return dir
  end

  def loadAllSaveDataDefaultInfo(dir)
    loadAllSaveDataDefaultSaveData(dir)
    chatPaletteSaveData = loadAllSaveDataDefaultChatPallete(dir)
    
    return chatPaletteSaveData
  end
  
  def loadAllSaveDataDefaultSaveData(dir)
    @logger.debug('loadAllSaveDataDefaultSaveData begin')
    saveFile = File.join(dir, @defaultAllSaveData)
    
    unless( File.exist?(saveFile) )
      @logger.debug(saveFile, 'saveFile is NOT exist')
      return
    end
    
    jsonDataString = File.readlines(saveFile).join
    loadFromJsonDataString(jsonDataString)
    
    @logger.debug('loadAllSaveDataDefaultSaveData end')
  end
  
  
  def loadAllSaveDataDefaultChatPallete(dir)
    file = File.join(dir, @defaultChatPallete)
    @logger.debug(file, 'loadAllSaveDataDefaultChatPallete file')
    
    return nil unless( File.exist?(file) )
    
    buffer = File.readlines(file).join
    @logger.debug(buffer, 'loadAllSaveDataDefaultChatPallete buffer')
    
    return buffer
  end
  
  
  def load()
    @logger.debug("load() Begin")
    
    result = {}
    
    begin
      checkLoad()
      
      params = getParamsFromRequestData()
      @logger.debug(params, 'load params')
      
      jsonDataString = params['fileData']
      @logger.debug(jsonDataString, 'jsonDataString')
      
      result = loadFromJsonDataString(jsonDataString)
      
    rescue => e
      result["resultText"] = e.to_s
    end
    
    @logger.debug(result, "load result")
    
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
    dirJsonText = getJsonString(dir)
    changedDir = dirJsonText[2...-2]
    
    @logger.debug(changedDir, 'localSpace name')
    
    text = text.gsub($imageUploadDirMarker, changedDir)
    return text
  end
  
  
  def loadFromJsonDataString(jsonDataString)
    jsonDataString = changeLoadText(jsonDataString)
    
    jsonData = getObjectFromJsonString(jsonDataString)
    loadFromJsonData(jsonData)
  end
  
  def loadFromJsonData(jsonData)
    @logger.debug(jsonData, 'loadFromJsonData jsonData')
    
    params = getParamsFromRequestData()
    
    removeCharacterDataList = params['removeCharacterDataList']
    if( removeCharacterDataList != nil )
      removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
    end
    
    targets = params['targets']
    @logger.debug(targets, "targets")
    
    if( targets.nil? ) 
      @logger.debug("loadSaveFileDataAll(jsonData)")
      loadSaveFileDataAll(jsonData)
    else
      @logger.debug("loadSaveFileDataFilterByTargets(jsonData, targets)")
      loadSaveFileDataFilterByTargets(jsonData, targets)
    end
    
    result = {
      "resultText"=> "OK"
    }
    
    @logger.debug(result, "loadFromJsonData result")
    
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
    @logger.debug(characterDataList, "characterDataList")
    
    characterDataList = characterDataList.delete_if{|i| (i["type"] != type)}
    addCharacterData( characterDataList )
  end
  
  def loadSaveFileDataFilterByTargets(jsonData, targets)
    saveDataAll = getSaveDataAllFromSaveData(jsonData)
    
    targets.each do |target|
      @logger.debug(target, 'loadSaveFileDataFilterByTargets each target')
      
      case target
      when "map"
        mapData = getLoadData(saveDataAll, 'map', 'mapData', {})
        changeMapSaveData(mapData)
      when "characterData", "mapMask", "mapMarker", "floorTile", "magicRangeMarker", "magicRangeMarkerDD4th", "Memo", getCardType()
        loadCharacterDataList(saveDataAll, target)
      when "characterWaitingRoom"
        @logger.debug("characterWaitingRoom called")
        waitingRoom = getLoadData(saveDataAll, 'characters', 'waitingRoom', [])
        setWaitingRoomInfo(waitingRoom)
      when "standingGraphicInfos"
        effects = getLoadData(saveDataAll, 'effects', 'effects', [])
        effects = effects.delete_if{|i| (i["type"] != target)}
        @logger.debug(effects, "standingGraphicInfos effects");
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
        @logger.error(target, "invalid load target type")
      end
    end
  end
  
  def loadSaveFileDataAll(jsonData)
    saveDataAll = getSaveDataAllFromSaveData(jsonData)
    
    @logger.debug("loadSaveFileDataAll(saveDataAll) begin")
    
    $tableNames.each do |fileTypeName, dummy|
      @logger.debug(fileTypeName, "fileTypeName")
      
      saveData = saveDataAll[fileTypeName]
      saveData ||= {}
      @logger.debug(saveData, "saveData")
      
      loadSaveFileDataForEachType(fileTypeName, saveData)
    end
    
    loadDiceBotTable(jsonData)
    
    @logger.debug("loadSaveFileDataAll(saveDataAll) end")
  end
  
  
  def loadSaveFileDataForEachType(fileTypeName, saveData)
    @logger.debug(fileTypeName, "loadSaveFileDataForEachType fileTypeName")
    @logger.debug(saveData, "loadSaveFileDataForRooms saveData")
    
    return if saveData.nil?
    
    case fileTypeName
    when 'chatMessageDataLog'
      return nil
    when 'playRoomInfo'
      return loadSaveFileDataForRooms(saveData)
      
    when 'map'
      saveData = saveData['mapData']
    when 'characters'
      return loadSaveFileDataForCharacters(saveData)
    end
    
    return if saveData.nil?

    changeDbJsonData( $tableNames[fileTypeName] ) do |currentData|
      saveData
    end
  end
  
  def loadSaveFileDataForRooms(newSaveData)
    return nil if newSaveData.nil?
    
    changePlayRoomData do |currentSaveData|
      newSaveData
    end
  end
  
  
  def loadSaveFileDataForCharacters(saveData)
    characters = saveData['characters']
    @logger.debug(characters, "loadSaveFileDataForCharacters characters")
    
    addCharacterData( characters )
  end
  
  
  def loadDiceBotTable(jsonData)
    
    data = jsonData[$diceBotTableSaveKey]
    return if( data.nil? )
    
    data.each do |info|
      info['table'] = getDiceBotTableString(info['table'])
      @dice_adapter.addBotTableMain(info)
    end
  
  end
  
  def getDiceBotTableString(table)
    
    lines = []
    table.each do |line|
      lines << line.join(":")
    end
    
    return lines.join("\n")
  end

  def uploadImageData()
    params = getParamsFromRequestData()
    image = DodontoF_MySqlKai::Image.new(self)
    image.uploadImageData(params)
  end
  
  
  #新規ファイル名。reqにroomNumberを持っていた場合、ファイル名に付加するようにする
  def getNewFileName(fileName, preFix = "")
    @newFileNameIndex ||= 0
    
    extName = getAllowedFileExtName(fileName)
    
    if( extName.nil? )
      raise "invalidFileNameExtension\t#{fileName}"
    end
    
    @logger.debug(extName, "extName")
    
    roomNumber  = getRequestData('roomNumber')
    if( roomNumber.nil? )
      roomNumber  = getRequestData('room')
      roomNumber = roomNumber.to_i unless roomNumber.nil?
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
    params = getParamsFromRequestData()
    image = DodontoF_MySqlKai::Image.new(self)
    image.deleteImage(params)
  end
  
  #override
  def addTextToFile(fileName, text)
    File.open(fileName, "a+") do |file|
      file.write(text);
    end
  end
  
  def uploadImageUrl()
    imageData = getParamsFromRequestData()
    image = DodontoF_MySqlKai::Image.new(self)
    image.uploadImageUrl(imageData)
  end
  
  
  def getGraveyardCharacterData()
    @logger.debug("getGraveyardCharacterData start.")
    
    result = getAllCharacters($characterStateGraveyard, true)
    
    graveyard = result.collect{|i| getObjectFromJsonString(i["json"])}
    @logger.debug(graveyard, "getGraveyardCharacterData graveyard")
    
    return graveyard
  end
  
  def getWaitingRoomInfo()
    @logger.debug("getWaitingRoomInfo start.")
    
    result = getAllCharacters($characterStateWaitingRoom, true)
    waitingRoom = result.collect{|i| getObjectFromJsonString(i["json"])}
    
    return waitingRoom
  end
  
  def setWaitingRoomInfo(characters)
    stateList = Array.new(characters.size, $characterStateWaitingRoom)
    addCharacterData(characters, stateList)
  end

  def sendDiceBotChatMessage
    @logger.debug('sendDiceBotChatMessage')
    
    params = getParamsFromRequestData()
    
    repeatCount = getDiceBotRepeatCount(params)
    
    results = []
    
    repeatCount.times do |i|
      
      paramsClone = params.clone
      paramsClone['message'] += " \##{ i + 1 }" if( repeatCount > 1 )
      
      result = sendDiceBotChatMessageOnece( paramsClone )
      @logger.debug(result, "sendDiceBotChatMessageOnece result")
      
      next if( result.nil? )
      
      results << result
    end
    
    @logger.debug(results, "sendDiceBotChatMessage results")
    
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
    
    state = params['state']
    senderName = params['name']
    senderName << ("\t" + state) unless( state.empty? )
    
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
    
    @logger.debug(chatData, 'sendDiceBotChatMessageOnece chatData')
    
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
    params['originalMessage'] = params['message']
    rollResult, isSecret, randResults = @dice_adapter.rollDice(params)
    
    secretMessage = ""
    if( isSecret )
      secretMessage = params['message'] + rollResult
    else
      params['message'] += rollResult
    end
    
    rolledMessage = getRolledMessage(params, isSecret, randResults)
    
    return rolledMessage, isSecret, secretMessage
  end
  
  def getDiceBotExtraTableDirName
    getRoomLocalSpaceDirName
  end
  
  
  def getRolledMessage(params, isSecret, randResults)
    @logger.debug("getRolledMessage Begin")

    @logger.debug(isSecret, "isSecret")
    @logger.debug(randResults, "randResults")
    
    if( isSecret )
      params['message'] = getLanguageKey('secretDice')
      randResults = randResults.collect{|value, max| [0, 0] }
    end
    
    message = params['message']
    
    if( randResults.nil? )
      @logger.debug("randResults is nil")
      return message
    end
    
    
    data = {
      "chatMessage" => message,
      "randResults" => randResults,
      "uniqueId" => params['uniqueId'],
      "power" => getDiceBotPower(params),
    }
    
    text = "###CutInCommand:rollVisualDice###" + getJsonString(data)
    @logger.debug(text, "getRolledMessage End text")
    
    return text
  end
  
  def getDiceBotPower(params)
    message = params['originalMessage']
    
    power = 0
    if /((!|！)+)(\r|$)/ === message
      power = $1.length
    end
    
    return power
  end

  def sendChatMessageAll
    @logger.debug("sendChatMessageAll Begin")
    
    result = {'result' => "NG" }
    
    return result if( $mentenanceModePassword.nil? )
    chatData = getParamsFromRequestData()
    
    password = chatData["password"]
    return result unless( password == $mentenanceModePassword )
    
    @logger.debug("adminPoassword check OK.")
    
    rooms = []
    
    $saveDataMaxCount.times do |roomNumber|
      @logger.debug(roomNumber, "loop roomNumber")
      
      initSaveFiles(roomNumber)
      
      next unless existRoom?
      
      @logger.debug(roomNumber, "sendChatMessageAll to No.")
      sendChatMessageByChatData(chatData)
      
      rooms << roomNumber
    end
    
    result['result'] = "OK"
    result['rooms'] = rooms
    @logger.debug(result, "sendChatMessageAll End, result")
    
    return result
  end
  
  def sendChatMessage
    chatData = getParamsFromRequestData()
    sendChatMessageByChatData(chatData)
  end
  
  
  def sendChatMessageByChatData(chatData)
    
    nowFlot = Time.now.to_f
    
    changeDb do
      query("INSERT INTO chats (roomNo, id, uniqueId, senderName, message, color, channel, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            getRoomNo(),
            nil,
            chatData['uniqueId'],
            chatData['senderName'],
            chatData['message'],
            chatData['color'].hex,
            chatData['channel'],
            nowFlot)
      
      deleteOldChatMessageData()
    end
  end
  
  
  def changeDb
    connectDb
    
    if( @isTransaction )
      return yield
    end
    
    @isTransaction = true
    
    @db.query("START TRANSACTION")
    
    begin
      yield
      @db.commit
    rescue => e
      @db.rollback
      @logger.exception(e)
      throw e
    end
    
    @db.close
    @db = nil
    
    @isTransaction = false
  end
  
  
  
#FIXME  
# $oldMessageTimeout は不要になりました。
  def deleteOldChatMessageData()
    
    result = readDb( "SELECT COUNT(*)",
                     :from => "chats" )
    row = result.first
    count = row['COUNT(*)']
    @logger.debug(count, "chats count")
    
    limit = $chatMessageDataLogAllLineMax
    limitMax = limit * 2
    
    if( count < limitMax )
      @logger.debug('chats count is NOT limit.')
      return
    end
    
    query("DELETE FROM chats WHERE id <= (SELECT id FROM chats ORDER BY id DESC LIMIT 1 OFFSET ?)", 
          limit)
    
    @logger.debug('delete old chats')
  end
  
  
  def deleteChatLog
    result = {'result' => "OK" }
    
    begin
      changeDb do
        query("DELETE FROM chats")
      end
    rescue => e
      result['result'] = getErrorResponseText(e)
      @logger.exception(e)
    end
    
    return result
  end
  
  def getChatMessageDataLog(saveData)
    getArrayInfoFromHash(saveData, 'chatMessageDataLog')
  end
  
  
  def changeMap()
    mapData = getParamsFromRequestData()
    @logger.debug(mapData, "changeMap mapData")
    
    changeMapSaveData(mapData)
  end
  
  def changeMapSaveData(newMapData)
    @logger.debug("changeMap Begin")
    
    changeMapData do |oldMapData|
      newMapData
    end
    
    @logger.debug("changeMap End")
  end
  
  def getMapId()
    result = readDb( "SELECT id",
                     :from => "maps" )
    row = result.first
    return nil if row.nil?
    
    id = row['id']
    return id
  end
  
  
  def drawOnMap
    @logger.debug('drawOnMap Begin')
    
    params = getParamsFromRequestData()
    drawData = params['data']
    
    drawOnMapByMapMarks(drawData)
  end
  
  def drawOnMapByMapMarks(drawData)
    @logger.debug(drawData, 'drawOnMapByMapMarks drawData')
    
    changeMapData do |mapData|
      setDraws(mapData, drawData)
      mapData
    end
  
    @logger.debug('drawOnMap End')
  end
  
  def changeMapData
    changeDbJsonData('maps') do |data|
      yield(data)
    end
  end
  
  
  def changeDbJsonData(tableName)
    result = readDb( "SELECT id, json",
                     :from => tableName )
    row = result.first
    return if row.nil?
    
    id = row['id']
    json = row['json']
    data = getObjectFromJsonString(json)
    
    data = yield(data)
    
    json = getJsonString(data)
    changeDb do 
      updateDb(:table => tableName,
               :set => {"json" => json},
               :where => {"id = ? " => id})
    end
  end
  
  
  def changeRoomDbJsonData()
    tableName = 'rooms'
    roomNo = getRoomNo
    result = readDb( "SELECT json ",
                     :from => tableName, 
                     :where => {"roomNo = ? " => roomNo})
                           
    row = result.first
    return if row.nil?
    
    json = row['json']
    data = getObjectFromJsonString(json)
    
    data = yield(data)
    
    json = getJsonString(data)
    changeDb do 
      updateDb(:table => tableName,
               :set => {"json" => json},
               :where => {"roomNo = ? " => roomNo})
    end
  end
  
  
  
  def setDraws(mapData, data)
    return if( data.nil? )
    return if( data.empty? )
    
    info = data.first
    if( info['imgId'].nil? )
      info['imgId'] = createCharacterImgId('draw_')
    end
    
    draws = getDraws(mapData)
    draws << data
  end
  
  
  def clearDrawOnMap
    mapMarks = []
    drawOnMapByMapMarks(mapMarks)
  end
  
  
  def undoDrawOnMap
    result = {
      'data' => nil
    }
    
    changeMapData do |mapData|
      draws = getDraws(mapData)
      result['data'] = draws.pop
      mapData
    end
    
    return result
  end
  
  def getDraws(mapData)
    mapData['draws'] ||= []
    return mapData['draws']
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
  
  def changeEffectsData
    changeDbJsonData('effects') do |data|
      yield(data)
    end
  end
  
  
  def addEffectData(effectDataList)
    changeDbJsonData do |data|
      yield(data)
      
      effects = getArrayInfoFromHash(saveData, 'effects')
      
      effectDataList.each do |effectData|
        @logger.debug(effectData, "addEffectData target effectData")
        
        if( effectData['type'] == 'standingGraphicInfos' )
          keys = ['type', 'name', 'state']
          found = findEffect(effects, keys, effectData)
          
          if( found )
            @logger.debug(found, "addEffectData is already exist, found data is => ")
            next 
          end
        end
        
        effectData['effectId'] = createCharacterImgId("effects_")
        effects << effectData
      end
    end
  end
  
  def changeEffect
    effectData = getParamsFromRequestData()
    targetCutInId = effectData['effectId']
    
    changeEffectsData do |saveData|
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
    
    @logger.debug(paramEffects, "changeEffectsAll paramEffects")
    
    type = paramEffects.first['type']
    
    changeEffectsData do |saveData|
      effects = getArrayInfoFromHash(saveData, 'effects')
      
      effects.delete_if{|i| (type == i['type'])}
      
      paramEffects.each do |param|
        effects << param
      end
      
      saveData
    end
  end
  
  
  def removeEffect()
    @logger.debug('removeEffect Begin')
    
    params = getParamsFromRequestData()
    effectIds = params['effectIds']
    @logger.debug(effectIds, 'effectIds')
    
    changeEffectsData do |saveData|
      
      effects = getArrayInfoFromHash(saveData, 'effects')
      @logger.debug(effects, 'effects')
      
      effects.delete_if{|i|
        effectIds.include?(i['effectId'])
      }
      
      saveData
    end
    
    @logger.debug('removeEffect End')
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
    @logger.debug(imageInfoFileName, 'imageInfoFileName')
    
    return imageInfoFileName
  end
  
  def changeImageTags()
    effectData = getParamsFromRequestData()
    image = DodontoF_MySqlKai::Image.new(self)
    image.changeImageTags(effectData)
  end
  
  def deleteFile(file)
    return unless File.exist?(file)
    File.delete(file)
  end
  
  def getImageTagsAndImageList
    image = DodontoF_MySqlKai::Image.new(self)
    image.getImageTagsAndImageList()
  end
  
  
  def createCharacterImgId(prefix = "character_")
    return nil
=begin
    @imgIdIndex ||= 0;
    @imgIdIndex += 1;
    
    #return (prefix + Time.now.to_f.to_s + "_" + @imgIdIndex.to_s);
    return (prefix + sprintf("%.4f_%04d", Time.now.to_f, @imgIdIndex));
=end
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
    
    @logger.debug("target characterData is already exist. no creation.", "isAlreadyExistCharacter?")
    return characterData['name']
  end
  
  ########FIXME
  
  def addCharacterData(characterDataList, stateList = [])
    result = {
      "addFailedCharacterNames" => []
    }
    
    changeDb do
      characterDataList.each_with_index do |characterData, index|
        state = stateList[index]
        state ||= $characterStateNomal
        
        query("INSERT INTO characters (roomNo, id, json, type, state, update_index) VALUES (?, ?, ?, ?, ?, ?)", 
               getRoomNo(), nil, "", characterData['type'], state, 1 )
        
        result = query("select LAST_INSERT_ID()")
        imgId = result.first["LAST_INSERT_ID()"].to_s
        @logger.debug(imgId, "insert imgId")
        
        characterData['imgId'] = imgId
        updateCharacters(characterData)
      end
    end
    
    result = readDb("SELECT *",
                    :from => "characters",
                    :others => ["ORDER BY id"])
    shapeUpDbResult(result)
    
    @logger.debug(result, "added characters")
    
    return result
    
=begin
        failedName = isAlreadyExistCharacterInRoom?( saveData, characterData )
        
        if( failedName )
          result["addFailedCharacterNames"] << failedName
          next
        end
=end
  end
  
  def updateCharacters(params, imgId = nil, state = nil)
    
    imgId = params['imgId'] if imgId.nil?
    
    json = getJsonString(params)
    
    setData = {"json" => json }
    setData["state"] = state unless state.nil?
    
    changeDb do
      updateDb(:table => 'characters',
               :set => setData,
               :where => {"id=? " => imgId} )
    end
  end
  
  def isAlreadyExistCharacterInRoom?( saveData, characterData )
    characters = getCharactersFromSaveData(saveData)
    waitingRoom = getWaitinigRoomFromSaveData(saveData)
    allCharacters = (characters + waitingRoom)
    
    failedName = isAlreadyExistCharacter?( allCharacters, characterData )
    return failedName
  end
  
  
  def changeCharacter()
    @logger.debug("changeCharacter")
    
    characterData = getParamsFromRequestData()
    @logger.debug(characterData, "characterData")
    
    changeCharacterData(characterData)
  end
  
  def changeCharacterData(characterData)
    changeDb do
      updateCharacters(characterData)
      @logger.debug(characterData, "character data change")
    end
    
=begin
      unless( characterData['name'].nil? or characterData['name'].empty? )
        alreadyExist = characters.find do |character|
          ( (character['name'] == characterData['name']) and
              (character['imgId'] != characterData['imgId']) )
        end
        
        if( alreadyExist ) 
          @logger.debug("same name character alread exist");
          return;
        end
      end
=end
      
  end
  
  def getIdFromCharacterData(characterData)
    characterData['imgId'].to_i
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
    @logger.debug("addCardZone Begin");
    
    data = getParamsFromRequestData()
    
    x = data['x']
    y = data['y']
    owner = data['owner']
    ownerName = data['ownerName']
    
    changeDb do
      cardData = getCardZoneData(owner, ownerName, x, y)
      addCharacterData( [cardData] )
    end
    
    @logger.debug("addCardZone End");
  end
  
  
  def initCards()
    @logger.debug("initCards Begin");
    
    clearAllCards
    
    params = getParamsFromRequestData()
    cardTypeInfos = params['cardTypeInfos']
    @logger.debug(cardTypeInfos, "cardTypeInfos")
    
    allCards = []
    stateList = []
    
    cardTypeInfos.each_with_index do |cardTypeInfo, index|
      mountName = cardTypeInfo['mountName']
      
      cards, cardMount, cardTrushMount = getInitCardMountInfos(cardTypeInfo, mountName, index)
      
      allCards.concat( cards )
      stateList.concat( Array.new(cards.size, $characterStateCardMount) )
      
      allCards << cardMount
      allCards << cardTrushMount
      stateList << $characterStateNomal
      stateList << $characterStateNomal
    end
    
    @logger.debug(allCards, "allCards")
    @logger.debug(stateList, "stateList")
    
    addCharacterData(allCards, stateList)
    
    waitForRefresh = 0.2
    sleep( waitForRefresh )
    
    @logger.debug("initCards End");
    
    cardExist = (not cardTypeInfos.empty?)
    return {"result" => "OK", "cardExist" => cardExist }
  end
  
  
  def clearAllCards
    clearCharacterByTypeLocal(getCardType)
    clearCharacterByTypeLocal(getCardMountType)
    clearCharacterByTypeLocal(getRandomDungeonCardMountType)
    clearCharacterByTypeLocal(getCardZoneType)
    clearCharacterByTypeLocal(getCardTrushMountType)
    clearCharacterByTypeLocal(getRandomDungeonCardTrushMountType)
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
    @logger.debug(cardsListFileName, "initCards cardsListFileName");
    
    cardsList = []
    readLines(cardsListFileName).each_with_index  do |i, lineIndex|
      cardsList << i.chomp.toutf8
    end
    
    @logger.debug(cardsList, "initCards cardsList")
    
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
      
      @logger.debug(imageName, "initCards imageName")
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
    @logger.debug("addCard begin");
    
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
    
    changeDb do
      cardData = getCardData(isText, imageName, imageNameBack, mountName, isUpDown, canDelete, canRewrite)
      cardData["x"] = addCardData['x']
      cardData["y"] = addCardData['y']
      cardData["isOpen"] = isOpen unless( isOpen.nil? )
      cardData["isBack"] = isBack unless( isBack.nil? )
      
      addCharacterData( [cardData] )
    end
    
    @logger.debug("addCard end");
    
  end
  
  #トランプのジョーカー枚数、使用デッキ数の指定
  def getInitCardSet(cardsList, cardTypeInfo)
    if( isRandomDungeonTrump(cardTypeInfo) )
      cardsListTmp = getInitCardSetForRandomDungenTrump(cardsList, cardTypeInfo)
      return cardsListTmp, true
    end
    
    useLineCount = cardTypeInfo['useLineCount']
    useLineCount ||= cardsList.size
    @logger.debug(useLineCount, 'useLineCount')
    
    deckCount = cardTypeInfo['deckCount']
    deckCount ||= 1
    @logger.debug(deckCount, 'deckCount')
    
    cardsListTmp = []
    deckCount.to_i.times do
      cardsListTmp += cardsList[0...useLineCount]
    end
    
    return cardsListTmp, false
  end
  
  def getInitCardSetForRandomDungenTrump(cardList, cardTypeInfo)
    @logger.debug("getInitCardSetForRandomDungenTrump start")
    
    @logger.debug(cardList.length, "cardList.length")
    @logger.debug(cardTypeInfo, "cardTypeInfo")
    
    useCount = cardTypeInfo['cardCount']
    jorkerCount = cardTypeInfo['jorkerCount']
    
    useLineCount = 13 * 4 + jorkerCount
    cardList = cardList[0...useLineCount]
    @logger.debug(cardList.length, "cardList.length")
    
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
    
    @logger.debug(aceList, "aceList");
    @logger.debug(aceList.length, "aceList.length");
    @logger.debug(noAceList.length, "noAceList.length");
    
    cardTypeInfo['aceList'] = aceList.clone
    
    result = []
    
    aceList = aceList.sort_by{rand}
    result << aceList.shift
    @logger.debug(aceList, "aceList shifted");
    @logger.debug(result, "result");
    
    noAceList = noAceList.sort_by{rand}
    
    while( result.length < useCount )
      result << noAceList.shift
      break if( noAceList.length <= 0 )
    end
    
    result = result.sort_by{rand}
    @logger.debug(result, "result.sorted");
    @logger.debug(noAceList, "noAceList is empty? please check");
    
    while(aceList.length > 0)
      result << aceList.shift
    end
    
    while(noAceList.length > 0)
      result << noAceList.shift
    end
    
    @logger.debug(result, "getInitCardSetForRandomDungenTrump end, result")
    
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
    
    setNextCardId(cardMountData, cards)
    
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
  
  def setTrushMountDataCardsInfo(cardMountData, cards)
    @logger.debug("setTrushMountDataCardsInfo Begin")
    
    mountName = cardMountData['mountName']
    imageName, _, isText = getCardTrushMountImageName(mountName, cards.last)
    
    cardMountData['cardCount'] = cards.size
    cardMountData["imageName"] = imageName
    cardMountData["imageNameBack"] = imageName
    cardMountData["isText"] = isText
    
    @logger.debug(cardMountData, "setTrushMountDataCardsInfo cardMountData")
    
    updateCharacters(cardMountData)
    
    @logger.debug("setTrushMountDataCardsInfo End")
  end
  
  def getCardTrushMountImageName(mountName, cardData = nil)
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
    @logger.debug("returnCard Begin");
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    @logger.debug(mountName, "mountName")
    
    changeDb do
      
      trushCards = getTrushMountCards(mountName)
      
      cardData = trushCards.pop
      @logger.debug(cardData, "cardData")
      
      if( cardData.nil? )
        @logger.debug("returnCard trushCards is empty. END.")
        return
      end
      
      cardData['x'] = params['x'] + 150
      cardData['y'] = params['y'] + 10
      @logger.debug('returned cardData', cardData)
      
      updateCharacters(cardData, nil, $characterStateNomal)
      
      trushMountData = findCharacterDataById( params['imgId'] )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
    end
    
    @logger.debug("returnCard End");
  end
  
  def drawCard()
    @logger.debug("drawCard Begin")
    
    params = getParamsFromRequestData()
    @logger.debug(params, 'params')
    
    result = {
      "result" => "NG"
    }
    
    changeDb do
      
      count = params['count']
      mountName = params['mountName']
      
      cards = getMountCards(mountName)
      
      cardDataList = []
      count.times do
        cardData = drawCardDataOne(params, cards)
        cardDataList << cardData if( cardData.nil? )
      end
      
      result["cardDataList"] = cardDataList
      result["result"] = "OK"
    end
    
    @logger.debug(result, "drawCard End")
    
    return result
  end
  
  def getMountCards(mountName)
    getMountCardsByMountType(mountName, $characterStateCardMount)
  end
  
  def getTrushMountCards(mountName)
    getMountCardsByMountType(mountName, $characterStateCardTrushMount)
  end
  
  def getMountCardsByMountType(mountName, mountType)
    result = getAllCharacters(mountType, true)
    @logger.debug(result, "drawCard base targets.")
    
    cards = result.collect{|i| getObjectFromJsonString(i["json"])}
    cards.delete_if{|i| i['mountName'] != mountName}
    
    return cards
  end
  
  
  
  def drawCardDataOne(params, cards)
    @logger.debug("drawCardDataOne Begin")
    
    imgId = params['imgId']
    cardMount = findCharacterDataById(imgId)
    return nil if( cardMount.nil? )
    
    @logger.debug(cardMount, "cardMount")
    
    cardCountDisplayDiff = cardMount['cardCountDisplayDiff']
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
    
    updateCharacters(cardData, nil, $characterStateNomal)
    
    @logger.debug(cards.size, 'cardMount[mountName].size')
    setCardCountAndBackImage(cardMount, cards)
    
    @logger.debug(cardData, "drawCardDataOne End")
    
    return cardData
  end
  

  def drawTargetTrushCard
    @logger.debug("drawTargetTrushCard Begin");
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    @logger.debug(mountName, "mountName")
    
    changeDb do
      cardData = findCharacterDataById(params['targetCardId'] )
      @logger.debug(cardData, "cardData")
      return if( cardData.nil? )
      
      cardData['x'] = params['x']
      cardData['y'] = params['y']
      
      updateCharacters(cardData, nil, $characterStateNomal)
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( params['mountId'] )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
    end
    
    @logger.debug("drawTargetTrushCard End");
    
    return {"result" => "OK"}
  end
  
  def drawTargetCard
    @logger.debug("drawTargetCard Begin")
    
    params = getParamsFromRequestData()
    @logger.debug(params, 'params')
    
    mountName = params['mountName']
    @logger.debug(mountName, 'mountName')
    
    changeDb do
      cards = getMountCards(mountName)
      cardData = cards.find{|i| i['imgId'] === params['targetCardId'] }
      
      if( cardData.nil? )
        @logger.debug(params['targetCardId'], "not found params['targetCardId']")
        return
      end
      
      cards.delete(cardData)
      
      cardData['x'] = params['x']
      cardData['y'] = params['y']
      
      cardData['isOpen'] = false
      cardData['isBack'] = false
      cardData['owner'] = params['owner']
      cardData['ownerName'] = params['ownerName']
      
      addCharacterData( [cardData] )
      
      cardMountData = findCharacterDataById( params['mountId'] )
      return if cardMountData.nil?
      
      @logger.debug(cards.size, 'cardMount[mountName].size')
      setCardCountAndBackImage(cardMountData, cards)
    end
    
    @logger.debug("drawTargetCard End")
    
    return {"result" => "OK"}
  end
  
  
  def setCardCountAndBackImage(cardMountData, cards)
    @logger.debug("setCardCountAndBackImage Begin")
    
    cardMountData['cardCount'] = cards.size
    
    card = cards.last
    unless( card.nil? )
      image = card["imageNameBack"]
      unless( image.nil? ) 
        cardMountData["imageNameBack"] = image
      end
    end
    
    @logger.debug(cardMountData, "setCardCountAndBackImage cardMountData")
    updateCharacters(cardMountData)
    
    @logger.debug("setCardCountAndBackImage End")
  end
  
  def dumpTrushCards()
    @logger.debug("dumpTrushCards Begin")
    
    params = getParamsFromRequestData()
    @logger.debug(params, 'dumpTrushCards params')
    
    mountName = params['mountName']
    @logger.debug(mountName, 'mountName')
    
    changeDb do
      card = findCharacterById( params['dumpedCardId'] )
      cardData = getObjectFromJsonString(card["json"])
      
      updateCharacters(cardData, nil, $characterStateCardTrushMount)
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( params['trushMountId'] )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
    end
    
    @logger.debug("dumpTrushCards End")
  end
  
  
  def shuffleCards
    @logger.debug("shuffleCard Begin")
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    trushMountId = params['mountId']
    isShuffle = params['isShuffle']
    
    @logger.debug(mountName, 'mountName')
    @logger.debug(trushMountId, 'trushMountId')
    
    changeDb do
      trushCards = getTrushMountCards(mountName)
      trushCards.each do |cardData|
        setTrushCardToMountSate(cardData)
        updateCharacters(cardData, nil, $characterStateCardMount)
      end
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( trushMountId )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
      
      cardMountData = findCardMountDataByType(mountName, getCardMountType)
      return if( cardMountData.nil?) 
      
      mountCards = getMountCards(mountName)
      
      if( isShuffle )
        isUpDown = cardMountData['isUpDown']
        mountCards = getShuffledMount(mountCards, isUpDown)
        
        mountCards.each do |data|
          updateCharacters(data, nil)
        end
      end
      
      @logger.debug(mountCards, "mountCards")
      @logger.debug(cardMountData, "cardMountData")
      
      setNextCardId(cardMountData, mountCards)
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    @logger.debug("shuffleCard End")
  end
  
  
  def setNextCardId(cardMountData, cards)
    return if cards.first.nil?
    cardMountData['nextCardId'] = cards.first['imgId']
  end
  
  def shuffleForNextRandomDungeon
    @logger.debug("shuffleForNextRandomDungeon Begin")
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    trushMountId = params['mountId']
    
    @logger.debug(mountName, 'mountName')
    @logger.debug(trushMountId, 'trushMountId')
    
    changeDb do
      
      trushCards = getTrushMountCards(mountName)
      mountCards = getMountCards(mountName)
      
      cardMountData = findCardMountDataByType(mountName, getRandomDungeonCardMountType)
      return if( cardMountData.nil?) 
      
      aceList = cardMountData['aceList']
      @logger.debug(aceList, "aceList")
      
      result = getAllCharacters()
      characters = result.collect{|i| getObjectFromJsonString(i["json"])}
      
      aceCards = []
      aceCards += deleteAceFromCards(trushCards, aceList)
      aceCards += deleteAceFromCards(mountCards, aceList)
      aceCards += deleteAceFromCards(characters, aceList)
      aceCards = aceCards.sort_by{rand}
      
      @logger.debug(aceCards, "aceCards")
      @logger.debug(trushCards.length, "trushCards.length")
      @logger.debug(mountCards.length, "mountCards.length")
      
      useCount = cardMountData['useCount']
      if( (mountCards.size + 1) < useCount )
        useCount = (mountCards.size + 1)
      end
      
      mountCards = mountCards.sort_by{rand}
      
      insertPoint = rand(useCount)
      @logger.debug(insertPoint, "insertPoint")
      mountCards[insertPoint, 0] = aceCards.shift
      
      while( aceCards.length > 0 )
        mountCards[useCount, 0] = aceCards.shift
        @logger.debug(useCount, "useCount")
      end
      
      mountCards = mountCards.reverse
      
      newDiff = mountCards.size - useCount
      newDiff = 3 if( newDiff < 3 )
      @logger.debug(newDiff, "newDiff")
      cardMountData['cardCountDisplayDiff'] = newDiff
      
      updateCharacters(mountCards, nil, $characterStateCardMount)
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( trushMountId )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
      
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    @logger.debug("shuffleForNextRandomDungeon End")
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
  
  def findCardMountDataByType(mountName, cardMountType)
    
    result = readDb( "SELECT *",
                     :from => "characters",
                     :where => {"type = ? " => cardMountType} )
    characters = result.collect{|i| getObjectFromJsonString(i["json"])}
    
    cardMountData = characters.find do |i| 
      i['mountName'] == mountName
    end
    
    return nil if(cardMountData.nil?)
    
    return cardMountData
  end
  
  def getShuffledMount(mountCards, isUpDown)
    mountCards = mountCards.sort_by{rand}
    mountCards.each do |i|
      i["rotation"] = getRotation(isUpDown)
    end
    
    return mountCards
  end
  
  def setTrushCardToMountSate(cardData)
    cardData['isOpen'] = false
    cardData['isBack'] = true
    cardData['owner'] = ""
    cardData['ownerName'] = ""
  end
  
  
  def getMountCardInfos
    params = getParamsFromRequestData()
    @logger.debug(params, 'getMountCardInfos params')
    
    mountName = params['mountName']
    mountId = params['mountId']
    
    cards = []
    
    changeDb do
      cards = getMountCards(mountName)
    
      cardMountData = findCharacterDataById(mountId)
      return nil if( cardMountData.nil? )
      
      cardCountDisplayDiff = cardMountData['cardCountDisplayDiff']
      
      @logger.debug(cardCountDisplayDiff, "cardCountDisplayDiff")
      @logger.debug(cards.length, "before cards.length")
      
      unless( cardCountDisplayDiff.nil? )
        unless( cards.empty? )
          cards = cards[cardCountDisplayDiff .. -1]
        end
      end
      
    end
    
    @logger.debug(cards.length, "getMountCardInfos cards.length")
    
    return cards
  end
  
  def getTrushMountCardInfos
    
    params = getParamsFromRequestData()
    @logger.debug(params, 'getTrushMountCardInfos params')
    
    cards = []
    
    changeDb do
      cards = getTrushMountCards( params['mountName'] )
    end
    
    return cards
  end
  
  
  def getCardList
    params = getParamsFromRequestData()
    @logger.debug(params, 'getCardList params')
    
    mountName = params['mountName']
    cardTypeInfo = {'mountName' => mountName}
    index = 0
    
    cardMount, = getInitCardMountInfos(cardTypeInfo, mountName, index)
    
    @logger.debug(cardMount, 'cardMount')
    
    return cardMount
  end
  
  
  def clearCharacterByType()
    @logger.debug("clearCharacterByType Begin")
    
    clearData = getParamsFromRequestData()
    @logger.debug(clearData, 'clearData')
    
    targetTypes = clearData['types']
    @logger.debug(targetTypes, 'targetTypes')
    
    targetTypes.each do |targetType|
      clearCharacterByTypeLocal(targetType)
    end
    
    @logger.debug("clearCharacterByType End")
  end
  
  def clearCharacterByTypeLocal(targetType)
    @logger.debug(targetType, "clearCharacterByTypeLocal targetType")
    
    changeDb do
      updateDb(:table => 'characters',
               :set => {"state" => $characterStateDeleted },
               :where => {"type=? " => targetType} )
    end
    
    @logger.debug("clearCharacterByTypeLocal End")
  end
  
  
  def removeCharacter()
    removeCharacterDataList = getParamsFromRequestData()
    removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
  end
  
  
  def removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
    @logger.debug(removeCharacterDataList, "removeCharacterDataList")
    
    changeDb do
      
      removeCharacterDataList.each do |removeCharacterData|
        @logger.debug(removeCharacterData, "removeCharacterData")
        
        isGotoGraveyard = removeCharacterData['isGotoGraveyard']
        
        imgId = removeCharacterData['imgId']
        character = findCharacterById(imgId)
        
        @logger.debug(character, "remove target character")
        next if character.nil?
        
        state = (isGotoGraveyard ? $characterStateGraveyard : $characterStateDeleted)
        
        @logger.debug("remove character")
        updateDb(:table => 'characters',
                 :set => {"state" => state },
                 :where => {"id=? " => imgId} )
      end
    end
    
=begin
    while(graveyard.size > $graveyardLimit)
      graveyard.shift
    end
=end
  
  end
  

  def enterWaitingRoomCharacter
    params = getParamsFromRequestData()
    characterId = params['characterId']
    # index = params['index']
    
    changeDb do
      updateDb(:table => 'characters',
               :set => {"state" => $characterStateWaitingRoom},
               :where => {"id=? " => characterId} )
    end
    
    return getWaitingRoomInfo()
=begin
    index = params['index']
      target = removeFromArray(characters) {|i| (i['imgId'] == characterId) }
      
      #待合室内をソートしている場合はこちらが適用されます
      target ||= removeFromArray(waitingRoom) {|i| (i['imgId'] == characterId) }
      
=end
  end
  
  
  def resurrectCharacter
    params = getParamsFromRequestData()
    resurrectCharacterId = params['imgId']
    @logger.debug(resurrectCharacterId, "resurrectCharacterId")
    
    changeDb do
      updateDb(:table => 'characters',
               :set => {"state" => $characterStateNomal},
               :where => {"id=? " => resurrectCharacterId} )
    end
    
    return nil
  end
  
  def clearGraveyard
    @logger.debug("clearGraveyard begin")

    changeDb do
      query("DELETE FROM characters WHERE state = ?",
            $characterStateGraveyard)
    end
    
    return nil
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
    @logger.debug("exitWaitingRoomCharacter Begin")
    
    params = getParamsFromRequestData()
    characterId = params['characterId']
    x = params['x']
    y = params['y']
    
    @logger.debug(characterId, 'exitWaitingRoomCharacter characterId')
    
    result = {"result" => "NG"}
    
    changeDb do
      character = findCharacterById(characterId)
      return result if(character.nil?)
      
      data = getObjectFromJsonString(character["json"])
      data['x'] = x
      data['y'] = y
      
      json = getJsonString(data)
      
      changeDb do
        updateDb(:table => 'characters',
                 :set => {"state" => $characterStateNomal,
                          "json" => json},
                 :where => {"id=? " => characterId} )
      end
    end
    
    result["result"] = "OK"
    return result
  end
  
  
  def removeFromArray(array)
    index = nil
    
    array.each_with_index do |i, targetIndex|
      @logger.debug(i, "i")
      @logger.debug(targetIndex, "targetIndex")
      b = yield(i)
      @logger.debug(b, "yield(i)")
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
    changeTimerData do |saveData|
      saveData['roundTimeData'] = roundTimeData
      saveData
    end
  end
  
  
  
  def addResource()
    params = getParamsFromRequestData()
    
    changeTimerData do |saveData|
      resource = getResourceFromSaveData(saveData)
      
      params['resourceId'] = createCharacterImgId("resource_")
      resource << params
      saveData
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
    
    changeTimerData do |saveData|
      resource = getResourceFromSaveData(saveData)
      
      resource.clear
      
      params.each do |param|
        resource << param
      end
      
      saveData
    end
  end
  
  def removeResource()
    params = getParamsFromRequestData()
    
    editResource(params) do |resource, index|
      resource.delete_at(index)
    end
  end
  
  
  def editResource(params)
    changeTimerData do |saveData|
      resource = getResourceFromSaveData(saveData)
      
      resourceId = params['resourceId']
      
      index = findIndexFromArray(resource) do |i|
        i['resourceId'] == resourceId
      end
      
      if( index.nil? )
        return
      end
      
      yield(resource, index)
      
      saveData
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
  
  
  #FIXME
  def moveCharacter()
    
    params = getParamsFromRequestData()
    
    changeDb do
      imgId = getIdFromCharacterData(params)
      character = findCharacterById(imgId)
      
      return if(character.nil?)
      
      data = getObjectFromJsonString(character["json"])
      data['x'] = params['x']
      data['y'] = params['y']
      
      updateCharacters(data, imgId)
      @logger.debug(data, "character data change")
    end
    
  end
  
  def findCharacterDataById(imgId)
    character = findCharacterById(imgId)
    return nil if character.nil?
    
    return getObjectFromJsonString( character["json"] )
  end
  
  def findCharacterById(imgId)
    result = readDb( "SELECT *",
                     :from => 'characters',
                     :where => {"id = ? " => imgId} )
    shapeUpDbResult(result)
    character = result.first
    return character
  end
  
  #override
  def getSaveFileTimeStamp(saveFileName)
    unless( isExist?(saveFileName) ) 
      return 0
    end
    
    timeStamp = File.mtime(saveFileName).to_f
    return timeStamp
  end
  
  def getResponse
    response =
      if DodontoF::MsgpackLoader.failed?
        {
          'warning' => { 'key' => 'youNeedInstallMsgPack' }
        }
      else
        analyzeCommand
      end

    return getJsonString(response)
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

  logger = DodontoF::Logger.instance

  stringIo = StringIO.new
  Zlib::GzipWriter.wrap(stringIo) do |gz|
    gz.write(result)
    gz.flush
    gz.finish
  end

  gzipResult = stringIo.string
  logger.debug(gzipResult.length.to_s, "CGI response zipped length  ")

  return gzipResult
end


def main(cgiParams)
  logger = DodontoF::Logger.instance

  logger.debug("main called")
  server = DodontoFServer_MySqlKai.new(SaveDirInfo.new(), cgiParams)
  logger.debug("server created")
  printResult(server)
  logger.debug("printResult called")
end

def printResult(server)
  logger = DodontoF::Logger.instance

  logger.debug("========================================>CGI begin.")

  text = "empty"

  header = $isModRuby ? '' : "Content-Type: application/json\n"

  begin
    result = server.getResponse

    if( server.jsonpCallBack )
      result = "#{server.jsonpCallBack}(" + result + ");";
    end

    logger.debug(result.length.to_s, "CGI response original length")

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
    logger.error(errorMessage, "errorMessage")

    text = "\n= ERROR ====================\n"
    text << errorMessage
    text << "============================\n"
  end

  logger.debug(header, "RESPONSE header")

  output = $stdout
  output.binmode if( defined?(output.binmode) )

  output.print( header + "\n")

  output.print( text )

  logger.debug("========================================>CGI end.")
end


def getCgiParams()
  logger = DodontoF::Logger.instance

  logger.debug("getCgiParams Begin")

  logger.debug(ENV['REQUEST_METHOD'], "ENV[REQUEST_METHOD]")
  input = nil
  messagePackedData = {}
  if( ENV['REQUEST_METHOD'].to_s == "POST" and
      ENV['CONTENT_TYPE'].to_s == "application/x-msgpack" )
    length = ENV['CONTENT_LENGTH'].to_i
    logger.debug(length, "getCgiParams length")

    input = $stdin.read(length)
    logger.debug(input, "getCgiParams input")
    messagePackedData = DodontoFServer_MySqlKai.getMessagePackFromData( input )
  end

  logger.debug(messagePackedData, "messagePackedData")
  logger.debug("getCgiParams End")

  return messagePackedData
end


def executeDodontoServerCgi()
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

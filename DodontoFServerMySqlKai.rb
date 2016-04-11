#!/usr/local/bin/ruby
#--*-coding:utf-8-*--
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby/ruby-mysql"
$LOAD_PATH << File.dirname(__FILE__) + "/src_bcdice"
$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

#CGI通信の主幹クラス用ファイル
#ファイルアップロード系以外は全てこのファイルへ通知が送られます。
#DB(MySQL)から各種データを読み出し・書き出しするのが主な作業。
#変更可能な設定は config.rb にまとめているため、環境設定のためにこのファイルを変更する必要は基本的には無いです。


#サーバCGIとクライアントFlashのバージョン一致確認用
$versionOnly = "Ver.1.47.24"
$versionDate = "2016/04/07"
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

require 'mysql'

if( $isFirstCgi )
  require 'cgiPatch_forFirstCgi'
end

# require "configMysqlKai.rb"
require "config.rb"

begin
  require "config_local.rb"
rescue Exception
end

if $isTestMode
  require "config_test.rb"
end


require "loggingFunction.rb"
require "FileLock.rb"
require "saveDirInfoMysql.rb"
require "CommandServer.rb"


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

class DodontoFServer < CommandServer
  
  def initialize(saveDirInfo, cgiParams)
    super cgiParams

    @saveDirInfo = saveDirInfo
    
    roomIndexKey = "room"
    initSaveFiles( getRequestData(roomIndexKey) )
    
    @isAddMarker = false
    @jsonpCallBack = nil
    @isJsonResult = true
    
    @diceBotTablePrefix = 'diceBotTable_'
    @fullBackupFileBaseName = "DodontoFFullBackup"
    
    @allSaveDataFileExt = '.tar.gz'
    @defaultAllSaveData = 'default.sav'
    @defaultChatPallete = 'default.cpd'
    
    @card = nil
  end
  
  def initSaveFiles(roomNumber)
    @saveDirInfo.init(roomNumber, $saveDataMaxCount, $SAVE_DATA_DIR)
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
  
  
  
  def getCommandSender
    if( @commandSender.nil? )
      @commandSender = getRequestData('own')
    end
    
    logging(@commandSender, "@commandSender")
    
    return @commandSender
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
  
  def analyzeWebInterface
    logging("analyzeWebInterfaceCatched begin")
    
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
    
    case commandName
    when 'getBusyInfo'
      return getBusyInfo
    when 'getServerInfo'
      return getWebIfServerInfo
    when 'getRoomList'
      return getWebIfRoomList
    when 'getLoginInfo'
      return getWebIfLoginInfo
    end
    
    loginOnWebInterface
    
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
    when 'refresh'
      return getWebIfRefresh
    when 'getLoginUserInfo'
      return getWebIfLoginUserInfo
    end
    
    return {'result'=> "command [#{commandName}] is NOT found"}
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
  
  def server_type_name
    "どどんとふ(MySQL-Kai)"
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
      logging(saveFileTypeName, "saveFileTypeName")
      
      func = @getCurrentSaveDataMethods[saveFileTypeName]
      
      next if func.nil?
      
      func.call do |targetSaveData|
        yield(targetSaveData, saveFileTypeName)
      end
    end
  end
  
  
  
  def getCurrentSaveDataForDbCharacter()
    logging("getCurrentSaveDataForDbCharacter Begin")
    
    update_index = @lastUpdateTimes['characters']
    logging(update_index, "characters update_index")
    
    lastTime = getLastUpdate('characters', update_index)
    logging(lastTime, "lastTime")
    
    # 最終更新が0の場合は結果が空の証拠なので取得無し
    if lastTime == 0
      logging("characters has NO change")
      return 
    end
    
    result = getAllCharacters()
    logging(result.size, "characters get result.size")
    logging(result, "characters get result")
    
    logging("New characters.")
    
    saveData = {}
    result.each do |row|
      saveData["characters"] ||= []
      saveData["characters"] << row["json"] # getJsonDataFromText( row["json"] )
    end
    
    @lastUpdateTimes['characters'] = lastTime
    
    yield(saveData)
    
    logging("getCurrentSaveDataForDbCharacter End")
  end
  
  def getLastUpdate(tableName, update_index)
    lastUpdateResult = readDb( "SELECT MAX(update_index)",
                               :from => tableName,
                               :where => {'update_index > ? ' => update_index} )
    
    lastTime = lastUpdateResult.first['MAX(update_index)'].to_i
    logging(lastTime, "lastTime")
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
    logging("getCurrentSaveDataForDbChat Begin")
    
    lastId = @lastUpdateTimes['chatMessageDataLog']
    
    result = readDb( "SELECT *",
                     :from => 'chats',
                     :where => {'id > ? ' => lastId} )
    logging(result, "chats get result")
    
    return if result.empty?
    
    logging("New chats message.")
    
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
    
    logging(saveData, "getCurrentSaveDataForDbChat saveData")
    logging("getCurrentSaveDataForDbChat End")
  end
  
  
  def getCurrentSaveDataForDbMap()
    logging("getCurrentSaveDataForDbMap Begin")
    
    getCurrentSaveDataForDbJsonType('map', 'maps') do |data|
      saveData = {}
      saveData['mapData'] = data
      yield(saveData)
    end
    
    logging("getCurrentSaveDataForDbMap End")
  end
  
  
  def getCurrentSaveDataForDbTime()
    logging("getCurrentSaveDataForDbTime Begin")
    
    getCurrentSaveDataForDbJsonType('time', 'times') do |data|
      saveData = {}
      saveData['roundTimeData'] = data['roundTimeData']
      yield(saveData)
    end
    
    logging("getCurrentSaveDataForDbTime End")
  end
  
  
  def getCurrentSaveDataForDbEffects()
    logging("getCurrentSaveDataForDbEffects Begin")
    
    getCurrentSaveDataForDbJsonType('effects', 'effects') do |data|
      saveData = {}
      saveData['effects'] = data['effects']
      yield(saveData)
    end
    
    logging("getCurrentSaveDataForDbTime End")
  end
  
  
  def getCurrentSaveDataForDbPlayRoom()
    logging("getCurrentSaveDataForDbPlayRoom Begin")
    
    getCurrentSaveDataForDbJsonType('playRoomInfo', 'rooms') do |data|
      logging(data, 'getCurrentSaveDataForDbPlayRoom data')
      
      saveData = data
      yield(saveData)
    end
    
    logging("getCurrentSaveDataForDbPlayRoom End")
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
    data = getJsonDataFromText( row["json"] )
    
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
      list[roomNo] = getJsonDataFromText( row["json"] )
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
    
    data = getJsonDataFromText( row["json"] )
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
    logging(commandText, "readDbCommon commandText")
    
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
    
    logging(commandText, "readDbCommon commandText")
    
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
      loggingException(e)
      loggingForce([commandText, params].inspect)
      loggingForce("commandText : #{commandText}")
      throw e
    end
    
    return result
  end
  
  def queryCatched(commandText, *params)
    logging("\n\n" + commandText + "\n", "query commandText")
    logging(params, "query params")
    
    sqlResult = nil
    
    statement = @db.prepare(commandText)
    sqlResult = statement.execute(*params)
    
    result = []
    return result if sqlResult.nil?
    return result unless sqlResult.hasResult
    
    sqlResult.each_hash do |row|
      result << row
    end
    
    logging(result, "query end result")
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
    logging("connectDbCommon Begin")
    
    return db unless( db.nil? )
    
    db = Mysql::new($databaseHostName, $databaseUserName, $databasePassword, $databaseName)
    
    logging("connectDbCommon End")
    return db
  end
  
  def isTableExist(tableName)
    connectDb
    
    result = @db.query("SHOW TABLES FROM #{$databaseName} LIKE '#{tableName}'")
    count = result.num_rows()
    return ( count != 0 )
  end
  
  
  def initDb
    
    logging("initDb Begin")
    
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
      loggingException(e)
      throw e
    end
    
    logging("initDb End")
  end

  command_noreturn
  def dropAllDb
    %w{chats characters maps times effects users rooms}.each do |target|
      
      logging("dropAllDb #{target}")
      
      next unless isTableExist(target)
      
      logging("dropAllDb #{target} DROP EXECUTE!")
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
      return 0
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
      "loginCount" => getLoginCount(),
      "maxLoginCount" => $aboutMaxLoginCount,
      "version" => $version,
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
    logging(channel, "channel")
    
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
    
    changeDb do
      
      result = getAllCharacters()
      
      characterData = nil
      result.each do |row|
        data = getJsonDataFromText( row["json"] )
        
        if data['name'] == targetName
          characterData = data
          break
        end
      end
      
      if( characterData.nil? )
        raise "「#{targetName}」という名前のキャラクターは存在しません"
      end
      
      name = getWebIfRequestAny(:getWebIfRequestText, 'name', characterData)
      logging(name, "name")
      
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
    logging("getWebIfRoomInfo begin")
    
    result = {}
    result['result'] = 'OK'
    
    changeTimerData do |saveData|
      roundTimeData = getHashValue(saveData, 'roundTimeData', {})
      result['counter'] = getHashValue(roundTimeData, "counterNames", [])
      saveData
    end
    
    roomInfo = getRoomInfoForWebIf
    result.merge!(roomInfo)
    
    logging(result, "getWebIfRoomInfo result")
    
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
    logging("setWebIfRoomInfo begin")
    
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
    
    changeTimerData do |saveData|
      roundTimeData = getRoundTimeDataFromSaveData(saveData)
      roundTimeData['counterNames'] = counterNames
      saveData
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
      'playRoomInfo' => getWebIfRequestNumber('roomInfo', -1),
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
  
  command
  def refresh
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
    updateLoginUserInfo(userName, uniqueId, isVisiter)
    return getAllUsersData()
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
  
  
  def updateLoginUserInfo(userName = '', uniqueId = '', isVisiter = false)
    logging(uniqueId, 'updateLoginUserInfo uniqueId')
    logging(userName, 'updateLoginUserInfo userName')
    
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
    
    logging("updateLoginUserInfo END")
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
  
  
  def getPlayRoomName(saveData, index)
    playRoomName = saveData['playRoomName']
    playRoomName ||= "プレイルームNo.#{index}"
    return playRoomName
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
  
  
  def getSaveDataLastAccessTimes( roomNumberRange )
    
    logging(roomNumberRange, "getSaveDataLastAccessTimes roomNumberRange")
    
    result = {}
    
    roomNumberRange.each do |roomNo|
      where = {"roomNo >= ? " => roomNo }
      time = getRoomTimeStamp(where)
      
      result[roomNo] = time
    end
    
    logging(result, "getSaveDataLastAccessTimes result")
    
    return result
  end

  command
  def removeOldPlayRoom
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
    result = removePlayRoomByParams(roomNumbers, ignoreLoginUser, password)
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
    
    command = <<COMMAND_END
SELECT 
  IF(
    (SELECT COUNT(roomNo) FROM rooms)=0,
    0,
    (
      IF(
        (SELECT MIN(roomNo) FROM rooms)<>0,
        0,
        MIN(roomNo+1)
      ) 
    )
  ) AS roomNo
FROM rooms
WHERE (roomNo+1) NOT IN (SELECT roomNo FROM rooms)
COMMAND_END
    
    connectDb
    result = query(command)
    logging(result, "findEmptyRoomNumber result")
    
    row = result.first
    row ||= {}
    logging(row, "findEmptyRoomNumber row")
    
    count = row['roomNo'].to_i
    
    emptyRoomNubmer = count
    logging(emptyRoomNubmer, 'emptyRoomNubmer')
    
    return emptyRoomNubmer
  end
  
  command
  def getPlayRoomStates
    logging("getPlayRoomStates Begin");
    
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
    
    logging(result, "getPlayRoomStates End result");
    
    return result
  end
  
  def getPlayRoomStatesLocal(minRoom, maxRoom)
    playRoomStates = []
    
    playRoomDataList = getPlayRoomDataList(minRoom, maxRoom)
    
    (minRoom .. maxRoom).each do |roomNo|
      playRoomState = getPlayRoomStateBase(roomNo)
      playRoomData = playRoomDataList[roomNo]
      playRoomStates << getPlayRoomStateLocal(roomNo, playRoomState, playRoomData)
    end
    
    return playRoomStates
  end
  
  def getPlayRoomStateBase(roomNo)
    playRoomState = {}
    
    playRoomState['passwordLockState'] = false
    playRoomState['index'] = sprintf("%3d", roomNo)
    playRoomState['playRoomName'] = "（空き部屋）"
    playRoomState['lastUpdateTime'] = ""
    playRoomState['canVisit'] = false
    playRoomState['gameType'] = ''
    playRoomState['loginUsers'] = []
    
    return playRoomState
  end
  

  def getPlayRoomStateLocal(roomNo, playRoomState, playRoomData)
    
    return playRoomState if( playRoomData.nil? or playRoomData.empty? )
    
    playRoomName = getPlayRoomName(playRoomData, roomNo)
    passwordLockState = (not playRoomData['playRoomChangedPassword'].nil?)
    canVisit = playRoomData['canVisit']
    gameType = playRoomData['gameType']
    
    timeStamp = getRoomTimeStamp()
    
    timeString = ""
    unless( timeStamp.nil? )
      timeString = "#{timeStamp.strftime('%Y/%m/%d %H:%M:%S')}"
    end
    
    loginUsers = getLoginUserNames(roomNo)
    
    playRoomState['passwordLockState'] = passwordLockState
    playRoomState['playRoomName'] = playRoomName
    playRoomState['lastUpdateTime'] = timeString
    playRoomState['canVisit'] = canVisit
    playRoomState['gameType'] = gameType
    playRoomState['loginUsers'] = loginUsers
    
    return playRoomState
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
  
  
  def getLoginUserNames(roomNo)
    userNames = []
    
    unless( existRoom?(roomNo) )
      return userNames
    end
    
    deleteUserInfo(roomNo)
    
    users = getAllUsersData(roomNo)
    userNames = users.collect{|i| i['userNames']}
    
    logging(userNames, "getLoginUserNames userNames")
    return userNames
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
  
  
  def getGameName(gameType)
    require 'diceBotInfos'
    diceBotInfos = DiceBotInfos.new.getInfos
    gameInfo = diceBotInfos.find{|i| i["gameType"] == gameType}
    
    return '--' if( gameInfo.nil? )
    
    return gameInfo["name"]
  end
  
  
  def getAllLoginCount()
    total = 0
    userList = []
    
    result = readDb( "SELECT COUNT(*), roomNo",
                     :from => "users",
                     :where => {"update_at >= ? " => getLoginTimeLimit() },
                     :others => ["GROUP BY roomNo"],
                     :noRoom => true)
    logging(result, "result")
    
    result.each do |row|
      roomNo = row["roomNo"].to_i
      count = row["COUNT(*)"].to_i
      
      total += count
      userList << [roomNo, count]
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
  
  command
  def getLoginInfo
    logging("getLoginInfo begin")
    
    uniqueId ||= createUniqueId()
    
    allLoginCount, loginUserCountList = getAllLoginCount()
    
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
    
    return languages
  end
  
  
  def createUniqueId
    # 識別子用の文字列生成。
    (Time.now.to_f * 1000).to_i.to_s(36)
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
  
  command
  def getDiceBotInfos
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
    logging("createDir BEGIN")
    
    @saveDirInfo.setSaveDataDirIndex(playRoomIndex)
    @saveDirInfo.createDir()
    
    initPlayRoomData(playRoomIndex)
    insertFirstMap
    insertFirstTime
    insertFirstEffect
    
    logging("createDir END")
  end
  
  
  def initPlayRoomData(roomNo)
    
    connectDb
    
    json = '{"canVisit":false,"gameType":"DiceBot","chatChannelNames":["メイン","雑談"],"canUseExternalImage":false,"playRoomChangedPassword":null,"playRoomName":"プレイルームNo.0"}'
    
    tableName = 'rooms'
    
    query("INSERT INTO #{tableName} (roomNo, json, update_index) VALUES (?, ?, ?)", 
           roomNo, json, 1)
  end

  command
  def createPlayRoom
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
      removeSaveDir(playRoomIndex)
      logging("@saveDirInfo.removeSaveDir(playRoomIndex) End")
      
      createDir(playRoomIndex)
      
      playRoomChangedPassword = getChangedPassword(playRoomPassword)
      logging(playRoomChangedPassword, 'playRoomChangedPassword')
      
      viewStates = params['viewStates']
      logging("viewStates", viewStates)
      
      
      changePlayRoomData do |saveData|
        saveData['playRoomName'] = playRoomName
        saveData['playRoomChangedPassword'] = playRoomChangedPassword
        saveData['chatChannelNames'] = chatChannelNames
        saveData['canUseExternalImage'] = canUseExternalImage
        saveData['canVisit'] = canVisit
        saveData['gameType'] = params['gameType']
        
        addViewStatesToSaveData(saveData, viewStates)
        
        saveData
      end
      
      sendRoomCreateMessage(playRoomIndex)
    rescue Exception => e
      loggingException(e)
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

  
  def changePlayRoomData
    changeRoomDbJsonData() do |data|
      yield(data)
    end
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

  command
  def changePlayRoom
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
      
      
      changePlayRoomData do |saveData|
        logging(saveData, 'changePlayRoom() saveData before')
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
        
logging(saveData, 'changePlayRoom() saveData end')
        
        saveData
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
    
    return true unless( existRoom? )
    
    matched = false
    
    saveData = getPlayRoomData()
    changedPassword = saveData['playRoomChangedPassword']
    matched = isPasswordMatch?(password, changedPassword)
    
    return matched
  end

  command
  def removePlayRoom
    params = getParamsFromRequestData()
    
    roomNumbers = params['roomNumbers']
    ignoreLoginUser = params['ignoreLoginUser']
    password = params['password']
    password ||= ""
    
    adminPassword = params["adminPassword"]
    logging(adminPassword, "removePlayRoom() adminPassword")
    if( isMentenanceMode(adminPassword) )
      password = nil
    end
    
    removePlayRoomByParams(roomNumbers, ignoreLoginUser, password)
  end
  
  def removePlayRoomByParams(roomNumbers, ignoreLoginUser, password)
    logging(ignoreLoginUser, 'removePlayRoomByParams Begin ignoreLoginUser')
    
    deletedRoomNumbers = []
    errorMessages = []
    passwordRoomNumbers = []
    askDeleteRoomNumbers = []
    
    roomNumbers.each do |roomNumber|
      roomNumber = roomNumber.to_i
      logging(roomNumber, 'roomNumber')
      
      resultText = checkRemovePlayRoom(roomNumber, ignoreLoginUser, password)
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
    removeSaveDir(roomNumber)
    removeLocalSpaceDir(roomNumber)
  end
  
  def removeLocalImageTags(roomNumber)
    tagInfos = getImageTags(roomNumber)
    deleteImages(tagInfos.keys)
  end
  
  
  def removeSaveDir(roomNo)
    @saveDirInfo.removeSaveDir(roomNo)
    
    changeDb do 
      %w{chats characters maps times effects users rooms}.each do |target|
        query("DELETE FROM #{target} WHERE roomNo=?", roomNo)
      end
    end
  end
  
  
  def checkRemovePlayRoom(roomNumber, ignoreLoginUser, password)
    roomNumberRange = (roomNumber..roomNumber)
    logging(roomNumberRange, "checkRemovePlayRoom roomNumberRange")
    
    unless( ignoreLoginUser )
      userNames = getLoginUserNames(roomNumber)
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
    logging(lastAccessTime, "lastAccessTime")
    
    unless( lastAccessTime.nil? )
      now = Time.now
      spendTimes = now - lastAccessTime
      logging(spendTimes, "spendTimes")
      logging(spendTimes / 60 / 60, "spendTimes / 60 / 60")
      if( spendTimes < $deletablePassedSeconds )
        return "プレイルームNo.#{roomNumber}の最終更新時刻から#{$deletablePassedSeconds}秒が経過していないため削除できません"
      end
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

  command
  def saveAllData
    logging("saveAllData begin")
    dir = getRoomLocalSpaceDirName
    makeDir(dir)
    
    params = getParamsFromRequestData()
    @saveAllDataBaseUrl = params['baseUrl']
    chatPaletteData = params['chatPaletteData']
    logging(@saveAllDataBaseUrl, "saveAllDataBaseUrl")
    logging(chatPaletteData, "chatPaletteData")
    
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
    
    logging(result, "saveAllData result")
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
    
    fromFileName, = from.split(/\t/)
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
  
  command
  def save
    isAddPlayRoomInfo = true
    extension = getRequestData('extension')
    
    addInfos = {}
    addInfos[$diceBotTableSaveKey] = getDiceTableData()
    
    saveSelectFiles($tableNames.keys, extension, isAddPlayRoomInfo, addInfos)
  end
  
  def getDiceTableData()
    dir = getDiceBotExtraTableDirName
    tableInfos = getBotTableInfosFromDir(dir)
    
    tableInfos.each{|i| i.delete('fileName') }
    
    return tableInfos
  end
  
  command
  def saveMap
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
    logging(selectTypes, "getSelectFilesData begin selectTypes")
    
    @lastUpdateTimes = {}
    selectTypes.each do |type|
      @lastUpdateTimes[type] = 0;
    end
    logging("dummy @lastUpdateTimes created")
    
    saveDataAll = {}
    getCurrentSaveData() do |targetSaveData, saveFileTypeName|
      
      if saveFileTypeName == 'characters'
        jsons = targetSaveData["characters"]
        characters = jsons.collect {|i| getJsonDataFromText(i) }
        targetSaveData["characters"] = characters
      end
      
      saveDataAll[saveFileTypeName] = targetSaveData
      logging(saveFileTypeName, "saveFileTypeName in save")
    end
    
    if( isAddPlayRoomInfo )
      @lastUpdateTimes['playRoomInfo'] = 0;
      saveDataAll['playRoomInfo'] = getPlayRoomData()
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

  command
  def checkRoomStatus
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
    
    isRoomExist = existRoom?
    logging(isRoomExist, "checkRoomStatus isRoomExist")
    
    if( isRoomExist )
      saveData = getPlayRoomData()
      playRoomName = getPlayRoomName(saveData, roomNumber)
      changedPassword = saveData['playRoomChangedPassword']
      chatChannelNames = saveData['chatChannelNames']
      canUseExternalImage = saveData['canUseExternalImage']
      canVisit = saveData['canVisit']
      unless( changedPassword.nil? )
        isPasswordLocked = true
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
      'isRoomExist' => isRoomExist,
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

  command
  def loginPassword
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
    
    saveData = getPlayRoomData()
    
    canVisit = saveData['canVisit']
    if( canVisit and visiterMode )
      result['resultText'] = "OK"
      result['visiterMode'] = true
    else
      playRoomChangedPassword = saveData['playRoomChangedPassword']
      if( isPasswordMatch?(password, playRoomChangedPassword) )
        result['resultText'] = "OK"
      else
        result['resultText'] = "passwordMismatch"
      end
    end
    
    return result
  end
  
  def isPasswordMatch?(password, changedPassword)
    return true if( changedPassword.nil? )
    ( password.crypt(changedPassword) == changedPassword )
  end

  command_noreturn
  def logout
    logoutData = getParamsFromRequestData()
    logging(logoutData, 'logoutData')
    
    uniqueId = logoutData['uniqueId']
    logging(uniqueId, 'uniqueId');
    
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
  
  command
  def getBotTableInfos
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
  
  command
  def addBotTable
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
      resultText = getLanguageKey( e.to_s )
    end
    
    logging(resultText, "addBotTableMain End resultText")
    
    return resultText
  end
  
  command
  def changeBotTable
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
      resultText = getLanguageKey( e.to_s )
    end
    
    logging(resultText, "changeBotTableMain End resultText")
    
    return resultText
  end
  
  command
  def removeBotTable
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

  command
  def requestReplayDataList
    logging("requestReplayDataList begin")
    result = {
      "resultText"=> "OK",
    }
    
    result["replayDataList"] = getReplayDataList() #[{"title"=>x, "url"=>y}]
    
    logging(result, "result")
    logging("requestReplayDataList end")
    return result
  end

  command
  def uploadReplayData
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

  command
  def removeReplayData
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

  command
  def uploadFile
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
  
  command
  def loadAllSaveData
    logging("loadAllSaveData() Begin")
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
    dir = File.join($imageUploadDir, "room_#{roomNo}")
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
  
  command
  def load
    logging("load() Begin")
    
    result = {}
    
    begin
      checkLoad()
      
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
    
    $tableNames.each do |fileTypeName, dummy|
      logging(fileTypeName, "fileTypeName")
      
      saveData = saveDataAll[fileTypeName]
      saveData ||= {}
      logging(saveData, "saveData")
      
      loadSaveFileDataForEachType(fileTypeName, saveData)
    end
    
    loadDiceBotTable(jsonData)
    
    logging("loadSaveFileDataAll(saveDataAll) end")
  end
  
  
  def loadSaveFileDataForEachType(fileTypeName, saveData)
    logging(fileTypeName, "loadSaveFileDataForEachType fileTypeName")
    logging(saveData, "loadSaveFileDataForRooms saveData")
    
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
    logging(characters, "loadSaveFileDataForCharacters characters")
    
    addCharacterData( characters )
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

  command
  def uploadImageData
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
      result["resultText"] = getLanguageKey( e.to_s )
    end
    
    logging(result, "uploadImageData result")
    logging("uploadImageData load End")
    
    return result
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
  
  command
  def deleteImage
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
  
  command
  def uploadImageUrl
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
  
  command
  def getGraveyardCharacterData
    logging("getGraveyardCharacterData start.")
    
    result = getAllCharacters($characterStateGraveyard, true)
    
    graveyard = result.collect{|i| getJsonDataFromText(i["json"])}
    logging(graveyard, "getGraveyardCharacterData graveyard")
    
    return graveyard
  end
 
  command
  def getWaitingRoomInfo
    logging("getWaitingRoomInfo start.")
    
    result = getAllCharacters($characterStateWaitingRoom, true)
    waitingRoom = result.collect{|i| getJsonDataFromText(i["json"])}
    
    return waitingRoom
  end
  
  def setWaitingRoomInfo(characters)
    stateList = Array.new(characters.size, $characterStateWaitingRoom)
    addCharacterData(characters, stateList)
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


  command
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


  command
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
      
      next unless existRoom?
      
      logging(roomNumber, "sendChatMessageAll to No.")
      sendChatMessageByChatData(chatData)
      
      rooms << roomNumber
    end
    
    result['result'] = "OK"
    result['rooms'] = rooms
    logging(result, "sendChatMessageAll End, result")
    
    return result
  end

  command_noreturn
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
      loggingException(e)
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
    logging(count, "chats count")
    
    limit = $chatMessageDataLogAllLineMax
    limitMax = limit * 2
    
    if( count < limitMax )
      logging('chats count is NOT limit.')
      return
    end
    
    query("DELETE FROM chats WHERE id <= (SELECT id FROM chats ORDER BY id DESC LIMIT 1 OFFSET ?)", 
          limit)
    
    logging('delete old chats')
  end

  command
  def deleteChatLog
    result = {'result' => "OK" }
    
    begin
      changeDb do
        query("DELETE FROM chats")
      end
    rescue => e
      result['result'] = getErrorResponseText(e)
      loggingException(e)
    end
    
    return result
  end
  
  def getChatMessageDataLog(saveData)
    getArrayInfoFromHash(saveData, 'chatMessageDataLog')
  end
  
  command_noreturn
  def changeMap
    mapData = getParamsFromRequestData()
    logging(mapData, "changeMap mapData")
    
    changeMapSaveData(mapData)
  end
  
  def changeMapSaveData(newMapData)
    logging("changeMap Begin")
    
    changeMapData do |oldMapData|
      newMapData
    end
    
    logging("changeMap End")
  end
  
  def getMapId()
    result = readDb( "SELECT id",
                     :from => "maps" )
    row = result.first
    return nil if row.nil?
    
    id = row['id']
    return id
  end


  command_noreturn
  def drawOnMap
    logging('drawOnMap Begin')
    
    params = getParamsFromRequestData()
    drawData = params['data']
    
    drawOnMapByMapMarks(drawData)
  end
  
  def drawOnMapByMapMarks(drawData)
    logging(drawData, 'drawOnMapByMapMarks drawData')
    
    changeMapData do |mapData|
      setDraws(mapData, drawData)
      mapData
    end
  
    logging('drawOnMap End')
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
    data = getJsonDataFromText(json)
    
    data = yield(data)
    
    json = getTextFromJsonData(data)
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
    data = getJsonDataFromText(json)
    
    data = yield(data)
    
    json = getTextFromJsonData(data)
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


  command_noreturn
  def clearDrawOnMap
    mapMarks = []
    drawOnMapByMapMarks(mapMarks)
  end

  command
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

  command_noreturn
  def addEffect
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

  command_noreturn
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

  command_noreturn
  def changeEffectsAll
    paramEffects = getParamsFromRequestData()
    return if( paramEffects.nil? )
    return if( paramEffects.empty? )
    
    logging(paramEffects, "changeEffectsAll paramEffects")
    
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

  command_noreturn
  def removeEffect
    logging('removeEffect Begin')
    
    params = getParamsFromRequestData()
    effectIds = params['effectIds']
    logging(effectIds, 'effectIds')
    
    changeEffectsData do |saveData|
      
      effects = getArrayInfoFromHash(saveData, 'effects')
      logging(effects, 'effects')
      
      effects.delete_if{|i|
        effectIds.include?(i['effectId'])
      }
      
      saveData
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

  command_noreturn
  def changeImageTags
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

  command
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
        
        unless( roomNumber.nil? )
          tmpTags.each do |key, value|
            next if value.nil?
            value.delete("roomNumber")
          end
        end
        
        imageTags.merge!( tmpTags )
      end
    end
    
    logging(imageTags, 'getImageTags imageTags')
    
    return imageTags
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

  command
  def addCharacter
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
        logging(imgId, "insert imgId")
        
        characterData['imgId'] = imgId
        updateCharacters(characterData)
      end
    end
    
    result = readDb("SELECT *",
                    :from => "characters",
                    :others => ["ORDER BY id"])
    shapeUpDbResult(result)
    
    logging(result, "added characters")
    
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
    
    json = JsonBuilder.new.build(params)
    
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

  command_noreturn
  def changeCharacter
    logging("changeCharacter")
    
    characterData = getParamsFromRequestData()
    logging(characterData, "characterData")
    
    changeCharacterData(characterData)
  end
  
  def changeCharacterData(characterData)
    changeDb do
      updateCharacters(characterData)
      logging(characterData, "character data change")
    end
    
=begin
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

  command_noreturn
  def addCardZone
    logging("addCardZone Begin");
    
    data = getParamsFromRequestData()
    
    x = data['x']
    y = data['y']
    owner = data['owner']
    ownerName = data['ownerName']
    
    changeDb do
      cardData = getCardZoneData(owner, ownerName, x, y)
      addCharacterData( [cardData] )
    end
    
    logging("addCardZone End");
  end


  command
  def initCards
    logging("initCards Begin");
    
    clearAllCards
    
    params = getParamsFromRequestData()
    cardTypeInfos = params['cardTypeInfos']
    logging(cardTypeInfos, "cardTypeInfos")
    
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
    
    logging(allCards, "allCards")
    logging(stateList, "stateList")
    
    addCharacterData(allCards, stateList)
    
    waitForRefresh = 0.2
    sleep( waitForRefresh )
    
    logging("initCards End");
    
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

  command_noreturn
  def addCard
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
    
    changeDb do
      cardData = getCardData(isText, imageName, imageNameBack, mountName, isUpDown, canDelete, canRewrite)
      cardData["x"] = addCardData['x']
      cardData["y"] = addCardData['y']
      cardData["isOpen"] = isOpen unless( isOpen.nil? )
      cardData["isBack"] = isBack unless( isBack.nil? )
      
      addCharacterData( [cardData] )
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
    logging("setTrushMountDataCardsInfo Begin")
    
    mountName = cardMountData['mountName']
    imageName, _, isText = getCardTrushMountImageName(mountName, cards.last)
    
    cardMountData['cardCount'] = cards.size
    cardMountData["imageName"] = imageName
    cardMountData["imageNameBack"] = imageName
    cardMountData["isText"] = isText
    
    logging(cardMountData, "setTrushMountDataCardsInfo cardMountData")
    
    updateCharacters(cardMountData)
    
    logging("setTrushMountDataCardsInfo End")
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

  command_noreturn
  def returnCard
    logging("returnCard Begin");
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    logging(mountName, "mountName")
    
    changeDb do
      
      trushCards = getTrushMountCards(mountName)
      
      cardData = trushCards.pop
      logging(cardData, "cardData")
      
      if( cardData.nil? )
        logging("returnCard trushCards is empty. END.")
        return
      end
      
      cardData['x'] = params['x'] + 150
      cardData['y'] = params['y'] + 10
      logging('returned cardData', cardData)
      
      updateCharacters(cardData, nil, $characterStateNomal)
      
      trushMountData = findCharacterDataById( params['imgId'] )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
    end
    
    logging("returnCard End");
  end

  command
  def drawCard
    logging("drawCard Begin")
    
    params = getParamsFromRequestData()
    logging(params, 'params')
    
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
    
    logging(result, "drawCard End")
    
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
    logging(result, "drawCard base targets.")
    
    cards = result.collect{|i| getJsonDataFromText(i["json"])}
    cards.delete_if{|i| i['mountName'] != mountName}
    
    return cards
  end
  
  
  
  def drawCardDataOne(params, cards)
    logging("drawCardDataOne Begin")
    
    imgId = params['imgId']
    cardMount = findCharacterDataById(imgId)
    return nil if( cardMount.nil? )
    
    logging(cardMount, "cardMount")
    
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
    
    logging(cards.size, 'cardMount[mountName].size')
    setCardCountAndBackImage(cardMount, cards)
    
    logging(cardData, "drawCardDataOne End")
    
    return cardData
  end

  command
  def drawTargetTrushCard
    logging("drawTargetTrushCard Begin");
    
    params = getParamsFromRequestData()
    
    mountName = params['mountName']
    logging(mountName, "mountName")
    
    changeDb do
      cardData = findCharacterDataById(params['targetCardId'] )
      logging(cardData, "cardData")
      return if( cardData.nil? )
      
      cardData['x'] = params['x']
      cardData['y'] = params['y']
      
      updateCharacters(cardData, nil, $characterStateNomal)
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( params['mountId'] )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
    end
    
    logging("drawTargetTrushCard End");
    
    return {"result" => "OK"}
  end

  command
  def drawTargetCard
    logging("drawTargetCard Begin")
    
    params = getParamsFromRequestData()
    logging(params, 'params')
    
    mountName = params['mountName']
    logging(mountName, 'mountName')
    
    changeDb do
      cards = getMountCards(mountName)
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
      
      addCharacterData( [cardData] )
      
      cardMountData = findCharacterDataById( params['mountId'] )
      return if cardMountData.nil?
      
      logging(cards.size, 'cardMount[mountName].size')
      setCardCountAndBackImage(cardMountData, cards)
    end
    
    logging("drawTargetCard End")
    
    return {"result" => "OK"}
  end
  
  
  def setCardCountAndBackImage(cardMountData, cards)
    logging("setCardCountAndBackImage Begin")
    
    cardMountData['cardCount'] = cards.size
    
    card = cards.last
    unless( card.nil? )
      image = card["imageNameBack"]
      unless( image.nil? ) 
        cardMountData["imageNameBack"] = image
      end
    end
    
    logging(cardMountData, "setCardCountAndBackImage cardMountData")
    updateCharacters(cardMountData)
    
    logging("setCardCountAndBackImage End")
  end

  command_noreturn
  def dumpTrushCards
    logging("dumpTrushCards Begin")
    
    params = getParamsFromRequestData()
    logging(params, 'dumpTrushCards params')
    
    mountName = params['mountName']
    logging(mountName, 'mountName')
    
    changeDb do
      card = findCharacterById( params['dumpedCardId'] )
      cardData = getJsonDataFromText(card["json"])
      
      updateCharacters(cardData, nil, $characterStateCardTrushMount)
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( params['trushMountId'] )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
    end
    
    logging("dumpTrushCards End")
  end

  command_noreturn
  def shuffleCards
    logging("shuffleCard Begin")
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    trushMountId = params['mountId']
    isShuffle = params['isShuffle']
    
    logging(mountName, 'mountName')
    logging(trushMountId, 'trushMountId')
    
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
      
      logging(mountCards, "mountCards")
      logging(cardMountData, "cardMountData")
      
      setNextCardId(cardMountData, mountCards)
      setCardCountAndBackImage(cardMountData, mountCards)
    end
    
    logging("shuffleCard End")
  end
  
  
  def setNextCardId(cardMountData, cards)
    return if cards.first.nil?
    cardMountData['nextCardId'] = cards.first['imgId']
  end

  command_noreturn
  def shuffleForNextRandomDungeon
    logging("shuffleForNextRandomDungeon Begin")
    
    params = getParamsFromRequestData()
    mountName = params['mountName']
    trushMountId = params['mountId']
    
    logging(mountName, 'mountName')
    logging(trushMountId, 'trushMountId')
    
    changeDb do
      
      trushCards = getTrushMountCards(mountName)
      mountCards = getMountCards(mountName)
      
      cardMountData = findCardMountDataByType(mountName, getRandomDungeonCardMountType)
      return if( cardMountData.nil?) 
      
      aceList = cardMountData['aceList']
      logging(aceList, "aceList")
      
      result = getAllCharacters()
      characters = result.collect{|i| getJsonDataFromText(i["json"])}
      
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
      
      newDiff = mountCards.size - useCount
      newDiff = 3 if( newDiff < 3 )
      logging(newDiff, "newDiff")
      cardMountData['cardCountDisplayDiff'] = newDiff
      
      updateCharacters(mountCards, nil, $characterStateCardMount)
      
      trushCards = getTrushMountCards(mountName)
      trushMountData = findCharacterDataById( trushMountId )
      return if trushMountData.nil?
      
      setTrushMountDataCardsInfo(trushMountData, trushCards)
      
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
  
  def findCardMountDataByType(mountName, cardMountType)
    
    result = readDb( "SELECT *",
                     :from => "characters",
                     :where => {"type = ? " => cardMountType} )
    characters = result.collect{|i| getJsonDataFromText(i["json"])}
    
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


  command
  def getMountCardInfos
    params = getParamsFromRequestData()
    logging(params, 'getMountCardInfos params')
    
    mountName = params['mountName']
    mountId = params['mountId']
    
    cards = []
    
    changeDb do
      cards = getMountCards(mountName)
    
      cardMountData = findCharacterDataById(mountId)
      return nil if( cardMountData.nil? )
      
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

  command
  def getTrushMountCardInfos
    
    params = getParamsFromRequestData()
    logging(params, 'getTrushMountCardInfos params')
    
    cards = []
    
    changeDb do
      cards = getTrushMountCards( params['mountName'] )
    end
    
    return cards
  end

  command
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

  command_noreturn
  def clearCharacterByType
    logging("clearCharacterByType Begin")
    
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
    
    changeDb do
      updateDb(:table => 'characters',
               :set => {"state" => $characterStateDeleted },
               :where => {"type=? " => targetType} )
    end
    
    logging("clearCharacterByTypeLocal End")
  end

  command_noreturn
  def removeCharacter
    removeCharacterDataList = getParamsFromRequestData()
    removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
  end
  
  
  def removeCharacterByRemoveCharacterDataList(removeCharacterDataList)
    logging(removeCharacterDataList, "removeCharacterDataList")
    
    changeDb do
      
      removeCharacterDataList.each do |removeCharacterData|
        logging(removeCharacterData, "removeCharacterData")
        
        isGotoGraveyard = removeCharacterData['isGotoGraveyard']
        
        imgId = removeCharacterData['imgId']
        character = findCharacterById(imgId)
        
        logging(character, "remove target character")
        next if character.nil?
        
        state = (isGotoGraveyard ? $characterStateGraveyard : $characterStateDeleted)
        
        logging("remove character")
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

  command
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

  command
  def resurrectCharacter
    params = getParamsFromRequestData()
    resurrectCharacterId = params['imgId']
    logging(resurrectCharacterId, "resurrectCharacterId")
    
    changeDb do
      updateDb(:table => 'characters',
               :set => {"state" => $characterStateNomal},
               :where => {"id=? " => resurrectCharacterId} )
    end
    
    return nil
  end
  
  command
  def clearGraveyard
    logging("clearGraveyard begin")

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

  command
  def exitWaitingRoomCharacter
    logging("exitWaitingRoomCharacter Begin")
    
    params = getParamsFromRequestData()
    characterId = params['characterId']
    x = params['x']
    y = params['y']
    
    logging(characterId, 'exitWaitingRoomCharacter characterId')
    
    result = {"result" => "NG"}
    
    changeDb do
      character = findCharacterById(characterId)
      return result if(character.nil?)
      
      data = getJsonDataFromText(character["json"])
      data['x'] = x
      data['y'] = y
      
      json = JsonBuilder.new.build(data)
      
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

  command_noreturn
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


  command_noreturn
  def addResource
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

  command_noreturn
  def changeResourcesAll
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

  command_noreturn
  def removeResource
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
  
  command_noreturn
  def moveCharacter
    #FIXME
    
    params = getParamsFromRequestData()
    
    changeDb do
      imgId = getIdFromCharacterData(params)
      character = findCharacterById(imgId)
      
      return if(character.nil?)
      
      data = getJsonDataFromText(character["json"])
      data['x'] = params['x']
      data['y'] = params['y']
      
      updateCharacters(data, imgId)
      logging(data, "character data change")
    end
    
  end
  
  def findCharacterDataById(imgId)
    character = findCharacterById(imgId)
    return nil if character.nil?
    
    return getJsonDataFromText( character["json"] )
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
    
    response = nil
    
    if( $dodontofWarning.nil? )
      begin
        response = analyzeCommand
      ensure
        begin
          @db.close unless( @db.nil? )
        rescue Exception
          # loggingForce("close Exception")
          # loggingException(e)
        end
      end
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

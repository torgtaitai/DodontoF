#!/usr/local/bin/ruby -Ku
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

require 'DodontoFServer.rb'
#require 'rubygems'
require 'mysql'

require 'dodontof/logger'
require 'dodontof/utils'

unless $isTestMode
  $SAVE_DATA_DIR = '.'
end

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

class SaveDataManagerOnMySql
  include DodontoF::Utils

  def initialize
    @tableLocked = false
    @db = nil

    @logger = DodontoF::Logger.instance
  end
  
  def getDb
    if( @db.nil? )
      @db = openDb
    end
    
    @db
  end
  
  def openDb
    @logger.debug("OPEN DB")
    Mysql::new($databaseHostName, $databaseUserName, $databasePassword, $databaseName)
  end
  
  def closeDb
    return if( @db.nil? )
    
    @logger.debug("CLOSE DB")
    
    getDb.close
    @db = nil
  end
  
  
  def open(fileName, isReadOnly, tableName = nil)
    #yield
    #return;
    
    if( tableName.nil? )
      dirName = File.dirname(fileName)
      tableName = getTableName(dirName)
    end
    
    lockType = (isReadOnly ? "READ" : "WRITE")
    
    if( @tableLocked )
      yield
      return
    end
    
    begin
      executeSql("LOCK TABLES #{tableName} #{lockType}")
      @tableLocked = true
      yield
    ensure
      @tableLocked = false
      executeSql("UNLOCK TABLES")
      closeDb
    end
    
  end
  
  
  def changeText(fileName, text)
    if( isExist?(fileName) )
      update(fileName, text)
    else
      createData(fileName, text)
    end
  end
  
  def getTableName(dirName)
    #return dirName.gsub(/\./, "_").gsub(/\//, "_")
    return dirName.gsub(/\./, "_").gsub(/\//, "_").downcase
  end
  
  
  def executeSql(sqlOriginal, *args)
    sqlOriginal += " "
    @logger.debug(sqlOriginal, "executeSql sqlOriginal")
    #@logger.debug(args.join(", "), "executeSql args")
    
    sqlParts = sqlOriginal.split(/\?/)
    
    if( (sqlParts.length - 1) != args.length )
      raise "executeSql args.lengt error (sqlParts.lengt:#{sqlParts.length.to_s}, args.length:#{args.length.to_s})"
    end
    
    sql = sqlParts.shift
    args.each_with_index do |arg, index|
      if( arg.class.name == "String" )
        arg = "'" + Mysql::quote(arg) + "'"
      end
      
      sql += arg.to_s
      sql += sqlParts.shift
    end
    
    @logger.debug(sql, "SQL query")
    
    result = getDb.query(sql)
    
    return result
  end
  
  def getSaveDataLastAccessTimes(dirNames, roomNumberRange)
    @logger.debug(dirNames, "getSaveDataLastAccessTimes dirNames")
    @logger.debug(roomNumberRange, "getSaveDataLastAccessTimes roomNumberRange")
    
    lastAccessTimeInfos = {}
    dirNames.each do |dirName|
      next unless ( isExistDir?(dirName) )
      
      next unless( /data_(\d+)\Z/ === dirName )
      
      dirIndex = $1.to_i
      next unless( roomNumberRange.include?(dirIndex) )
      
      tableName = getTableName(dirName)
      
      times = []
      result = executeSql("SELECT fileName, time FROM #{tableName}")
      
      result.each do |row|
        fileName = row.shift
        @logger.debug(fileName, "fileName")
        
        baseName = File.basename(fileName)
        @logger.debug(baseName, "baseName")
        
        timeValue = row.shift.to_f
        @logger.debug(timeValue, "timeValue")
        times << Time.at(timeValue)
      end
      
      lastAccessTimeInfos[dirIndex] = times.max
    end
    
    @logger.debug(lastAccessTimeInfos, "getSaveDataLastAccessTimes lastAccessTimeInfos")
    
    return lastAccessTimeInfos
  end

  def update(fileName, text)
    dirName = File.dirname(fileName)
    tableName = getTableName(dirName)
    
    time = getCurrentTime
    executeSql("UPDATE #{tableName} SET text=?, time=? WHERE fileName=?", text, time, fileName);
  end
  
  def getText(fileName)
    dirName = File.dirname(fileName)
    tableName = getTableName(dirName)
    
    text = ''
    result = executeSql("SELECT text FROM #{tableName} WHERE fileName=?", fileName)
    result.each do |row|
      text += row.first
    end
    
    return text
  end
  
  def isChatFileName(fileName)
    base = File.basename(fileName)
    return ( base == "chat.json" )
  end
  
  def getChatTime(fileName)
    @logger.debug(fileName, "getChatTime fileName")
    
    dirName = File.dirname(fileName)
    tableName = getChatTableName(dirName)
    createChatTable(tableName)
    
    maxTime = 0
    
    numberLimit = $chatMessageDataLogAllLineMax
    result = executeSql("SELECT MAX(time) FROM #{tableName} WHERE number<#{numberLimit}")
    result.each do |row|
      maxTime = row.first.to_f
    end
    
    @logger.debug(maxTime, "getChatTime maxTime")
    
    return maxTime
  end
    
  def getTime(fileName)
    @logger.debug(fileName, "getTime fileName")
    
    if( isChatFileName(fileName) )
      return getChatTime(fileName)
    end
    
    dirName = File.dirname(fileName)
    tableName = getTableName(dirName)
    
    time = 0
    
    result = executeSql("SELECT time FROM #{tableName} WHERE fileName=?", fileName)
    result.each do |row|
      time = row.first.to_f
    end
    
    return time.to_f
  end
  
  def createTable(dirName)
    if( isExistDir?(dirName) )
      raise "このプレイルームはすでに作成済みです。"
    end
    
    tableName = getTableName(dirName)
    
    sql = <<SQL
CREATE TABLE #{tableName} (
   fileName CHAR(255) UNIQUE,
   text LONGBLOB,
   time DECIMAL(15,5)
);
SQL
    executeSql(sql)
    
    @allTableNames = []
    
    insertNewData(dirName)
  end
  
  def insertNewData(dirName)
    sourceDir = 'saveData_forNewCreation'
    saveFileNames = $saveFiles.values
    
    saveFileNames.each do |saveFileName|
      
      sourceFileName = File.join(sourceDir, saveFileName)
      @logger.debug(sourceFileName, "insertNewData sourceFileName")
      
      next unless( File.exist?(sourceFileName) )
      @logger.debug(sourceFileName, "insertNewData exist sourceFileName")
      
      text = File.readlines(sourceFileName).join
      
      fileName = File.join(dirName, saveFileName)
      @logger.debug(fileName, "insertNewData fileName")
      
      createData(fileName, text)
    end
  end
  
  def getChatTableName(dirName)
    return getTableName(dirName + "_chat")
  end
  
  def createChatTable(tableName)
    createChatTableOnly(tableName)
    createChatTableInstance(tableName)
  end
  
  def createChatTableOnly(tableName)
    @logger.debug(tableName, "createChatTableOnly tableName")
    return if( isExistTable?(tableName) )
    
    @logger.debug(tableName, "createChatTableOnly tableName NOT exist")
    
    sql = <<SQL
CREATE TABLE #{tableName} (
   number INT UNIQUE,
   text LONGBLOB,
   time DECIMAL(15,5)
);
SQL
    executeSql(sql)
    
    @allTableNames = []
  end
  
  def executeMaxSql(tableName, item)
    sql = "SELECT MAX(#{item}) FROM #{tableName}"
    @logger.debug(sql, "executeCountSql sql")
    
    result = executeSql(sql)
    
    row = result.fetch_row
    @logger.debug(row, "result.fetch_row")
    
    return -1 if( row.nil? )
    
    maxNumber = row.first
    @logger.debug(maxNumber, "row.first")
    
    if( maxNumber == nil )
      maxNumber = -1
    else
      maxNumber = maxNumber.to_i
    end
    
    return maxNumber
  end
  
  def createChatTableInstance(tableName)
    @logger.debug(tableName, "createChatTableInstance tableName")
    
    numberLimit = $chatMessageDataLogAllLineMax
    @logger.debug(numberLimit, "createChatTableInstance numberLimit")
    
    maxNumber = executeMaxSql(tableName, "number")
    @logger.debug(maxNumber, "maxNumber")
    return if( maxNumber >= numberLimit )
    
    ((maxNumber + 1) ... numberLimit).each do |number|
      @logger.debug(number, "createChatTableInstance each number")
      text = ""
      time = getCurrentTime
      executeSql("INSERT INTO #{tableName} VALUES (?, ?, ?)", number, text, time)
    end
  end
  
  
  def removeSaveDir(dirName)
    tableName = getTableName(dirName)
    deleteTable(tableName)
    
    chatTableName = getChatTableName(dirName)
    deleteTable(chatTableName)
  end
  
  def deleteTable(tableName)
    return unless( isExistTable?(tableName))
    
    executeSql("DROP TABLE #{tableName}")
  end
  
  def createData(fileName, text)
    dirName = File.dirname(fileName)
    tableName = getTableName(dirName)
    
    time = getCurrentTime
    executeSql("INSERT INTO #{tableName} VALUES (?, ?, ?)", fileName, text, time)
  end
  
  def getCurrentTime
    @currentMilliTime ||= Time.now.to_f;
    return @currentMilliTime;
  end
  
  def isExist?(fileName)
    dirName = File.dirname(fileName)
    
    return false unless( isExistDir?(dirName) )
    
    tableName = getTableName(dirName)
    
    count = 0
    
    begin
      count = executeCountSql("SELECT count(*) FROM #{tableName} WHERE fileName=?", fileName)
    rescue
    end
    
    return (count >= 1)
  end
  
  def executeCountSql(sql, *args)
    @logger.debug(sql, "executeCountSql sql")
    
    result = executeSql(sql, *args)
    row = result.fetch_row
    return 0 if( row.nil? )
    
    first = row.first
    count = first.to_i
    
    @logger.debug(count, "executeCountSql count")
    
    return count
  end
  
  def loadSaveFileForChat(typeName, fileName, lastUpdateTimes)
    lastTime = lastUpdateTimes[typeName]
    @logger.debug(lastUpdateTimes, "loadSaveFileForChat lastUpdateTimes")
    @logger.debug(lastTime, "loadSaveFileForChat lastTime")
    
    dirName = File.dirname(fileName)
    tableName = getChatTableName(dirName)
    createChatTable(tableName)
    
    lines = []
    result = executeSql("SELECT text,time FROM #{tableName} WHERE (time>#{lastTime}) and (text!=\"\") ORDER BY time")
    
    result.each do |row|
      text = row.shift
      lines << text
      
      lastUpdateTimes[typeName] = row.shift.to_f
    end
    
    if( lines.empty? )
      return {}
    end
    
    data = lines.collect{|line| getObjectFromJsonString(line.chomp) }
    saveData = {"chatMessageDataLog" => data}
    
    return saveData
  end
  
  def isSaveData(dirName)
    saveDir = File.join($SAVE_DATA_DIR, "saveData")
    saveDir2 = File.join(saveDir, "")
    @logger.debug(saveDir, "saveDir")
    @logger.debug(saveDir2, "saveDir2")
    
    return (( saveDir == dirName ) || ( dirName.index(saveDir2) == 0 ))
  end
  
  def isExistTable?(tableName)
    @logger.debug(tableName, "isExistDir? tableName")
    
    @allTableNames ||= []
    if( @allTableNames.empty? )
      result = executeSql("SHOW TABLES;")
      result.each do |row|
        @allTableNames << row.first
      end
    end
    
    @logger.debug(@allTableNames, "@allTableNames")
    
    isExist = @allTableNames.include?(tableName)
    @logger.debug(isExist, "isExistDir? isExist")
    
    return isExist
  end
  
  def isExistDir?(dirName)
    @logger.debug(dirName, "isExistDir? dirName")
    
    unless( isSaveData(dirName) )
      @logger.debug("unless( isSaveData(dirName) )")
      return File.exist?(dirName)
    end
    
    @logger.debug(dirName, "this dir is SaveData dir")
    
    tableName = getTableName(dirName)
    isExistTable?(tableName)
  end
  
  
  def sendChatMessage(chatMessageData, fileName)
    dirName = File.dirname(fileName)
    tableName = getChatTableName(dirName)
    createChatTable(tableName)
    
    isReadOnly = false
    open(nil, isReadOnly, tableName) do
      
      time = getCurrentTime
      text = getJsonString([time, chatMessageData])
      
      numberLimit = $chatMessageDataLogAllLineMax
      oldestNumber = 0
      result = executeSql("SELECT number FROM #{tableName} WHERE number<#{numberLimit} ORDER BY time limit 1")
      result.each do |row|
        oldestNumber = row.first
      end
      
      @logger.debug(oldestNumber, "oldestNumber")
      
      executeSql("UPDATE #{tableName} SET text=?,time=? WHERE (number=#{oldestNumber})", text, time);
                 
    end
    
  end
  
  
  def loadSaveFileDataForChatType(trueSaveFileName, saveDataForChat)
    @logger.debug("loadSaveFileDataForChatType begin")
    
    dirName = File.dirname(trueSaveFileName)
    tableName = getChatTableName(dirName)
    createChatTable(tableName)
    
    numberLimit = $chatMessageDataLogAllLineMax
    
    (0 ... numberLimit).each do |number|
      
      count = executeCountSql("SELECT count(*) FROM #{tableName} WHERE (number=?)", number);
      next if( count == 0 )
      
      text = ""
      unless( saveDataForChat.nil? )
        chatData = saveDataForChat[number]
        unless( chatData.nil? )
          text = getJsonString(chatData)
        end
      end
      
      time = getCurrentTime
      executeSql("UPDATE #{tableName} SET text=?,time=? WHERE (number=?)", text, time, number);
    end
    
    @logger.debug("loadSaveFileDataForChatType end")
  end
  
  def deleteChatLogBySaveFile(trueSaveFileName)
    dirName = File.dirname(trueSaveFileName)
    tableName = getChatTableName(dirName)
    
    deleteTable(tableName)
    createChatTable(tableName)
  end
  
end



class MySqlAccesser
  def self.setSaveDataManager(manager)
    @@saveDataManager = manager
  end
  
  def isExist?(fileName)
    @@saveDataManager.isExist?(fileName)
  end
  
  def isExistDir?(dirName)
    @@saveDataManager.isExistDir?(dirName)
  end
  
  def createFile(fileName, text)
    @@saveDataManager.changeText(fileName, text)
  end
  
  def isSaveData(fileName)
    @@saveDataManager.isSaveData(fileName)
  end
  
  def getSaveFileText(fileName)
    @@saveDataManager.getText(fileName)
  end
  
  def getSaveFileTimeStamp(fileName)
    @@saveDataManager.getTime(fileName)
  end
  
  def sendChatMessage(chatMessageData, saveFileName)
    @@saveDataManager.sendChatMessage(chatMessageData, saveFileName)
  end
  
  def loadSaveFileForChat(typeName, fileName, lastUpdateTimes)
    @@saveDataManager.loadSaveFileForChat(typeName, fileName, lastUpdateTimes)
  end
  
  def loadSaveFileDataForChatType(trueSaveFileName, saveDataForChat)
    @@saveDataManager.loadSaveFileDataForChatType(trueSaveFileName, saveDataForChat)
  end
  
  def deleteChatLogBySaveFile(trueSaveFileName)
    @@saveDataManager.deleteChatLogBySaveFile(trueSaveFileName)
  end
end



class SaveDirInfoMySql < SaveDirInfo
  def self.setSaveDataManager(manager)
    @@saveDataManager = manager
  end
  
  
  def createDir()
    dirName = getDirName()
    @@saveDataManager.createTable(dirName)
  end
  
  def removeSaveDir(saveDataDirIndex)
    dirName = getDirNameByIndex(saveDataDirIndex)
    @@saveDataManager.removeSaveDir(dirName)
  end

  def getExistFileNames(dirName, fileNames)
    existFileNames = []

    fileNames.each do |fileName|
      full_fileName = File.join(dirName, fileName)
      @logger.debug(full_fileName, "getExistFileNames full_fileName")

      if( @@saveDataManager.isExistDir?(full_fileName) or
            @@saveDataManager.isExist?(full_fileName) )

        @logger.debug(full_fileName, "getExistFileNames full_fileName exist")
        existFileNames << full_fileName
      end
    end

    @logger.debug(existFileNames, "getExistFileNames existFileNames")

    return existFileNames
  end

  def getSaveDataLastAccessTimes(fileNames, roomNumberRange)
    saveDirs = getSaveDataDirs(roomNumberRange)
    return @@saveDataManager.getSaveDataLastAccessTimes(saveDirs, roomNumberRange)
  end
  
end




require "FileLock"

class FileLockMySql < FileLock
  
  def self.setSaveDataManager(manager)
    @@saveDataManager = manager
  end
  
  
  def initialize(lockFileName, isReadOnly = false)
    @lockFileName = lockFileName
    @isReadOnly = isReadOnly
  end
  
  def lock(&action)
    @@saveDataManager.open(@lockFileName, @isReadOnly) do
      action.call
    end
  end
  
end



class DodontoFServer_MySql < DodontoFServer
  
  def getDataAccesser
    @dataAccesser ||= MySqlAccesser.new
    @dataAccesser
  end
  
  def addTextToFile(fileName, addedText)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    text = getSaveTextOnFileLocked(fileName)
    text += addedText
    createFile(fileName, text)
  end
  
  def createFile(fileName, text)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    @dataAccesser.createFile(fileName, text)
  end
  
  
  def getSaveTextOnFileLocked(fileName)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    text = getDataAccesser().getSaveFileText(fileName)
    return "{}" if( text.nil? )
    
    return text
  end
  
  def getSaveFileLock(fileName, isReadOnly = false)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    begin
      return FileLockMySql.new(fileName, isReadOnly)
    rescue
      @logger.error(@saveDirInfo.inspect, "when getSaveFileLock error : @saveDirInfo.inspect");
      raise
    end
  end
  
  
  def getSaveFileTimeStamp(fileName)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    getDataAccesser().getSaveFileTimeStamp(fileName)
  end
  
  
  def isExist?(fileName)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    getDataAccesser().isExist?(fileName)
  end
  
  def isExistDir?(dirName)
    return super unless( getDataAccesser().isSaveData(dirName) )
    
    getDataAccesser().isExistDir?(dirName)
  end
  
  def readLines(fileName)
    return super unless( getDataAccesser().isSaveData(fileName) )
    
    saveData = getSaveTextOnFileLocked(fileName)
    lines = saveData.split(/\n/)
    return lines
  end
  
  
  def loadSaveFileForChat(typeName, saveFileName)
    getDataAccesser().loadSaveFileForChat(typeName, saveFileName, @lastUpdateTimes)
  end
  
  def loadSaveFile(typeName, saveFileName)
    if( isChatType(typeName) )
      return loadSaveFileForChat(typeName, saveFileName)
    end
    
    return super
  end
  
  
  def sendChatMessageByChatData(chatData)
    @logger.debug(chatData, "sendChatMessage chatData")
    saveFileName = @saveFiles['chatMessageDataLog']
    getDataAccesser().sendChatMessage(chatData, saveFileName)
  end
  
  
  def loadSaveFileDataForEachType(fileTypeName, trueSaveFileName, saveDataForType)
    if( isChatType(fileTypeName) )
      getDataAccesser().loadSaveFileDataForChatType(trueSaveFileName, saveDataForType[fileTypeName])
      return
    end
    
    super
  end
  
  def deleteChatLogBySaveFile(trueSaveFileName)
    getDataAccesser().deleteChatLogBySaveFile(trueSaveFileName)
  end
  
  def getTestResponseText
    "「どどんとふ（MySQL）」の動作環境は正常に起動しています。";
  end
  
end


def mainMySql(cgiParams)
  
  saveDataManager = SaveDataManagerOnMySql.new
  
  begin
    FileLockMySql.setSaveDataManager(saveDataManager)
    MySqlAccesser.setSaveDataManager(saveDataManager)
    SaveDirInfoMySql.setSaveDataManager(saveDataManager)
    
    server = DodontoFServer_MySql.new(SaveDirInfoMySql.new(), cgiParams)
    
    printResult(server)
  ensure
    saveDataManager.closeDb
  end
end



if( $0 === __FILE__ )
  cgiParams = getCgiParams()
  
  mainMySql(cgiParams)
end

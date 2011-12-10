#--*-coding:utf-8-*--

require 'fileutils'

class SaveDirInfo
  
  def init(saveDataDirIndexObject, saveDataMaxCount = 0, subDir = '.')
    @saveDataDirIndexObject = saveDataDirIndexObject
    @saveDataDirIndex = nil
    @subDir = subDir
    @saveDataMaxCount = saveDataMaxCount
    @sampleMode = false
  end
  
  def setSampleMode
    @sampleMode = true
  end
  
  def getMaxCount
    @saveDataMaxCount
  end
  
  def getSaveDataBaseDir()
    return File.join(@subDir, "saveData")
  end
  
  
  def each_with_index(roomNumberRange, *fileNames)
    saveDirs = getSaveDataDirs( roomNumberRange )
    
    saveDirs.each_with_index do |saveDir, index|
      next unless( /data_(\d+)\Z/ === saveDir )
      
      dirIndex = $1.to_i
      saveFiles = getExistFileNames(saveDir, fileNames)
      yield(saveFiles, dirIndex)
    end
  end
  
  def getExistFileNames(dir, fileNames)
    result = []
    
    fileNames.each do |fileName|
      file = File.join(dir, fileName)
      if( FileTest.exist?(file) )
        result << file
      end
    end
    
    return result
  end
  
  def getSaveDataDirs( roomNumberRange )
    dir = getSaveDataBaseDir
    dirNames = []
    roomNumberRange.each{|i| dirNames << File.join("data_" + i.to_s)}
    saveDirs = getExistFileNames(dir, dirNames)
    
    return saveDirs
  end
  
  def getSaveDataLastAccessTimes(fileNames, roomNumberRange)
    logging(fileNames, "getSaveDataLastAccessTimes fileNames")
    
    saveDirs = getSaveDataDirs( roomNumberRange )
    logging(saveDirs, "getSaveDataLastAccessTimes saveDirs")
    
    result = {}
    saveDirs.each do |saveDir|
      next unless( /data_(\d+)\Z/ === saveDir )
      
      dirIndex = $1.to_i
      next unless( roomNumberRange.include?(dirIndex) )
      
      saveFiles = getExistFileNames(saveDir, fileNames)
      mtimes = saveFiles.collect{|i| File.mtime(i)}
      result[dirIndex] = mtimes.max
    end
    
    logging(result, "getSaveDataLastAccessTimes result")
    
    return result;
  end
  
  def setSaveDataDirIndex(index)
    @saveDataDirIndex = index.to_i
  end
  
  def getSaveDataDirIndex
    if( @saveDataDirIndex )
      return @saveDataDirIndex
    end
    
    logging(@requestData.inspect, "requestData")
    
    logging(@saveDataDirIndexObject, "saveDataDirIndexObject")
    
    if( @saveDataDirIndexObject.instance_of?( StringIO ) )
      logging("is StringIO")
      @saveDataDirIndexObject = @saveDataDirIndexObject.string
    end
    saveDataDirIndex = @saveDataDirIndexObject.to_i
    
    logging(saveDataDirIndex.inspect, "saveDataDirIndex")
    
    unless( @sampleMode )
      if( saveDataDirIndex > @saveDataMaxCount )
        raise "saveDataDirIndex:#{saveDataDirIndex} is over Limit:(#{@saveDataMaxCount}"
      end
    end
    
    logging(saveDataDirIndex, "saveDataDirIndex")
    
    return saveDataDirIndex
  end
  
  def getDirName()
    logging("getDirName begin..")
    saveDataDirIndex = getSaveDataDirIndex()
    return getDirNameByIndex(saveDataDirIndex)
  end
  
  def getDirNameByIndex(saveDataDirIndex)
    saveDataBaseDirName = getSaveDataBaseDir()
    
    saveDataDirName = ''
    if( saveDataDirIndex >= 0 )
      dataDirName = "data_" + saveDataDirIndex.to_s
      saveDataDirName = File.join(saveDataBaseDirName, dataDirName)
      logging(saveDataDirName, "saveDataDirName created")
    end
    
    return saveDataDirName
  end
  
  def createDir()
    logging('createDir begin')
    
    saveDataDirName = getDirName()
    logging(saveDataDirName, 'createDir saveDataDirName')
    
    if( FileTest.directory?(saveDataDirName) )
      raise "このプレイルームはすでに作成済みです。"
    end
    
    logging("cp_r new save data...")
    
    Dir::mkdir(saveDataDirName)
    File.chmod(0777, saveDataDirName)
    
    options = {
      :preserve => true,
    }
    
    sourceDir = 'saveData_forNewCreation'
    
    fileNames = getSaveFileAllNames()
    srcFiles = getExistFileNames(sourceDir, fileNames)
    
    FileUtils.cp_r(srcFiles, saveDataDirName, options);
    logging("cp_r new save data")
    
    logging('createDir end')
  end
  
  def getSaveFileAllNames
    fileNames = []
    
    saveFiles = $saveFiles.values + [
      $loginUserInfo,
      $playRoomInfo,
      $chatMessageDataLogAll,
    ]
    
    saveFiles.each do |i|
      fileNames << i
      fileNames << i + ".lock"
    end
    
    return fileNames
  end
  
  def removeSaveDir(saveDataDirIndex)
    dirName = getDirNameByIndex(saveDataDirIndex)
    self.class.removeDir(dirName)
  end
  
  def self.removeDir(dirName)
    unless( FileTest.directory?(dirName) )
      return
    end
    
    #fileNames = getSaveFileAllNames
    #files = getExistFileNames(dirName, fileNames)
    files = Dir.glob( File.join(dirName, "*") )
    
    logging(files, "removeDir files")
    files.each do |fileName|
      File.delete(fileName.untaint)
    end
    
    Dir.delete(dirName)
  end
  
  def getTrueSaveFileName(saveFileName)
    begin
      saveDataDirName = getDirName()
      logging(saveDataDirName, "saveDataDirName")
      
      return File.join(saveDataDirName, saveFileName)
    rescue => e
      loggingForce($!.inspect )
      loggingForce(e.inspect )
      raise e
    end
  end
  
end

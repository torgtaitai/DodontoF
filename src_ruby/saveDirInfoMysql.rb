#--*-coding:utf-8-*--

require 'fileutils'

require 'dodontof/logger'

class SaveDirInfo
  def self.removeDir(dirName)
    return unless( FileTest.directory?(dirName) )

    # force = true
    # FileUtils.remove_entry_secure(dirName, force)
    # 上記のメソッドは一部レンタルサーバ(さくらインターネット等）で禁止されているので、
    # この下の方法で対応しています。

    logger = DodontoF::Logger.instance

    files = Dir.glob( File.join(dirName, "*") )

    logger.debug(files, "removeDir files")
    files.each do |fileName|
      File.delete(fileName.untaint)
    end

    Dir.delete(dirName)
  end
  
  def init(saveDataDirIndexObject, saveDataMaxCount = 0, subDir = '.')
    @saveDataDirIndexObject = saveDataDirIndexObject
    @saveDataDirIndex = nil
    @subDir = subDir
    @saveDataMaxCount = saveDataMaxCount
    @sampleMode = false

    @logger = DodontoF::Logger.instance
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
    @logger.debug(fileNames, "getSaveDataLastAccessTimes fileNames")
    
    saveDirs = getSaveDataDirs( roomNumberRange )
    @logger.debug(saveDirs, "getSaveDataLastAccessTimes saveDirs")
    
    result = {}
    saveDirs.each do |saveDir|
      next unless( /data_(\d+)\Z/ === saveDir )
      
      dirIndex = $1.to_i
      next unless( roomNumberRange.include?(dirIndex) )
      
      saveFiles = getExistFileNames(saveDir, fileNames)
      mtimes = saveFiles.collect{|i| File.mtime(i)}
      result[dirIndex] = mtimes.max
    end
    
    @logger.debug(result, "getSaveDataLastAccessTimes result")
    
    return result;
  end
  
  def setSaveDataDirIndex(index)
    @saveDataDirIndex = index.to_i
  end
  
  def getSaveDataDirIndex
    if( @saveDataDirIndex )
      return @saveDataDirIndex
    end
    
    @logger.debug(@requestData.inspect, "requestData")
    
    @logger.debug(@saveDataDirIndexObject, "saveDataDirIndexObject")
    
    if( @saveDataDirIndexObject.instance_of?( StringIO ) )
      @logger.debug("is StringIO")
      @saveDataDirIndexObject = @saveDataDirIndexObject.string
    end
    saveDataDirIndex = @saveDataDirIndexObject.to_i
    
    @logger.debug(saveDataDirIndex.inspect, "saveDataDirIndex")
    
    unless( @sampleMode )
      if( saveDataDirIndex > @saveDataMaxCount )
        raise "saveDataDirIndex:#{saveDataDirIndex} is over Limit:(#{@saveDataMaxCount}"
      end
    end
    
    @logger.debug(saveDataDirIndex, "saveDataDirIndex")
    
    return saveDataDirIndex
  end
  
  def getDirName()
    @logger.debug("getDirName begin..")
    saveDataDirIndex = getSaveDataDirIndex()
    return getDirNameByIndex(saveDataDirIndex)
  end
  
  def getDirNameByIndex(saveDataDirIndex)
    saveDataBaseDirName = getSaveDataBaseDir()
    
    saveDataDirName = ''
    if( saveDataDirIndex >= 0 )
      dataDirName = "data_" + saveDataDirIndex.to_s
      saveDataDirName = File.join(saveDataBaseDirName, dataDirName)
      @logger.debug(saveDataDirName, "saveDataDirName created")
    end
    
    return saveDataDirName
  end
  
  def createDir()
    @logger.debug('createDir begin')
    
    saveDataDirName = getDirName()
    @logger.debug(saveDataDirName, 'createDir saveDataDirName')
    
    if( FileTest.directory?(saveDataDirName) )
      return
      # raise "このプレイルームはすでに作成済みです。"
    end
    
    @logger.debug("cp_r new save data...")
    
    Dir::mkdir(saveDataDirName)
    File.chmod(0777, saveDataDirName)
    
    @logger.debug('createDir end')
  end
  
  
  def removeSaveDir(saveDataDirIndex)
    dirName = getDirNameByIndex(saveDataDirIndex)
    self.class.removeDir(dirName)
  end
  
  def getTrueSaveFileName(saveFileName)
    @logger.debug(saveFileName, "savedirinfo.getTrueSaveFileName saveFileName")
    begin
      saveDataDirName = getDirName()
      @logger.debug(saveDataDirName, "saveDataDirName")
      
      return File.join(saveDataDirName, saveFileName)
    rescue Exception => e
      @logger.error($!.inspect )
      @logger.error(e.inspect )
      raise e
    end
  end
  
  
  def getSharedFileName(fileName)
    begin
      dir = getSaveDataBaseDir()
      return File.join(dir, fileName)
    rescue => e
      @logger.error($!.inspect )
      @logger.error(e.inspect )
      raise e
    end
  end
  
end

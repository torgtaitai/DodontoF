
class FileLock
  
  def initialize(lockFileName)
    @lockFileName = lockFileName
    
    unless( File.exist?(@lockFileName) )
      createLockFile
    end
  end
  
  def createLockFile
    File.open(@lockFileName, "w+") do |file|
      file.write("lock")
    end
  end
  
  def lock(&action)
    open(@lockFileName, "r+") do |f|
      f.flock(File::LOCK_EX)
      begin
        action.call
      ensure
        f.flush()
        f.flock(File::LOCK_UN)
      end
    end
  end
  
end

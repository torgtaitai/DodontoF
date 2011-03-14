
class FileLock2
  
  def initialize(lockFileName, isReadOnly = false)
    @lockFileName = lockFileName
    @isReadOnly = isReadOnly
    
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
    mode = (@isReadOnly ? File::LOCK_SH : File::LOCK_EX)
    open(@lockFileName, "r+") do |f|
      f.flock(mode)
      begin
        action.call
      ensure
        f.flush() unless( @isReadOnly )
        f.flock(File::LOCK_UN)
      end
    end
  end
  
end

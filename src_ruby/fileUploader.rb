#--*-coding:utf-8-*--

require 'kconv'
require 'config'

class FileUploader
  
  def initialize
    @resultMessage = "...."
  end
  
  def init(uploadFileInfo, fileSizeLimit, fileCountLimit)
    @uploadFileInfo = uploadFileInfo
    @fileSizeLimit = fileSizeLimit
    @fileCountLimit = fileCountLimit
  end
  
  def getUploadFileName
    uploadFileName = @uploadFileInfo.original_filename
    logging(uploadFileName, "uploadFileName")
    
    return uploadFileName
  end
  
  def getUploadFileExtName
    uploadFileName = getUploadFileName
    return File.extname(uploadFileName)
  end
  
  def checkUploadFileSize
    fileSize = @uploadFileInfo.size
    logging(fileSize, "fileSize");
    if( fileSize > (@fileSizeLimit * 1024 * 1024))
      raise "ファイルのサイズが上限の#{ sprintf('%0.2f', @fileSizeLimit) }MBを超えています。（アップロードしようとしたファイルのサイズ:#{ sprintf('%0.2f', 1.0 * fileSize / 1024 / 1024) }MB)"
    end
  end
  
  def createDirAndCrean(dirName)
    unless( FileTest.directory?(dirName) )
      Dir::mkdir(dirName)
    end
    
    files = Dir.glob( File.join(dirName, "*") )
    logging(files, "dir include fileNames")
    
    newOrderFiles = files.sort!{|a, b| File.mtime(b) <=> File.mtime(a)}
    newOrderFiles.each_with_index do |file, index|
      if( index < (@fileCountLimit - 1) )
        logging("@fileCountLimit", @fileCountLimit)
        logging("delete pass file", file)
        next
      end
      File.delete(file)
      logging("deleted file", file)
    end
  end
  
  def createUploadFile(saveDataDirIndex, fileName, subDirName = ".")
    
    saveDirInfo = SaveDirInfo.new(saveDataDirIndex, $saveDataMaxCount, $SAVE_DATA_DIR)
    saveDirName = saveDirInfo.getTrueSaveFileName(subDirName)
    logging(saveDirName, "saveDirName")
    
    unless(subDirName == ".")
      createDirAndCrean(saveDirName)
    end
    
    saveFileName = File.join(saveDirName, fileName)
    logging(saveFileName, "saveFileName")
    
    logging("open...")
    open(saveFileName, "w+") do |file|
      
      file.binmode
      file.write(@uploadFileInfo.read)
    end
    logging("close...")
    
    logging("createUploadFile end.")
    
    return saveFileName
  end
  
  def setSuccessMeesage(result)
    @resultMessage = "アップロードに成功しました。<br />この画面を閉じてください。"
  end
  
  def setErrorMessage(result)
    @resultMessage = "result:#{result}\nアップロードに失敗しているような気がします。<br />・・・が、もしかすると仕様変更かもしれません。"
  end
  
  def setExceptionErrorMeesage(exception)
    logging("Exception")
    
    $debug = true
    
    @resultMessage = "アップロード中に下記のエラーが発生しました。もう一度試すか管理者に連絡してください。<br />"
    @resultMessage += "<hr /><br />"
    @resultMessage += exception.to_s + "<br />"
    @resultMessage += exception.inspect.toutf8
    @resultMessage += $!.inspect.toutf8
    @resultMessage += $@.inspect.toutf8
    logging(@resultMessage)
  end
  
  def printResultHtml
    header = "Content-Type: text/html\ncharset: utf-8\n\n";
    print header
    
    message = '<html>
<META HTTP-EQUIV="Content-type" CONTENT="text/html; charset=UTF-8">
<body>
' + @resultMessage + '
</body></html>'
    message = message.toutf8
    
    logging(message)
    
    print message.toutf8
  end
end



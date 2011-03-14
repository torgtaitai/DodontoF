#--*-coding:utf-8-*--


require 'test/unit'
require 'kconv'
require 'logger'
require 'imageUploader'
require 'DodontoFServer'


$debug = true

def getLogMessageProc(obj, *options)
  message = obj.inspect.tosjis
  if( obj.instance_of?(String) )
    message = obj
  end
  return message = "#{options.join(',')}:#{message}"
end

def logging(obj, *options)
  $log ||= Logger.new("log.txt", 3)
  $log.level = ( $debug ? Logger::DEBUG : Logger::ERROR )

  $log.debug() do 
    getLogMessageProc(obj, *options)
  end
end



class TestDodontoFServer < Test::Unit::TestCase
 
  def setup
  end
  
  def test_getImageList
    cgi = {
      'imageData'=>'{"imageType":"map"}',
      'Command' => 'getImageList',
      'saveDataDirIndex' => '0',
    }
    $imageTypeInfos['map'] = "./testMapImages"
    server = DodontoFServer.new(cgi)
    result = server.getResponse
    assert_equal('{"mapImageList":["./testMapImages/01akt11.jpeg","./testMapImages/Blue hills.jpg","./testMapImages/Sunset.jpg"]}', result);
  end
  
  def test_FileBasename
    fileName = 'C:\Documents and Settings\All Users\Documents\My Pictures\Sample Pictures\At the Arch.jpg'
    assert_equal('At the Arch.jpg', ImageUploaderForDndMap.getBaseName(fileName))

    fileName = 'C:\Documents and Settings\All Users\Documents\My Pictures\Sample Pictures\\'
    assert_equal('', ImageUploaderForDndMap.getBaseName(fileName))
    
    fileName = 'At the Arch.jpg'
    assert_equal('At the Arch.jpg', ImageUploaderForDndMap.getBaseName(fileName))
  end
  
  def test_getImageList
    cgi = {
      'Command' => 'getPlayRoomState',
      'maxPlayRoomCount' => '10',
    }
    
    server = DodontoFServer.new(cgi)
    result = server.getResponse.tosjis
    
    print(result + "\n")
    
    #assert_equal('', result);
  end
  
end

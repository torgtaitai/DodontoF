#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"

require 'DodontoFServer'

class WebCameraCaptureImageUploader
  def upload
    logging("WebCameraCaptureImageUploader upload Begin")
    
    imageType = 'character'
    imageDir = $imageTypeInfos[imageType]
    now = Time.new
    fileBaseName = now.strftime("%Y%m%d_%H%M%S_") + now.usec.to_s
    
    imageFileName = "#{imageDir}/#{fileBaseName}.png"
    logging(imageFileName, "imageFileName")
    
    open( imageFileName, "wb" ){ |file|
      $stdin.binmode # バイナリモード
      file.write( $stdin.read )
    }
    
    jsonData = {
      "resultText"=> "OK"
    }
    result = JsonBuilder.new.build(jsonData)
    logging(result, "result")
    logging("Pass.")
    
    header = "Content-Type: text/html\ncharset: utf-8\n\n";
    text = header + result
    
    logging(text, "CGI respons string")
    print(text)
    logging(text)
    logging("CGI end.")
  end
end

if( $0 === __FILE__ )
  WebCameraCaptureImageUploader.new.upload
end



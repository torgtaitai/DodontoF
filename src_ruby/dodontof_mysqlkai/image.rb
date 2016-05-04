#--*-coding:utf-8-*--

module DodontoF_MySqlKai
  # Image情報
  class Image
    def initialize(server, saveDirInfo)
      @logger = DodontoF::Logger.instance
      @server = server
      @saveDirInfo = saveDirInfo
    end

    def deleteImage(params)
      @logger.debug("deleteImage begin")

      @logger.debug(params, "imageData")

      imageUrlList = params['imageUrlList']
      @logger.debug(imageUrlList, "imageUrlList")

      deleteImages(imageUrlList)
    end

    def deleteImages(imageUrlList)
      imageFiles = @server.getAllImageFileNameFromTagInfoFile()
      @server.addLocalImageToList(imageFiles)
      @logger.debug(imageFiles, "imageFiles")

      imageUrlFileName = $imageUrlText
      @logger.debug(imageUrlFileName, "imageUrlFileName")

      deleteCount = 0
      resultText = ""
      imageUrlList.each do |imageUrl|
        if( @server.isProtectedImage(imageUrl) )
          warningMessage = "#{imageUrl}は削除できない画像です。"
          next
        end

        imageUrl.untaint
        deleteResult1 = @server.deleteImageTags(imageUrl)
        deleteResult2 = @server.deleteTargetImageUrl(imageUrl, imageFiles, imageUrlFileName)
        deleteResult = (deleteResult1 or deleteResult2)

        if( deleteResult )
          deleteCount += 1
        else
          warningMessage = "不正な操作です。あなたが削除しようとしたファイル(#{imageUrl})はイメージファイルではありません。"
          @logger.error(warningMessage)
          resultText += warningMessage
        end
      end

      resultText += "#{deleteCount}個のファイルを削除しました。"
      result = {"resultText" => resultText}
      @logger.debug(result, "result")

      @logger.debug("deleteImage end")
      return result
    end

    def uploadImageUrl(imageData)
      @logger.debug("uploadImageUrl begin")

      @logger.debug(imageData, "imageData")

      imageUrl = imageData['imageUrl']
      @logger.debug(imageUrl, "imageUrl")

      imageUrlFileName = $imageUrlText
      @logger.debug(imageUrlFileName, "imageUrlFileName")

      resultText = "画像URLのアップロードに失敗しました。"
      locker = @server.getSaveFileLock(imageUrlFileName)
      locker.lock do
        alreadyExistUrls = @server.readLines(imageUrlFileName).collect{|i| i.chomp }
        if( alreadyExistUrls.include?(imageUrl) )
          resultText = "すでに登録済みの画像URLです。"
        else
          @server.addTextToFile(imageUrlFileName, (imageUrl + "\n"))
          resultText = "画像URLのアップロードに成功しました。"
        end
      end

      tagInfo = imageData['tagInfo']
      @logger.debug(tagInfo, 'uploadImageUrl.tagInfo')
      @server.changeImageTagsLocal(imageUrl, tagInfo)

      @logger.debug("uploadImageUrl end")

      result = {"resultText" => resultText}
      return result
    end
  end
end

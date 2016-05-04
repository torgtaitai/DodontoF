#--*-coding:utf-8-*--

module DodontoF
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
      imageFiles = getAllImageFileNameFromTagInfoFile()
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
      changeImageTagsLocal(imageUrl, tagInfo)

      @logger.debug("uploadImageUrl end")

      result = {"resultText" => resultText}
      return result
    end

    def uploadImageData(params)
      @logger.debug("uploadImageData load Begin")

      result = {
        "resultText"=> "OK"
      }

      begin
        imageFileName = params["imageFileName"]
        @logger.debug(imageFileName, "imageFileName")

        imageData = getImageDataFromParams(params, "imageData")
        smallImageData = getImageDataFromParams(params, "smallImageData")

        if( imageData.nil? )
          @logger.debug("createSmallImage is here")
          imageFileNameBase = File.basename(imageFileName)
          saveSmallImage(smallImageData, imageFileNameBase, imageFileName)
          return result
        end

        saveDir = @server.getUploadImageDataUploadDir(params)
        imageFileNameBase = @server.getNewFileName(imageFileName, "img")
        @logger.debug(imageFileNameBase, "imageFileNameBase")

        uploadImageFileName = @server.fileJoin(saveDir, imageFileNameBase)
        @logger.debug(uploadImageFileName, "uploadImageFileName")

        open( uploadImageFileName, "wb+" ) do |file|
          file.write( imageData )
        end

        saveSmallImage(smallImageData, imageFileNameBase, uploadImageFileName)

      rescue => e
        result["resultText"] = DodontoF::Utils.getLanguageKey( e.to_s )
      end

      @logger.debug(result, "uploadImageData result")
      @logger.debug("uploadImageData load End")

      return result
    end

    def getImageTagsAndImageList
      result = {}

      result['tagInfos'] = @server.getImageTags()
      result['imageList'] = getImageList()
      result['imageDir'] = $imageUploadDir

      @logger.debug("getImageTagsAndImageList result", result)

      return result
    end

    def changeImageTags(effectData)
      source = effectData['source']
      tagInfo = effectData['tagInfo']

      changeImageTagsLocal(source, tagInfo)
    end

    private

    def getImageDataFromParams(params, key)
      value = params[key]

      sizeCheckResult = @server.checkFileSizeOnMb(value, $UPLOAD_IMAGE_MAX_SIZE)
      raise sizeCheckResult unless( sizeCheckResult.empty? )

      return value
    end

    def getImageList()
      @logger.debug("getImageList start.")

      imageList = getAllImageFileNameFromTagInfoFile()
      @logger.debug(imageList, "imageList all result")

      @server.addTextsCharacterImageList(imageList, $imageUrlText)
      @server.addLocalImageToList(imageList)

      @server.deleteInvalidImageFileName(imageList)

      imageList.sort!

      return imageList
    end

    def saveSmallImage(smallImageData, imageFileNameBase, uploadImageFileName)
      @logger.debug("saveSmallImage begin")
      @logger.debug(imageFileNameBase, "imageFileNameBase")
      @logger.debug(uploadImageFileName, "uploadImageFileName")

      smallImageDir = @server.getSmallImageDir
      uploadSmallImageFileName = @server.fileJoin(smallImageDir, imageFileNameBase)
      uploadSmallImageFileName += ".png";
      uploadSmallImageFileName.untaint
      @logger.debug(uploadSmallImageFileName, "uploadSmallImageFileName")

      open( uploadSmallImageFileName, "wb+" ) do |file|
        file.write( smallImageData )
      end
      @logger.debug("small image create successed.")

      # TODO: saveSmallImage中のgetParamsFromRequestDataを引数に追い出す
      params = @server.getParamsFromRequestData()
      tagInfo = params['tagInfo']
      @logger.debug(tagInfo, "saveSmallImage tagInfo")

      tagInfo["smallImage"] = uploadSmallImageFileName
      @logger.debug(tagInfo, "saveSmallImage tagInfo smallImage url added")

      margeTagInfo(tagInfo, uploadImageFileName)
      @logger.debug(tagInfo, "saveSmallImage margeTagInfo tagInfo")
      changeImageTagsLocal(uploadImageFileName, tagInfo)

      @logger.debug("saveSmallImage end")
    end

    def changeImageTagsLocal(source, tagInfo)
      return if( tagInfo.nil? )

      roomNumber = tagInfo["roomNumber"]

      @server.changeSaveData( @server.getImageInfoFileName(roomNumber) ) do |saveData|
        saveData['imageTags'] ||= {}
        imageTags = saveData['imageTags']

        imageTags[source] = tagInfo
      end
    end

    def getAllImageFileNameFromTagInfoFile()
      imageTags = @server.getImageTags()
      imageFileNames = imageTags.keys

      return imageFileNames
    end

    def margeTagInfo(tagInfo, source)
      @logger.debug(source, "margeTagInfo source")
      imageTags = @server.getImageTags()
      tagInfo_old = imageTags[source]
      @logger.debug(tagInfo_old, "margeTagInfo tagInfo_old")
      return if( tagInfo_old.nil? )

      tagInfo_old.keys.each do |key|
        tagInfo[key] = tagInfo_old[key]
      end

      @logger.debug(tagInfo, "margeTagInfo tagInfo")
    end
  end
end

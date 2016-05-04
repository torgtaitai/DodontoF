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

      result['tagInfos'] = getImageTags()
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

    def removeRoomImageTags(roomNumber)
      tagInfos = getImageTags(roomNumber)
      deleteImages(tagInfos.keys)
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

      addTextsCharacterImageList(imageList, $imageUrlText)
      addLocalImageToList(imageList)

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
      imageTags = getImageTags()
      imageFileNames = imageTags.keys

      return imageFileNames
    end

    def margeTagInfo(tagInfo, source)
      @logger.debug(source, "margeTagInfo source")
      imageTags = getImageTags()
      tagInfo_old = imageTags[source]
      @logger.debug(tagInfo_old, "margeTagInfo tagInfo_old")
      return if( tagInfo_old.nil? )

      tagInfo_old.keys.each do |key|
        tagInfo[key] = tagInfo_old[key]
      end

      @logger.debug(tagInfo, "margeTagInfo tagInfo")
    end

    def getImageTags(*roomNoList)
      @logger.debug('getImageTags start')

      imageTags = {}

      if roomNoList.empty?
        roomNoList = [nil, @saveDirInfo.getSaveDataDirIndex]
      end

      roomNoList.each do |roomNumber|
        @server.getSaveData( @server.getImageInfoFileName(roomNumber) ) do |saveData|
          tmpTags = saveData['imageTags']
          tmpTags ||= {}

=begin
        unless( roomNumber.nil? )
          tmpTags.each do |key, value|
            next if value.nil?
            value.delete("roomNumber")
          end
        end
=end

          imageTags.merge!( tmpTags )
        end
      end

      @logger.debug(imageTags, 'getImageTags imageTags')

      return imageTags
    end

    def deleteImages(imageUrlList)
      imageFiles = getAllImageFileNameFromTagInfoFile()
      addLocalImageToList(imageFiles)
      @logger.debug(imageFiles, "imageFiles")

      imageUrlFileName = $imageUrlText
      @logger.debug(imageUrlFileName, "imageUrlFileName")

      deleteCount = 0
      resultText = ""
      imageUrlList.each do |imageUrl|
        if( isProtectedImage(imageUrl) )
          warningMessage = "#{imageUrl}は削除できない画像です。"
          next
        end

        imageUrl.untaint
        deleteResult1 = deleteImageTags(imageUrl)
        deleteResult2 = deleteTargetImageUrl(imageUrl, imageFiles, imageUrlFileName)
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

    def deleteImageTags(source)
      roomNumber = @saveDirInfo.getSaveDataDirIndex
      isDeleted = deleteImageTagsByRoomNo(source, roomNumber)
      return true if( isDeleted )

      return deleteImageTagsByRoomNo(source, nil)
    end

    def deleteImageTagsByRoomNo(source, roomNumber)
      @server.changeSaveData( @server.getImageInfoFileName(roomNumber) ) do |saveData|
        imageTags = saveData['imageTags']
        return false if imageTags.nil?

        tagInfo = imageTags.delete(source)
        return false if tagInfo.nil?

        smallImage = tagInfo["smallImage"]
        begin
          @server.deleteFile(smallImage)
        rescue => e
          @logger.exception(e)
        end
      end

      return true
    end

    def deleteTargetImageUrl(imageUrl, imageFiles, imageUrlFileName)
      @logger.debug(imageUrl, "deleteTargetImageUrl(imageUrl)")

      if( imageFiles.include?(imageUrl) )
        if( @server.isExist?(imageUrl) )
          @server.deleteFile(imageUrl)
          return true
        end
      end

      locker = @server.getSaveFileLock(imageUrlFileName)
      locker.lock do
        lines = @server.readLines(imageUrlFileName)
        @logger.debug(lines, "lines")

        deleteResult = lines.reject!{|i| i.chomp == imageUrl }

        unless( deleteResult )
          return false
        end

        @logger.debug(lines, "lines deleted")
        @server.createFile(imageUrlFileName, lines.join)
      end

      return true
    end

    def isProtectedImage(imageUrl)
      $protectImagePaths.each do |url|
        if( imageUrl.index(url) == 0 )
          return true
        end
      end

      return false
    end

    def addLocalImageToList(imageList)
      dir = "#{$imageUploadDir}/public"
      addLocalImageToListByDir(imageList, dir)

      dir = @server.getRoomLocalSpaceDirName
      if( File.exist?(dir) )
        addLocalImageToListByDir(imageList, dir)
      end
    end

    def addLocalImageToListByDir(imageList, dir)
      DodontoF::Utils.makeDir(dir)

      files = Dir.glob("#{dir}/*")

      files.each do |fileName|
        file = file.untaint

        next if( imageList.include?(fileName) )
        next unless( isImageFile(fileName) )
        next unless( @server.isAllowedFileExt(fileName) )

        imageList << fileName
        @logger.debug(fileName, "added local image")
      end

      return imageList
    end

    def isImageFile(fileName)
      rule = /.(jpg|jpeg|gif|png|bmp|swf)$/i
      (rule === fileName)
    end

    def addTextsCharacterImageList(imageList, *texts)
      texts.each do |text|
        next unless( @server.isExist?(text) )

        lines = @server.readLines(text)
        lines.each do |line|
          line.chomp!

          next if(line.empty?)
          next if(imageList.include?(line))

          imageList << line
        end
      end
    end
  end
end

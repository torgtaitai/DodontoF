#--*-coding:utf-8-*--

module DodontoF
  # PlayRoom情報
  class PlayRoom
    def initialize(server, saveDirInfo)
      @logger = DodontoF::Logger.instance
      @server = server
      @saveDirInfo = saveDirInfo
    end

    def create(params)
      @logger.debug('createPlayRoom begin')

      resultText = "OK"
      playRoomIndex = -1
      begin
        @logger.debug(params, "params")

        checkCreatePlayRoomPassword(params['createPassword'])

        playRoomName = params['playRoomName']
        playRoomPassword = params['playRoomPassword']
        chatChannelNames = params['chatChannelNames']
        canUseExternalImage = params['canUseExternalImage']

        canVisit = params['canVisit']
        playRoomIndex = params['playRoomIndex']

        if( playRoomIndex == -1 )
          playRoomIndex = findEmptyRoomNumber()
          raise "noEmptyPlayRoom" if(playRoomIndex == -1)

          @logger.debug(playRoomIndex, "findEmptyRoomNumber playRoomIndex")
        end

        @logger.debug(playRoomName, 'playRoomName')
        @logger.debug('playRoomPassword is get')
        @logger.debug(playRoomIndex, 'playRoomIndex')

        @server.initSaveFiles(playRoomIndex)
        checkSetPassword(playRoomPassword, playRoomIndex)

        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) Begin")
        @saveDirInfo.removeSaveDir(playRoomIndex)
        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) End")

        @server.createDir(playRoomIndex)

        playRoomChangedPassword = DodontoF::Utils.getChangedPassword(playRoomPassword)
        @logger.debug(playRoomChangedPassword, 'playRoomChangedPassword')

        viewStates = params['viewStates']
        @logger.debug("viewStates", viewStates)

        trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)

        @server.changeSaveData(trueSaveFileName) do |saveData|
          saveData['playRoomName'] = playRoomName
          saveData['playRoomChangedPassword'] = playRoomChangedPassword
          saveData['chatChannelNames'] = chatChannelNames
          saveData['canUseExternalImage'] = canUseExternalImage
          saveData['canVisit'] = canVisit
          saveData['gameType'] = params['gameType']

          addViewStatesToSaveData(saveData, viewStates)
        end

        sendRoomCreateMessage(playRoomIndex)
      rescue Exception => e
        resultText = DodontoF::Utils.getLanguageKey( e.to_s )
      end

      result = {
        "resultText" => resultText,
        "playRoomIndex" => playRoomIndex,
      }
      @logger.debug(result, 'result')
      @logger.debug('createDir finished')

      return result
    end


    def change(params)
      @logger.debug("changePlayRoom begin")

      resultText = "OK"

      begin
        @logger.debug(params, "params")

        playRoomPassword = params['playRoomPassword']
        checkSetPassword(playRoomPassword)

        playRoomChangedPassword = DodontoF::Utils.getChangedPassword(playRoomPassword)
        @logger.debug('playRoomPassword is get')

        viewStates = params['viewStates']
        @logger.debug("viewStates", viewStates)

        trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)

        @server.changeSaveData(trueSaveFileName) do |saveData|
          saveData['playRoomName'] = params['playRoomName']
          saveData['playRoomChangedPassword'] = playRoomChangedPassword
          saveData['chatChannelNames'] = params['chatChannelNames']
          saveData['canUseExternalImage'] = params['canUseExternalImage']
          saveData['canVisit'] = params['canVisit']
          saveData['backgroundImage'] = params['backgroundImage']
          saveData['gameType'] = params['gameType']

          preViewStateInfo = saveData['viewStateInfo']
          unless( isSameViewState(viewStates, preViewStateInfo) )
            addViewStatesToSaveData(saveData, viewStates)
          end

        end
      rescue Exception => e
        resultText = DodontoF::Utils.getLanguageKey( e.to_s )
      end

      result = {
        "resultText" => resultText,
      }
      @logger.debug(result, 'changePlayRoom result')

      return result
    end

    def remove(params)
      roomNumbers = params['roomNumbers']
      ignoreLoginUser = params['ignoreLoginUser']
      password = params['password']
      password ||= ""
      isForce = params['isForce']

      adminPassword = params["adminPassword"]
      @logger.debug(adminPassword, "removePlayRoom() adminPassword")
      if( @server.isMentenanceMode(adminPassword) )
        password = nil
      end

      @server.removePlayRoomByParams(roomNumbers, ignoreLoginUser, password, isForce)
    end

    def removeOlds()
      roomNumberRange = (0 .. $saveDataMaxCount)
      accessTimes = @server.getSaveDataLastAccessTimes( roomNumberRange )
      result = removeOldRoomFromAccessTimes(accessTimes)
      return result
    end

    def getState(roomNo)
      # playRoomState = nil
      playRoomState = {}
      playRoomState['passwordLockState'] = false
      playRoomState['index'] = sprintf("%3d", roomNo)
      playRoomState['playRoomName'] = "（空き部屋）"
      playRoomState['lastUpdateTime'] = ""
      playRoomState['canVisit'] = false
      playRoomState['gameType'] = ''
      playRoomState['loginUsers'] = []

      begin
        playRoomState = getStateCatched(roomNo, playRoomState)
      rescue Exception => e
        @logger.error("getPlayRoomStateLocal Exception rescue")
        @logger.exception(e)
      end

      return playRoomState
    end

  private

    def checkCreatePlayRoomPassword(password)
      @logger.debug('checkCreatePlayRoomPassword Begin')
      @logger.debug(password, 'password')

      return if( $createPlayRoomPassword.empty? )
      return if( $createPlayRoomPassword == password )

      raise "errorPassword"
    end

    def findEmptyRoomNumber()
      emptyRoomNubmer = -1

      roomNumberRange = (0..$saveDataMaxCount)

      roomNumberRange.each do |roomNumber|
        @saveDirInfo.setSaveDataDirIndex(roomNumber)
        trueSaveFileName = @saveDirInfo.getTrueSaveFileName($playRoomInfo)

        next if( @server.isExist?(trueSaveFileName) )

        emptyRoomNubmer = roomNumber
        break
      end

      return emptyRoomNubmer
    end

    def sendRoomCreateMessage(roomNo)
      chatData = {
        "senderName" => "どどんとふ",
        "message" => "＝＝＝＝＝＝＝　プレイルーム　【　No.　#{roomNo}　】　へようこそ！　＝＝＝＝＝＝＝",
        "color" => "cc0066",
        "uniqueId" => '0',
        "channel" => 0,
      }

      @server.sendChatMessageByChatData(chatData)
    end

    def checkSetPassword(playRoomPassword, roomNumber = nil)
      return if( playRoomPassword.empty? )

      if( roomNumber.nil? )
        roomNumber = @saveDirInfo.getSaveDataDirIndex
      end

      if( $noPasswordPlayRoomNumbers.include?(roomNumber) )
        raise "noPasswordPlayRoomNumber"
      end
    end

    def isSameViewState(viewStates, preViewStateInfo)
      result = true

      preViewStateInfo ||= {}

      viewStates.each do |key, value|
        unless( value == preViewStateInfo[key] )
          result = false
          break
        end
      end

      return result
    end

    def addViewStatesToSaveData(saveData, viewStates)
      viewStates['key'] = Time.now.to_f.to_s
      saveData['viewStateInfo'] = viewStates
    end

    def getStateCatched(roomNo, playRoomState)
      playRoomInfoFile = @saveDirInfo.getTrueSaveFileName($playRoomInfo)

      return playRoomState unless( @server.isExist?(playRoomInfoFile) )

      playRoomData = nil
      @server.getSaveData(playRoomInfoFile) do |playRoomDataTmp|
        playRoomData = playRoomDataTmp
      end
      @logger.debug(playRoomData, "playRoomData")

      return playRoomState if( playRoomData.empty? )

      playRoomName = @server.getPlayRoomName(playRoomData, roomNo)
      passwordLockState = (not playRoomData['playRoomChangedPassword'].nil?)
      canVisit = playRoomData['canVisit']
      gameType = playRoomData['gameType']
      timeStamp = getSaveDataLastAccessTime( $saveFiles['chatMessageDataLog'], roomNo )

      timeString = ""
      unless( timeStamp.nil? )
        timeString = "#{timeStamp.strftime('%Y/%m/%d %H:%M:%S')}"
      end

      loginUsers = @server.getLoginUserNames()

      playRoomState['passwordLockState'] = passwordLockState
      playRoomState['playRoomName'] = playRoomName
      playRoomState['lastUpdateTime'] = timeString
      playRoomState['canVisit'] = canVisit
      playRoomState['gameType'] = gameType
      playRoomState['loginUsers'] = loginUsers

      return playRoomState
    end

    def getSaveDataLastAccessTime( fileName, roomNo )
      data = @saveDirInfo.getSaveDataLastAccessTime(fileName, roomNo)
      time = data[roomNo]
      return time
    end

    def removeOldRoomFromAccessTimes(accessTimes)
      @logger.debug("removeOldRoom Begin")
      if( $removeOldPlayRoomLimitDays <= 0 )
        return accessTimes
      end

      @logger.debug(accessTimes, "accessTimes")

      roomNumbers = @server.getDeleteTargetRoomNumbers(accessTimes)

      ignoreLoginUser = true
      password = nil
      isForce = true
      result = @server.removePlayRoomByParams(roomNumbers, ignoreLoginUser, password, isForce)
      @logger.debug(result, "removePlayRoomByParams result")

      return result
    end
  end
end

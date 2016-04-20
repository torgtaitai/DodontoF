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
        playRoomState = @server.getPlayRoomStateLocal(roomNo, playRoomState)
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
  end
end

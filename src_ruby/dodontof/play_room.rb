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
        @server.checkSetPassword(playRoomPassword, playRoomIndex)

        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) Begin")
        @saveDirInfo.removeSaveDir(playRoomIndex)
        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) End")

        @server.createDir(playRoomIndex)

        playRoomChangedPassword = @server.getChangedPassword(playRoomPassword)
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

          @server.addViewStatesToSaveData(saveData, viewStates)
        end

        @server.sendRoomCreateMessage(playRoomIndex)
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
  end
end

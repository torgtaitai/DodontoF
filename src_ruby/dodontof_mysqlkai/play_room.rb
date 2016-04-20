#--*-coding:utf-8-*--

module DodontoF_MySqlKai
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
        # DodontoF::PlayRoomとの違い(@server, @saveDirInfo)に注意
        @server.removeSaveDir(playRoomIndex)
        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) End")

        @server.createDir(playRoomIndex)

        playRoomChangedPassword = @server.getChangedPassword(playRoomPassword)
        @logger.debug(playRoomChangedPassword, 'playRoomChangedPassword')

        viewStates = params['viewStates']
        @logger.debug("viewStates", viewStates)

        # DodontoF::PlayRoomとの違いに注意
        # 1. trueSaveFileNameをこちらでは求めない
        # 2. changePlayRoomDataとchangeSaveData(trueSaveFileName)

        @server.changePlayRoomData do |saveData|
          saveData['playRoomName'] = playRoomName
          saveData['playRoomChangedPassword'] = playRoomChangedPassword
          saveData['chatChannelNames'] = chatChannelNames
          saveData['canUseExternalImage'] = canUseExternalImage
          saveData['canVisit'] = canVisit
          saveData['gameType'] = params['gameType']

          @server.addViewStatesToSaveData(saveData, viewStates)

          # DodontoF::PlayRoomとの違いに注意
          # changePlayRoomData()はchangeSaveData()と違い
          # iteratorからreturnを受け利用する
          saveData
        end

        @server.sendRoomCreateMessage(playRoomIndex)
      rescue Exception => e
        @logger.exception(e)
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
      # このメソッドは全体的にDodontoF::PlayRoomと異なるので注意

      emptyRoomNubmer = -1

      command = <<COMMAND_END
SELECT
  IF(
    (SELECT COUNT(roomNo) FROM rooms)=0,
    0,
    (
      IF(
        (SELECT MIN(roomNo) FROM rooms)<>0,
        0,
        MIN(roomNo+1)
      )
    )
  ) AS roomNo
FROM rooms
WHERE (roomNo+1) NOT IN (SELECT roomNo FROM rooms)
COMMAND_END

      @server.connectDb
      result = @server.query(command)
      @logger.debug(result, "findEmptyRoomNumber result")

      row = result.first
      row ||= {}
      @logger.debug(row, "findEmptyRoomNumber row")

      count = row['roomNo'].to_i

      emptyRoomNubmer = count
      @logger.debug(emptyRoomNubmer, 'emptyRoomNubmer')

      return emptyRoomNubmer
    end
  end
end

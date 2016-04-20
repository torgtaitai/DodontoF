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
        checkSetPassword(playRoomPassword, playRoomIndex)

        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) Begin")
        # DodontoF::PlayRoomとの違い(@server, @saveDirInfo)に注意
        @server.removeSaveDir(playRoomIndex)
        @logger.debug("@saveDirInfo.removeSaveDir(playRoomIndex) End")

        @server.createDir(playRoomIndex)

        playRoomChangedPassword = DodontoF::Utils.getChangedPassword(playRoomPassword)
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

          addViewStatesToSaveData(saveData, viewStates)

          # DodontoF::PlayRoomとの違いに注意
          # changePlayRoomData()はchangeSaveData()と違い
          # iteratorからreturnを受け利用する
          saveData
        end

        sendRoomCreateMessage(playRoomIndex)
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

        # DodontoF::PlayRoomとの違いに注意
        # 1. trueSaveFileNameをこちらでは求めない
        # 2. changePlayRoomDataとchangeSaveData(trueSaveFileName)

        changePlayRoomData do |saveData|
          @logger.debug(saveData, 'changePlayRoom() saveData before')
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

          @logger.debug(saveData, 'changePlayRoom() saveData end')

          # DodontoF::PlayRoomとの違いに注意
          # changePlayRoomData()はchangeSaveData()と違い
          # iteratorからreturnを受け利用する
          saveData
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

    # ** DodontoF::PlayRoomと違いgetStateは存在しない **

    # DodontoF::PlayRoomと違い
    # 1. getPlayRoomStateLocalが呼び出し可能点になっている
    # 2. getPlayRoomStateLocalの引数の個数からして異なるし実装も全体的に違う
    # という点に注意
    def getPlayRoomStateLocal(roomNo, playRoomState, playRoomData)
      return playRoomState if( playRoomData.nil? or playRoomData.empty? )

      playRoomName = getPlayRoomName(playRoomData, roomNo)
      passwordLockState = (not playRoomData['playRoomChangedPassword'].nil?)
      canVisit = playRoomData['canVisit']
      gameType = playRoomData['gameType']

      timeStamp = @server.getRoomTimeStamp()

      timeString = ""
      unless( timeStamp.nil? )
        timeString = "#{timeStamp.strftime('%Y/%m/%d %H:%M:%S')}"
      end

      loginUsers = getLoginUserNames(roomNo)

      playRoomState['passwordLockState'] = passwordLockState
      playRoomState['playRoomName'] = playRoomName
      playRoomState['lastUpdateTime'] = timeString
      playRoomState['canVisit'] = canVisit
      playRoomState['gameType'] = gameType
      playRoomState['loginUsers'] = loginUsers

      return playRoomState
    end


    def remove(params)
      roomNumbers = params['roomNumbers']
      ignoreLoginUser = params['ignoreLoginUser']
      password = params['password']
      password ||= ""

      adminPassword = params["adminPassword"]
      @logger.debug(adminPassword, "removePlayRoom() adminPassword")
      if( @server.isMentenanceMode(adminPassword) )
        password = nil
      end

      removePlayRoomByParams(roomNumbers, ignoreLoginUser, password)
    end

    def removeOlds()
      roomNumberRange = (0 .. $saveDataMaxCount)
      accessTimes = getSaveDataLastAccessTimes( roomNumberRange )
      result = removeOldRoomFromAccessTimes(accessTimes)
      return result
    end

    def check(params)
      roomNumber = params['roomNumber']
      @logger.debug(roomNumber, 'roomNumber')

      @saveDirInfo.setSaveDataDirIndex(roomNumber)

      isMentenanceModeOn = false
      isWelcomeMessageOn = $isWelcomeMessageOn
      playRoomName = ''
      chatChannelNames = nil
      canUseExternalImage = false
      canVisit = false
      isPasswordLocked = false

      isRoomExist = @server.existRoom?
      @logger.debug(isRoomExist, "checkRoomStatus isRoomExist")

      if( isRoomExist )
        saveData = @server.getPlayRoomData()
        playRoomName = getPlayRoomName(saveData, roomNumber)
        changedPassword = saveData['playRoomChangedPassword']
        chatChannelNames = saveData['chatChannelNames']
        canUseExternalImage = saveData['canUseExternalImage']
        canVisit = saveData['canVisit']
        unless( changedPassword.nil? )
          isPasswordLocked = true
        end
      end

      adminPassword = params["adminPassword"]
      if( @server.isMentenanceMode(adminPassword) )
        isPasswordLocked = false
        isWelcomeMessageOn = false
        isMentenanceModeOn = true
        canVisit = false
      end

      @logger.debug("isPasswordLocked", isPasswordLocked);

      result = {
        'isRoomExist' => isRoomExist,
        'roomName' => playRoomName,
        'roomNumber' => roomNumber,
        'chatChannelNames' => chatChannelNames,
        'canUseExternalImage' => canUseExternalImage,
        'canVisit' => canVisit,
        'isPasswordLocked' => isPasswordLocked,
        'isMentenanceModeOn' => isMentenanceModeOn,
        'isWelcomeMessageOn' => isWelcomeMessageOn,
      }

      @logger.debug(result, "checkRoomStatus End result")

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

    # ** DodontoF::PlayRoomと違って、getSaveDataLastAccessTimeの依存性がまだ外に出ているので後回しにした **

    def removeOldRoomFromAccessTimes(accessTimes)
      @logger.debug("removeOldRoom Begin")
      if( $removeOldPlayRoomLimitDays <= 0 )
        return accessTimes
      end

      @logger.debug(accessTimes, "accessTimes")

      roomNumbers = getDeleteTargetRoomNumbers(accessTimes)

      ignoreLoginUser = true
      password = nil
      result = removePlayRoomByParams(roomNumbers, ignoreLoginUser, password)
      @logger.debug(result, "removePlayRoomByParams result")

      return result
    end

    # DodontoF::PlayRoomとはisForceパラメタの存在に違いがあるので注意
    def removePlayRoomByParams(roomNumbers, ignoreLoginUser, password)
      @logger.debug(ignoreLoginUser, 'removePlayRoomByParams Begin ignoreLoginUser')

      deletedRoomNumbers = []
      errorMessages = []
      passwordRoomNumbers = []
      askDeleteRoomNumbers = []

      roomNumbers.each do |roomNumber|
        roomNumber = roomNumber.to_i
        @logger.debug(roomNumber, 'roomNumber')

        # DodontoF::PlayRoomとはisForceパラメタの存在に違いがあるので注意
        resultText = checkRemovePlayRoom(roomNumber, ignoreLoginUser, password)
        @logger.debug(resultText, "checkRemovePlayRoom resultText")

        case resultText
        when "OK"
          removePlayRoomData(roomNumber)
          deletedRoomNumbers << roomNumber
        when "password"
          passwordRoomNumbers << roomNumber
        when "userExist"
          askDeleteRoomNumbers << roomNumber
        else
          errorMessages << resultText
        end
      end

      result = {
        "deletedRoomNumbers" => deletedRoomNumbers,
        "askDeleteRoomNumbers" => askDeleteRoomNumbers,
        "passwordRoomNumbers" => passwordRoomNumbers,
        "errorMessages" => errorMessages,
      }
      @logger.debug(result, 'result')

      return result
    end

    def removePlayRoomData(roomNumber)
      removeLocalImageTags(roomNumber)
      @saveDirInfo.removeSaveDir(roomNumber)
      removeLocalSpaceDir(roomNumber)
    end

    def removeLocalImageTags(roomNumber)
      tagInfos = @saveDirInfo.getImageTags(roomNumber)
      @saveDirInfo.deleteImages(tagInfos.keys)
    end

    def removeLocalSpaceDir(roomNumber)
      dir = @server.getRoomLocalSpaceDirNameByRoomNo(roomNumber)
      DodontoF::Utils.rmdir(dir)
    end

    # DodontoF::PlayRoomとはisForceパラメタの存在が違うので注意
    def checkRemovePlayRoom(roomNumber, ignoreLoginUser, password)
      roomNumberRange = (roomNumber..roomNumber)
      @logger.debug(roomNumberRange, "checkRemovePlayRoom roomNumberRange")

      unless( ignoreLoginUser )
        userNames = getLoginUserNames(roomNumber)
        userCount = userNames.size
        @logger.debug(userCount, "checkRemovePlayRoom userCount");

        if( userCount > 0 )
          return "userExist"
        end
      end

      if( not password.nil? )
        if( not checkPassword(roomNumber, password) )
          return "password"
        end
      end

      if( $unremovablePlayRoomNumbers.include?(roomNumber) )
        return "unremovablePlayRoomNumber"
      end

      lastAccessTimes = getSaveDataLastAccessTimes( roomNumberRange )
      lastAccessTime = lastAccessTimes[roomNumber]
      # DodontoF::PlayRoomでは、ここで
      # lastAccessTime ||= 0
      # しているが、こちらには無い点に注意
      @logger.debug(lastAccessTime, "lastAccessTime")

      # DodontoF::PlayRoomでは、ここで
      # lastAccessTime = 0 if isForce
      # により強制的に時間経過を生じさせ処理している

      # 上記のlastAccessTime ||=0が無い代わりに
      # 以下のように陽にnil?の場合は削除しない対応で処理している点に注意
      # DodontoF::PlayRoomでは0になるので自然と
      # spendTimes < $deletablePassedSeconds が成り立つという扱い
      # (しかしそれはバグだと思われる...どちらが正しいとするか。)
      # TODO: 共通化する
      unless( lastAccessTime.nil? )
        now = Time.now
        spendTimes = now - lastAccessTime
        @logger.debug(spendTimes, "spendTimes")
        @logger.debug(spendTimes / 60 / 60, "spendTimes / 60 / 60")
        if( spendTimes < $deletablePassedSeconds )
          return "プレイルームNo.#{roomNumber}の最終更新時刻から#{$deletablePassedSeconds}秒が経過していないため削除できません"
        end
      end

      return "OK"
    end

    # アクセス中のユーザ名をすべて取得する
    # 単純に使えるプロパティメソッドなのでpublicにするべきかもしれないが
    # いったん利用者がないことを考えてprivateにしている
    #
    # 実装がDodontoF::PlayRoomとまったく異なるので注意
    def getLoginUserNames(roomNo)
      userNames = []

      unless( @server.existRoom?(roomNo) )
        return userNames
      end

      @server.deleteUserInfo(roomNo)

      users = @server.getAllUsersData(roomNo)
      userNames = users.collect{|i| i['userNames']}

      @logger.debug(userNames, "getLoginUserNames userNames")
      return userNames
    end

    # 実装がDodontoF::PlayRoomと異なるので注意
    def checkPassword(roomNumber, password)
      return true unless( $isPasswordNeedFroDeletePlayRoom )

      @saveDirInfo.setSaveDataDirIndex(roomNumber)

      return true unless( @server.existRoom? )

      matched = false

      saveData = @server.getPlayRoomData()
      changedPassword = saveData['playRoomChangedPassword']
      matched = DodontoF::Utils.isPasswordMatch?(password, changedPassword)

      return matched
    end

    def getSaveDataLastAccessTimes( roomNumberRange )
      @logger.debug(roomNumberRange, "getSaveDataLastAccessTimes roomNumberRange")

      result = {}

      roomNumberRange.each do |roomNo|
        # TODO: これ多分ネクストキーロックが効いて酷いのでは…。=でよさそうなので直す
        where = {"roomNo >= ? " => roomNo }
        time = @server.getRoomTimeStamp(where)

        result[roomNo] = time
      end

      @logger.debug(result, "getSaveDataLastAccessTimes result")

      return result
    end

    def getDeleteTargetRoomNumbers(accessTimes)
      @logger.debug(accessTimes, "getDeleteTargetRoomNumbers accessTimes")

      roomNumbers = []

      accessTimes.each do |index, time|
        @logger.debug(index, "index")
        @logger.debug(time, "time")

        next if( time.nil? )

        timeDiffSeconds = (Time.now - time)
        @logger.debug(timeDiffSeconds, "timeDiffSeconds")

        limitSeconds = $removeOldPlayRoomLimitDays * 24 * 60 * 60
        @logger.debug(limitSeconds, "limitSeconds")

        if( timeDiffSeconds > limitSeconds )
          @logger.debug( index, "roomNumbers added index")
          roomNumbers << index
        end
      end

      @logger.debug(roomNumbers, "roomNumbers")
      return roomNumbers
    end

    def getPlayRoomName(saveData, index)
      playRoomName = saveData['playRoomName']
      playRoomName ||= "プレイルームNo.#{index}"
      return playRoomName
    end
  end
end

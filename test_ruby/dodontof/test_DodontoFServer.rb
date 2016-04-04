#--*-coding:utf-8-*--
$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path( '../..', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'

# テスト用のコンフィグファイルをDodontoFServerに読みこませる
$isTestMode = true
require 'DodontoFServer.rb'
require 'server_test_impl.rb'

class DodontoFServerTest < Test::Unit::TestCase
  include DodontoFServerTestImpl

  def getTargetDodontoFServer
    DodontoFServer
  end

  # ------------------------ room系コマンドテスト

  def create_mock_playroom(name = 'testroom', index = -1)
    params = {
      'cmd' => 'createPlayRoom',
      'params' => {
        'createPassword' => '',
        'playRoomName' => name,
        'playRoomPassword' => '',
        'chatChannelNames' => '',
        'canUseExternalImage' => '',
        'canVisit' => '',
        'playRoomIndex' => index,
        'viewStates' => {}
      }
    }
    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    server.getResponse
  end

  # 'createPlayRoom' => :hasReturn,
  def test_createPlayRoom
    expected = "{\"resultText\":\"OK\",\"playRoomIndex\":1}"

    result = create_mock_playroom
    assert_equal expected, result
  end

  # 'getPlayRoomStates' => :hasReturn,
  def test_getPlayRoomState
    params = {
      'cmd' => 'getPlayRoomStates',
      'params' => {
        'minRoom' => 0,
        'maxRoom' => 3,
      }
    }

    create_mock_playroom('TESTROOM_ALPHA', 1)
    create_mock_playroom('TESTROOM_BETA', 5)
    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse

    # 必要なキーは帰ってきてますよね？
    assert_match /index/, result
    assert_match /minRoom/, result
    assert_match /maxRoom/, result
    assert_match /gameType/, result
    assert_match /playRoomStates/, result
    assert_match /playRoomName/, result
    assert_match /lastUpdateTime/, result
    assert_match /passwordLockState/, result
    assert_match /loginUsers/, result
    assert_match /canVisit/, result

    # TESTROOM_ALPHAはリザルトに入ってますよね？
    assert_match /TESTROOM_ALPHA/, result
    # TESTROOM_BETAはリザルトに入って*ません*よね？
    assert !(/TESTROOM_BETA/ =~ result)
  end

  # 'checkRoomStatus' => :hasReturn,
  def test_checkRoomStatus
    params = {
      'cmd' => 'checkRoomStatus',
      'params' => {
        'roomNumber' => 1
      }
    }

    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse
    assert_match /isRoomExist/, result
    assert_match /roomName/, result
    assert_match /roomNumber/, result
    assert_match /chatChannelNames/, result
    assert_match /canUseExternalImage/, result
    assert_match /canVisit/, result
    assert_match /isPasswordLocked/, result
    assert_match /isMentenanceModeOn/, result
    assert_match /isWelcomeMessageOn/, result
  end

  # 'changePlayRoom' => :hasReturn,
  def test_changePlayRoom
    params = {
      'cmd' => 'changePlayRoom',
      'room' => 1,
      'params' => {
        'playRoomName' => 'TESTROOM_CHANGED',
        'playRoomPassword' => '',
        'chatChannelNames' => '',
        'canUseExternalImage' => '',
        'canVisit' => '',
        'playRoomIndex' => 1,
        'viewStates' => {}
      }
    }

    create_mock_playroom('TESTROOM', 1)
    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse
    assert_match /resultText/, result
    assert_match /OK/, result

    state = server.getPlayRoomState(1)
    assert_equal 'TESTROOM_CHANGED', state['playRoomName']
  end

  # 'removePlayRoom' => :hasReturn,
  def test_removePlayRoom
    params = {
      'cmd' => 'removePlayRoom',
      'params' => {
        'roomNumbers' => [1, 2]
      }
    }

    create_mock_playroom('TESTROOM2', 2) # テスト中作って10秒立たないからこれは消せないはず

    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse
    parsed = JsonParser.new.parse(result)

    # ほしいレスポンスキーは帰ってくるのか
    assert parsed.has_key? 'deletedRoomNumbers'
    assert parsed.has_key? 'askDeleteRoomNumbers'
    assert parsed.has_key? 'passwordRoomNumbers'
    assert parsed.has_key? 'errorMessages'

    # 狙い通りか
    assert_equal [1], parsed['deletedRoomNumbers']
    assert_equal [], parsed['askDeleteRoomNumbers']
    assert_equal [], parsed['passwordRoomNumbers']
    assert_match /10秒/, parsed['errorMessages'][0]

    state = server.getPlayRoomState(2)
    assert_match /TESTROOM2/, state['playRoomName']
  end

  class SaveDirInfoForRemoveOldPlayRoom < SaveDirInfo
    def getSaveDataLastAccessTimes(fileNames, roomNumberRange)
      # 強制的に2000年ごろが最終アクセスの古いセーブだったということにする
      result = super(fileNames, roomNumberRange)
      result[2] = Time.mktime 2000, 1, 1, 00, 00, 00
      result
    end
  end

  # 'removeOldPlayRoom' => :hasReturn,
  def test_removeOldPlayRoom
    params = {
      'cmd' => 'removeOldPlayRoom',
      'params' => { }
    }

    create_mock_playroom('TESTROOM1', 1)
    create_mock_playroom('TESTROOM2', 2)

    savedirs = SaveDirInfoForRemoveOldPlayRoom.new
    server = getDodontoFServerForTest.new savedirs, params
    result = server.getResponse
    parsed = JsonParser.new.parse(result)

    # ほしいレスポンスキーは帰ってくるのか
    assert parsed.has_key? 'deletedRoomNumbers'
    assert parsed.has_key? 'askDeleteRoomNumbers'
    assert parsed.has_key? 'passwordRoomNumbers'
    assert parsed.has_key? 'errorMessages'

    # 内容は正しいか
    assert_equal [2], parsed['deletedRoomNumbers']
    assert_equal [], parsed['askDeleteRoomNumbers']
    assert_equal [], parsed['passwordRoomNumbers']
    assert_equal [], parsed['errorMessages']
  end
end

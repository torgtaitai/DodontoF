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
    result = create_mock_playroom
    parsed = JsonParser.new.parse(result)

    assert parsed.has_key? 'resultText'
    assert parsed.has_key? 'playRoomIndex'

    assert_equal 'OK', parsed['resultText']
    assert_equal 1, parsed['playRoomIndex']
  end

  # 'getPlayRoomStates' => :hasReturn,
  def test_getPlayRoomStates
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

  # ------------------------ bot系コマンドテスト

 def test_getDiceBotInfos
    params = {
      'cmd' => 'getDiceBotInfos',
      'params' => { }
    }

    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse
    parsed = JsonParser.new.parse(result)
    assert 1 <= parsed.size
    parsed.each do |item|
      assert item.has_key? 'name'
      assert item.has_key? 'gameType'
      assert item.has_key? 'prefixs'
      assert item.has_key? 'info'
    end
 end

  def test_getBotTableInfos
    params = {
      'cmd' => 'getBotTableInfos',
      'params' => { }
    }

    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse
    parsed = JsonParser.new.parse(result)

    assert parsed.has_key? 'resultText'
    assert parsed.has_key? 'tableInfos'
  end

  def create_mock_bot_table(title)
    params = {
      'cmd' => 'addBotTable',
      'params' => {
        'gameType' => 'DiceBot',
        'command' => '1d6',
        'dice' => '',
        'title' => title,
        'table' => []
      }
    }
    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    server.getResponse
  end

  def test_addBotTable
    result = create_mock_bot_table('TEST')
    parsed = JsonParser.new.parse(result)

    assert parsed.has_key? 'resultText'
    assert parsed.has_key? 'tableInfos'

    item = parsed['tableInfos'][0]

    assert item.has_key? 'fileName'
    assert item.has_key? 'gameType'
    assert item.has_key? 'command'
    assert item.has_key? 'dice'
    assert item.has_key? 'title'
    assert item.has_key? 'table'
  end

  def test_changeBotTable
    params = {
      'cmd' => 'changeBotTable',
      'params' => {
        # 変えるときは元の値をここで指定できる
        # 変えない時も指定しても動く
        'originalGameType' => 'DiceBot',
        'originalCommand' => '1d6',

        'gameType' => 'DiceBot',
        'command' => '1d6',
        # dice, titleは指定しなくても動いちゃうので
        # この辺はもしかしたらエラーチェックを入れたほうがいいのかもしれない
        'dice' => 'DICE_TEST',
        'title' => 'TEST_CHANGED',
        # tableは指定しないとnilで落ちる。
        # dice, titleと非対称な感じなのでどちらかに合わせたいところだが...。
        'table' => [
          '1:TABLETEST_1',
          '2:TABLETEST_2'
        ],
      }
    }

    create_mock_bot_table('TEST')

    server = getDodontoFServerForTest.new savedirs = SaveDirInfo.new, params
    result = server.getResponse
    parsed = JsonParser.new.parse(result)

    assert parsed.has_key? 'resultText'
    assert parsed.has_key? 'tableInfos'

    item = parsed['tableInfos'][0]
    assert item.has_key? 'fileName'
    assert item.has_key? 'gameType'
    assert item.has_key? 'command'
    assert item.has_key? 'dice'
    assert item.has_key? 'title'
    assert item.has_key? 'table'

    # prefixにマッチする名前になってる
    assert_match /diceBotTable_/, item['fileName']
    # gameTypeにマッチする名前になってる
    assert_match /DiceBot/, item['fileName']
    # commandにマッチする名前になってる
    assert_match /1d6/, item['fileName']

    assert_equal '1d6', item['command']
    assert_equal 'DICE_TEST', item['dice']
    assert_equal 'TEST_CHANGED', item['title']

    table = item['table']
    assert_equal 2, table.size
    assert_equal 1, table[0][0]
    assert_equal 2, table[1][0]
    assert_match /TABLETEST_/, table[0][1]
    assert_match /TABLETEST_/, table[1][1]
  end

  def test_removeBotTable
    params = {
      'cmd' => 'removeBotTable',
      'params' => {
        'gameType' => 'DiceBot',
        'command' => '1d6',
      }
    }

    create_mock_bot_table('TEST')

    server = getDodontoFServerForTest.new SaveDirInfo.new, params
    result = server.getResponse
    parsed = JsonParser.new.parse(result)

    assert parsed.has_key? 'resultText'
    assert parsed.has_key? 'tableInfos'
    # 削除されて0件が返ってくるはず
    assert_equal 0, parsed['tableInfos'].size
  end
end

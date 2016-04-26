#--*-coding:utf-8-*--

$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('.', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'
require 'test/unit/assertions/assert_have_keys'

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

  def createMockPlayRoom(name = 'testroom', index = -1)
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
    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    server.getResponse
  end

  # 'createPlayRoom' => :hasReturn,
  def test_createPlayRoom
    result = createMockPlayRoom
    parsed = JsonParser.parse(result)

    assert_have_keys(parsed,
                     'resultText',
                     'playRoomIndex')

    assert_equal('OK', parsed['resultText'])
    assert_equal(1, parsed['playRoomIndex'])
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

    createMockPlayRoom('TESTROOM_ALPHA', 1)
    createMockPlayRoom('TESTROOM_BETA', 5)
    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    # 必要なキーは帰ってきてますよね？
    assert_have_keys(parsed,
                     'minRoom',
                     'maxRoom',
                     'playRoomStates')

    # 部屋のデータのテスト
    playRoomStates = parsed['playRoomStates']

    expectedKeysInPlayRoomState = [
      'passwordLockState',
      'index',
      'playRoomName',
      'lastUpdateTime',
      'canVisit',
      'gameType',
      'loginUsers',
    ]
    playRoomStates.each do |r|
      # ループごとにオブジェクトを作らないよう配列を渡す
      assert_have_keys(r, *expectedKeysInPlayRoomState)
    end

    playRoomNames = playRoomStates.map { |r| r['playRoomName'] }

    assert_equal(true, playRoomNames.include?('TESTROOM_ALPHA'))
    assert_equal(false, playRoomNames.include?('TESTROOM_BETA'))
  end

  # 'checkRoomStatus' => :hasReturn,
  def test_checkRoomStatus
    params = {
      'cmd' => 'checkRoomStatus',
      'params' => {
        'roomNumber' => 1
      }
    }

    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    assert_have_keys(parsed,
                     'isRoomExist',
                     'roomName',
                     'roomNumber',
                     'chatChannelNames',
                     'canUseExternalImage',
                     'canVisit',
                     'isPasswordLocked',
                     'isMentenanceModeOn',
                     'isWelcomeMessageOn')
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

    createMockPlayRoom('TESTROOM', 1)
    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    assert_equal({ 'resultText' => 'OK' }, parsed)

    state = server.getPlayRoomState(1)
    assert_equal('TESTROOM_CHANGED', state['playRoomName'])
  end

  # 'removePlayRoom' => :hasReturn,
  def test_removePlayRoom
    params = {
      'cmd' => 'removePlayRoom',
      'params' => {
        'roomNumbers' => [1, 2]
      }
    }

    createMockPlayRoom('TESTROOM2', 2) # テスト中作って10秒立たないからこれは消せないはず

    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    # ほしいレスポンスキーは帰ってくるのか
    assert_have_keys(parsed,
                     'deletedRoomNumbers',
                     'askDeleteRoomNumbers',
                     'passwordRoomNumbers',
                     'errorMessages')

    # 狙い通りか
    assert_equal([1], parsed['deletedRoomNumbers'])
    assert_equal([], parsed['askDeleteRoomNumbers'])
    assert_equal([], parsed['passwordRoomNumbers'])
    assert_match(/10秒/, parsed['errorMessages'][0])

    state = server.getPlayRoomState(2)
    assert_match(/TESTROOM2/, state['playRoomName'])
  end

  # test_removeOldPlayRoom 用の SaveDirInfo オブジェクトを返す
  def newSaveDirInfoForRemoveOldPlayRoom
    saveDirInfo = SaveDirInfo.new

    # 特異メソッドで書き換え、外部への影響をなくす
    def saveDirInfo.getSaveDataLastAccessTimes(fileNames, roomNumberRange)
      # 強制的に2000年ごろが最終アクセスの古いセーブだったということにする
      result = super(fileNames, roomNumberRange)
      result[2] = Time.mktime(2000, 1, 1, 0, 0, 0)
      result
    end

    saveDirInfo
  end
  private :newSaveDirInfoForRemoveOldPlayRoom

  # 'removeOldPlayRoom' => :hasReturn,
  def test_removeOldPlayRoom
    params = {
      'cmd' => 'removeOldPlayRoom',
      'params' => {}
    }

    createMockPlayRoom('TESTROOM1', 1)
    createMockPlayRoom('TESTROOM2', 2)

    server = getDodontoFServerForTest.new(
      newSaveDirInfoForRemoveOldPlayRoom, params
    )
    result = server.getResponse
    parsed = JsonParser.parse(result)

    # ほしいレスポンスキーは帰ってくるのか
    assert_have_keys(parsed,
                     'deletedRoomNumbers',
                     'askDeleteRoomNumbers',
                     'passwordRoomNumbers',
                     'errorMessages')

    # 内容は正しいか
    assert_equal([2], parsed['deletedRoomNumbers'])
    assert_equal([], parsed['askDeleteRoomNumbers'])
    assert_equal([], parsed['passwordRoomNumbers'])
    assert_equal([], parsed['errorMessages'])
  end

  # ------------------------ bot系コマンドテスト

 def test_getDiceBotInfos
    params = {
      'cmd' => 'getDiceBotInfos',
      'params' => {}
    }

    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)
    assert_operator(1, :<=,  parsed.size)

    expectedKeys = [
      'name',
      'gameType',
      'prefixs',
      'info'
    ]
    parsed.each do |item|
      # ループごとにオブジェクトを作らないよう配列を渡す
      assert_have_keys(item, *expectedKeys)
    end
 end

  def test_getBotTableInfos
    params = {
      'cmd' => 'getBotTableInfos',
      'params' => {}
    }

    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    assert_have_keys(parsed,
                     'resultText',
                     'tableInfos')
  end

  def createMockBotTable(title)
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
    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    server.getResponse
  end

  def test_addBotTable
    result = createMockBotTable('TEST')
    parsed = JsonParser.parse(result)

    assert_have_keys(parsed,
                     'resultText',
                     'tableInfos')

    item = parsed['tableInfos'][0]

    assert_have_keys(item,
                     'fileName',
                     'gameType',
                     'command',
                     'dice',
                     'title',
                     'table')
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

    createMockBotTable('TEST')

    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    assert_have_keys(parsed,
                     'resultText',
                     'tableInfos')

    item = parsed['tableInfos'][0]

    assert_have_keys(item,
                     'fileName',
                     'gameType',
                     'command',
                     'dice',
                     'title',
                     'table')

    assert_match(/diceBotTable_/, item['fileName'],
                 'prefix にマッチする名前になっている')
    assert_match(/DiceBot/, item['fileName'],
                 'gameType にマッチする名前になっている')
    assert_match(/1d6/, item['fileName'],
                 'command にマッチする名前になっている')

    assert_equal('1d6', item['command'])
    assert_equal('DICE_TEST', item['dice'])
    assert_equal('TEST_CHANGED', item['title'])

    table = item['table']
    assert_equal(2, table.size)
    assert_equal(1, table[0][0])
    assert_equal(2, table[1][0])
    assert_match(/TABLETEST_/, table[0][1])
    assert_match(/TABLETEST_/, table[1][1])
  end

  def test_removeBotTable
    params = {
      'cmd' => 'removeBotTable',
      'params' => {
        'gameType' => 'DiceBot',
        'command' => '1d6',
      }
    }

    createMockBotTable('TEST')

    server = getDodontoFServerForTest.new(SaveDirInfo.new, params)
    result = server.getResponse
    parsed = JsonParser.parse(result)

    assert_have_keys(parsed,
                     'resultText',
                     'tableInfos')

    assert_equal(0, parsed['tableInfos'].size,
                 '削除されて0件が返ってくるはず')
  end
end

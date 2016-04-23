#--*-coding:utf-8-*--

$LOAD_PATH.unshift(File.expand_path('../..', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path( '..', File.dirname(__FILE__)))

require 'stringio'
require 'test_helper'

require 'test/unit'

# テスト用のコンフィグファイルをDodontoFServerに読みこませる
$isTestMode = true
require 'DodontoFServer.rb'

require 'msgpack/msgpackPure'
require 'json/jsonParser'

class CGIRequestTest < Test::Unit::TestCase
  def setup
    # 環境変数の記録用
    @environ = {}
    # 標準入力の記録用
    @prevStdin = $stdin
    # 標準出力の記録用
    @prevStdout = $stdout
  end

  def teardown
    # 環境変数、標準入力、標準出力を元に戻す
    ENV.update(@environ)
    $stdin = @prevStdin
    $stdout = @prevStdout
  end

  # コマンドを指定せずに GET した場合
  def test_CGI_GET_noCommand
    updateEnv('REQUEST_METHOD' => 'GET',
              'QUERY_STRING' => '')

    out = StringIO.new
    changeStdout(out)

    executeDodontoServerCgi

    pattern = /^#{Regexp.escape('["「どどんとふ」の動作環境は正常に起動しています。"]')}$/
    assert_match(pattern, out.string)
  end

  def test_CGI_GET_webif_getBusyInfo
    updateEnv('REQUEST_METHOD' => 'GET',
              'QUERY_STRING' => 'webif=getBusyInfo')

    out = StringIO.new
    changeStdout(out)

    executeDodontoServerCgi

    assert_match(/^\{"loginCount":\d+,"maxLoginCount":\d+,"version":".+?","result":"OK"\}$/,
                 out.string)
  end

  def test_CGI_POST_getPlayRoomStates
    # メッセージデータの準備
    paramObject = {
      'cmd' => 'getPlayRoomStates',
      'params' => {
        'minRoom' => 0,
        'maxRoom' => 3,
      }
    }
    messagePackedData = MessagePackPure.pack(paramObject)

    # 環境変数の更新
    updateEnv('REQUEST_METHOD' => 'POST',
              'CONTENT_TYPE' => 'application/x-msgpack',
              'CONTENT_LENGTH' => messagePackedData.bytesize.to_s)

    # 標準入力、標準出力の変更
    inIo = StringIO.new(messagePackedData)
    changeStdin(inIo)

    out = StringIO.new
    changeStdout(out)

    # サーバー実行
    executeDodontoServerCgi

    # 出力の変換
    out_tail = out.string.lines.last.chomp
    response = JsonParser.new.parse(out_tail)

    assert_equal(true, response.kind_of?(Hash))
  end

  private

  # 標準入力を記録してから変更する
  def changeStdin(stdin)
    @prevStdin = $stdin
    $stdin = stdin
  end

  # 標準出力を記録してから変更する
  def changeStdout(stdout)
    @prevStdout = $stdout
    $stdout = stdout
  end

  # 環境変数を記録してから更新する
  #
  # Ruby の CGI ライブラリのテストより流用
  # @see https://github.com/ruby/ruby/blob/3e92b635fb5422207b7bbdc924e292e51e21f040/test/cgi/update_env.rb
  def updateEnv(environ)
    environ.each do |key, val|
      @environ[key] = ENV[key] unless @environ.key?(key)
      ENV[key] = val
    end
  end
end

#--*-coding:utf-8-*--

require 'fileutils'

# 3種類あるサーバ実装を統一的に検査するためのテスト実装モジュール
# それぞれのサーバ用のテストケースでincludeして使います。
# 共通するテストはこのクラスの中で書いてしまってください。
# またどのサーバ実装を対象にするのかは
# getTargetDodontoFServerメソッドをオーバライドして
# クラス定数を返却しておくことで、こちらに伝えるようにしてください
# (内部的にDodontoFServer類をテストに乗せるためのモックオブジェクトを生成します)
module DodontoFServerTestImpl
  # テスト対象にするDodontoFServer
  # 利用者コードでinclude後にオーバライドしてください
  def getTargetDodontoFServer
    fail NotImplementedError, 'ServerTestimpl need override TargetDodontoFServer()'
  end

  # テスト用のモックオブジェクト
  # コンストラクション時にいい加減な物を渡してもエラーを抑止する
  # モック要件に応じて増やしたり継承したりして使う
  def getDodontoFServerForTest
    @dodontof_server_for_Test ||= Class.new(getTargetDodontoFServer) do
      attr_accessor :mock_raw_cgi_value

      def getRawCGIValue(key)
        @mock_raw_cgi_value ||= {}
        @mock_raw_cgi_value[key]
      end
    end
  end

  def setup
    FileUtils.mkdir_p $SAVE_DATA_DIR
    FileUtils.mkdir_p $imageUploadDir
    FileUtils.mkdir_p $replayDataUploadDir
    FileUtils.mkdir_p $saveDataTempDir
    FileUtils.mkdir_p $fileUploadDir
    FileUtils.cp_r 'saveData', File.join($SAVE_DATA_DIR, 'saveData')
  end

  def teardown
    FileUtils.rm_r '.temp'
  end

  def test_request_analyze
    instance = getDodontoFServerForTest.new SaveDirInfo.new, {'test' => 'ok'}
    assert_equal 'ok', instance.getRequestData('test'), 'ok'
  end

  def test_response
    instance = getDodontoFServerForTest.new SaveDirInfo.new, {'cmd' => ''}
    assert_match /「.+」の動作環境は正常に起動しています。/, instance.getResponse
  end
end

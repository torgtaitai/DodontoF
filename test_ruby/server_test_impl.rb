#--*-coding:utf-8-*--

require 'fileutils'

# 3種類あるサーバ実装を統一的に検査するためのテスト実装モジュール
# それぞれのサーバ用のテストからincludeして使います
# テスト中でインスタンス化するのに使うため
# このrbファイルをrequireする前に
# TARGET_DODONTF_SERVER_CLASSという定数を、
# 対象のサーバクラスを代入して初期化してください
# 例: TARGET_DODONTF_SERVER_CLASS = DodontoFServer
module ServerTestImpl
  # テスト用のモックオブジェクト
  # コンストラクション時にいい加減な物を渡してもエラーを抑止する
  # モック要件に応じて増やしたり継承したりして使う
  class DodontoFServerForTest < TARGET_DODONTF_SERVER_CLASS
    attr_accessor :mock_raw_cgi_value
    def getRawCGIValue; @mock_raw_cgi_value; end
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
    instance = DodontoFServerForTest.new SaveDirInfo.new, {'test' => 'ok'}
    assert_equal 'ok', instance.getRequestData('test'), 'ok'
  end

  def test_response
    instance = DodontoFServerForTest.new SaveDirInfo.new, {'cmd' => ''}
    assert_match /「.+」の動作環境は正常に起動しています。/, instance.getResponse
  end
end

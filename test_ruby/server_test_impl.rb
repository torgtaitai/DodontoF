# -*- coding: utf-8 -*-

require 'fileutils'

# 3種類あるサーバ実装を統一的に検査するためのテスト実装モジュール
# それぞれのサーバ用のテストケースでincludeして使います。
# 共通するテストはこのクラスの中で書いてしまってください。
# またどのサーバ実装を対象にするのかは
# getTargetDodontoFServerメソッドをオーバライドして
# クラス定数を返却しておくことで、こちらに伝えるようにしてください
# (内部的にDodontoFServer類をテストに乗せるためのモックオブジェクトを生成します)
module DodontoFServerTestImpl

  def setup
    # DodontoFリポジトリの中にある、セットアップ時に使う
    # $imageUploadDir の初期状態を保存したディレクトリ
    initial_image_upload_dir = 'imageUploadSpace'

    FileUtils.mkdir_p $SAVE_DATA_DIR
    FileUtils.cp_r initial_image_upload_dir, $imageUploadDir
    FileUtils.mkdir_p $replayDataUploadDir
    FileUtils.mkdir_p $saveDataTempDir
    FileUtils.mkdir_p $fileUploadDir
    FileUtils.cp_r 'saveData', File.join($SAVE_DATA_DIR, 'saveData')
  end

  def teardown
    FileUtils.rm_r('.temp')
  end

  def test_response
    instance = getDodontoFServerForTest.new(SaveDirInfo.new, { 'cmd' => '' })
    assert_match(/「.+」の動作環境は正常に起動しています。/, instance.getResponse)
  end

  private

  # テスト対象にするDodontoFServer
  # 利用者コードでinclude後にオーバライドしてください
  def getTargetDodontoFServer
    fail NotImplementedError, 'getTargetDodontoFServer() must be overridden'
  end

  # テスト用のモックオブジェクト
  # コンストラクション時にいい加減な物を渡してもエラーを抑止する
  # モック要件に応じて増やしたり継承したりして使う
  def getDodontoFServerForTest
    @dodontofServerForTest ||= Class.new(getTargetDodontoFServer) do
      attr_accessor :mockRawCgiValue

      def getRawCGIValue(key)
        @mockRawCgiValue ||= {}
        @mockRawCgiValue[key]
      end
    end
  end
end

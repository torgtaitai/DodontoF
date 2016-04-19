#--*-coding:utf-8-*--

$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'

require 'dodontof/utils'

require 'fileutils'

module DodontoF
  # ユーティリティメソッドのテスト
  class UtilsTest < Test::Unit::TestCase
    # getJsonString は JSON 文字列を返す
    def test_getJsonStringShouldReturnJsonString
      assert_equal('[1,2,3]',
                   Utils.getJsonString([1, 2, 3]),
                   '配列を渡した場合')
      assert_equal('{"a":1}',
                   Utils.getJsonString({ 'a' => 1 }),
                   'ハッシュを渡した場合')
    end

    # getObjectFromJsonString は JSON 文字列から変換されたオブジェクトを返す
    def test_getObjectFromJsonStringShouldReturnObject
      assert_equal([1, 2, 3],
                   Utils.getObjectFromJsonString('[1,2,3]'),
                   '配列を表す JSON 文字列を渡した場合')
      assert_equal({ 'a' => 1 },
                   Utils.getObjectFromJsonString('{"a":1}'),
                   'オブジェクトを表す JSON 文字列を渡した場合')
    end

    # makeDir は 適当なディレクトリをその場に「存在する状態」にする
    # この時他にファイルがあれば上書きする
    def test_makeDir
      # そういうディレクトリを構成しておく
      FileUtils.mkdir_p './.temp'
      open('./.temp/makeDirTest', 'w') { |f| f.puts 'test' }

      Utils.makeDir('.temp/makeDirTest')
      assert File.exists? './.temp/makeDirTest'
      assert File.directory? './.temp/makeDirTest'
    end

    # rmdir は指定したディレクトリを削除する
    def test_rmdir
      # そういうディレクトリを構成しておく
      FileUtils.mkdir_p './.temp/test'
      assert File.exists? './.temp/test'

      Utils.rmdir('.temp/test')
      assert File.exists? './.temp/'
      assert !(File.exists? './.temp/test')
    end

    # getLanguageKeyはキー値に対して何らかのラッピングを施す
    # (ラップキーが適切についているか？というのを検査するのは
    # ただのChangeDetectorになるので避けた)
    def test_getLanguageKey
      # LanguageKeyはキー値を何らかの形でラップしたものであるはずだから
      # 少なくとも指定したキーとマッチする部分列があるはずだ
      assert_match /test/, Utils.getLanguageKey('test')
    end
  end
end

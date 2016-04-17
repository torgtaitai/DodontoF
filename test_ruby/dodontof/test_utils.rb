#--*-coding:utf-8-*--

$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'

require 'dodontof/utils'

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
  end
end

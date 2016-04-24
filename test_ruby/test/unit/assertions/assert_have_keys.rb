#--*-coding:utf-8-*--

require 'test/unit'

module Test::Unit::Assertions
  # +hash+ のキーに +keys+ がすべて存在することを表明する
  def assert_have_keys(hash, *keys)
    keys.each do |k|
      assert_equal(true, hash.has_key?(k))
    end
  end
end

#--*-coding:utf-8-*--
$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path( '../..', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'

# テスト用のコンフィグファイルをDodontoFServerに読みこませる
$isTestMode = true
require 'DodontoFServerMySqlKai.rb'

TARGET_DODONTF_SERVER_CLASS = DodontoFServer
require 'server_test_impl.rb'

class DodontoFServerMySqlKaiTest < Test::Unit::TestCase
  include ServerTestImpl
end

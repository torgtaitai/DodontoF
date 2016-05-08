#--*-coding:utf-8-*--
$LOAD_PATH.unshift(File.expand_path('.', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path( '../..', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'

# テスト用のコンフィグファイルをDodontoFServerに読みこませる
$isTestMode = true
require 'DodontoFServerMySql.rb'
require 'server_test_impl.rb'

class DodontoFServer_MySqlTest < Test::Unit::TestCase
  include DodontoFServerTestImpl
  def getTargetDodontoFServer
    DodontoFServer_MySql
  end
end

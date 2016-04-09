#--*-coding:utf-8-*--
$LOAD_PATH << File.join(File.dirname(__FILE__), '..')
$LOAD_PATH << File.dirname(__FILE__)

require 'test/unit'

# テスト用のコンフィグファイルをDodontoFServerに読みこませる
$isTestMode = true
require 'DodontoFServer.rb'

TARGET_DODONTF_SERVER_CLASS = DodontoFServer
require 'ServerTestImpl.rb'

class DodontoFServerTest < Test::Unit::TestCase
  include ServerTestImpl
end

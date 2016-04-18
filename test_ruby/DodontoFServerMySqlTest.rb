#--*-coding:utf-8-*--
$LOAD_PATH << File.join(File.dirname(__FILE__), '..')
$LOAD_PATH << File.dirname(__FILE__)

require 'test/unit'

# テスト用のコンフィグファイルをDodontoFServerに読みこませる
$isTestMode = true
require 'DodontoFServerMySql.rb'

TARGET_DODONTF_SERVER_CLASS = DodontoFServer_MySql
require 'ServerTestImpl.rb'

class DodontoFServer_MySqlTest < Test::Unit::TestCase
  include ServerTestImpl
end

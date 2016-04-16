#--*-coding:utf-8-*--

$LOAD_PATH.unshift(File.expand_path('.', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'
require 'logger'
require 'kconv'
require 'stringio'

require 'loggingFunction'

# ログ関数のテスト
class LoggingFunctionTest < Test::Unit::TestCase
  def setup
    $logFileMaxCount = 0
    $logFileMaxSize = 4096
  end

  # デバッグモードでは logging は出力を行う
  def test_logging_should_output_if_debug
    out = StringIO.new
    init_logger_with_debug_level(out)

    logging('debug')

    assert_match(/^D,/, out.string)
  end

  # 非デバッグモードでは logging は出力しない
  def test_logging_should_not_output_unless_debug
    out = StringIO.new
    init_logger_with_error_level(out)

    logging('debug')

    assert(out.string.empty?)
  end

  # デバッグモードでは loggingForce は出力を行う
  def test_loggingForce_should_output_if_debug
    out = StringIO.new
    init_logger_with_error_level(out)

    loggingForce('error')

    assert_match(/^E,/, out.string)
  end

  # 非デバッグモードでも loggingForce は出力を行う
  def test_loggingForce_should_output_unless_debug
    out = StringIO.new
    init_logger_with_error_level(out)

    loggingForce('error')

    assert_match(/^E,/, out.string)
  end

  # String のログの形式が正しい
  def test_format_of_string_log_should_be_correct
    out = StringIO.new
    init_logger_with_debug_level(out)

    logging('getBusyInfo', 'commandName')

    assert_match(/commandName:getBusyInfo/, out.string)
  end

  # Array のログの形式が正しい
  def test_format_of_array_log_should_be_correct
    out = StringIO.new
    init_logger_with_debug_level(out)

    logging('getBusyInfo', 'commandName')

    array = [:a, :b, :c]
    logging(array, 'array', 'symbol')

    assert_match(/array,symbol:\[:a, :b, :c\]/, out.string)
  end

  private

  # デバッグモード用ロガーを準備する
  def init_logger_with_debug_level(io)
    $log = nil
    $debug = true
    $logFileName = io

    initLog
  end

  # 非デバッグモード用ロガーを準備する
  def init_logger_with_error_level(io)
    $log = nil
    $debug = false
    $logFileName = io

    initLog
  end
end

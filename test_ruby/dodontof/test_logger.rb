#--*-coding:utf-8-*--

$LOAD_PATH.unshift(File.expand_path('..', File.dirname(__FILE__)))

require 'test_helper'

require 'test/unit'
require 'stringio'
require 'logger'

require 'dodontof/logger'

module DodontoF
  # どどんとふ共通ロガーのテスト
  class LoggerTest < Test::Unit::TestCase
    def setup
      $logFileName = STDOUT
      $logFileMaxCount = 0
      $logFileMaxSize = 4096

      @logger = Logger.instance
    end

    # mod_ruby 使用時はログレベルが FATAL になる
    def test_level_should_be_fatal_on_mod_ruby
      @logger.update_level(true, true)

      assert_equal(::Logger::FATAL, @logger.level)
    end

    # デバッグモードではログレベルが DEBUG になる
    def test_level_should_be_debug_if_debug
      @logger.update_level(false, true)

      assert_equal(::Logger::DEBUG, @logger.level)
    end

    # 非デバッグモードではログレベルが ERROR になる
    def test_level_should_be_error_unless_debug
      @logger.update_level(false, false)

      assert_equal(::Logger::ERROR, @logger.level)
    end

    # デバッグモードでは debug は出力を行う
    def test_debug_should_output_if_debug
      out = StringIO.new
      init_logger_with_debug_level(out)

      @logger.debug('debug')

      assert_match(/^D,/, out.string)
    end

    # 非デバッグモードでは debug は出力しない
    def test_debug_should_not_output_unless_debug
      out = StringIO.new
      init_logger_with_error_level(out)

      @logger.debug('debug')

      assert(out.string.empty?)
    end

    # デバッグモードでは error は出力を行う
    def test_error_should_output_if_debug
      out = StringIO.new
      init_logger_with_error_level(out)

      @logger.error('error')

      assert_match(/^E,/, out.string)
    end

    # 非デバッグモードでも error は出力を行う
    def test_error_should_output_unless_debug
      out = StringIO.new
      init_logger_with_error_level(out)

      @logger.error('error')

      assert_match(/^E,/, out.string)
    end

    # String のログの形式が正しい
    def test_format_of_string_log_should_be_correct
      out = StringIO.new
      init_logger_with_debug_level(out)

      @logger.debug('getBusyInfo', 'commandName')

      assert_match(/commandName:getBusyInfo/, out.string)
    end

    # Array のログの形式が正しい
    def test_format_of_array_log_should_be_correct
      out = StringIO.new
      init_logger_with_debug_level(out)

      @logger.debug('getBusyInfo', 'commandName')

      array = [:a, :b, :c]
      @logger.debug(array, 'array', 'symbol')

      assert_match(/array,symbol:\[:a, :b, :c\]/, out.string)
    end

    private

    # デバッグモード用ロガーを準備する
    def init_logger_with_debug_level(io)
      @logger.
        reset(io).
        update_level(false, true)
    end

    # 非デバッグモード用ロガーを準備する
    def init_logger_with_error_level(io)
      @logger.
        reset(io).
        update_level(false, false)
    end
  end
end

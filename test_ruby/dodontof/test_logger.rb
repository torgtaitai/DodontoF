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
    def test_levelShouldBeFatalOnModRuby
      @logger.updateLevel(true, true)

      assert_equal(::Logger::FATAL, @logger.level)
    end

    # デバッグモードではログレベルが DEBUG になる
    def test_levelShouldBeDebugIfDebug
      @logger.updateLevel(false, true)

      assert_equal(::Logger::DEBUG, @logger.level)
    end

    # 非デバッグモードではログレベルが ERROR になる
    def test_levelShouldBeErrorUnlessDebug
      @logger.updateLevel(false, false)

      assert_equal(::Logger::ERROR, @logger.level)
    end

    # デバッグモードでは debug は出力を行う
    def test_debugShouldOutputIfDebug
      out = StringIO.new
      initLoggerWithDebugLevel(out)

      @logger.debug('debug')

      assert_match(/^D,/, out.string)
    end

    # 非デバッグモードでは debug は出力しない
    def test_debugShouldNotOutputUnlessDebug
      out = StringIO.new
      initLoggerWithErrorLevel(out)

      @logger.debug('debug')

      assert(out.string.empty?)
    end

    # デバッグモードでは error は出力を行う
    def test_ErrorShouldOutputIfDebug
      out = StringIO.new
      initLoggerWithErrorLevel(out)

      @logger.error('error')

      assert_match(/^E,/, out.string)
    end

    # 非デバッグモードでも error は出力を行う
    def test_errorShouldOutputUnlessDebug
      out = StringIO.new
      initLoggerWithErrorLevel(out)

      @logger.error('error')

      assert_match(/^E,/, out.string)
    end

    # String のログの形式が正しい
    def test_formatOfStringLogShouldBeCorrect
      out = StringIO.new
      initLoggerWithDebugLevel(out)

      @logger.debug('getBusyInfo', 'commandName')

      assert_match(/commandName:getBusyInfo/, out.string)
    end

    # Array のログの形式が正しい
    def test_formatOfArrayLogShouldBeCorrect
      out = StringIO.new
      initLoggerWithDebugLevel(out)

      @logger.debug('getBusyInfo', 'commandName')

      array = [:a, :b, :c]
      @logger.debug(array, 'array', 'symbol')

      assert_match(/array,symbol:\[:a, :b, :c\]/, out.string)
    end

    private

    # デバッグモード用ロガーを準備する
    def initLoggerWithDebugLevel(io)
      @logger.
        reset(io).
        updateLevel(false, true)
    end

    # 非デバッグモード用ロガーを準備する
    def initLoggerWithErrorLevel(io)
      @logger.
        reset(io).
        updateLevel(false, false)
    end
  end
end

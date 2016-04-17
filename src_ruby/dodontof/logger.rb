#--*-coding:utf-8-*--

require 'logger'
require 'singleton'
require 'kconv'

module DodontoF
  # どどんとふ共通ロガー
  class Logger
    include Singleton

    # コンストラクタ
    def initialize
      reset
      updateLevel
    end

    # ロガーを作り直す
    # @param [String, IO] logdev ログデバイス
    # @param [Integer, String] shiftAge 保持する古いログファイルの数
    #   またはローテーション頻度
    # @param [Integer] shiftSize 最大ログファイルサイズ
    # @return [self]
    def reset(logdev = $logFileName,
              shiftAge = $logFileMaxCount,
              shiftSize = $logFileMaxSize)
      @logger = ::Logger.new(logdev, shiftAge, shiftSize)
      self
    end

    # ログレベルを返す
    def level
      @logger.level
    end

    # ログレベルを更新する
    # @param [Boolean] modRuby modRuby を使用しているかどうか
    # @param [Boolean] debug デバッグログ出力を行うかどうか
    # @return [self]
    def updateLevel(modRuby = $isModRuby,
                     debug = $debug)
      @logger.level =
        if modRuby
          ::Logger::FATAL
        else
          debug ? ::Logger::DEBUG : ::Logger::ERROR
        end

      self
    end

    # デバッグログ出力を行う
    # @param [Object] obj 対象オブジェクト
    # @param [Object] headers ヘッダ
    # @return [self]
    def debug(obj, *headers)
      # ブロックは遅延評価されるのでフィルターする必要はない
      @logger.debug { logMessage(obj, headers) }
      self
    end

    # エラーログ出力を行う
    # @param [Object] obj 対象オブジェクト
    # @param [Object] headers ヘッダ
    # @return [self]
    def error(obj, *headers)
      # ブロックは遅延評価されるのでフィルターする必要はない
      @logger.error { logMessage(obj, headers) }
      self
    end

    private

    # ログのメッセージを返す
    # @param [Object] obj 対象オブジェクト
    # @param [Array] headers ヘッダ
    def logMessage(obj, headers)
      message = obj.instance_of?(String) ? obj : obj.inspect.tosjis

      "#{headers.join(',')}:#{message}"
    end
  end
end

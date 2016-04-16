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
      update_level
    end

    # ロガーを作り直す
    # @param [String, IO] logdev ログデバイス
    # @param [Integer, String] shift_age 保持する古いログファイルの数
    #   またはローテーション頻度
    # @param [Integer] shift_size 最大ログファイルサイズ
    # @return [self]
    def reset(logdev = $logFileName,
              shift_age = $logFileMaxCount,
              shift_size = $logFileMaxSize)
      @logger = ::Logger.new(logdev, shift_age, shift_size)
      self
    end

    # ログレベルを返す
    def level
      @logger.level
    end

    # ログレベルを更新する
    # @param [Boolean] mod_ruby mod_ruby を使用しているかどうか
    # @param [Boolean] debug デバッグログ出力を行うかどうか
    # @return [self]
    def update_level(mod_ruby = $isModRuby,
                     debug = $debug)
      @logger.level =
        if mod_ruby
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
      @logger.debug { log_message(obj, headers) }
      self
    end

    # エラーログ出力を行う
    # @param [Object] obj 対象オブジェクト
    # @param [Object] headers ヘッダ
    # @return [self]
    def error(obj, *headers)
      # ブロックは遅延評価されるのでフィルターする必要はない
      @logger.error { log_message(obj, headers) }
      self
    end

    private

    # ログのメッセージを返す
    # @param [Object] obj 対象オブジェクト
    # @param [Array] headers ヘッダ
    def log_message(obj, headers)
      message = obj.instance_of?(String) ? obj : obj.inspect.tosjis

      "#{headers.join(',')}:#{message}"
    end
  end
end

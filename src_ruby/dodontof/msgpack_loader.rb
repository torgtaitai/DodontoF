# -*- coding: utf-8 -*-

lib_dir = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

module DodontoF
  # MessagePack ライブラリの読み込み処理
  module MsgpackLoader
    # MessagePack ライブラリの読み込みに失敗したかどうか
    @@failed = false

    module_function
    # MessagePack ライブラリを読み込む
    # @return [true] MessagePack ライブラリの読み込みが行われた場合
    # @return [false] MessagePack ライブラリの読み込みが行われなかった場合
    def load
      # 既に読み込まれていたら何もしない
      return false if defined?(::MessagePack)

      begin
        if $isMessagePackInstalled
          # gem install msgpack してる場合はこちら
          require 'rubygems'
          require 'msgpack'
        else
          if RUBY_VERSION >= '1.9.0'
            # msgpack の Ruby 1.9 用
            require 'msgpack/msgpack19'
          else
            # MessagePackPure バージョン
            require 'msgpack/msgpackPure'
          end
        end
      rescue LoadError
        # 読み込み失敗
        @@failed = true
        return false
      end

      true
    end

    # MessagePack ライブラリの読み込みに失敗したかどうかを返す
    # @return [Boolean] MessagePack ライブラリの読み込みに失敗したかどうか
    def failed?
      @@failed
    end
  end
end

DodontoF::MsgpackLoader.load

# -*- coding: utf-8 -*-

# このコードは下記URLのコードをもとに作成されました。
# 元となるコードのライセンスはPublic Domainです。
# http://ruby-webapi.googlecode.com/svn/trunk/misc/SimpleJson/SimpleJson_jp.rb

# このコードはRuby1.9.0以上を対象としています。
# Ruby1.8系で同様の機能を利用する場合には jsonParserPure.rb をrequireしてください。

module JsonParser

  ERR_IllegalSyntax  = "[JsonParser] Syntax error"

  module_function

  def parse(str)
    str = (str.encode('UTF-8') rescue str.dup)
    raise ERR_IllegalUnicode unless str.valid_encoding?

    begin
      return JSON.parse(str, :max_nesting => false)
    rescue JSON::JSONError => e
      exception = RuntimeError.new(e.message)
      exception.set_backtrace(e.backtrace)
      raise exception
    end
  end
end

module JsonBuilder

  module_function

  def build(obj)
    begin
      obj = [obj] unless obj.is_a?(Array) || obj.is_a?(Hash)
      return JSON.generate(obj, :max_nesting => MAX_NEST, :check_circular => false)
    rescue JSON::JSONError => e
      exception = RuntimeError.new(e.message)
      exception.set_backtrace(e.backtrace)
      raise exception
    end
  end

  private

  MAX_NEST = 19

end

if RUBY_VERSION >= '1.9.0'
  require 'json'
else
  require 'json/jsonParserPure'
end

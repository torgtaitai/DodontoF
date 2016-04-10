#--*-coding:utf-8-*--

# コマンドサーバクラス
# DodontoFServerやDodontoFServerMySqlKaiといった
# ネットワークからCommandを受け取って、それを使って処理を行うコードのクラス
# 内部でcommandメソッドを使ってメソッドを定義すると
# 自動的にcommandAnalyze()で呼び出し可能なメソッドとなる
class CommandServer
  # 次のメソッドをどのモードで追加するか
  @@next_method_type = :notCommand
  # CGIに飛んできたコマンドのどれを実際にコマンドとして扱うかのテーブル
  @@commands = { }

  # コマンド関数を作る
  def self.command
    @@next_method_type = :hasReturn
  end

  # 戻り値を使わないタイプのコマンド関数を作る
  def self.command_noreturn
    @@next_method_type = :hasNoReturn
  end

  # メソッド追加時に呼ばれるコールバック
  def self.method_added(name)
    return if @@next_method_type == :notCommand
    @@commands[name.to_s] = @@next_method_type
    @@next_method_type = :notCommand
  end

  def initialize(cgiParams)
    @cgiParams = cgiParams

    @isWebIf = false
  end

  def web_interface?
    @isWebIf
  end

  # このメソッドはCGIクラスへのアクセスを伴いますが
  # テスト中にCGIクラスを利用してパラメタを得てしまうとブロッキングが起きますので
  # テスト時にはモック化して適当な値を返すために切り出されています
  def getRawCGIValue
    @cgi ||= CGI.new
    @cgi.params[key].first
  end

  def getRequestData(key)
    logging(key, "getRequestData key")

    value = @cgiParams[key]
    # logging(@cgiParams, "@cgiParams")
    # logging(value, "getRequestData value")

    if( value.nil? )
      if( @isWebIf )
        value = getRawCGIValue
      end
    end

    # logging(value, "getRequestData result")

    return value
  end

  def analyzeCommand
    commandName = getRequestData('cmd')

    logging(commandName, "commandName")

    if( commandName.nil? or commandName.empty? )
      return getResponseTextWhenNoCommandName
    end

    commandType = @@commands[commandName]
    logging(commandType, "commandType")

    case commandType
    when :hasReturn
      return self.send( commandName )
    when :hasNoReturn
      self.send( commandName )
      return nil
    else
      throw Exception.new("\"" + commandName.untaint + "\" is invalid command")
    end
  end

  def getResponseTextWhenNoCommandName
    logging("getResponseTextWhenNoCommandName Begin")

    response = analyzeWebInterfaceCatcher

    if( response.nil? )
      response =  getTestResponseText
    end

    return response
  end

  def server_type_name
    fail NotImplementedError, 'server_type_name is not implemented.'
  end

  def getTestResponseText
    unless ( FileTest::directory?( $SAVE_DATA_DIR + '/saveData') )
      return "Error : saveData ディレクトリ(#{$SAVE_DATA_DIR + '/saveData'}) が存在しません。"
    end
    if ( Dir::mkdir( $SAVE_DATA_DIR + '/saveData/data_checkTestResponse') )
      Dir::rmdir($SAVE_DATA_DIR + '/saveData/data_checkTestResponse' )
    end
    unless ( FileTest::directory?( $imageUploadDir ) )
      return "Error : 画像保存用ディレクトリ #{$imageUploadDir} が存在しません。"
    end
    if ( Dir::mkdir( $imageUploadDir + '/data_checkTestResponse' ) )
      Dir::rmdir($imageUploadDir + '/data_checkTestResponse' )
    end
    return "「#{server_type_name}」の動作環境は正常に起動しています。"
  end

  def analyzeWebInterfaceCatcher
    @isWebIf = true

    result = { 'result'=> 'NG' }

    begin
      result = analyzeWebInterface
      logging("analyzeWebInterface end result", result)
      setJsonpCallBack
    rescue Exception => e
      result['result'] = e.to_s
    end

    return result
  end

  def analyzeWebInterface
    fail NotImplementedError, 'analyzeWebInterface is not implemented.'
  end
end

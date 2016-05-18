# -*- coding: utf-8 -*-

require 'dodontof/logger'

class DiceBotInfos
  
  def initialize
    @baseDiceBot = {
    'name' => 'BaseDiceBot',
    'gameType' => 'BaseDiceBot',
    'prefixs' => [
      '\d+D\d*', #加算ロール　(xDn)
      '\d+B\d+', #バラバラロール　(xBn)
      '\d+R\d+', #個数振り足しロール　(xRn)
      '\d+U\d+', #上方無限ロール　(xUn)
      'C\(', #計算用(Cコマンド)
      '\([\d\+\-\*\/]+\)', #ダイスの個数部分計算用
      '\d+U\d+', #上方無限ロール　(xUn)
      '(\d+|\[\d+\.\.\.\d+\])D(\d+|\[\d+\.\.\.\d+\])', #ランダム数値の埋め込み　([n...m]D[x...y])
      '\d+[\+\-\*\/]', #a+xDn のような加減算用
      'D66', #D66ダイス
      'make', #ランダムジェネレータ用
      'choice\[', #ランダム選択　(choice[A, B, C])
    ],
    'info' => <<INFO_MESSAGE_TEXT
【ダイスボット】チャットにダイス用の文字を入力するとダイスロールが可能
入力例）２ｄ６＋１　攻撃！
出力例）2d6+1　攻撃！
　　　　  diceBot: (2d6) → 7
上記のようにダイス文字の後ろに空白を入れて発言する事も可能。
以下、使用例
　3D6+1>=9 ：3d6+1で目標値9以上かの判定
　1D100<=50 ：D100で50％目標の下方ロールの例
　3U6[5] ：3d6のダイス目が5以上の場合に振り足しして合計する(上方無限)
　3B6 ：3d6のダイス目をバラバラのまま出力する（合計しない）
　10B6>=4 ：10d6を振り4以上のダイス目の個数を数える
　(8/2)D(4+6)<=(5*3)：個数・ダイス・達成値には四則演算も使用可能
　C(10-4*3/2+2)：C(計算式）で計算だけの実行も可能
　choice[a,b,c]：列挙した要素から一つを選択表示。ランダム攻撃対象決定などに
　S3d6 ： 各コマンドの先頭に「S」を付けると他人結果の見えないシークレットロール
　3d6/2 ： ダイス出目を割り算（切り捨て）。切り上げは /2U、四捨五入は /2R。
　D66 ： D66ダイス。順序はゲームに依存。D66N：そのまま、D66S：昇順。
INFO_MESSAGE_TEXT
    }
    
    noneDiceBot = {
    'name' => 'ダイスボット(指定無し)',
    'gameType' => 'DiceBot',
    'prefixs' => [
    ],
    'info' => <<INFO_MESSAGE_TEXT
ゲーム固有の判定がある場合はこの場所に記載されます。
INFO_MESSAGE_TEXT
    }
    
    @infos = [noneDiceBot,
             ]

    @logger = DodontoF::Logger.instance
  end
  
  
  def getInfos
    
    @orders = getDiceBotOrder
    
    addAnotherDiceBotToInfos()
    sortInfos()
    deleteInfos() unless( $isDisplayAllDice )
    
    @infos << @baseDiceBot
    
    return @infos
  end
  
  def deleteInfos
    @logger.debug(@orders, '@orders')
    
    @infos.delete_if do |info|
      not @orders.include?(info['name'])
    end
  end
  
  def sortInfos
    @infos = @infos.sort_by do |info|
      index = @orders.index(info['name'])
      index ||= 999
      index.to_i
    end
  end
  
  def getDiceBotOrder
    orders = $diceBotOrder.split("\n")
    return orders
  end
  
  
  def addAnotherDiceBotToInfos
    ignoreBotNames = ['DiceBot', 'DiceBotLoader', 'baseBot', '_Template', 'test']
    
    require 'diceBot/DiceBot'
    
    botFiles = Dir.glob("src_bcdice/diceBot/*.rb")
    
    botNames = botFiles.collect{|i| File.basename(i, ".rb").untaint}
    botNames.delete_if{|i| ignoreBotNames.include?(i) }
    
    botNames.each do |botName|
      @logger.debug(botName, 'load unknown dice bot botName')
      require "diceBot/#{botName}"
      diceBot = Module.const_get(botName).new
      @infos << diceBot.info
    end
  end
  
end

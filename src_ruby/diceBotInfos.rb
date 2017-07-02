# -*- coding: utf-8 -*-

require 'dodontof/logger'

# ダイスボットの情報の一覧の取得処理
class DiceBotInfos
  # ダイスボット指定なしの場合の情報
  NONE_DICE_BOT_INFO = {
    'name' => 'ダイスボット(指定無し)',
    'gameType' => 'DiceBot',
    'prefixs' => [],
    'info' => "ゲーム固有の判定がある場合はこの場所に記載されます。\n"
  }

  # 基本的なダイスボットの情報
  BASE_DICE_BOT_INFO = {
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
      'choice\[' #ランダム選択　(choice[A, B, C])
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

  # 収集時に無視するボット名
  BOT_NAMES_TO_IGNORE = [
    'DiceBot',
    'DiceBotLoader',
    'DiceBotLoaderList',
    'baseBot',
    '_Template',
    'test'
  ]

  # ダイスボットディレクトリに含まれるダイスボットを収集する
  # @return [Array<DiceBot>]
  # @see https://github.com/torgtaitai/BCDice/commit/11ee56c8dfdb00ac232c8b5cbf87a963d37df974
  # @todo BCDiceをコミット11ee56c以降に更新すると、BCDice側のDiceBotLoader.collectDiceBotsで行える
  #
  # BCDiceからのバックポート。
  def self.collectDiceBots
    diceBotDir = File.expand_path('../src_bcdice/diceBot', File.dirname(__FILE__))

    require("#{diceBotDir}/DiceBot")

    botFiles = Dir.glob("#{diceBotDir}/*.rb")
    botNames =
      botFiles.map { |botFile| File.basename(botFile, '.rb').untaint }
    validBotNames =
      # 特別な名前のものを除外する
      (botNames - BOT_NAMES_TO_IGNORE).
      # 正しいクラス名になるものだけ選ぶ
      select { |botName| /\A[A-Z]/ === botName }

    validBotNames.map { |botName|
      require("#{diceBotDir}/#{botName}")
      Object.const_get(botName).new
    }
  end

  # ダイスボットの情報の一覧を取得する
  # @param [Array<String>] orderedGameNames 順序付けられたゲーム名の配列
  # @param [Boolean] showAllDiceBots すべてのダイスボットを表示するか
  # @return [Array<Hash>]
  def self.get(orderedGameNames, showAllDiceBots)
    diceBots = self.collectDiceBots

    # ゲーム名 => ダイスボットの対応を作る
    diceBotFor = Hash[
      diceBots.map { |diceBot| [diceBot.gameName, diceBot] }
    ]
    toDiceBot = lambda { |gameName| diceBotFor[gameName] }

    orderedEnabledDiceBots = orderedGameNames.
      map(&toDiceBot).
      # ゲーム名が誤記されていた場合nilになるので除く
      compact

    orderedDiceBots =
      if showAllDiceBots
        disabledGameNames = diceBotFor.keys - orderedGameNames
        orderedDisabledDiceBots = disabledGameNames.
          sort.
          map(&toDiceBot)

        # 一覧に記載されていたゲーム→記載されていなかったゲームの順
        orderedEnabledDiceBots + orderedDisabledDiceBots
      else
        orderedEnabledDiceBots
      end

    # 指定なし→各ゲーム→基本の順で返す
    [NONE_DICE_BOT_INFO] + orderedDiceBots.map(&:info) + [BASE_DICE_BOT_INFO]
  end
end

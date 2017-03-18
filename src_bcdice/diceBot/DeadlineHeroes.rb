# -*- coding: utf-8 -*-

class DeadlineHeroes < DiceBot
  
  def gameName
    'デッドラインヒーローズ'
  end
  
  def gameType
    "DeadlineHeroes"
  end
  
  def prefixs
    [
      'DLH\\d+([\\+\\-]\\d+)*',
      'DC(肉体|L|P|精神|S|M|環境|C|E)\\-\d+',
    ]
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・行為判定
　DLHxxx
　（xxx=成功率）
　「DLH50+20-30」などのように、加減算の式で記述することもできます。
　クリティカル、ファンブルについても、自動的に判別されます。
　成功率は上限を100％、下限を０％としています。

・デスチャート
　DC●●-X
　（●●=チャートの指定、X=マイナス値）
　"肉体" の代わりに L か P
　"精神" の代わりに S か M
　"環境" の代わりに C か E でも同等の挙動をします。
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
    when /^DLH(\d+([\+\-]\d+)*)/i
      text = ""
      
      dice10, = roll(1, 10)
      dice10 = 0 if dice10 == 10
      dice01, = roll(1, 10)
      dice01 = 0 if dice01 == 10
      
      diceTotal = dice10*10 + dice01
      diceTotal = 100 if diceTotal == 0
      
      text = "1D100[#{dice10},#{dice01}]=#{'%02d' % [diceTotal]}"
      
      expressions = $1
      successRate = sumUpExpressions(expressions)
      successRate = 100 if successRate > 100
      successRate = 0 if successRate < 0
      
      text = "行為判定(成功率:#{(expressions =~ /[\+\-]/) ? (expressions + ' = '+successRate.to_s) : successRate.to_s}) => #{text} => "
      
      if diceTotal <= successRate then
        # 成功
        text += " 出目#{'%02d' % [diceTotal]}≦#{'%02d' % [successRate]}％ => 成功"
        text += " (クリティカル！ … パワーの代償１／２)" if isRepdigit?(dice10, dice01)
      else
        # 失敗
        text += " 出目#{'%02d' % [diceTotal]}＞#{'%02d' % [successRate]}％ => 失敗"
        text += " (ファンブル！ … パワーの代償２倍＆振り直し不可)" if isRepdigit?(dice10, dice01)
      end
      
      return text
    when /^DC(肉体|L|P|精神|S|M|環境|C|E)\-(\d+)/i
      minusScore = $2.to_i
      
      chartName = nil
      chartName = '肉体' if command =~ /^DC(肉体|L|P)/i # L は「ライフ」、 P は physical のニュアンス
      chartName = '精神' if command =~ /^DC(精神|S|M)/i # S は「サニティ」、 M は mental のニュアンス
      chartName = '環境' if command =~ /^DC(環境|C|E)/i # C は「クレジット」、 E は environmental のニュアンス
      
      return fetchDeathChart(chartName, minusScore)
    end
    
    return nil
  end
  
  def isRepdigit?(diceA, diceB)
    return diceA == diceB
  end
  
  # ex: "10+15-23" -> 10+15-23 -> 2
  def sumUpExpressions(formula)
    ((formula.scan(/[\+\-]?\d+/).map do |x| convertExpressionToInt(x) end).inject(0) do |sum, x| sum + x end)
  end
  
  # ex1: "10" -> 10
  # ex2: "+15" -> 15
  # ex3: "-23" -> -23
  def convertExpressionToInt(expressionText)
    return expressionText.to_i if expressionText =~ /^\-?\d+/
    return convertExpressionToInt(expressionText.slice(1..-1)) if expressionText =~ /^\+\d+$/
    raise
  end
  
  def fetchDeathChart(chartName, minusScore)
    dice, = roll(1, 10)
    keyNumber = dice + minusScore
    
    keyText, resultText, = fetchFromChart(keyNumber, getDeathChartByName(chartName))
    
    return "デスチャート（#{chartName}）[マイナス値=#{minusScore} + 1D10(->#{dice}) = #{keyNumber}] => #{keyText} … #{resultText}"
  end
  
  def fetchFromChart(keyNumber, chart)
    unless chart.empty? then
      # return "key number = #{keyNumber}, size of chart = #{chart.size}, class of chart = #{chart.class}]"
      minKey = chart.keys.min
      maxKey = chart.keys.max
      
      return ["#{minKey}以下", chart[minKey]] if keyNumber < minKey
      return ["#{maxKey}以上", chart[maxKey]] if keyNumber > maxKey
      return [keyNumber.to_s, chart[keyNumber]] if chart.has_key? keyNumber
    end
    
    return ["未定義", "？？？"]
  end
  
  def getDeathChartByName(chartName)
    return {} unless @@deathCharts.has_key? chartName
    return @@deathCharts[chartName]
  end
  
  @@deathCharts = {
    '肉体' => {
      10 => "何も無し。キミは奇跡的に一命を取り留めた。闘いは続く。",
      11 => "激痛が走る。以後、イベント終了時まで、全ての判定の成功率－10％。",
      12 => "キミは［硬直］ポイント２点を得る。［硬直］ポイントを所持している間、キミは「属性：妨害」のパワーを使用することができない。各ラウンド終了時、キミは所持している［硬直］ポイントを１点減らしてもよい。",
      13 => "渾身の一撃!!　キミは〈生存〉判定を行なう。失敗した場合、［死亡］する。",
      14 => "キミは［気絶］ポイント２点を得る。［気絶］ポイントを所持している間、キミはあらゆるパワーを使用できず、自身のターンを得ることもできない。各ラウンド終了時、キミは所持している［気絶］ポイントを１点減らしてもよい。",
      15 => "以後、イベント終了時まで、全ての判定の成功率－20％。",
      16 => "記録的一撃!!　キミは〈生存〉－20％の判定を行なう。失敗した場合、［死亡］する。",
      17 => "キミは［瀕死］ポイント２点を得る。［瀕死］ポイントを所持している間、キミはあらゆるパワーを使用できず、自身のターンを得ることもできない。各ラウンド終了時、キミは所持している［瀕死］ポイントを１点を失う。全ての［瀕死］ポイントを失う前に戦闘が終了しなかった場合、キミは［死亡］する。",
      18 => "叙事詩的一撃!!　キミは〈生存〉－30％の判定を行なう。失敗した場合、［死亡］する。",
      19 => "以後、イベント終了時まで、全ての判定の成功率－30％。",
      20 => "神話的一撃!!　キミは宙を舞って三回転ほどした後、地面に叩きつけられる。見るも無惨な姿。肉体は原型を留めていない（キミは［死亡］した）。",
    },
    '精神' => {
      10 => "何も無し。キミは歯を食いしばってストレスに耐えた。",
      11 => "以後、イベント終了時まで、全ての判定の成功率－10％。",
      12 => "キミは［恐怖］ポイント２点を得る。［恐怖］ポイントを所持している間、キミは「属性：攻撃」のパワーを使用できない。各ラウンド終了時、キミは所持している［恐怖］ポイントを１点減らしてもよい。",
      13 => "とても傷ついた。キミは〈意志〉判定を行なう。失敗した場合、［絶望］してＮＰＣとなる。",
      14 => "キミは［気絶］ポイント２点を得る。［気絶］ポイントを所持している間、キミはあらゆるパワーを使用できず、自身のターンを得ることもできない。各ラウンド終了時、キミは所持している［気絶］ポイントを１点減らしてもよい。",
      15 => "以後、イベント終了時まで、全ての判定の成功率－20％。",
      16 => "信じるものに裏切られたような痛み。キミは〈意志〉－20％の判定を行なう。失敗した場合、［絶望］してＮＰＣとなる。",
      17 => "キミは［混乱］ポイント２点を得る。［混乱］ポイントを所持している間、キミは本来味方であったキャラクターに対して、可能な限り最大の被害を与える様、行動し続ける。各ラウンド終了時、キミは所持している［混乱］ポイントを１点減らしてもよい。",
      18 => "あまりに残酷な現実。キミは〈意志〉－30％の判定を行なう。失敗した場合、［絶望］してＮＰＣとなる。",
      19 => "以後、イベント終了時まで、全ての判定の成功率－30％。",
      20 => "宇宙開闢の理に触れるも、それは人類の認識限界を超える何かであった。キミは［絶望］し、以後ＮＰＣとなる。",
    },
    '環境' => {
      10 => "何も無し。キミは黒い噂を握りつぶした。",
      11 => "以後、イベント終了時まで、全ての判定の成功率－10％。",
      12 => "ピンチ！　以後、イベント終了時まで、キミは《支援》を使用できない。",
      13 => "裏切り!!　キミは〈経済〉判定を行なう。失敗した場合、キミはヒーローとしての名声を失い、［汚名］を受ける。",
      14 => "以後、シナリオ終了時まで、代償にクレジットを消費するパワーを使用できない。",
      15 => "キミの悪評は大変なもののようだ。協力者からの支援が打ち切られる。以後、シナリオ終了時まで、全ての判定の成功率－20％。",
      16 => "信頼の失墜!!　キミは〈経済〉－20％の判定を行なう。失敗した場合、キミはヒーローとしての名声を失い、［汚名］を受ける。",
      17 => "以後、シナリオ終了時まで、【環境】系の技能のレベルがすべて０となる。",
      18 => "捏造報道!!　身の覚えのない犯罪への荷担が、スクープとして報道される。キミは〈経済〉－30％の判定を行なう。失敗した場合、キミはヒーローとしての名声を失い、［汚名］を受ける。",
      19 => "以後、イベント終了時まで、全ての判定の成功率－30％。",
      20 => "キミの名は史上最悪の汚点として永遠に歴史に刻まれる。もはやキミを信じる仲間はなく、キミを助ける社会もない。キミは［汚名］を受けた。",
    },
  }
  
end

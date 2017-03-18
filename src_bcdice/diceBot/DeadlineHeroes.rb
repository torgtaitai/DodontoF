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
      'RNC[JO]',
      'HNC(.+)?\\*?',
    ]
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・行為判定
　DLHxxx
　（xxx=成功率）
　例）DLH80
　「DLH50+20-30」などのように、加減算の式で記述することもできます。
　クリティカル、ファンブルについても、自動的に判別されます。
　成功率は上限を100％、下限を０％としています。

・デスチャート
　DC●●-X
　（●●=チャートの指定、X=マイナス値）
　例）DC肉体-5
　"肉体" の代わりに L か P
　"精神" の代わりに S か M
　"環境" の代わりに C か E でも同等の挙動をします。

・ヒーローネームチャート
　HNC●●
　（●●には "色" や "動物" などを指定）
　例）HNC武器
　●●を省略すると「組み合わせ例」チャートを参照します。
　ベース表を参照する際、末尾に * をつけると、追加の表参照を自動的に解決します。
　例）HNCベースＢ*

・リアルネームチャート
　RNCJ リアルネームチャート（日本）
　RNCO リアルネームチャート（海外）
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
    when /^DLH(\d+([\+\-]\d+)*)/i
      dice10, dice01, diceTotal = rollD100
      
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
    when /^RNC([JO])/i
      chartName = $1 == 'J' ? '日本' : '海外'
      dice10, dice01, diceTotal, = rollD100
      
      text = "リアルネームチャート（#{chartName}）"
      text += ": 1D100[#{dice10},#{dice01}]=#{diceTotal}"
      text += (" => " + fetchResultFromRealNameChart(diceTotal, getRealNameChartByName(chartName)))
      
      return text
    when /^HNC(.+)?\*?/i
      chartName = $1.to_s
      
      isNeededAutoCompletion = false
      if chartName =~ /[\*＊]$/ then
        isNeededAutoCompletion = true
        chartName.sub!(/[\*＊]$/, "")
      end
      
      if chartName == "" then
        result, = doRollHeroNameTemplateChart()
        return "ヒーローネームチャート（組み合わせ例）: 1D10[#{result[:dice]}] => #{result[:result]}" unless result.nil?
      else
        result, = doRollHeroNameBaseChart(chartName, isNeededAutoCompletion)
        return "ヒーローネームチャート（#{chartName}）: 1D10[#{result[:dice]}] => #{result[:result]}" unless result.nil?
        
        result, = doRollHeroNameElementChart(chartName)
        return "ヒーローネームチャート（#{chartName}）: 1D10[#{result[:dice]}] => #{result[:name]}（意味：#{result[:mean]}）" unless result.nil?
        
        return "不明なチャート名です: #{chartName.inspect}"
      end
    end
    
    return nil
  end
  
  def rollD100
    dice10, = roll(1, 10)
    dice10 = 0 if dice10 == 10
    dice01, = roll(1, 10)
    dice01 = 0 if dice01 == 10
    
    diceTotal = dice10*10 + dice01
    diceTotal = 100 if diceTotal == 0
    
    return [dice10, dice01, diceTotal]
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
    
    return "デスチャート（#{chartName}）[マイナス値:#{minusScore} + 1D10(->#{dice}) = #{keyNumber}] => #{keyText} … #{resultText}"
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
  
  def fetchResultFromRealNameChart(keyNumber, chart)
    columns, chartBody, = chart
    
    chartBody.each do |row|
      range, elements, = row
      next unless range.include? keyNumber
      
      result = "(#{range.to_s}) … "
      
      if elements.size > 1 then
        e1, e2, e3, = elements
        c1, c2, c3, = columns
        
        result += ([[c1, e1], [c2, e2], [c3, e3]].map do |x|
          c, e, = x
          e.nil? ? nil : "#{c}: #{e}"
        end.select do |x|
          !x.nil?
        end.join("  ｜  "))
      else
        result += elements.first
      end
      
      return result
    end
    
    return "未定義 … ？？？"
  end
  
  def getRealNameChartByName(chartName)
    return {} unless @@realNameCharts.has_key? chartName
    return @@realNameCharts[chartName]
  end
  
  @@realNameCharts = {
    '日本' => [['姓', '名（男）', '名（女）'], [
      [01..06, ['アイカワ／相川、愛川', 'アキラ／晶、章', 'アン／杏']],
      [07..12, ['アマミヤ／雨宮', 'エイジ／映司、英治', 'イノリ／祈鈴、祈']],
      [13..18, ['イブキ／伊吹', 'カズキ／和希、一輝', 'エマ／英真、恵茉']],
      [19..24, ['オガミ／尾上', 'ギンガ／銀河', 'カノン／花音、観音']],
      [25..30, ['カイ／甲斐', 'ケンイチロウ／健一郎', 'サラ／沙羅']],
      [31..36, ['サカキ／榊、阪木', 'ゴウ／豪、剛', 'シズク／雫']],
      [37..42, ['シシド／宍戸', 'ジロー／次郎、治郎', 'チズル／千鶴、千尋']],
      [43..48, ['タチバナ／橘、立花', 'タケシ／猛、武', 'ナオミ／直美、尚美']],
      [49..54, ['ツブラヤ／円谷', 'ツバサ／翼', 'ハル／華、波留']],
      [55..60, ['ハヤカワ／早川', 'テツ／鉄、哲', 'ヒカル／光']],
      [61..66, ['ハラダ／原田', 'ヒデオ／英雄', 'ベニ／紅']],
      [67..72, ['フジカワ／藤川', 'マサムネ／正宗、政宗', 'マチ／真知、町']],
      [73..78, ['ホシ／星', 'ヤマト／大和', 'ミア／深空、美杏']],
      [79..84, ['ミゾグチ／溝口', 'リュウセイ／流星', 'ユリコ／由里子']],
      [85..90, ['ヤシダ／矢志田', 'レツ／烈、裂', 'ルイ／瑠衣、涙']],
      [91..96, ['ユウキ／結城', 'レン／連、錬', 'レナ／玲奈']],
      [97..100, ['名無し（何らかの理由で名前を持たない、もしくは失った）']],
    ]],
    '海外' => [['名（男）', '名（女）', '姓'], [
      [01..06, ['アルバス', 'アイリス', 'アレン']],
      [07..12, ['クリス', 'オリーブ', 'ウォーケン']],
      [13..18, ['サミュエル', 'カーラ', 'ウルフマン']],
      [19..24, ['シドニー', 'キルスティン', 'オルセン']],
      [25..30, ['スパイク', 'グウェン', 'カーター']],
      [31..36, ['ダミアン', 'サマンサ', 'キャラダイン']],
      [37..42, ['ディック', 'ジャスティナ', 'シーゲル']],
      [43..48, ['デンゼル', 'タバサ', 'ジョーンズ']],
      [49..54, ['ドン', 'ナディン', 'パーカー']],
      [55..60, ['ニコラス', 'ノエル', 'フリーマン']],
      [61..66, ['ネビル', 'ハーリーン', 'マーフィー']],
      [67..72, ['バリ', 'マルセラ', 'ミラー']],
      [73..78, ['ビリー', 'ラナ', 'ムーア']],
      [79..84, ['ブルース', 'リンジー', 'リーヴ']],
      [85..90, ['マーヴ', 'ロザリー', 'レイノルズ']],
      [91..96, ['ライアン', 'ワンダ', 'ワード']],
      [97..100, ['名無し（何らかの理由で名前を持たない、もしくは失った）']],
    ]],
  }
  
  def doRollHeroNameTemplateChart()
    chart = getHeroNameTemplateChart()
    
    unless chart.nil? then
      dice, = roll(1, 10)
      
      if chart.has_key? dice then
        return {:dice => dice, :result => chart[dice]}
      end
    end
    
    nil
  end
  
  def doRollHeroNameBaseChart(chartName, isNeededAutoCompletion = false)
    chart = getHeroNameBaseChartByName(chartName.sub("A", "Ａ").sub("B", "Ｂ").sub("C", "Ｃ"))
    
    unless chart.nil? then
      dice, = roll(1, 10)
      
      if chart.has_key? dice then
        result = {:dice => dice, :result => chart[dice]}
        
        if result[:result] =~ /［(.+)］/ then
          if isNeededAutoCompletion then
            innerResult = doRollHeroNameElementChart($1.to_s)
            result[:innerResult] = innerResult
            result[:coreResult] = innerResult[:name]
            result[:result] += " => 1D10[#{innerResult[:dice]}] => #{innerResult[:name]}（意味：#{innerResult[:mean]}）"
          end
        end
        
        return result
      end
    end
    
    nil
  end
  
  def doRollHeroNameElementChart(chartName)
    chart = getHeroNameElementChartByName(chartName.sub("/", "／"))
    
    unless chart.nil? then
      dice, = roll(1, 10)
      
      name = nil
      mean = nil
      
      if chart.has_key? dice then
        name, mean, = chart[dice]
      end
      
      return nil if name.nil? || mean.nil?
      
      return {:dice => dice, :name => name, :mean => mean,}
    else
      nil
    end
  end
  
  def getHeroNameTemplateChart()
    @@heroNameTemplates
  end
  
  def getHeroNameBaseChartByName(chartName)
    return @@heroNameBaseCharts[chartName] if @@heroNameBaseCharts.has_key? chartName
    return nil
  end
  
  def getHeroNameElementChartByName(chartName)
    return @@heroNameElementCharts[chartName] if @@heroNameElementCharts.has_key? chartName
    return nil
  end
  
  @@heroNameTemplates = {
    1 => 'ベースＡ＋ベースＢ',
    2 => 'ベースＢ',
    3 => 'ベースＢ×２回',
    4 => 'ベースＢ＋ベースＣ',
    5 => 'ベースＡ＋ベースＢ＋ベースＣ',
    6 => 'ベースＡ＋ベースＢ×２回',
    7 => 'ベースＢ×２回＋ベースＣ',
    8 => '（ベースＢ）・オブ・（ベースＢ）',
    9 => '（ベースＢ）・ザ・（ベースＢ）',
    10 => '任意',
  }
  
  @@heroNameBaseCharts = {
    'ベースＡ' => {
      1 => 'ザ・',
      2 => 'キャプテン・',
      3 => 'ミスター／ミス／ミセス・',
      4 => 'ドクター／プロフェッサー・',
      5 => 'ロード／バロン／ジェネラル・',
      6 => 'マン・オブ・',
      7 => '［強さ］',
      8 => '［色］',
      9 => 'マダム／ミドル・',
      10 => '数字（１～10）・',
    },
    'ベースＢ' => {
      1 => '［神話／夢］',
      2 => '［武器］',
      3 => '［動物］',
      4 => '［鳥］',
      5 => '［虫／爬虫類］',
      6 => '［部位］',
      7 => '［光］',
      8 => '［攻撃］',
      9 => '［その他］',
      10 => '数字（１～10）・',
    },
    'ベースＣ' => {
      1 => 'マン／ウーマン',
      2 => 'ボーイ／ガール',
      3 => 'マスク／フード',
      4 => 'ライダー',
      5 => 'マスター',
      6 => 'ファイター／ソルジャー',
      7 => 'キング／クイーン',
      8 => '［色］',
      9 => 'ヒーロー／スペシャル',
      10 => 'ヒーロー／スペシャル',
    },
  }
  
  @@heroNameElementCharts = {
    '部位' => {
      1 => ['ハート', '心臓'],
      2 => ['フェイス', '顔'],
      3 => ['アーム', '腕'],
      4 => ['ショルダー', '肩'],
      5 => ['ヘッド', '頭'],
      6 => ['アイ', '眼'],
      7 => ['フィスト', '拳'],
      8 => ['ハンド', '手'],
      9 => ['クロウ', '爪'],
      10 => ['ボーン', '骨'],
    },
    '武器' => {
      1 => ['ナイヴス', '短剣'],
      2 => ['ソード', '剣'],
      3 => ['ハンマー', '鎚'],
      4 => ['ガン', '銃'],
      5 => ['スティール', '刃'],
      6 => ['タスク', '牙'],
      7 => ['ニューク', '核'],
      8 => ['アロー', '矢'],
      9 => ['ソウ', 'ノコギリ'],
      10 => ['レイザー', '剃刀'],
    },
    '色' => {
      1 => ['ブラック', '黒'],
      2 => ['グリーン', '緑'],
      3 => ['ブルー', '青'],
      4 => ['イエロー', '黃'],
      5 => ['レッド', '赤'],
      6 => ['バイオレット', '紫'],
      7 => ['シルバー', '銀'],
      8 => ['ゴールド', '金'],
      9 => ['ホワイト', '白'],
      10 => ['クリア', '透明'],
    },
    '動物' => {
      1 => ['バニー', 'ウサギ'],
      2 => ['タイガー', '虎'],
      3 => ['シャーク', '鮫'],
      4 => ['キャット', '猫'],
      5 => ['コング', 'ゴリラ'],
      6 => ['ドッグ', '犬'],
      7 => ['フォックス', '狐'],
      8 => ['パンサー', '豹'],
      9 => ['アス', 'ロバ'],
      10 => ['バット', '蝙蝠'],
    },
    '神話／夢' => {
      1 => ['アポカリプス', '黙示録'],
      2 => ['ウォー', '戦争'],
      3 => ['エターナル', '永遠'],
      4 => ['エンジェル', '天使'],
      5 => ['デビル', '悪魔'],
      6 => ['イモータル', '死なない'],
      7 => ['デス', '死神'],
      8 => ['ドリーム', '夢'],
      9 => ['ゴースト', '幽霊'],
      10 => ['デッド', '死んでいる'],
    },
    '攻撃' => {
      1 => ['ストローク', '一撃'],
      2 => ['クラッシュ', '壊す'],
      3 => ['ブロウ', '吹き飛ばす'],
      4 => ['ヒット', '打つ'],
      5 => ['パンチ', '殴る'],
      6 => ['キック', '蹴る'],
      7 => ['スラッシュ', '斬る'],
      8 => ['ペネトレイト', '貫く'],
      9 => ['ショット', '撃つ'],
      10 => ['キル', '殺す'],
    },
    'その他' => {
      1 => ['ヒューマン', '人間'],
      2 => ['エージェント', '代理人'],
      3 => ['ブースター', '泥棒'],
      4 => ['アイアン', '鉄'],
      5 => ['サンダー', '雷'],
      6 => ['ウォッチャー', '監視者'],
      7 => ['プール', '水たまり'],
      8 => ['マシーン', '機械'],
      9 => ['コールド', '冷たい'],
      10 => ['サイド', '側面'],
    },
    '鳥' => {
      1 => ['ホーク', '鷹'],
      2 => ['ファルコン', '隼'],
      3 => ['キャナリー', 'カナリア'],
      4 => ['ロビン', 'コマツグミ'],
      5 => ['イーグル', '鷲'],
      6 => ['オウル', 'フクロウ'],
      7 => ['レイブン', 'ワタリガラス'],
      8 => ['ダック', 'アヒル'],
      9 => ['ペンギン', 'ペンギン'],
      10 => ['フェニックス', '不死鳥'],
    },
    '光' => {
      1 => ['ライト', '光'],
      2 => ['シャドウ', '影'],
      3 => ['ファイアー', '炎'],
      4 => ['ダーク', '暗い'],
      5 => ['ナイト', '夜'],
      6 => ['ファントム', '幻影'],
      7 => ['トーチ', '灯火'],
      8 => ['フラッシュ', '閃光'],
      9 => ['ランタン', '手さげランプ'],
      10 => ['サン', '太陽'],
    },
    '虫／爬虫類' => {
      1 => ['ビートル', '甲虫'],
      2 => ['バタフライ／モス', '蝶／蛾'],
      3 => ['スネーク／コブラ', '蛇'],
      4 => ['アリゲーター', 'ワニ'],
      5 => ['ローカスト', 'バッタ'],
      6 => ['リザード', 'トカゲ'],
      7 => ['タートル', '亀'],
      8 => ['スパイダー', '蜘蛛'],
      9 => ['アント', 'アリ'],
      10 => ['マンティス', 'カマキリ'],
    },
    '強さ' => {
      1 => ['スーパー／ウルトラ', '超'],
      2 => ['ワンダー', '驚異的'],
      3 => ['アルティメット', '究極の'],
      4 => ['ファンタスティック', '途方もない'],
      5 => ['マイティ', '強い'],
      6 => ['インクレディブル', '凄い'],
      7 => ['アメージング', '素晴らしい'],
      8 => ['ワイルド', '狂乱の'],
      9 => ['グレイテスト', '至高の'],
      10 => ['マーベラス', '驚くべき'],
    },
  }
end

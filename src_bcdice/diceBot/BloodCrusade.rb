#--*-coding:utf-8-*--

class BloodCrusade < DiceBot
  
  def initialize
    super
    @sendMode = 2;
    @sortType = 1;
    @d66Type = 2;
    @fractionType = "roundUp";     # 端数切り上げに設定
  end
  def gameName
    'ブラッド・クルセイド'
  end
  
  def gameType
    "BloodCrusade"
  end
  
  def prefixs
     ['RT', 'ST', 'IST', 'BRT', 'CHT', 'SHT', 'DHT', 'LHT', 'EHT', 'AST', 'MIT', 'SIT']
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
・各種表
　・関係属性表         RT
　・シーン表           ST
　・先制判定指定特技表 IST
　・身体部位決定表　　 BRT
　・自信幸福表　　　　 CHT
　・地位幸福表　　　　 SHT
　・日常幸福表　　　　 DHT
　・人脈幸福表　　　　 LHT
　・退路幸福表　　　　 EHT
　・ランダム全特技表　 AST
　・軽度狂気表　　　　 MIT
　・重度狂気表　　　　 SIT
・D66ダイスあり
INFO_MESSAGE_TEXT
  end
  
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    return '1', secret_flg unless( /(^|\s)(S)?(RT|ST|IST|BRT|CHT|SHT|DHT|LHT|EHT|AST|MIT|SIT)(\s|$)/i =~ string )
    
    secretMarker = $2
    command = $3
    output_msg = getTableResult(command, nick_e);
    
    if( secretMarker )     # 隠しロール
      secret_flg = true if(output_msg != '1');
    end
    
    return output_msg, secret_flg
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    return '' unless(signOfInequality == ">=")
    
    if(dice_n <= 2)
      return " ＞ ファンブル(【モラル】-3。追跡フェイズなら吸血シーンを追加。戦闘フェイズなら吸血鬼は追加行動を一回得る)";
    elsif(dice_n >= 12)
      return " ＞ スペシャル(【モラル】+3。追跡フェイズならあなたに関係を持つPCの【モラル】+2。攻撃判定ならダメージ+1D6）";
    elsif(total_n >= diff)
      return " ＞ 成功";
    else
      return " ＞ 失敗";
    end
  end
  

####################       ブラッド・クルセイド      ########################
  def getTableResult(string, nick_e)
    string = string.upcase
    output = '1';
    type = "";
    total_n = "";
    
    debug('getTableResult string', string)
    
    case string
      
    when 'RT'
      type = '関係属性表';
      output, total_n = getRelationTable
    when 'ST'
      type = 'シーン表';
      output, total_n = getSceneTable
    when 'IST'
      type = '先制判定指定特技表';
      output, total_n = getInitiativeSkillTable
    when 'BRT'
      type = '身体部位決定表';
      output, total_n = getBodyRegionTable
    when 'CHT'
      type = '自信幸福表';
      output, total_n = getConfidenceHappyTable
    when 'SHT'
      type = '地位幸福表';
      output, total_n = getStatusHappyTable
    when 'DHT'
      type = '日常幸福表';
      output, total_n = getDailyHappyTable
    when 'LHT'
      type = '人脈幸福表';
      output, total_n = getLinkHappyTable
    when 'EHT'
      type = '退路幸福表';
      output, total_n = getEvacuationHappyTable
    when 'AST'
      type = 'ランダム全特技表';
      output, total_n = getAllSkillTable
    when 'MIT'
      type = '軽度狂気表'
      output, total_n = getMildInsanityTable
    when 'SIT'
      type = '重度狂気表'
      output, total_n = getSevereInsanityTable
    end
    
    return output if(output == '1')
    
    output = "#{nick_e}: #{type}(#{total_n}) ＞ #{output}";
    return output;
  end
  
  
  def getRelationTable
    table = [
             '共感/不信',
             '友情/忌避',
             '愛情/嫌悪',
             '忠義/侮蔑',
             '憧憬/引け目',
             '保護欲/殺意',
            ]
    return get_table_by_1d6(table)
  end
  
  def getSceneTable
    table = [
             'どこまでも広がる荒野。風が吹き抜けていく。',
             '血まみれの惨劇の跡。いったい誰がこんなことを？',
             '都市の地下。かぼそい明かりがコンクリートを照らす。',
             '豪華な調度が揃えられた室内。くつろぎの空間を演出。',
             '普通の道端。様々な人が道を行き交う。',
             '明るく浮かぶ月の下。暴力の気配が満ちていく。',
             '打ち捨てられた廃墟。荒れ果てた景色に心も荒む。',
             '生活の様子が色濃く残る部屋の中。誰の部屋だろう？',
             '喧しい飲食店。騒ぐ人々に紛れつつ自体は進行する。',
             'ざわめく木立。踊る影。',
             '高い塔の上。都市を一望できる。',
            ]
    return get_table_by_2d6(table)
  end
  
  
  def getInitiativeSkillTable
    table = [
             '《自信/社会5》',
             '《地位/社会9》',
             '《日常/環境3》',
             '《人脈/環境9》',
             '《退路/環境11》',
             '《心臓/胴部7》',
            ]
    return get_table_by_1d6(table)
  end
  
  def getBodyRegionTable
    table = [
             '《脳》',
             '《利き腕》',
             '《利き脚》',
             '《消化器》',
             '《感覚器》',
             '《攻撃したキャラクターの任意》',
             '《口》',
             '《呼吸器》',
             '《逆脚》',
             '《逆腕》',
             '《心臓》',
            ]
    return get_table_by_2d6(table)
  end
  
  def getConfidenceHappyTable
    table = [
             '【戦闘能力】あなたは吸血鬼狩人としての自分の戦闘能力に自信を持っています。たとえ負けようとも、それは運か相手か仲間が悪かったので、あなたの戦闘能力が低いわけではありません。',
             '【美貌】あなたは自分が美しいことを知っています。他人もあなたを美しいと思っているはず。鏡を見るたびに、あなたは自分の美しさに惚れ惚れしてしまいます。',
             '【血筋】あなたは名家の血を引く者です。祖先の栄光を背負い、家門の名誉を更に増すために、偉業をなす運命にあります。または、普通にいい家族に恵まれているのかもしれません。',
             '【趣味の技量】あなたは趣味の分野では第一人者です。必ずしも名前が知れ渡っているわけではありませんが、どんな相手にも負けない自信があります。どんな趣味かは自由です。',
             '【仕事の技量】職場で最も有能なもの、それがあなたです。誰もあなたの仕事の量とクオリティを超えられません。どんな仕事をしているかは自由に決めて構いません。',
             '【長生き】あなたは吸血鬼狩人としてかなりの年月を過ごしてきたが、まだ死んでいません。これは誇るべきことです。そこらの若造には、まだまだ負けていません。',
            ]
    return get_table_by_1d6(table)
  end
  
  def getStatusHappyTable
    table = [
             '【役職】あなたは職場、あるいは吸血鬼狩人の組織のなかで高い階級についています。そのため、下にいるものには命令でき、相応の敬意を払われます。',
             '【英雄】あなたはかつて偉業を成し遂げたことがあり、誰でもそれを知っています。少々くすぐったい気もしますが、英雄として扱われるのは悪くありません。',
             '【お金持ち】あなたには財産があります。それも生半可な財産ではなく、人が敬意を払うだけの財産です。あなたはお金に困ることはなく、その幸せを知っています',
             '【特権階級】あなたは国が定める特権階級の一員です。王族や貴族をイメージするとわかりやすいでしょう。あなたは、どこに行っても、それ相応の扱いを受けることになります。',
             '【人格者】誰もが認める人格者としての評判を持っているため、あなたのところには悩みを抱えた人々が引きも切らずに押しかけてきます。大変ですが、ちょっと楽しい',
             '【リーダー】あなたは所属している何らかの組織を率いる立場にあります。会社の社長や、部活動の部長などです。あなたは求められてその地位にあります',
            ]
    return get_table_by_1d6(table)
  end
  
  def getDailyHappyTable
    table = [
             '【家】あなたの家はとても快適な空間です。コストと時間をかけて作り上げられた、あなたが居住するための空間。それはあなたの幸せの源なのです。',
             '【職場】あなたは仕事が楽しくて仕方ありません。意義ある仕事で払いも悪くなく、チームの仲間はみんないい奴ばかりです。残業は……ちょっとあるかもしれません。',
             '【行きつけの店】あなたには休みの日や職場帰りに立ち寄る行きつけの店があり、そこにいる時間は安らぎを感じることができます。店員とも顔見知りです。',
             '【ベッド】あなたは動物を飼っています。よく懐いた可愛い、またはかっこいい動物です。一緒に過ごす時間はあなたに幸せを感じさせてくれます',
             '【親しい隣人】おとなりさんやお向かいさん。よくお土産を渡したり、小さな子供を預かったりするような仲です。風邪を引いたときには、家事を手伝ってくれることも。',
             '【思い出】あなたは昔の思い出を心の支えにしています。何らかの幸せな記憶……それがあれば、この先にどんなつらいことが待っていても大丈夫でしょう。',
            ]
    return get_table_by_1d6(table)
  end
  
  def getLinkHappyTable
    table = [
             '【理解ある家族】あなたの家族は、あなたが吸血鬼狩人であることを知ったうえで協力してくれます。これがどれほど稀なことかは、仲間に聞けば分かるでしょう。',
             '【有能な友人】あなたの友人は、吸血鬼の存在とあなたの本当の仕事を知っています。そして、直接戦うだけの技量はないものの、あなたの探索をサポートしてくれます。',
             '【愛する恋人】あなたには愛する人がいます。見つめあうだけで、あなたの心は舞い上がり……帰ってきません。この恋人を失うなんて、考えるだけでも恐ろしいことです。',
             '【同志の権力者】あなたには吸血鬼の存在を知りながら、奴らに屈していない権力者との繋がりがあります。様々な違法行為をはたらく際に、役に立つでしょう。',
             '【得がたい師匠】あなたは使う武器を学んだ師匠がいて、それを通して兄弟弟子とも繋がりがあります。過酷な訓練を経て、彼らとあなたには強い絆ができています。',
             '【可愛い子供】あなたには子供がいます。聡明で魅力的、しかも健康な……将来を嘱望される子供です。子供が掴む幸せな未来を思う時、あなたの顔には笑みが広がります。',
            ]
    return get_table_by_1d6(table)
  end
  
  def getEvacuationHappyTable
    table = [
             '【故郷の町】あなたは生まれ育った街を離れて吸血鬼狩人として活動しています。いつの日かあの町へ帰る……その思いがあなたを戦いのなかで支えています。',
             '【待っている人】あなたが吸血鬼狩人をやめて、普通の暮らしに戻ることを待ちわびている人がいます。そして、あなたはその思いに応えたいと思っています。',
             '【就職先】あなたは吸血鬼狩りの報酬がなくなっても、すぐに入ることができる就職先があるので安心です。有能なのか過疎地域なのかは分かりませんが。',
             '【配偶者】あなたは吸血鬼狩人をやめたあとに家庭に入ろうと考えています。暮らしの設計はすでに済み、あとは実行するだけなのですが、なかなかそうはいきません。',
             '【大志】あなたが吸血鬼狩人として活動しているのは、やむにやまれぬ事情があるからです。あなたには「本当にやりたかったこと」があり、いつかその夢をかなえる気でいます。',
             '【空想の王国】あなたには辛いことがあると白昼夢にふける、あるいは物語に没入する癖があり、そのときには非常に幸せな気分になることができます。',
            ]
    return get_table_by_1d6(table)
  end

  # ランダム全特技表
  # 1d6で分野選択->2d6で分野から特技選択
  def getAllSkillTable
    tableCSKT = [
                 '社会2：怯える',
                 '社会3：脅す',
                 '社会4：考えない',
                 '社会5：自信',
                 '社会6：黙る',
                 '社会7：伝える',
                 '社会8：だます',
                 '社会9：地位',
                 '社会10：笑う',
                 '社会11：話す',
                 '社会12：怒る',
                ]

    tableHSKT = [
                 '頭部2：聴く',
                 '頭部3：感覚器',
                 '頭部4：見る',
                 '頭部5：反応',
                 '頭部6：考える',
                 '頭部7：脳',
                 '頭部8：閃く',
                 '頭部9：予感',
                 '頭部10：叫ぶ',
                 '頭部11：口',
                 '頭部12：噛む',
                ]

    tableASKT = [
                 '腕部2：締める',
                 '腕部3：殴る',
                 '腕部4：斬る',
                 '腕部5：利き腕',
                 '腕部6：撃つ',
                 '腕部7：操作',
                 '腕部8：刺す',
                 '腕部9：逆腕',
                 '腕部10：振る',
                 '腕部11：掴む',
                 '腕部12：投げる',
                ]

    tableBSKT = [
                 '胴部2：塞ぐ',
                 '胴部3：呼吸器',
                 '胴部4：止める',
                 '胴部5：受ける',
                 '胴部6：測る',
                 '胴部7：心臓',
                 '胴部8：逸らす',
                 '胴部9：かわす',
                 '胴部10：耐える',
                 '胴部11：消化器',
                 '胴部12：落ちる',
                ]

    tableLSKT = [
                 '脚部2：走る',
                 '脚部3：迫る',
                 '脚部4：蹴る',
                 '脚部5：利き脚',
                 '脚部6：跳ぶ',
                 '脚部7：仕掛ける',
                 '脚部8：踏む',
                 '脚部9：逆脚',
                 '脚部10：這う',
                 '脚部11：伏せる',
                 '脚部12：歩く',
                ]

    tableESKT = [
                 '環境2：休む',
                 '環境3：日常',
                 '環境4：隠れる',
                 '環境5：待つ',
                 '環境6：現れる',
                 '環境7：人脈',
                 '環境8：捕らえる',
                 '環境9：開ける',
                 '環境10：逃げる',
                 '環境11：退路',
                 '環境12：休まない',
                ]

    table = [
             '1社会',
             '2頭部',
             '3胴部',
             '4腕部',
             '5脚部',
             '6環境',
            ]
#    table2 = [
#              get_table_by_2d6(tableCSKT),
#              get_table_by_2d6(tableHSKT),
#              get_table_by_2d6(tableBSKT),
#              get_table_by_2d6(tableASKT),
#              get_table_by_2d6(tableLSKT),
#              get_table_by_2d6(tableESKT),
#             ]

    categoryNum, categoryDummy = roll(1, 6)
    detailText = nil
    detailNum = 0
    if categoryNum == 1 then
      detailText, detailNum = get_table_by_2d6(tableCSKT)
    elsif categoryNum == 2 then
      detailText, detailNum = get_table_by_2d6(tableHSKT)
    elsif categoryNum == 3 then
      detailText, detailNum = get_table_by_2d6(tableBSKT)
    elsif categoryNum == 4 then
      detailText, detailNum = get_table_by_2d6(tableASKT)
    elsif categoryNum == 5 then
      detailText, detailNum = get_table_by_2d6(tableLSKT)
    elsif categoryNum == 6 then
      detailText, detailNum = get_table_by_2d6(tableESKT)
    end
    return detailText, "#{categoryNum},#{detailNum}"
  end
  
  # 軽度狂気表
  def getMildInsanityTable
    table = [
             '【誇大妄想】（判定に失敗するたびに【感情】が１増加する。）',
             '【記憶喪失】（【幸福】の修復判定にマイナス２の修正。）',
             '【こだわり】（戦闘中の行動を「パス」以外で一つ選択し、その行動をすると【感情】が６増加する。）',
             '【お守り中毒】（「幸運のお守り」を装備していない場合、全ての2d6判定にマイナス１の修正。）',
             '【不死幻想】（自分が受けるダメージが全て１増加する。）',
             '【血の飢え】（戦闘中に最低１体でも死亡させないと、戦闘終了時に【感情】１０増加。【激情】は獲得できない。）',
            ]
    return get_table_by_1d6(table)
  end

  # 重度狂気表
  def getSevereInsanityTable
    table = [
             '【幸福依存】（【幸福】を一つ選択し、その【幸福】が結果フェイズに失われたとき、死亡する。）',
             '【見えない友達】（自分の関わる「関係を深める」判定にマイナス３の修正がつく。）',
             '【臆病】（自分の行う妨害判定にマイナス２の修正がつく。）',
             '【陰謀論】（「幸福を味わう」判定にマイナス３の修正がつく。）',
             '【指令受信】（追跡フェイズＢでの自分の行動は、可能な範囲でGMが決定する。）',
             '【猜疑心】（自分が「連携攻撃」を行うとき、関係の【深度】をダメージに加えられない。）',
            ]
    return get_table_by_1d6(table)
  end

end

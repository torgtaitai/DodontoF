#--*-coding:utf-8-*--

class DiceBotInfos
  
  def initialize
    
    noneDiceBot = {
    'name' => 'ダイスボット(指定無し)',
    'gameType' => 'DiceBot',
    'fileName' => 'DiceBot',
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
INFO_MESSAGE_TEXT
    }
    
    @infos = [noneDiceBot,
### DICE_BOT_INFO_BEGIN
  {
    'name' => 'アリアンロッド',
    'gameType' => 'Arianrhod',
    'fileName' => 'Arianrhod',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
・クリティカル、ファンブルの自動判定を行います。(クリティカル時の追加ダメージも表示されます)
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'アルスマギカ',
    'gameType' => 'ArsMagica',
    'fileName' => 'ArsMagica',
    'prefixs' => ['ArS'],
    'info' => <<INFO_MESSAGE_TEXT
・ストレスダイス　(ArSx+y)
　"ArS(ボッチダイス)+(修正)"です。判定にも使えます。Rコマンド(1R10+y[m])に読替をします。
　ボッチダイスと修正は省略可能です。(ボッチダイスを省略すると1として扱います)
　botchダイスの0の数が2以上の時は、数えて表示します。
　（注意！） botchの判断が発生したときには、そのダイスを含めてロールした全てのダイスを[]の中に並べて表示します。
　例) (1R10[5]) ＞ 0[0,1,8,0,8,1] ＞ Botch!
　　最初の0が判断基準で、その右側5つがボッチダイスです。1*2,8*2,0*1なので1botchという訳です。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'バルナ・クロニカ',
    'gameType' => 'BarnaKronika',
    'fileName' => 'BarnaKronika',
    'prefixs' => ['\d+BK','\d+BA','\d+BKC\d+','\d+BAC\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・通常判定　nBK
　ダイス数nで判定ロールを行います。
　セット数が1以上の時はセット数も表示します。
・攻撃判定　nBA
　ダイス数nで判定ロールを行い、攻撃値と命中部位も表示します。
・クリティカルコール　nBKCt　nBACt
　判定コマンドの後ろに「Ct」を付けるとクリティカルコールです。
　ダイス数n,コール数tで判定ロールを行います。
　ダイス数nで判定ロールを行います。
　セット数が1以上の時はセット数も表示し、攻撃判定の場合は命中部位も表示します。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'バトルテック',
    'gameType' => 'BattleTech',
    'fileName' => 'BattleTech',
    'prefixs' => ['\d*SRM\d+.+','\d*LRM\d+.+','\d*BT.+','CT','DW','CD\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・判定方法
　(回数)BT(ダメージ)(部位)+(基本値)>=(目標値)
　回数は省略時 1固定。
　部位はC（正面）R（右）、L（左）。省略時はC（正面）固定
　U（上半身）、L（下半身）を組み合わせ CU/RU/LU/CL/RL/LLも指定可能
　例）BT3+2>=4
　　正面からダメージ3の攻撃を技能ベース2目標値4で1回判定
　例）2BT3RL+5>=8
　　右下半身にダメージ3の攻撃を技能ベース5目標値8で2回判定
　ミサイルによるダメージは BT(ダメージ)の変わりに SRM2/4/6, LRM5/10/15/20を指定
　例）3SRM6LU+5>=8
　　左上半身にSRM6連を技能ベース5目標値8で3回判定
・CT：致命的命中表
・DW：転倒後の向き表
・CDx：メッwク戦士意識維持表。ダメージ値xで判定　例）CD3
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ブラッド・クルセイド',
    'gameType' => 'BloodCrusade',
    'fileName' => 'BloodCrusade',
    'prefixs' => ['RT','ST','IST','BRT','CHT','SHT','DHT','LHT','EHT','AST','MIT','SIT'],
    'info' => <<INFO_MESSAGE_TEXT
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
  },
  {
    'name' => 'カードランカー',
    'gameType' => 'CardRanker',
    'fileName' => 'CardRanker',
    'prefixs' => ['RM'],
    'info' => <<INFO_MESSAGE_TEXT
ランダムでモンスターカードを選ぶ (RM)
場所表 (ST)
街中場所表 (CST)
郊外場所表 (OST)
学園場所表 (SST)
運命表 (DT)
大会運命表 (TDT)
学園運命表 (SDT)
崩壊運命表 (CDT)
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'カオスフレア',
    'gameType' => 'Chaos Flare',
    'fileName' => 'ChaosFlare',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
失敗、成功の判定。差分値の計算も行います。
ファンブル時は達成値を-20します。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'Chill',
    'gameType' => 'Chill',
    'fileName' => 'Chill',
    'prefixs' => ['SR\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・ストライク・ランク　(SRx)
　"SRストライク・ランク"の形で記入します。
　ストライク・ランク・チャートに従って自動でダイスロールを行い、
　負傷とスタミナロスを計算します。
　ダイスロールと同様に、他のプレイヤーに隠れてロールすることも可能です。
　例）SR7　　　sr13　　　SR(7+4)　　　Ssr10
INFO_MESSAGE_TEXT
  },
  {
    'name' => '墜落世界',
    'gameType' => 'CrashWorld',
    'fileName' => 'CrashWorld',
    'prefixs' => ['CW\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・判定 CWn
初期目標値n (必須)
例・CW8
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'クトゥルフ',
    'gameType' => 'Cthulhu',
    'fileName' => 'Cthulhu',
    'prefixs' => ['RES\(\d+','CBR\(\d+,\d+\)'],
    'info' => <<INFO_MESSAGE_TEXT
・1D100の目標値判定で、クリティカル(決定的成功)／スペシャル／ファンブル(致命的失敗)の自動判定。
　例）1D100<=50
　　　Cthulhu : (1D100<=50) → 96 → 致命的失敗

・抵抗ロール　(RES(x-n))
　RES(自分の能力値-相手の能力値)で記述します。
　抵抗ロールに変換して成功したかどうかを表示します。
　例）RES(12-10)
　　　Cthulhu : (1d100<=60) → 35 → 成功

・組み合わせ判定　(CBR(x,y))
　目標値 x と y で％ロールを行い、成功したかどうかを表示します。
　例）CBR(50,20)
　　　Cthulhu : (1d100<=70,20) → 22[成功,失敗] → 失敗
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'クトゥルフテック',
    'gameType' => 'CthulhuTech',
    'fileName' => 'CthulhuTech',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
テストのダイス計算を実装。
成功、失敗、クリティカル、ファンブルの自動判定。
コンバットテスト(防御側有利なので「>=」ではなく「>」で入力)の時はダメージダイスも表示。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ダークブレイズ',
    'gameType' => 'DarkBlaze',
    'fileName' => 'DarkBlaze',
    'prefixs' => ['DB','BT'],
    'info' => <<INFO_MESSAGE_TEXT
・行為判定　(DBxy#n)
　行為判定専用のコマンドです。
　"DB(能力)(技能)#(修正)"でロールします。Rコマンド(3R6+n[x,y]>=m mは難易度)に読替をします。
　クリティカルとファンブルも自動で処理されます。
　DB@x@y#m と DBx,y#m にも対応しました。
　例）DB33　　　DB32#-1　　　DB@3@1#1　　　DB3,2　　　DB23#1>=4　　　3R6+1[3,3]>=4

・掘り出し袋表　(BTx)
　"BT(ダイス数)"で掘り出し袋表を自動で振り、結果を表示します。
　例）BT1　　　BT2　　　BT[1...3]
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'デモンパラサイト',
    'gameType' => 'DemonParasite',
    'fileName' => 'DemonParasite',
    'prefixs' => ['(N|A|M|U|C|)?URGE\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・衝動表　(URGEx)
　"URGE衝動レベル"の形で指定します。
　衝動表に従って自動でダイスロールを行い、結果を表示します。
　ダイスロールと同様に、他のプレイヤーに隠れてロールすることも可能です。
　頭に識別文字を追加して、デフォルト以外の衝動表もロールできます。
　・NURGEx　頭に「N」を付けると「新衝動表」。
　・AURGEx　頭に「A」を付けると「誤作動表」。
　・MURGEx　頭に「M」を付けると「ミュータント衝動表」になります。
　・UURGEx　頭に「U」が付くと鬼御魂の戦闘外衝動表。
　・CURGEx　頭に「C」で鬼御魂の戦闘中衝動表になります。
例）URGE1　　　urge5　　　Surge2
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ダブルクロス2nd,3rd',
    'gameType' => 'DoubleCross',
    'fileName' => 'DoubleCross',
    'prefixs' => ['(\d+dx|ET)'],
    'info' => <<INFO_MESSAGE_TEXT
・判定コマンド　(xDX+y@c or xDXc+y)
　"(個数)DX(修正)@(クリティカル値)"もしくは"(個数)DX(クリティカル値)(修正)"で指定します。
　加算減算のみ修正値も付けられます。
　内部で読み替えています。
　例）10dx　　　10dx+5@8(OD tool式)　　　5DX7+7-3(疾風怒濤式)

・各種表
　・感情表(ET)
　　ポジティブとネガティブの両方を振って、表になっている側に懿｢ｫを付けて表示します。
　　もちろん任意で選ぶ部分は変更して構いません。

・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'アースドーン',
    'gameType' => 'EarthDawn',
    'fileName' => 'EarthDawn',
    'prefixs' => ['\d+e\d+'],
    'info' => <<INFO_MESSAGE_TEXT
ステップダイス　(xEn+k)
ステップx、目標値n、カルマダイスkでステップダイスをロールします。
振り足しも自動。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'Eclipse Phase',
    'gameType' => 'EclipsePhase',
    'fileName' => 'EclipsePhase',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
1D100<=m 方式の判定で成否、クリティカル・ファンブルを自動判定
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'エルリック！',
    'gameType' => 'Elric!',
    'fileName' => 'Elric',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
貫通、クリティカル、ファンブルの自動判定を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'エムブリオマシン',
    'gameType' => 'EmbryoMachine',
    'fileName' => 'EmbryoMachine',
    'prefixs' => ['(EM\t+|HLT|MFT|SFT)'],
    'info' => <<INFO_MESSAGE_TEXT
・判定ロール(EMt+m@c#f)
　目標値t、修正値m、クリティカル値c(省略時は20)、ファンブル値f(省略時は2)で攻撃判定を行います。
　命中した場合は命中レベルと命中部位も自動出力します。
　Rコマンドに読み替えされます。
・各種表
　・命中部位表　HLT
　・白兵攻撃ファンブル表　MFT
　・射撃攻撃ファンブル表　SFT
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ゲヘナ・アナスタシス',
    'gameType' => 'GehennaAn',
    'fileName' => 'GehennaAn',
    'prefixs' => ['(\d+G\d+|\d+GA\d+)'],
    'info' => <<INFO_MESSAGE_TEXT
戦闘判定と通常判定に対応。幸運の助け、連撃増加値(戦闘判定)、闘技チット(戦闘判定)を自動表示します。
・戦闘判定　(nGAt+m)
　ダイス数n、目標値t、修正値mで戦闘判定を行います。
　幸運の助け、連撃増加値、闘技チットを自動処理します。
・通常判定　(nGt+m)
　ダイス数n、目標値t、修正値mで通常判定を行います。
　幸運の助けを自動処理します。(連撃増加値、闘技チットを表示抑制します)
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ガンドッグ',
    'gameType' => 'Gundog',
    'fileName' => 'Gundog',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
失敗、成功、クリティカル、ファンブルとロールの達成値の自動判定を行います。
nD9ロールも対応。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ガンドッグ・ゼロ',
    'gameType' => 'GundogZero',
    'fileName' => 'GundogZero',
    'prefixs' => ['(.DPT|.FT)'],
    'info' => <<INFO_MESSAGE_TEXT
失敗、成功、クリティカル、ファンブルとロールの達成値の自動判定を行います。
nD9ロールも対応。
・ダメージペナルティ表　　(〜DPTx) (x:修正)
　射撃(SDPT)、格闘(MDPT)、車両(VDPT)、汎用(GDPT)の各表を引くことが出来ます。
　修正を後ろに書くことも出来ます。
・ファンブル表　　　　　　(〜FTx)  (x:修正)
　射撃(SFT)、格闘(MFT)、投擲(TFT)の各表を引くことが出来ます。
　修正を後ろに書くことも出来ます。
INFO_MESSAGE_TEXT
  },
  {
    'name' => '比叡山炎上',
    'gameType' => 'Hieizan',
    'fileName' => 'Hieizan',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
大成功、自動成功、失敗、自動失敗、大失敗の自動判定を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ハンターズムーン',
    'gameType' => 'HuntersMoon',
    'fileName' => 'HuntersMoon',
    'prefixs' => ['(ET|CLT|SLT|HLT|FLT|DLT|MAT|SAT|TST|THT|TAT|TBT|TLT|TET)'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
　判定時にクリティカルとファンブルを自動判定します。
・各種表
　・遭遇表　(ET)
　・都市ロケーション表　(CLT)
　・閉所ロケーション表　(SLT)
　・炎熱ロケーション表　(HLT)
　・冷暗ロケーション表　(FLT)
　・部位ダメージ決定表　(DLT)
　・モノビースト行動表　(MAT)
　・異形アビリティー表　(SATx) (xは個数)
　・指定特技(社会)表　　(TST)
　・指定特技(頭部)表　　(THT)
　・指定特技(腕部)表　　(TAT)
　・指定特技(胴部)表　　(TBT)
　・指定特技(脚部)表　　(TLT)
　・指定特技(環境)表　　(TET)
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => '無限のファンタジア',
    'gameType' => 'InfiniteFantasia',
    'fileName' => 'InfiniteFantasia',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
失敗、成功レベルの自動判定を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'マギカロギア',
    'gameType' => 'MagicaLogia',
    'fileName' => 'MagicaLogia',
    'prefixs' => ['WT','FCT','ST','FT','AT','BGT','DAT','FAT','WIT','RTT','TPT','TCT','PCT','MCT','ICT','SCT','XCT','WCT','CCT','BST','PT','XEST','IWST','MCST','WDST','LWST'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
スペシャル／ファンブル／成功／失敗を判定
・各種表
変調表　　　　WT
運命変転表　　FCT
　典型的災厄 TCT／物理的災厄 PCT／精神的災厄 MCT／狂気的災厄 ICT
　社会的災厄 SCT／超常的災厄 XCT／不思議系災厄 WCT／コミカル系災厄 CCT
シーン表　　　ST
　極限環境 XEST／内面世界 IWST／魔法都市 MCST
　死後世界 WDST／迷宮世界 LWST
ファンブル表　FT
事件表　　　　AT
経歴表　　　　　BGT
初期アンカー表　DAT
運命属性表　　　FAT
願い表　　　　　WIT
ランダム特技表　RTT
時の流れ表　　　TPT
ブランク秘密表　BST
プライズ表　　　PT
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => '迷宮デイズ',
    'gameType' => 'MeikyuDays',
    'fileName' => 'MeikyuDays',
    'prefixs' => ['\d+MD','DRT','DNT','DBT','DHT','KST','CAT','CFT','FWT','T1T','T2T','T3T','T4T','MPT','APT','DCT','MCT','PCT','LCT'],
    'info' => <<INFO_MESSAGE_TEXT
・判定　(nMD+m)
　n個のD6を振って大きい物二つだけみて達成値を算出します。修正mも可能です。
　絶対成功と絶対失敗も自動判定します。
・各種表
　・散策表　　　　　　DRT
　・交渉表　　　　　　DNT
　・休憩表　　　　　　DBT
　・ハプニング表　　　DHT
　・カーネル停止表　　KST
　・痛打表　CAT／戦闘ファンブル表　CFT／致命傷表　FWT
　・おたから表１／２／３／４　T1T/T2T/T3T/T4T
　・相場表　　　　　　MPT
　・登場表　　　　　　APT
　・因縁表　DCT／怪物因縁表　MCT／PC因縁表　PCT／ラブ因縁表　LCT
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => '迷宮キングダム',
    'gameType' => 'MeikyuKingdom',
    'fileName' => 'MeikyuKingdom',
    'prefixs' => ['\d+MK','LRT','ORT','CRT','ART','FRT','TBT','CBT','SBT','VBT','FBT','ABT','WBT','LBT','THT','CHT','SHT','VHT','KDT','KCT','KMT','CAT','FWT','CFT','TT','NT','ET','MPT','T1T','T2T','T3T','T4T','T5T','NAME.*','DFT','IDT\d*','WIT','LIT','RIT','SIT','RWIT','RUIT','IFT','\d+RET','PNT\d*','MLT\d*','KNT\d+','WORD\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・判定　(nMK+m)
　n個のD6を振って大きい物二つだけみて達成値を算出します。修正mも可能です。
　絶対成功と絶対失敗も自動判定します。
・各種表
　・散策表(〜RT)：生活散策表 LRT／治安散策表 ORT／文化散策表 CRT／軍事散策表 ART／お祭り表 FRT
　・休憩表(〜BT)：才覚休憩表 TBT／魅力休憩表 CBT／探索休憩表 SBT／武勇休憩表 VBT／お祭り休憩表 FBT／捜索後休憩表 ABT／全体休憩表 WBT／カップル休憩表 LBT
　・ハプニング表(〜HT)：才覚ハプニング表 THT／魅力ハプニング表 CHT／探索ハプニング表 SHT
　　／武勇ハプニング表 VHT
　・王国災厄表 KDT／王国変動表 KCT／王国変動失敗表 KMT
　・王国名決定表１／２／３／４／５ KNT1／KNT2／KNT3／KNT4
　・痛打表 CAT／致命傷表 FWT／戦闘ファンブル表 CFT
　・道中表 TT／交渉表 NT／感情表 ET／相場表 MPT
　・お宝表１／２／３／４／５ T1T／T2T／T3T／T4T／T5T
　・名前表 NAMEx (xは個数)
　・名前表A NAMEA／名前表B NAMEB／エキゾチック名前表 NAMEEX／ファンタジック名前表 NAMEFA
　・アイテム関連（猟奇戦役不使用の場合をカッコ書きで出力）
　　・デバイスファクトリー　　DFT
　　・アイテムカテゴリ決定表　IDT
　　・アイテム表（〜IT)：武具 WIT／生活 LIT／回復 RIT／探索 SIT／レア武具 RWIT／レア一般 RUIT
　　・アイテム特性決定表　　　IFT
　・ランダムエンカウント表　nRET (nはレベル,1〜6)
　・地名決定表　　　　PNTx (xは個数)
　・迷宮風景表　　　　MLTx (xは個数)
　・単語表１／２／３／４　WORD1／WORD2／WORD3／WORD4
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'モノトーン・ミュージアム',
    'gameType' => 'MonotoneMusium',
    'fileName' => 'MonotoneMusium',
    'prefixs' => ['OT','DT','WDT'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
　・通常判定　　　　　　2D6+m>=t[c,f]
　　修正値m,目標値t,クリティカル値c,ファンブル値fで判定ロールを行います。
　　クリティカル値、ファンブル値は省略可能です。([]ごと省略できます)
　　自動成功、自動失敗、成功、失敗を自動表示します。
・各種表
　・兆候表　　　OT
　・歪み表　　　DT
　・世界歪曲表　WDT
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'NJSLYRBATTLE',
    'gameType' => 'NJSLYRBATTLE',
    'fileName' => 'NjslyrBattle',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
・カラテロール
2d6<=(カラテ点)
例）2d6<=5
(2D6<=5) ＞ 2[1,1] ＞ 2 ＞ 成功 重点 3 溜まる
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ネクロニカ',
    'gameType' => 'Nechronica',
    'fileName' => 'Nechronica',
    'prefixs' => ['(\d+NC|\d+NA)'],
    'info' => <<INFO_MESSAGE_TEXT
・判定　(nNC+m)
　ダイス数n、修正値mで判定ロールを行います。
　ダイス数が2以上の時のパーツ破損数も表示します。
・攻撃判定　(nNA+m)
　ダイス数n、修正値mで攻撃判定ロールを行います。
　命中部位とダイス数が2以上の時のパーツ破損数も表示します。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ナイトウィザード',
    'gameType' => 'NightWizard',
    'fileName' => 'NightWizard',
    'prefixs' => ['\d+NW'],
    'info' => <<INFO_MESSAGE_TEXT
・判定用コマンド　(nNW+m@x#y)
　"(常時特殊能力含む基本値)NW(常時以外の特殊能力及び状態異常)@(クリティカル値)#(ファンブル値)"でロールします。
　Rコマンド(2R6m[n,m]c[x]f[y]>=t tは目標値)に読替されます。
　クリティカル値、ファンブル値が無い場合は1や13などのあり得ない数値を入れてください。
　例）12NW-5@7#2　　1NW　　50nw+5@7,10#2,5
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ナイトメアハンター=ディープ',
    'gameType' => 'NightmareHunterDeep',
    'fileName' => 'NightmareHunterDeep',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
加算ロール時に６の個数をカウントして、その４倍を自動的に加算します。
(出目はそのまま表示で合計値が6-10の読み替えになります)
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'パラサイトブラッド',
    'gameType' => 'ParasiteBlood',
    'fileName' => 'ParasiteBlood',
    'prefixs' => ['(N|A|M|U|C|)?URGE\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・衝動表　(URGEx)
　"URGE衝動レベル"の形で指定します。
　衝動表に従って自動でダイスロールを行い、結果を表示します。
　ダイスロールと同様に、他のプレイヤーに隠れてロールすることも可能です。
　頭に識別文字を追加して、デフォルト以外の衝動表もロールできます。
　・NURGEx　頭に「N」を付けると「新衝動表」。
　・AURGEx　頭に「A」を付けると「誤作動表」。
　・MURGEx　頭に「M」を付けると「ミュータント衝動表」になります。
　・UURGEx　頭に「U」が付くと鬼御魂の戦闘外衝動表。
　・CURGEx　頭に「C」で鬼御魂の戦闘中衝動表になります。
例）URGE1　　　urge5　　　Surge2
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ピーカーブー',
    'gameType' => 'Peekaboo',
    'fileName' => 'Peekaboo',
    'prefixs' => ['SET','PSET','OET','IBT','SBT'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
　判定時にクリティカルとファンブルを自動判定します。
・各種表
　・学校イベント表　　　　　　　　SET
　・個別学校イベント表　　　　　　PSET
　・オバケ屋敷イベント表　　　　　OET
　・イノセント用バタンキュー！表　IBT
　・スプーキー用バタンキュー！表　SBT
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ペンドラゴン',
    'gameType' => 'Pendragon',
    'fileName' => 'Pendragon',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
クリティカル、成功、失敗、ファンブルの自動判定を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ファンタズムアドベンチャー',
    'gameType' => 'PhantasmAdventure',
    'fileName' => 'PhantasmAdventure',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
成功、失敗、決定的成功、決定的失敗の表示とクリティカル・ファンブル値計算の実装。
INFO_MESSAGE_TEXT
  },
  {
    'name' => '六門世界2nd',
    'gameType' => 'RokumonSekai2',
    'fileName' => 'RokumonSekai2',
    'prefixs' => ['\d+RS'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
aRSm<=t
能力値a,修正値m,目標値tで判定ロールを行います。
Rコマンド(3R6m<=t[a])に読み替えます。
成功度、評価、ボーナスダイスを自動表示します。
　例) 3RS+1<=9　3R6+1<=9[3]
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ロールマスター',
    'gameType' => 'RoleMaster',
    'fileName' => 'RoleMaster',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
上方無限ロール(xUn)の境界値を96にセットします。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ルーンクエスト',
    'gameType' => 'RuneQuest',
    'fileName' => 'RuneQuest',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
クリティカル、エフェクティブ(効果的成功)、ファンブルの自動判定を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'りゅうたま',
    'gameType' => 'Ryutama',
    'fileName' => 'Ryutama',
    'prefixs' => ['R\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
　Rx,y>=t（x,y：使用する能力値、t：目標値）
　1ゾロ、クリティカルも含めて判定結果を表示します
　能力値１つでの判定は Rx>=t で行えます
例）R8,6>=13
INFO_MESSAGE_TEXT
  },
  {
    'name' => '真・女神転生TRPG　覚醒編',
    'gameType' => 'SMTKakuseihen',
    'fileName' => 'ShinMegamiTenseiKakuseihen',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
・判定
1D100<=(目標値) でスワップ・通常・逆スワップ判定を判定。
威力ダイスは nU6[6] (nはダイス個数)でロール可能です。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'サタスペ',
    'gameType' => 'Satasupe',
    'fileName' => 'Satasupe',
    'prefixs' => ['(\d+R|TAGT|\w+IET|\w+IHT|F\w*T|F\w*T|A\w*T|G\w*A\w*T|A\w*T|R\w*FT|NPCT)'],
    'info' => <<INFO_MESSAGE_TEXT
・判定コマンド　(nR>=x[y,z])
　nが最大ロール回数、xが難易度、yが目標成功度、zがファンブル値です。
　yとzは省略可能です。
　例）　10r>=7　　　8R>=7[3,3]　　　10r>=5[5]　　　8R>=7[,3]
・各種表
　「TAGT3」のようにコマンド末尾に数字を入れると複数回一辺に引くことが出来ます。
　・タグ決定表　(TAGT)
　・情報イベント表　(〜IET)
　　　犯罪表(CrimeIET)、生活表(LifeIET)、恋愛表(LoveIET)、教養表(CultureIET)、戦闘表(CombatIET)
　・情報ハプニング表　(〜IHT)
　　　犯罪表(CrimeIHT)、生活表(LifeIHT)、恋愛表(LoveIHT)、教養表(CultureIHT)、戦闘表(CombatIHT)
　・命中判定ファンブル表　(FumbleT)
　・致命傷表　(FatalT)
　・アクシデント表　(AccidentT)
　・汎用アクシデント表　(GeneralAT)
　・その後表　(AfterT)
　・ロマンスファンブル表　(RomanceFT)
　・NPCの年齢と好みを一括出力　(NPCT)
　　　NPCの年齢区分(実年齢)、好み/雰囲気、好み/年齢を一括で引きます。
　　　使用しない部分は無視してください。
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'シャドウラン',
    'gameType' => 'ShadowRun',
    'fileName' => 'ShadowRun',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
上方無限ロール(xUn)の境界値を6にセットします。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'シャドウラン第４版',
    'gameType' => 'ShadowRun4',
    'fileName' => 'ShadowRun4',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
個数振り足しロール(xRn)の境界値を6にセット、バラバラロール(xBn)の目標値を5以上にセットします。
BコマンドとRコマンド時に、グリッチの表示を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => '真空学園',
    'gameType' => 'ShinkuuGakuen',
    'fileName' => 'ShinkuuGakuen',
    'prefixs' => ['CRL','CSW','CLS','CSS','CSP','CAX','CCL','CMA','CBX','CPR','CST','RL','SW','LS','SS','SP','AX','CL','BW','MA','BX','PR','ST'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
RLx：技能ベースｘで技能チェックのダイスロール
RLx>=y：この書式なら目標値 ｙ で判定結果出力
　例）RL10　　RL22>=50

・武器攻撃
（武器記号）（技能ベース値）
　例）SW10　BX30
武器を技能ベースでダイスロール。技発動までチェック。
武器記号は以下の通り
　SW：剣、LS：大剣、SS：小剣、SP：槍、
　AX：斧、CL：棍棒、BW：弓、MA：体術、
　BX：ボクシング、PR：プロレス、ST：幽波紋

・カウンター攻撃
カウンター技は武器記号の頭に「C」をつけるとロール可能。
　例）CSW10　CBX76
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'シノビガミ',
    'gameType' => 'ShinobiGami',
    'fileName' => 'ShinobiGami',
    'prefixs' => ['ST','FT','ET','WT','BT','CST','MST','DST','TST','NST','KST','TKST','GST','GWT','GAST','KYST','JBST','KFT','KWT','MT','RTT'],
    'info' => <<INFO_MESSAGE_TEXT
・各種表
　・(無印)シーン表　ST／ファンブル表　FT／感情表　ET
　　　／変調表　WT／戦場表　BT／異形表　MT／ランダム特技決定表　RTT
　・(弐)都市シーン表　CST／館シーン表　　MST／出島シーン表　DST
　・(参)トラブルシーン表　TST／日常シーン表　NST／回想シーン表　KST
　・(死)東京シーン表　TKST／戦国シーン表　GST
　・(乱)戦国変調表　GWT
　・(リプレイ戦1〜2巻)学校シーン表　GAST／京都シーン表　KYST
　　　／神社仏閣シーン表　JBST
　・(怪)怪ファンブル表　KFT／怪変調表　KWT
　・（その他）秋空に雪舞えばシーン表　AKST／災厄シーン表　CLST
　　／出島EXシーン表　DXST／斜歯ラボシーン表　HLST
　　／夏の終わりシーン表　NTST／培養プラントシーン表　　PLST
・D66ダイスあり
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ソードワールド',
    'gameType' => 'SwordWorld',
    'fileName' => 'SwordWorld',
    'prefixs' => ['K\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・SW　レーティング表　　　　　(Kx[c]+m$f) (x:キー, c:クリティカル値, m:ボーナス, f:出目修正)
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ソードワールド2.0',
    'gameType' => 'SwordWorld2.0',
    'fileName' => 'SwordWorld2_0',
    'prefixs' => ['K\d+'],
    'info' => <<INFO_MESSAGE_TEXT
自動的成功、成功、失敗、自動的失敗の自動判定を行います。

・レーティング表　(Kx)
　"Kキーナンバー+ボーナス"の形で記入します。
　ボーナスの部分に「K20+K30」のようにレーティングを取ることは出来ません。
　また、ボーナスは複数取ることが出来ます。
　レーティング表もダイスロールと同様に、他のプレイヤーに隠れてロールすることも可能です。
　例）K20　　　K10+5　　　k30　　　k10+10　　　Sk10-1　　　k10+5+2

・クリティカル値の設定
　クリティカル値は"[クリティカル値]"で指定します。
　指定しない場合はクリティカル値10とします。
　クリティカル処理が必要ないときは13などとしてください。(防御時などの対応)
　またタイプの軽減化のために末尾に「@クリティカル値」でも処理するようにしました。
　例）K20[10]　　　K10+5[9]　　　k30[10]　　　k10[9]+10　　　k10-5@9

・ダイス目の修正（運命変転やクリティカルレイ用）
　末尾に「$修正値」で処理するようにしました。
　修正値が数字のみの場合は、固定値として処理されます。
　クリティカルする場合は止まるまで自動で振りますが、固定値や修正値の適用は最初の一回だけです。
　例）K20$+1　　　K10+5$9　　　k10-5@9$+2　　　k10[9]+10$9

・首切り刀用レーティング上昇 r10
　例）K20r10　K30+24@8R10　K40+24@8$12r10

・グレイテストフォーチュンは末尾に gt
　例）K20gf　K30+24@8GF　K40+24@8$12r10gf
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'トーグ',
    'gameType' => 'TORG',
    'fileName' => 'Torg',
    'prefixs' => ['(TG|RT|Result|IT|Initimidate|TT|Taunt|Trick|CT|MT|Maneuver|ODT|ords|odamage|DT|damage|BT|bonus|total)'],
    'info' => <<INFO_MESSAGE_TEXT
・判定　(TGm)
　TORG専用の判定コマンドです。
　"TG(技能基本値)"でロールします。Rコマンドに読替されます。
　振り足しを自動で行い、20の出目が出たときには技能無し値も並記します。
・各種表　"(表コマンド)(数値)"で振ります。
　・一般結果表 成功度出力「RTx or RESULTx」
　・威圧/威嚇 対人行為結果表「ITx or INTIMIDATEx or TESTx」
　・挑発/トリック 対人行為結果表「TTx or TAUNTx or TRICKx or CTx」
　・間合い 対人行為結果表「MTx or MANEUVERx」
　・オーズ（一般人）ダメージ　「ODTx or ORDSx or ODAMAGEx」
　・ポシビリティー能力者ダメージ「DTx or DAMAGEx」
　・ボーナス表「BTx+y or BONUSx+y or TOTALx+y」 xは数値, yは技能基本値
INFO_MESSAGE_TEXT
  },
  {
    'name' => '特命転攻生',
    'gameType' => 'TokumeiTenkousei',
    'fileName' => 'TokumeiTenkousei',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
「1の出目でEPP獲得」、判定時の「成功」「失敗」「ゾロ目で自動振り足し」を判定。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'トンネルズ＆トロールズ',
    'gameType' => 'Tunnels & Trolls',
    'fileName' => 'TunnelsAndTrolls',
    'prefixs' => ['(\d+H?BS)'],
    'info' => <<INFO_MESSAGE_TEXT
失敗、成功、自動失敗の自動判定とゾロ目の振り足し経験値の自動計算を行います。
SAVEの難易度を「レベル」で表記することが出来ます。
例えば「2Lv」と書くと「25」に置換されます。
判定時以外は悪意ダメージを表示します。
バーサークとハイパーバーサーク用に専用コマンドが使えます。

・行為判定　(#nLV+x)
　"#（レベル）Lv（修正値）"で振り、結果の成否と経験値を表示します。
　レベルを半角?にすると(#?Lv+XX)成功する最高レベルを自動計算します。(経験値は1Lv成功としています)
　判定時にはゾロ目を自動で振り足します。

・バーサークとハイパーバーサーク　(nBS+x or nHBS+x)
　"(ダイス数)BS(修正値)"でバーサーク、"(ダイス数)HBS(修正値)"でハイパーバーサークでロールできます。
　最初のダイスの読替は、個別の出目はそのままで表示。
　下から２番目の出目をずらした分だけ合計にマイナス修正を追加して表示します。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ワープス',
    'gameType' => 'WARPS',
    'fileName' => 'WARPS',
    'prefixs' => [],
    'info' => <<INFO_MESSAGE_TEXT
失敗、成功度の自動判定を行います。
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ウォーハンマー',
    'gameType' => 'Warhammer',
    'fileName' => 'Warhammer',
    'prefixs' => ['WH'],
    'info' => <<INFO_MESSAGE_TEXT
・クリティカル表(whHxx/whAxx/whBxx/whLxx)
　"WH部位 クリティカル値"の形で指定します。部位は「H(頭部)」「A(腕)」「B(胴体)」「L(足)」の４カ所です。
　例）whH10 whA5 WHL4
・命中判定(WHx@t)
　"WH(命中値)@(種別)"の形で指定します。
　種別は脚の数を数字、翼が付いているものは「W」、手が付いているものは「H」で書きます。
　「2H(二足)」「2W(有翼二足)」「4(四足)」「4H(半人四足)」「4W(有翼四足)」「W(鳥類)」となります。
　命中判定を行って、当たれば部位も表示します。
　なお、種別指定を省略すると「二足」、「@」だけにすると全種別の命中部位を表示します。(コマンドを忘れた時の対応です)
　例）wh60　　wh43@4W　　WH65@
INFO_MESSAGE_TEXT
  },
  {
    'name' => 'ウィッチクエスト',
    'gameType' => 'WitchQuest',
    'fileName' => 'WitchQuest',
    'prefixs' => ['WQ\d+','SET\d+'],
    'info' => <<INFO_MESSAGE_TEXT
・チャレンジ(成功判定)(WQn)
　n回2d6ダイスを振って判定を行います。
　例）WQ3
・SET（ストラクチャーカードの遭遇表(SETn)
　ストラクチャーカードの番号(n)の遭遇表結果を得ます。
　例）SET1　SET48
INFO_MESSAGE_TEXT
  },
  {
    'name' => '絶対隷奴',
    'gameType' => 'ZettaiReido',
    'fileName' => 'ZettaiReido',
    'prefixs' => ['\d+\-2DR'],
    'info' => <<INFO_MESSAGE_TEXT
・判定
m-2DR+n>=x
m(基本能力),n(修正値),x(目標値)
DPの取得の有無も表示されます。
INFO_MESSAGE_TEXT
  },
### DICE_BOT_INFO_END
             ]
  end
  
  
  def getInfos
    
    ignoreBotNames = ['DiceBot', 'DiceBotLoader', 'baseBot', '_Template', 'test']
    ignoreBotNames += @infos.collect {|i| i['fileName']}
    
    @orders = getDiceBotOrder
    deleteInfos()
    sortInfos()
    
    require 'diceBot/DiceBot'
    
    botFiles = Dir.glob("src_bcdice/diceBot/*.rb")
    
    botNames = botFiles.collect{|i| File.basename(i, ".rb").untaint}
    botNames.delete_if{|i| ignoreBotNames.include?(i) }
    
    botNames.each do |botName|
      logging(botName, 'load unknown dice bot botName')
      require "diceBot/#{botName}"
      diceBot = Module.const_get(botName).new
      @infos << diceBot.info
    end
    
    @infos.each{|i| i.delete('fileName')}
    
    return @infos
  end
  
  def deleteInfos
    logging(@orders, '@orders')
    
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
  
end

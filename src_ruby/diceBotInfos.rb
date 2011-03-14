#--*-coding:utf-8-*--

$diceBotInfos = 
  [
  {
    'label'    => 'ダイスボット(指定無し)',
    'gameType' => '',
    'prefix'   => '',
  },
  {
    'label'    => 'アースドーン',
    'gameType' => 'EarthDawn',
    'prefix'   => '\d+e\d+',
  },
  {
    'label' =>    'アリアンロッド',
    'gameType' => 'Arianrhod',
    'prefix' =>   '',
  },
  {
    'label' =>    'アルスマギカ',
    'gameType' => 'ArsMagica',
    'prefix' =>   'ArS',
  },
  {
    'label' =>    'ウォーハンマー',
    'gameType' => 'Warhammer',
    'prefix' =>   'WH',
  },
  {
    'label' =>    'エルリック！',
    'gameType' => 'Elric!',
    'prefix' =>   '',
  },
  {
    'label' =>    'エムブリオマシン',
    'gameType' => 'EmbryoMachine',
    'prefix' =>   '(EM\t+|HLT|MFT|SFT)',
  },
  {
    'label' =>    'カオスフレア',
    'gameType' => 'Chaos Flare',
    'prefix' =>   '',
  },
  {
    'label' =>    'ガンドッグ',
    'gameType' => 'Gundog',
    'prefix' =>   '',
  },
  {
    'label' =>    'ガンドッグ・ゼロ',
    'gameType' => 'GundogZero',
    'prefix' =>   '(.DPT|.FT)',
  },
  {
    'label' =>    'クトゥルフ',
    'gameType' => 'Cthulhu',
    'prefix' =>   '',
  },
  {
    'label' =>    'クトゥルフテック',
    'gameType' => 'CthulhuTech',
    'prefix' =>   '',
  },
  {
    'label' =>    'ゲヘナ・アナスタシス',
    'gameType' => 'GehennaAn',
    'prefix' =>   '(\d+G\d+|\d+GA\d+)',
  },
  {
    'label' =>    'サタスペ',
    'gameType' => 'Satasupe',
    'prefix' =>   '(\d+R|TAGT|\w+IET|\w+IHT|F\w*T|F\w*T|A\w*T|G\w*A\w*T|A\w*T|R\w*FT|NPCT)',
  },
  {
    'label' =>    'シノビガミ',
    'gameType' => 'ShinobiGami',
    'prefix' =>   '(BT|ET|FT|ST|WT|CST|MST|DST|TST|NST|KST)',
  },
  {
    'label' =>    'シャドウラン',
    'gameType' => 'ShadowRun',
    'prefix' =>   '',
  },
  {
    'label' =>    'シャドウラン第４版',
    'gameType' => 'ShadowRun4',
    'prefix' =>   '',
  },
  {
    'label' =>    'ソードワールド',
    'gameType' => 'SwordWorld',
    'prefix' =>   'K\d+',
  },
  {
    'label' =>    'ソードワールド2.0',
    'gameType' => 'SwordWorld2.0',
    'prefix' =>   'K\d+',
  },
  {
    'label' =>    'ダークブレイズ',
    'gameType' => 'DarkBlaze',
    'prefix' =>   '(DB\d+|DB@|BT\d+)',
  },
  {
    'label' =>    'ダブルクロス2nd,3rd',
    'gameType' => 'DoubleCross',
    'prefix' =>   '(\d+dx|ET)',
  },
  {
    'label' =>    'デモンパラサイト',
    'gameType' => 'Demon Parasite',
    'prefix' =>   '((N|A|M)?URGE\d+|OUURGE\d|OCURGE)',
  },
  {
    'label' =>    'トーグ',
    'gameType' => 'TORG',
    'prefix' =>   '(TG|RT|Result|IT|Initimidate||TT|Taunt|Trick|CT|MT|Maneuver|ODT|ords|odamage|DT|damage||BT|bonus|total)',
  },
  {
    'label' =>    '特命転校生',
    'gameType' => 'TokumeiTenkousei',
    'prefix' =>   '',
  },
  {
    'label' =>    'トンネルズ＆トロールズ',
    'gameType' => 'Tunnels &amp; Trolls',
    'prefix' =>   '(\d+H?BS)',
  },
  {
    'label' =>    'ナイトウィザード',
    'gameType' => 'NightWizard',
    'prefix' =>   '\d+NW',
  },
  {
    'label' =>    'ナイトメアハンター=ディープ',
    'gameType' => 'NightmareHunterDeep',
    'prefix' =>   '',
  },
  {
    'label' =>    'ファンタズムアドベンチャー',
    'gameType' => 'PhantasmAdventure',
    'prefix' =>   '',
  },
  {
    'label' =>    'パラサイトブラッド',
    'gameType' => 'ParasiteBlood',
    'prefix' =>   '(N|A|M)?URGE\d+',
  },
  {
    'label' =>    'ハンターズムーン',
    'gameType' => 'HuntersMoon',
    'prefix' =>   '(ET|CLT|SLT|HLT|FLT|DLT|MAT|SAT|TST|THT|TAT|TBT|TLT|TET)',
  },
  {
    'label' =>    'ペンドラゴン',
    'gameType' => 'Pendragon',
    'prefix' =>   '',
  },
  {
    'label' =>    '迷宮キングダム',
    'gameType' => 'MeikyuKingdom',
    'prefix' =>   '\d+MK|LRT|ORT|CRT|ART|TBT|CBT|SBT|VBT|THT|CHT|SHT|VHT|KDT|KCT|KMT|CAT|FWT|CFT|TT|NT|ET|T1T|T2T|T3T|T4T|T5T|NAME',
  },
  {
    'label' =>    'ルーンクエスト',
    'gameType' => 'RuneQuest',
    'prefix' =>   '',
  },
  {
    'label' =>    'ロールマスター',
    'gameType' => 'RoleMaster',
    'prefix' =>   '',
  },
  {
    'label' =>    'ワープス',
    'gameType' => 'WARPS',
    'prefix' =>   '',
  },
  {
    'label' =>    '比叡山炎上',
    'gameType' => 'Hieizan',
    'prefix' =>   '',
  },
  {
    'label' =>    '無限のファンタジア',
    'gameType' => 'Infinite Fantasia',
    'prefix' =>   '',
  },
  {
    'label' =>    'Chill',
    'gameType' => 'Chill',
    'prefix' =>   'SR\d+',
  },
]

#--*-coding:utf-8-*--

class Card
  
  def initialize
    @cardsListInfos =
      [
       
       { 'type' => 'trump_swf',
         'title' => 'トランプ',
         'fileName' => 'cards/trump_swf.txt',
       },
       
       { 'type' => "trump_swf\t1x1",
         'title' => 'トランプ',
         'fileName' => 'cards/trump_mini_swf.txt',
       },
       
       
       { 'type' => 'randomDungeonTrump',
         'title' => 'ランダムダンジョン・トランプ',
         'fileName' => 'cards/trump_swf.txt',
       },
       
       
       { 'type' => 'insane',
         'title' => 'インセイン：狂気カード',
         'fileName' => 'cards/insane.txt',
       },
       
       { 'type' => 'witchQuestWitchTaro',
         'title' => 'ウィッチクエスト：ウィッチ・タロー',
         'fileName' => 'cards/witchQuestWitchTaro.txt',
       },
       
       
       { 'type' => 'witchQuestStructureCard',
         'title' => 'ウィッチクエスト：ストラクチャーカード(テキストのみ)',
         'fileName' => 'cards/witchQuestStructureCard.txt',
       },
       
       { 'type' => 'CardRanker',
         'title' => 'カードランカー',
         'fileName' => 'cards/cardRanker.txt',
       },
       
       { 'type' => 'gunMetalBlaze',
         'title' => 'ガンメタル・ブレイズ：シチュエーションカード',
         'fileName' => 'cards/gunMetalBlaze.txt',
       },
       
       { 'type' => 'gunMetalBlazeLoversStreet',
         'title' => 'ガンメタル・ブレイズ：シチュエーションカード(ラバーズストリート対応版)',
         'fileName' => 'cards/gunMetalBlazeLoversStreet.txt',
       },
       
       { 'type' => 'shanhaitaimakou',
         'title' => '上海退魔行：陰陽カード',
         'fileName' => 'cards/shanhaitaimakou.txt',
       },
       
       { 'type' => 'shinnen',
         'title' => '深淵：運命カード',
         'fileName' => 'cards/shinnen.txt',
       },
       
       { 'type' => 'shinnen_red',
         'title' => '深淵：運命カード(夢魔の占い札対応版)',
         'fileName' => 'cards/shinnen_red.txt',
       },
       
       { 'type' => 'nova',
         'title' => 'トーキョーN◎VA：ニューロデッキ',
         'fileName' => 'cards/nova.txt',
       },
       
       { 'type' => 'torg',
         'title' => 'TORG：ドラマデッキ',
         'fileName' => 'cards/torg.txt',
       },
       
       { 'type' => 'torg_English',
         'title' => 'TORG：Drama Deck [English]',
         'fileName' => 'cards/torg_English.txt',
       },
       
       { 'type' => 'bladeOfArcana',
         'title' => 'ブレイド・オブ・アルカナ：タロット',
         'fileName' => 'cards/bladeOfArcana.txt',
       },
       
       { 'type' => 'farRoadsToLoad_chien:hikari',
         'title' => 'ファー・ローズ・トゥ・ロード：地縁カード:光',
         'fileName' => 'cards/farRoadsToLoad/chien_hikari.txt',
       },
       
       { 'type' => 'farRoadsToLoad_chien:ishi',
         'title' => '石',
         'fileName' => 'cards/farRoadsToLoad/chien_ishi.txt',
       },
       
       { 'type' => 'farRoadsToLoad_chien:koori',
         'title' => '氷',
         'fileName' => 'cards/farRoadsToLoad/chien_koori.txt',
       },
       
       { 'type' => 'farRoadsToLoad_chien:mori',
         'title' => '森',
         'fileName' => 'cards/farRoadsToLoad/chien_mori.txt',
       },
       
       { 'type' => 'farRoadsToLoad_chien:umi',
         'title' => '海',
         'fileName' => 'cards/farRoadsToLoad/chien_umi.txt',
       },
       
       { 'type' => 'farRoadsToLoad_chien:yami',
         'title' => '闇',
         'fileName' => 'cards/farRoadsToLoad/chien_yami.txt',
       },
       
       { 'type' => 'farRoadsToLoad_reien:chi',
         'title' => 'ファー・ローズ・トゥ・ロード：霊縁カード:地',
         'fileName' => 'cards/farRoadsToLoad/reien_chi.txt',
       },
       
       { 'type' => 'farRoadsToLoad_reien:hi',
         'title' => '火',
         'fileName' => 'cards/farRoadsToLoad/reien_hi.txt',
       },
       
       { 'type' => 'farRoadsToLoad_reien:kaze',
         'title' => '風',
         'fileName' => 'cards/farRoadsToLoad/reien_kaze.txt',
       },

       { 'type' => 'farRoadsToLoad_reien:mizu',
         'title' => '水',
         'fileName' => 'cards/farRoadsToLoad/reien_mizu.txt',
       },
       
       { 'type' => 'farRoadsToLoad_reien:uta',
         'title' => '歌',
         'fileName' => 'cards/farRoadsToLoad/reien_uta.txt',
       },
       
       { 'type' => 'actCard',
         'title' => 'マスカレイド・スタイル：アクト・カード',
         'fileName' => 'cards/actCard.txt',
       },
       
       { 'type' => 'tatoono',
         'title' => 'ローズ・トゥ・ロード：タトゥーノ',
         'fileName' => 'cards/tatoono.txt',
       },
       
       { 'type' => 'ItrasBy_ChanceCard',
         'title' => 'Itras By：チャンスカード',
         'fileName' => 'cards/ItrasBy_ChanceCard.txt',
       },
       
       { 'type' => 'ItrasBy_ResolutionCard',
         'title' => 'Itras By：解決カード',
         'fileName' => 'cards/ItrasBy_ResolutionCard.txt',
       },
       
       { 'type' => 'harrowdeck',
         'title' => 'Pathfinder：Harrow Deck',
         'fileName' => 'cards/PathfinderHarrowDeck.txt',
       },
       
       
      ]
  end
  
  def collectCardTypeAndTypeName()
    result = @cardsListInfos.collect do |cardsInfo|
      { 'type' => cardsInfo['type'],
        'title' => cardsInfo['title'],
      }
    end
    
    return result
  end
  
  
  # 
  # (カード種別名)(タブ)(横幅)x(盾幅)とカード種別を設定するとカードの縦横幅が指定できる
  # 例）"trump_swf\t4x6" であれば、
  #   　カード種別 'trump_swf' を 横4，縦6 の幅でカードが生成される。
  #
  def getCardInfo(typeFull)
    
    type = typeFull
    if( /^([^\t]*)/ == typeFull)
      type = $1
    end
    
    result = nil
    @cardsListInfos.each do |cardsInfo|
      case cardsInfo['type']
      when typeFull
        return cardsInfo
      when type
        result = cardsInfo
      end
    end
    
    return result
  end
  
  
  def getCardFileName(type)
    cardsInfo = getCardInfo(type)
    return cardsInfo['fileName']
  end
  
  def getCardTitleName(type)
    cardsInfo = getCardInfo(type)
    return cardsInfo['title']
  end
  
end

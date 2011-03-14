#--*-coding:utf-8-*--

class Card
  
  @@cardsListInfos = [
    
=begin
    { 'type' => 'trump_jorker3',
      'title' => 'トランプ',
      'fileName' => 'cards/trump_jorker3.txt',
    },
    
    { 'type' => 'trump_3',
      'title' => 'トランプ',
      'fileName' => 'cards/trump_3.txt',
    },
=end
    { 'type' => 'trump_2',
      'title' => 'トランプ',
      'fileName' => 'cards/trump_2.txt',
    },
    
    
    { 'type' => 'torg',
      'title' => 'TORG：ドラマデッキ',
      'fileName' => 'cards/torg.txt',
    },
    
    { 'type' => 'nova',
      'title' => 'トーキョーN◎VA：ニューロデッキ',
      'fileName' => 'cards/nova.txt',
    },
    
    { 'type' => 'shinnen',
      'title' => '深淵：運命カード',
      'fileName' => 'cards/shinnen.txt',
    },
    
    { 'type' => 'shinnen_red',
      'title' => '深淵：運命カード(夢魔の占い札対応版)',
      'fileName' => 'cards/shinnen_red.txt',
    },
    
    { 'type' => 'bladeOfArcana',
      'title' => 'ブレイド・オブ・アルカナ：タロット',
      'fileName' => 'cards/bladeOfArcana.txt',
    },
    
    { 'type' => 'gunMetalBlaze',
      'title' => 'ガンメタル・ブレイズ：シチュエーションカード',
      'fileName' => 'cards/gunMetalBlaze.txt',
    },
    
    { 'type' => 'gunMetalBlazeLoversStreet',
      'title' => 'ガンメタル・ブレイズ：シチュエーションカード(ラバーズストリート対応版)',
      'fileName' => 'cards/gunMetalBlazeLoversStreet.txt',
    },
    
    { 'type' => 'tatoono',
      'title' => 'ローズ・トゥ・ロード：タトゥーノ',
      'fileName' => 'cards/tatoono.txt',
    },
    
    { 'type' => 'actCard',
      'title' => 'マスカレイド・スタイル：アクト・カード',
      'fileName' => 'cards/actCard.txt',
    },
    
    
  ];
  
  
  def collectCardTypeAndTypeName()
    result = @@cardsListInfos.collect do |cardsInfo|
      { 'type' => cardsInfo['type'],
        'title' => cardsInfo['title'],
      }
    end
    
    return result
  end
  
  def getCardInfo(type)
    result = @@cardsListInfos.find do |cardsInfo|
      cardsInfo['type'] == type
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

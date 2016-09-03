# -*- coding: utf-8 -*-

class LostRoyal < DiceBot
  
  def initialize
    super
    @sendMode = 2
    @sortType = 1
    @d66Type = 1
  end
  
  def gameName
    'ロストロイヤル'
  end
  
  def gameType
    "LostRoyal"
  end
  
  def prefixs
    []
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・D66ダイスあり
INFO_MESSAGE_TEXT
  end
end

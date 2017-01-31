# -*- coding: utf-8 -*-

class BStyleFlag_ChineseTraditional < DiceBot

  def initialize
    super
    @upplerRollThreshold = 96;
    @unlimitedRollDiceType = 100;
  end
  def gameName
    'B級恐怖片TRPG'
  end
  
  def gameType
    "BStyleFlag:ChineseTraditional"
  end
  
  def prefixs
     []
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
骰表 台詞類死亡flag SCRIPTS／事件類死亡flag　EVENTS／
INFO_MESSAGE_TEXT
  end
  
end

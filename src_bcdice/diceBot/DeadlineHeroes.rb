# -*- coding: utf-8 -*-

class DeadlineHeroes < DiceBot
  
  def gameName
    'デッドラインヒーローズ'
  end
  
  def gameType
    "DeadlineHeroes"
  end
  
  def prefixs
    []
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    return nil
  end
  
end

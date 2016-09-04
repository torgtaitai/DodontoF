# -*- coding: utf-8 -*-

class CodeLayered < DiceBot
  
  def initialize
    super
    @sendMode = 2
    @sortType = 2
  end
  
  def gameName
    '英雄武装ＲＰＧコード：レイヤード'
  end
  
  def gameType
    "CodeLayered"
  end
  
  def prefixs
     ['CL\d+(\+\d+)?']
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
CLx
CLx+y
　x = 能力値
　y = 技能レベル
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
      when /^CL(\d+)(\+(\d+))?(\s+|$)/i
        return check_cl($1.to_i, $3.to_i)
      when /^CL(\d+)(\s+|$)/i
        return check_cl($1.to_i)
    end
    
    return nil
  end
  
  def check_cl(ability, additinal = 0, border = 6)
    dices = []
    
    (ability + additinal).times do
      dice, = roll(1, 10)
      dices << dice
    end
    
    result = dices.count do |x| x <= border end
    
    text = "#{ability + additinal}D#{10} |> [#{dices.join ","}] ≦ #{border}"
    
    if result > 0 then
      text += " |> #{result}"
      
      critical_bonus = dices.count do |x| x == 1 end
      if critical_bonus >= 1 then
        text += " |> Critical!(#{critical_bonus}) |> #{result + critical_bonus}"
      end
    else
      text += " |> ファンブル"
    end
    
    return text
  end
end

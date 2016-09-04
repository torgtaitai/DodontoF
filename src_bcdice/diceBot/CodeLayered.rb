# -*- coding: utf-8 -*-

class CodeLayered < DiceBot
  
  def initialize
    super
    @sendMode = 2
    @sortType = 2
  end
  
  def gameName
    'コード：レイヤード'
  end
  
  def gameType
    "CodeLayered"
  end
  
  def prefixs
     ['CL\d+(\+\d+)?(>=\d+)?']
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
CLx
CLx+y
CLx>=z
CLx+y>=z
　x = 能力値
　y = 技能レベル
　z = 難易度
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
      when /^CL(\d+)(\+(\d+))?\>\=(\d+)(\s+|$)/i
        return check_cl($1.to_i, $3.to_i, $4.to_i)
      when /^CL(\d+)(\+(\d+))?(\s+|$)/i
        return check_cl($1.to_i, $3.to_i)
      when /^CL(\d+)\>\=(\d+)(\s+|$)/i
        return check_cl($1.to_i, 0, $2.to_i)
      when /^CL(\d+)(\s+|$)/i
        return check_cl($1.to_i)
    end
    
    return nil
  end
  
  def check_cl(ability, additinal = 0, difficulty = -1, border = 6)
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
      result += critical_bonus
      
      if critical_bonus >= 1 then
        text += " |> Critical!(#{critical_bonus}) |> #{result}"
      end
    else
      text += " |> ファンブル"
      result = -1
    end
    
    if difficulty >= 0 then
      if result >= difficulty then
        text += "（成功）"
      else
        text += "（失敗）"
      end
    end
    
    return text
  end
end

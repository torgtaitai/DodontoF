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
     ['CL\d+([\+\-]\d+)*(>=\d+)?']
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
CLx
CLx+y
CLx+y-v
CLx>=z
CLx+y>=z
CLx+y-v>=z
　x = 能力値
　y, v = 技能レベル、特技などによるダイス数の増減
　z = 難易度
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
      when /^CL(\d+)([+\-](\d+))*\>\=(\d+)(\s+|$)/i
        ability = $1.to_i
        difficulty = command.scan(/\>\=(\d+)/)[0][0].to_i
        matched = command.split(' ')[0].scan(/[+\-]\d+/)
        members = []
        
        unless matched.nil? then
          members = matched.map do |x| member_to_i(x) end
        end
        
        return check_cl(ability, members, difficulty)

        return check_cl($1.to_i, [$3.to_i], $4.to_i)
      when /^CL(\d+)([+\-](\d+))*(\s+|$)/i
        ability = $1.to_i
        matched = command.split(' ')[0].scan(/[+\-]\d+/)
        members = []
        
        unless matched.nil? then
          members = matched.map do |x| member_to_i(x) end
        end
        
        return check_cl(ability, members)
    end
    
    return nil
  end
  
  def member_to_i(m)
    if m[0] == '+' then
      m.slice(1..-1).to_i
    else
      m.to_i
    end
  end
  
  def check_cl(ability, additinals = [], difficulty = -1, border = 6)
    dices = []
    
    number_of_dice = ability
    
    unless additinals.empty? then
      number_of_dice += additinals.inject(:+)
    end
    
    number_of_dice.times do
      dice, = roll(1, 10)
      dices << dice
    end
    
    result = dices.count do |x| x <= border end
    
    text = "#{number_of_dice}D#{10} |> [#{dices.join ","}] ≦ #{border}"
    
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

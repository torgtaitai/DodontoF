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
     ['CL\d+([\+\-]\d+)*(>=\d+)?(@\d+)?', 'EC']
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
CLx
CLx@w
CLx+y
CLx+y-v
CLx+y-v@w
CLx>=z
CLx+y>=z
CLx+y-v>=z
CLx+y-v>=z@w
　x = 能力値
　y, v = 技能レベル、特技などによるダイス数の増減
　（ファンブルの処理の都合上、必ず能力値と分けてください）
　z = 難易度
　w = 判定値

EC
　邂逅表
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
      when /^CL(\d+)([+\-](\d+))*\>\=(\d+)(\@\d+)?(\s+|$)/i
        ability = $1.to_i
        difficulty = command.scan(/\>\=(\d+)/)[0][0].to_i
        matched = command.split(' ')[0].scan(/[+\-]\d+/)
        members = []
        border = 6
        
        if command =~ /\@(\d+)/ then
          border = $1.to_i
        end
        
        unless matched.nil? then
          members = matched.map do |x| member_to_i(x) end
        end
        
        return check_cl(ability, members, difficulty, border)
      when /^CL(\d+)([+\-](\d+))*(\@\d+)?(\s+|$)/i
        ability = $1.to_i
        matched = command.split(' ')[0].scan(/[+\-]\d+/)
        members = []
        border = 6
        
        if command =~ /\@(\d+)/ then
          border = $1.to_i
        end
        
        unless matched.nil? then
          members = matched.map do |x| member_to_i(x) end
        end
        
        return check_cl(ability, members, -1, border)
      when /^EC/i
        return encounter_chart
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
    
    text = "#{number_of_dice}D#{10}(能力値=#{ability}) |> [#{dices.join ","}] ≦ #{border}"
    
    if dices.min > ability then
      text += " |> ファンブル"
      result = -1
    end
    
    if result >= 0 then
      text += " |> #{result}"
      
      critical_bonus = dices.count do |x| x == 1 end
      result += critical_bonus
      
      if critical_bonus >= 1 then
        text += " |> Critical!(#{critical_bonus}) |> #{result}"
      end
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
  
  def encounter_chart
    dice, = roll(1, 100)
    
    index = (dice - 1) / 5
    
    relation, emotion = [
      ["ライバル", "競争心"],
      ["幼子", "庇護"],
      ["刺激", "興味"],
      ["同志", "誠意"],
      ["友人", "友情"],
      ["先達", "憧憬"],
      ["ビジネス", "信用"],
      ["くされ縁", "ウマが合う"],
      ["秘密", "連帯感"],
      ["借り", "借りがある"],
      ["家族", "親愛"],
      ["主人", "忠誠"],
      ["戦友", "信頼"],
      ["同類", "共感"],
      ["貸し", "貸しがある"],
      ["保護者", "頭が上がらない"],
      ["苦手なひと", "苦手"],
      ["ファン", "執着心"],
      ["トラウマ", "恐怖"],
      ["宿敵", "殺意"],
    ][index]
    
    return "邂逅表 1D100[#{dice}] -> (#{index*5+1}-#{index*5+5}) 関係：#{relation} ／ 感情：#{emotion}"
  end
end

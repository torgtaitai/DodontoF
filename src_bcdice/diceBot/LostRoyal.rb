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
    ['LR\[[0-5],[0-5],[0-5],[0-5],[0-5],[0-5]\]']
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・D66ダイスあり

行為判定
　LR[x,x,x,x,x,x]
　　x の並びには【判定表】の数値を順番に入力する。
　　（例： LR[1,3,0,1,2] ）
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    
    case command
      when /LR\[([0-5]),([0-5]),([0-5]),([0-5]),([0-5]),([0-5])\]/i
        return check_lostroyal([$1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i,])
    end
    
    return nil
  end
  
  def check_lostroyal(checking_table)
    keys = []
    
    for i in 0...3
      key, = roll(1, 6)
      keys << key
    end
    
    scores = (keys.map do |k| checking_table[k - 1] end).to_a
    total_score = scores.inject(:+)
    
    chained_sequence = find_sequence(keys)
    
    text = "3D6 => [#{keys.join(",")}] => (#{scores.join("+")}) => #{total_score}"
    
    unless chained_sequence.nil? || chained_sequence.empty? then
      text += " | #{chained_sequence.size} chain! (#{chained_sequence.join(",")}) => #{total_score + chained_sequence.size}"
      
      if chained_sequence.size >= 3 then
        text += " [スペシャル]"
      end
    end
    
    return text
  end
  
  def find_sequence(keys)
    keys = keys.sort
    
    sequence = (1...6).map do |start_key|
      find_sequence_from_start_key(keys, start_key)
    end.find_all do |x|
      x.size > 1
    end.sort do |a, b|
      a.size <=> b.size
    end.last
    
    sequence
  end
  
  def find_sequence_from_start_key(keys, start_key)
    chained_keys = []
    
    key = start_key
    
    while keys.include? key
      chained_keys << key
      key += 1
    end
    
    if chained_keys.size > 0 && chained_keys[0] == 1 then
      key = 6
      while keys.include? key
        chained_keys.unshift key
        key -= 1
      end
    end
    
    return chained_keys
  end
end

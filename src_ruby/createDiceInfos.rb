#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__) + "/../src_bcdice/"

require 'diceBot/DiceBot'

def getInfo(info)
  return <<INFO_TEXT
  {
    'name' => '#{info[:name]}',
    'gameType' => '#{info[:gameType]}',
    'fileName' => '#{info[:fileName]}',
    'prefixs' => [#{getPrefixsText(info)}],
    'info' => <<INFO_MESSAGE_TEXT
#{info[:info].chomp}
INFO_MESSAGE_TEXT
  },
INFO_TEXT
end

def getPrefixsText(info)
  prefixs = info[:prefixs]
  
  return '' if( prefixs.empty? )
  
  return "'" + prefixs.join("','") + "'"
end



def updateBcDiceConfig(infos)
  gameTypesText = infos.collect{|i| i[:gameType]}.join("\n")
  
  updateFile('../src_bcdice/configBcDice.rb',
             /\$allGameTypes = %w\{[^}]+?\}/m,
             "$allGameTypes = %w{\n#{gameTypesText}\n}")
end

def updateDiceBotConfig(infos)
  infoText = infos.collect{|i| getInfo(i)}
  
  updateFile('diceBotInfos.rb',
             /### DICE_BOT_INFO_BEGIN\n.*### DICE_BOT_INFO_END\n/m, 
             "### DICE_BOT_INFO_BEGIN\n#{infoText}### DICE_BOT_INFO_END\n")
end


def updateFile(fileName, before, after)
  buffer = File.readlines(fileName).join
  buffer.sub!(before, after)
  
  File.open(fileName, "w+") do |file|
    file.write(buffer)
  end
end

def getDiceInfos
  infos = []

  ignoreBotNames = ['DiceBot', 'DiceBotLoader', '_Template', 'test']

  botFiles = Dir.glob("./../src_bcdice/diceBot/*.rb")

  botFiles.each do |botFile|
    botName = File.basename(botFile, ".rb").untaint
    
    next if( ignoreBotNames.include?(botName) )
    
    require "diceBot/#{botName}"
    diceBot = Module.const_get(botName).new
    
    info = diceBot.info
    info[:fileName] = botName
    infos << info
  end

  infos = infos.sort_by{|i| i[:gameType]}
  
  return infos
end


if $0 == __FILE__
  infos = getDiceInfos()
  updateDiceBotConfig(infos)
  updateBcDiceConfig(infos)
end

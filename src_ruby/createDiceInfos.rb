#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__) + "/../src_bcdice/"

require 'diceBot/DiceBot'

infos = []

ignoreBotNames = ['DiceBot', 'DiceBotLoader', '_Template', 'test']

botFiles = Dir.glob("./../src_bcdice/diceBot/*.rb")

botFiles.each do |botFile|
  botName = File.basename(botFile, ".rb").untaint
  
  next if( ignoreBotNames.include?(botName) )
  
  require "diceBot/#{botName}"
  diceBot = Module.const_get(botName).new
  infos << [diceBot.info, botName]
end


def getInfo(info_and_fileName)
  info, botName = info_and_fileName
  
  return <<INFO_TEXT
  {
    'name' => '#{info[:name]}',
    'gameType' => '#{info[:gameType]}',
    'fileName' => '#{botName}',
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

infos = infos.sort_by{|i| i.first[:gameType]}
infoText = infos.collect{|i| getInfo(i)}

targetFileName = 'diceBotInfos.rb'
buffer = File.readlines(targetFileName).join

buffer.sub!(/### DICE_BOT_INFO_BEGIN\n.*### DICE_BOT_INFO_END\n/m,
            "### DICE_BOT_INFO_BEGIN\n#{infoText}### DICE_BOT_INFO_END\n")

File.open(targetFileName, "w+") do |file|
  file.write(buffer)
end

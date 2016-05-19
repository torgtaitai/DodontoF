# -*- coding: utf-8 -*-

class Card
  
  def initialize(logger, dir = nil)
    @logger = logger
    dir ||= 'cards'
    @cardsListInfos = getInitCardsListInfos( dir )
  end
  
  def getInitCardsListInfos(dir)
    
    targets = "#{dir}/**/*.txt"
    
    cardFiles = Dir.glob(targets)
    cardFiles.delete_if{|i| base = File.basename(i); (/^_/ === base) or (/_\./ === base)}
    
    cardsListInfos = []
    
    cardFiles.each do |fileName|
      fileName = fileName.untaint
      
      params = []
      File.open(fileName) do |file|
        line = file.gets.chomp
        params = line.split(/,/)
      end
      
      type = getCardType(fileName)
      title = getCardParamString(params, "title", type)
      width = getCardParamValue(params, "width", nil)
      height = getCardParamValue(params, "height", nil)
      
      info = {
        'fileName' => fileName,
        'type' => type,
        'title' => title,
        'height' => height,
        'width' => width,
      }
      info.delete_if{|key, value| value == nil}
      
      cardsListInfos << info
    end
    
    initCardSize(cardsListInfos)
    
    return cardsListInfos
  end
  
  def getCardType(fileName)
    base = File.basename(fileName, ".txt")
    return base
  end
  
  def getCardParamString(params, name, defaultValue)
    params.each do |data|
      if /#{name}\s*=\s*(.+)/ === data
        return $1
      end
    end
    
    return defaultValue
  end
  
  def getCardParamValue(params, name, defaultValue)
    value = getCardParamString(params, name, defaultValue)
    return value if value == defaultValue
    return value.to_i
  end
  
  
  def getCardsListInfos
    @cardsListInfos
  end
  
  def initCardSize(cardsListInfos)
    
    cardsListInfos.each do |info|
      width = info['width']
      height = info['height']
      
      next if width.nil? or height.nil?
      
      info['type'] = info['type'] + "\t#{width}x#{height}"
    end
  end
  
  
  def collectCardTypeAndTypeName(cardOrder = nil)
    result = @cardsListInfos.collect do |cardsInfo|
      { 'type' => cardsInfo['type'],
        'title' => cardsInfo['title'],
      }
    end
    
    return result if cardOrder.nil?
    
    padding = 0
    result = result.sort_by do |info|
      padding += 1
      index = cardOrder.index( info['title'] )
      index ||= (999 + padding)
      index.to_i
    end
    
    return result
  end
  
  
  # カード種別名と一致するカードのデータを取得。
  # この際、識別に使うカード種別名には
  # 
  #   (カード種別名)(タブ)(横幅)x(縦幅)
  # 
  # という形で縦横幅の情報も含まれています。
  # そのため、盾横幅も含めて完全に一致する情報を検索する必要があります。
  # 
  def getCardInfo(targetType)
    
    width = nil
    height = nil
    if( /^(.\w+)\t(\d+)x(\d+)$/ === targetType)
      targetType = $1
      width = $2.to_i
      height = $3.to_i
    end
    
    @logger.debug(targetType, "getCardInfo targetType")
    
    info = @cardsListInfos.find{|info| info['type'] == targetType}
    @logger.debug(info, "perfect match info")
    return info unless info.nil?
    
    info = @cardsListInfos.find do |info|
      index = info['type'].index(targetType)
      if index == 0
        (width == info['width']) and (height == info['height'])
      end
    end
    @logger.debug(info, "2nd found info")
    return info unless info.nil?
    
    return nil
  end
  
  
  def getCardFileName(type)
    cardsInfo = getCardInfo(type)
    return cardsInfo['fileName']
  end
  
  def getCardTitleName(type)
    cardsInfo = getCardInfo(type)
    return cardsInfo['title']
  end
  
end



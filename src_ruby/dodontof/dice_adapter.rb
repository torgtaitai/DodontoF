# -*- coding: utf-8 -*-
module DodontoF
  # ダイスBOTへのアダプタ
  class DiceAdapter

    def initialize(dir, prefix)
      @logger = DodontoF::Logger.instance
      @dir = dir
      @diceBotTablePrefix = prefix
    end

    def rollDice(params)
      require 'cgiDiceBot.rb'

      message = params['message']
      gameType = params['gameType']
      isNeedResult = params['isNeedResult']

      @logger.debug(message, 'rollDice message')
      @logger.debug(gameType, 'rollDice gameType')

      bot = CgiDiceBot.new

      result, randResults = bot.roll(message, gameType, @dir, @diceBotTablePrefix, isNeedResult)

      result.gsub!(/＞/, '→')
      result.sub!(/\r?\n?\Z/m, '')

      @logger.debug(result, 'rollDice result')
      @logger.debug(randResults, 'rollDice randResults')

      return result, bot.isSecret, randResults
    end

    def getGameCommandInfos
      require 'cgiDiceBot.rb'
      bot = CgiDiceBot.new
      @logger.debug(@dir, 'dir')

      commandInfos = bot.getGameCommandInfos(@dir, @diceBotTablePrefix)
      @logger.debug(commandInfos, "getGameCommandInfos End commandInfos")

      return commandInfos
    end

    def getBotTableInfosFromDir
      @logger.debug(@dir, 'getBotTableInfosFromDir dir')

      require 'TableFileData'

      isLoadCommonTable = false
      tableFileData = TableFileData.new( isLoadCommonTable )
      tableFileData.setDir(@dir, @diceBotTablePrefix)
      tableInfos = tableFileData.getAllTableInfo

      @logger.debug(tableInfos, "getBotTableInfosFromDir tableInfos")
      tableInfos.sort!{|a, b| a["command"].to_i <=> b["command"].to_i}

      @logger.debug(tableInfos, 'getBotTableInfosFromDir result tableInfos')

      return tableInfos
    end

    def addBotTableMain(params)
      @logger.debug("addBotTableMain Begin")

      DodontoF::Utils.makeDir(@dir)

      require 'TableFileData'

      resultText = 'OK'
      begin
        creator = TableFileCreator.new(@dir, @diceBotTablePrefix, params)
        creator.execute
      rescue Exception => e
        @logger.exception(e)
        resultText = getLanguageKey( e.to_s )
      end

      @logger.debug(resultText, "addBotTableMain End resultText")

      return resultText
    end

    def changeBotTableMain(params)
      @logger.debug("changeBotTableMain Begin")

      require 'TableFileData'

      resultText = 'OK'
      begin
        creator = TableFileEditer.new(@dir, @diceBotTablePrefix, params)
        creator.execute
      rescue Exception => e
        @logger.exception(e)
        resultText = getLanguageKey( e.to_s )
      end

      @logger.debug(resultText, "changeBotTableMain End resultText")

      return resultText
    end

    def removeBotTableMain(params)
      @logger.debug("removeBotTableMain Begin")

      command = params["command"]

      require 'TableFileData'

      isLoadCommonTable = false
      tableFileData = TableFileData.new( isLoadCommonTable )
      tableFileData.setDir(@dir, @diceBotTablePrefix)
      tableInfos = tableFileData.getAllTableInfo

      tableInfo = tableInfos.find{|i| i["command"] == command}
      @logger.debug(tableInfo, "tableInfo")
      return if( tableInfo.nil? )

      fileName = tableInfo["fileName"]
      @logger.debug(fileName, "fileName")
      return if( fileName.nil? )

      @logger.debug("isFile exist?")
      return unless( File.exist?(fileName) )

      begin
        File.delete(fileName)
      rescue Exception => e
        @logger.exception(e)
      end

      @logger.debug("removeBotTableMain End")
    end
  end
end

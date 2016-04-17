#--*-coding:utf-8-*--

require 'dodontof/logger'

def initLog
  # ロガーのインスタンスが存在しなければ自動で生成され準備が行われる
  DodontoF::Logger.instance
end

def logging(obj, *options)
  logger = DodontoF::Logger.instance
  logger.debug(obj, *options)
end

def loggingForce(obj, *options)
  logger = DodontoF::Logger.instance
  logger.error(obj, *options)
end

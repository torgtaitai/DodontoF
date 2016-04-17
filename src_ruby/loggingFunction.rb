#--*-coding:utf-8-*--

require 'dodontof/logger'

def initLog
  logger = DodontoF::Logger.instance
  logger.
    reset.
    updateLevel
end

def logging(obj, *options)
  logger = DodontoF::Logger.instance
  logger.debug(obj, *options)
end

def loggingForce(obj, *options)
  logger = DodontoF::Logger.instance
  logger.error(obj, *options)
end

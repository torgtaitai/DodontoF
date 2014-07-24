#--*-coding:utf-8-*--

def initLog
  return unless( $log.nil? )
  
  $log = Logger.new($logFileName, $logFileMaxCount, $logFileMaxSize)
  $log.level = ( $debug ? Logger::DEBUG : Logger::ERROR )
  $log.level = Logger::FATAL if( $isModRuby )
end


def getLogMessageProc(obj, *options)
  message = obj.inspect.tosjis
  if( obj.instance_of?(String) )
    message = obj
  end
  return message = "#{options.join(',')}:#{message}"
end

def logging(obj, *options)
  return unless( $debug )
  
  $log.debug() do 
    getLogMessageProc(obj, *options)
  end
end

def loggingForce(obj, *options)
  $log.error() do 
    getLogMessageProc(obj, *options)
  end
end

def loggingTest(*args)
end

def debug(obj1, *obj2)
  logging(obj1, *obj2)
end

#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
require 'json/jsonParser'
require 'config'
require 'cgi'

if( $0 === __FILE__ )
  cgi = CGI.new
  params = cgi.params
  callBack = params['callback']
  
  jsonData = {
    :loginCount => File.readlines($loginCountFile).join.to_i,
    :maxLoginCount => $aboutMaxLoginCount,
    :version => $version,
  }
  
  text = JsonBuilder.new.build(jsonData)
  
  print( cgi.header )
  print( "#{callBack}(" + text + ");");
end

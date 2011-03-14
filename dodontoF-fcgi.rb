#!/usr/bin/ruby
#--*-coding:utf-8-*--
Encoding.default_external='utf-8'

#require 'rubygems'
require 'cgiPatch_forFirstCgi'
require 'fcgiwrap'

FCGIWrap.each do
   load '/var/www/lighttpd/D_DEV/DodontoFServer.rb'
   initLog();
#   $SAFE = 1
   main();
end

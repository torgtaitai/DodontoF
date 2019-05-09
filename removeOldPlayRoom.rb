#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--
$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

require 'DodontoFServer'

initLog();

#src_ruby/config.rbまたは、src_ruby/config_local.rb内の $removeOldPlayRoomLimitDays で指定された期間を経過した部屋を自動削除
#拡張機能→古いプレイルームを削除のUI操作をcronなどで自動化したい人向け
DodontoFServer.new(SaveDirInfo.new(),{"room" => 1}).removeOldPlayRoom

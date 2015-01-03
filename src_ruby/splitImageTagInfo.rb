#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--

Dir.chdir('..')

$LOAD_PATH << File.dirname(__FILE__) + "/src_ruby"
$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

require 'DodontoFServer'


class SplitImageTagInfo < DodontoFServer
  
  def initialize()
    super(SaveDirInfo.new(), {"room" => 1})
  end
  
  def split()
    
    localTags = {}
    
    oldFile = getImageInfoFileName(nil)
    
    print("split #{oldFile}\n")
    
    changeSaveData( oldFile ) do |saveData|
      tags = saveData['imageTags']
      tags ||= {}
      
      tags.each do |source, tagInfo|
        roomNo = tagInfo.delete("roomNumber")
        next if roomNo.nil?
        
        roomNo = roomNo.to_i
        
        localTags[roomNo] ||= []
        localTags[roomNo] << [source, tagInfo]
      end
      
      localTags.each do |roomNo, list|
        list.each do |data|
          source, tagInfo = data
          tags.delete(source)
        end
      end
    end
    
    
    localTags.keys.sort.each do |roomNo|
      
      list = localTags[roomNo]
      next if list.nil?
      
      @saveDirInfo.setSaveDataDirIndex(roomNo)
      newFile = getImageInfoFileName(roomNo)
      
      imageTags = {}
      
      list.each do |data|
        source, tagInfo = data
        imageTags[source] = tagInfo
      end
      
      changeSaveData( newFile ) do |saveData|
        saveData['imageTags'] = imageTags
      end
      
      print("create #{newFile}\n")
    end
    
    print("END\n")
  end
  
end

SplitImageTagInfo.new.split

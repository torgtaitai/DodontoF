# -*- coding: utf-8 -*-

require 'rake/clean'

Dir.glob('tasks/*.rake') do |rake_file|
  load(rake_file)
end

task :default => :test

CLOBBER.include('DodontoF.swf')

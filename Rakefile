require "rake/testtask"

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test_ruby/**/test*.rb']
end

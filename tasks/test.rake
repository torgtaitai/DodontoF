# -*- coding: utf-8 -*-

require 'rake/testtask'

Rake::TestTask.new(:test_libs) do |t|
  t.test_files = ['test_ruby/test*.rb', 'test_ruby/dodontof/**/test*.rb']
end

Rake::TestTask.new(:test_cgi) do |t|
  t.test_files = ['test_ruby/cgi/test*.rb']
end

desc 'すべてのテストを行う'
task :test do
  failures = []

  puts('[ライブラリのテスト]')
  begin
    Rake::Task['test_libs'].execute
  rescue
    failures << 'ライブラリ'
  end

  puts
  puts('[CGI のテスト]')
  begin
    Rake::Task['test_cgi'].execute
  rescue
    failures << 'CGI'
  end

  unless failures.empty?
    raise "テスト失敗: #{failures.join(', ')}"
  end
end

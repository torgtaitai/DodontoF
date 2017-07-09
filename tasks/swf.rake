# -*- coding: utf-8 -*-

desc 'SWF ファイルを作成する'
task :swf do
  mxmlc = 'mxmlc'
  options = [
    '-target-player=10.0.12',
    '-define=TEST::isTest,false',
    '-define=COMPILE::isReplayer,false',
    '-define=COMPILE::isMySql,false',
    '-include-libraries+=./corelib/bin/corelib.swc',
    '-o ../DodontoF.swf'
  ]
  input = 'DodontoF.mxml'
  command = ([mxmlc] + options + [input]).join(' ')

  Dir.chdir('src_actionScript') do
    sh(command)
  end
end

# -*- coding: utf-8 -*-

if RUBY_VERSION >= '1.9.2'
  require_relative 'zip_recursive'

  module DodontoFDist
    module_function

    # DodontoFServer.rbからどどんとふのバージョンを取得する
    # @param [String] dodontof_root どどんとふのルートディレクトリ
    # @return [String]
    def dodontof_version(dodontof_root)
      dodontof_server_rb = "#{dodontof_root}/DodontoFServer.rb"

      version = catch(:version_found) do
        File.open(dodontof_server_rb) do |f|
          version_pattern = /\A\s*VERSION\s*=\s*(?:'([.\d]+)'|"([.\d]+)")/
          while line = f.gets
            m = line.match(version_pattern)
            throw(:version_found, m[1] || m[2]) if m
          end
        end

        raise 'DodontoFServer.rbにバージョン情報が含まれていません'
      end

      version
    end

    # 現在のコミットIDを取得する
    # @param [String] dodontof_root どどんとふのルートディレクトリ
    # @return [String]
    def current_commit_id(dodontof_root)
      current_commit_id = Dir.chdir(dodontof_root) do
        `git log -1 --format='%h'`
      end

      if !current_commit_id || current_commit_id.empty?
        raise '現在のコミットIDの取得に失敗しました'
      end

      current_commit_id.chomp
    end
  end

  desc '配布アーカイブを作成する'
  task :dist do
    unless File.exist?('DodontoF.swf')
      Rake::Task['swf'].execute
    end

    dodontof_root = File.expand_path('..', File.dirname(__FILE__))

    version = DodontoFDist.dodontof_version(dodontof_root)
    current_commit_id = DodontoFDist.current_commit_id(dodontof_root)

    zip_filename_version = "DodontoF_Ver.#{version}.zip"
    zip_filename_commit_id = "DodontoF_#{current_commit_id}.zip"

    # 配布アーカイブに含めるファイルの準備
    mkdir_p('dist')
    Dir.chdir('dist') do
      rm_rf('DodontoF_WebSet')
      mkdir('DodontoF_WebSet')

      Dir.chdir('DodontoF_WebSet') do
        mkdir('public_html')

        Dir.chdir('public_html') do
          sh("git clone --recursive #{dodontof_root}/.git DodontoF")

          Dir.chdir('DodontoF') do
            sh("git checkout -b dist #{current_commit_id}")

            cp("#{dodontof_root}/DodontoF.swf", '.')
            mv('imageUploadSpace', '..')
            mv('saveData', '../..')

            zf_src_actionScript =
              ZipFileGenerator.new('src_actionScript', 'src_actionScript.zip')
            zf_src_actionScript.write

            rm_rf(Dir.glob('.git*') + ['dist', 'src_actionScript', 'README.md'])
          end

          Dir.chdir('imageUploadSpace') do
            mkdir('public')
          end
        end
      end

      puts
      puts("[配布アーカイブのファイル名]")
      puts("バージョン (v): #{zip_filename_version}")
      puts("コミットID (c): #{zip_filename_commit_id}")

      zip_filename = nil
      loop do
        print('どちらのファイル名で保存しますか? [V/c] > ')

        line = $stdin.gets
        abort unless line

        case line.chomp
        when '', 'V', 'v'
          zip_filename = zip_filename_version
          break
        when 'C', 'c'
          zip_filename = zip_filename_commit_id
          break
        end
      end

      rm_rf(zip_filename)

      zf_dodontof = ZipFileGenerator.new('DodontoF_WebSet', zip_filename)
      zf_dodontof.write
    end
  end
end

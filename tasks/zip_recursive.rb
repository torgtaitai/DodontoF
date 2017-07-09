# -*- coding: utf-8 -*-

# Original: https://github.com/rubyzip/rubyzip/blob/2569a655fe1c241dfdcea9d871d2fb676a9d4b85/README.md

require 'zip'

# This is a simple example which uses rubyzip to
# recursively generate a zip file from the contents of
# a specified directory. The directory itself is not
# included in the archive, rather just its contents.
#
# Usage:
#   directory_to_zip = "/tmp/input"
#   output_file = "/tmp/out.zip"
#   zf = ZipFileGenerator.new(directory_to_zip, output_file)
#   zf.write()
class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  # Zip the input directory.
  def write
    ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |io|
      write_entries([@input_dir], '', io)
    end

    puts("ZIPファイル生成完了: #{@output_file}")
  end

  private

  # A helper method to make the recursion work.
  def write_entries(entries, path, io)
    entries.each do |e|
      zip_file_path = path == '' ? e : File.join(path, e)

      if File.directory?(zip_file_path)
        recursively_deflate_directory(zip_file_path, io)
      else
        put_into_archive(zip_file_path, io)
      end
    end
  end

  def recursively_deflate_directory(zip_file_path, io)
    io.mkdir(zip_file_path)
    subdir = Dir.entries(zip_file_path) - %w(. ..)
    write_entries(subdir, zip_file_path, io)
  end

  def put_into_archive(zip_file_path, io)
    io.get_output_stream(zip_file_path) do |f|
      f.write(File.open(zip_file_path, 'rb').read)
    end
  end
end

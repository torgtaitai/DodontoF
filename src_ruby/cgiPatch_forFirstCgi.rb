#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'cgi'
require 'fileutils'

# FastCGI環境下でSTDIN読込時にシステムコールエラーが発生するための対策
class CGI
   module QueryExtension

    undef :read_multipart   
    def read_multipart(boundary, content_length)
      ## read first boundary
#      stdin = $stdin # $stdinに直アクセスでシステムエラーを吐く
      stdin = stdinput
      first_line = "--#{boundary}#{EOL}"
      content_length -= first_line.bytesize
      status = stdin.read(first_line.bytesize)
      raise EOFError.new("no content body")  unless status
      raise EOFError.new("bad content body") unless first_line == status
      ## parse and set params
      params = {}
      @files = {}
      boundary_rexp = /--#{Regexp.quote(boundary)}(#{EOL}|--)/
      boundary_size = "#{EOL}--#{boundary}#{EOL}".bytesize
      boundary_end  = nil
      buf = ''
      bufsize = 10 * 1024
      max_count = MAX_MULTIPART_COUNT
      n = 0
      while true
        (n += 1) < max_count or raise StandardError.new("too many parameters.")
        ## create body (StringIO or Tempfile)
#        body = create_body(bufsize < content_length) #TempFileが上手く生成されていないので全てStringIO経由で受け取る
        body = create_body(false)
        class << body
          if method_defined?(:path)
            alias local_path path
          else
            def local_path
              nil
            end
          end
          attr_reader :original_filename, :content_type
        end
        ## find head and boundary
        head = nil
        separator = EOL * 2
        until head && matched = boundary_rexp.match(buf)
          if !head && pos = buf.index(separator)
            len  = pos + EOL.bytesize
            head = buf[0, len]
            buf  = buf[(pos+separator.bytesize)..-1]
          else
            if head && buf.size > boundary_size
              len = buf.size - boundary_size
              body.print(buf[0, len])
              buf[0, len] = ''
            end
            c = stdin.read(bufsize < content_length ? bufsize : content_length)
            raise EOFError.new("bad content body") if c.nil? || c.empty?
            buf << c
            content_length -= c.bytesize
          end
        end
        ## read to end of boundary
        m = matched
        len = m.begin(0)
        s = buf[0, len]
        if s =~ /(\r?\n)\z/
          s = buf[0, len - $1.bytesize]
        end
        body.print(s)
        buf = buf[m.end(0)..-1]
        boundary_end = m[1]
        content_length = -1 if boundary_end == '--'
        ## reset file cursor position
        body.rewind
        ## original filename
        /Content-Disposition:.* filename=(?:"(.*?)"|([^;\r\n]*))/i.match(head)
        filename = $1 || $2 || ''
        filename = CGI.unescape(filename) if unescape_filename?()
        body.instance_variable_set('@original_filename', filename.taint)
        ## content type
        /Content-Type: (.*)/i.match(head)
        (content_type = $1 || '').chomp!
        body.instance_variable_set('@content_type', content_type.taint)
        ## query parameter name
        /Content-Disposition:.* name=(?:"(.*?)"|([^;\r\n]*))/i.match(head)
        name = $1 || $2 || ''
        if body.original_filename.empty?
          value=body.read.dup.force_encoding(@accept_charset)
          (params[name] ||= []) << value
          unless value.valid_encoding?
            if @accept_charset_error_block
              @accept_charset_error_block.call(name,value)
            else
              raise InvalidEncoding,"Accept-Charset encoding error"
            end
          end
          class << params[name].last;self;end.class_eval do
            define_method(:read){self}
            define_method(:original_filename){""}
            define_method(:content_type){""}
          end
        else
          (params[name] ||= []) << body
          @files[name]=body
          #FileUtils.cp(body, '/tmp',{:verbose => true, :preserve =>true}) if body.is_a(TmpFile)         
        end
        ## break loop
        break if buf.size == 0
        break if content_length == -1
      end
      raise EOFError, "bad boundary end of body part" unless boundary_end =~ /--/
      params.default = []
      params
    end # read_multipart
   end
end

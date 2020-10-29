#!/usr/bin/env ruby
# encoding: utf-8
# Spreadsheet::Encoding -- spreadheet -- 07.09.2011 -- mhatakeyama@ywesee.com
# Spreadsheet::Encoding -- spreadheet -- 03.07.2009 -- hwyss@ywesee.com

module Spreadsheet
  ##
  # Methods for Encoding-conversions. You should not need to use any of these.
  module Encodings
    if RUBY_VERSION >= '1.9'
      def client string, internal='UTF-16LE'
        string = string.dup
        string.force_encoding internal
        string.encode Spreadsheet.client_encoding
      end
      def internal string, client=Spreadsheet.client_encoding
        string = string.dup
        string.force_encoding client
        string.encode('UTF-16LE').force_encoding('ASCII-8BIT')
      end
      def utf8 string, client=Spreadsheet.client_encoding
        string = string.dup
        string.force_encoding client
        string.encode('UTF-8')
      end
    else
      require 'iconv'
      @@iconvs = {}

      def build_output_encoding(to_encoding)
        [to_encoding, Spreadsheet.enc_translit, Spreadsheet.enc_ignore].compact.join('//')
      end

      def client string, internal='UTF-16LE'
        string = string.dup
        key = [Spreadsheet.client_encoding, internal]
        iconv = @@iconvs[key] ||= Iconv.new(Spreadsheet.client_encoding, internal)
        iconv.iconv string
      end
      def internal string, client=Spreadsheet.client_encoding, to_encoding = 'UTF-16LE'
        string = string.dup
        key = [to_encoding, client]
        iconv = @@iconvs[key] ||= Iconv.new(build_output_encoding(to_encoding), client)
        iconv.iconv string
      end
      def utf8 string, client=Spreadsheet.client_encoding, to_encoding = 'UTF-8'
        string = string.dup
        key = [to_encoding, client]
        iconv = @@iconvs[key] ||= Iconv.new(build_output_encoding(to_encoding), client)
        iconv.iconv string
      end
    end
  rescue LoadError
    warn "You don't have Iconv support compiled in your Ruby. Spreadsheet may not work as expected"
    def client string, internal='UTF-16LE'
      string.delete "\0"
    end
    def internal string, internal='UTF-16LE'
      string.split('').zip(Array.new(string.size, 0.chr)).join
    end
  end
end


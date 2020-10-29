# frozen_string_literal: true

# pdf_object.rb : Handles Ruby to PDF object serialization
#
# Copyright April 2008, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

# Top level Module
#
module PDF
  module Core
    module_function

    def real(num)
      num.to_f.round(4)
    end

    def real_params(array)
      array.map { |e| real(e) }.join(' ')
    end

    def utf8_to_utf16(str)
      (+"\xFE\xFF").force_encoding(::Encoding::UTF_16BE) +
        str.encode(::Encoding::UTF_16BE)
    end

    # encodes any string into a hex representation. The result is a string
    # with only 0-9 and a-f characters. That result is valid ASCII so tag
    # it as such to account for behaviour of different ruby VMs
    def string_to_hex(str)
      str.unpack('H*').first.force_encoding(::Encoding::US_ASCII)
    end

    # Serializes Ruby objects to their PDF equivalents.  Most primitive objects
    # will work as expected, but please note that Name objects are represented
    # by Ruby Symbol objects and Dictionary objects are represented by Ruby
    # hashes (keyed by symbols)
    #
    #  Examples:
    #
    #     pdf_object(true)      #=> "true"
    #     pdf_object(false)     #=> "false"
    #     pdf_object(1.2124)    #=> "1.2124"
    #     pdf_object('foo bar') #=> "(foo bar)"
    #     pdf_object(:Symbol)   #=> "/Symbol"
    #     pdf_object(['foo',:bar, [1,2]]) #=> "[foo /bar [1 2]]"
    #
    def pdf_object(obj, in_content_stream = false)
      case obj
      when NilClass   then 'null'
      when TrueClass  then 'true'
      when FalseClass then 'false'
      when Numeric
        obj = real(obj) unless obj.is_a?(Integer)

        # NOTE: this can fail on huge floating point numbers, but it seems
        # unlikely to ever happen in practice.
        num_string = String(obj)

        # Truncate trailing fraction zeroes
        num_string.sub(/(\d*)((\.0*$)|(\.0*[1-9]*)0*$)/, '\1\4')
      when Array
        '[' + obj.map { |e| pdf_object(e, in_content_stream) }.join(' ') + ']'
      when PDF::Core::LiteralString
        obj = obj.gsub(/[\\\n\r\t\b\f\(\)]/) { |m| "\\#{m}" }
        "(#{obj})"
      when Time
        obj = obj.strftime('D:%Y%m%d%H%M%S%z').chop.chop + "'00'"
        obj = obj.gsub(/[\\\n\r\t\b\f\(\)]/) { |m| "\\#{m}" }
        "(#{obj})"
      when PDF::Core::ByteString
        "<#{obj.unpack('H*').first}>"
      when String
        obj = utf8_to_utf16(obj) unless in_content_stream
        "<#{string_to_hex(obj)}>"
      when Symbol
        '/' + obj.to_s.unpack('C*').map do |n|
          if n < 33 || n > 126 || [35, 40, 41, 47, 60, 62].include?(n)
            '#' + n.to_s(16).upcase
          else
            [n].pack('C*')
          end
        end.join
      when ::Hash
        output = +'<< '
        obj.each do |k, v|
          unless k.is_a?(String) || k.is_a?(Symbol)
            raise PDF::Core::Errors::FailedObjectConversion,
              'A PDF Dictionary must be keyed by names'
          end
          output << pdf_object(k.to_sym, in_content_stream) << ' ' <<
            pdf_object(v, in_content_stream) << "\n"
        end
        output << '>>'
      when PDF::Core::Reference
        obj.to_s
      when PDF::Core::NameTree::Node
        pdf_object(obj.to_hash)
      when PDF::Core::NameTree::Value
        pdf_object(obj.name) + ' ' + pdf_object(obj.value)
      when PDF::Core::OutlineRoot, PDF::Core::OutlineItem
        pdf_object(obj.to_hash)
      else
        raise PDF::Core::Errors::FailedObjectConversion,
          "This object cannot be serialized to PDF (#{obj.inspect})"
      end
    end
  end
end

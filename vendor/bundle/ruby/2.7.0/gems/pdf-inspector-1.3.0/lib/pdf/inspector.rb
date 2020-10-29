require 'rubygems'
require 'pdf/reader'
require 'pdf/inspector/text'
require 'pdf/inspector/xobject'
require 'pdf/inspector/extgstate'
require 'pdf/inspector/graphics'
require 'pdf/inspector/page'
require 'stringio'

module PDF
  class Inspector
    def self.analyze(output, *args, &block)
      if output.is_a?(String)
        output = StringIO.new(output)
      end
      obs = new(*args, &block)
      PDF::Reader.open(output) do |reader|
        reader.pages.each do |page|
          page.walk(obs)
        end
      end
      obs
    end

    def self.analyze_file(filename, *args, &block)
      File.open(filename, 'rb') do |io|
        analyze(io, *args, &block)
      end
    end

    def self.parse(obj)
      PDF::Reader::Parser.new(
        PDF::Reader::Buffer.new(StringIO.new(obj)),
        nil
      ).parse_token
    end
  end
end

# frozen_string_literal: true

module Plaintext
  # Handler base class for XML based (MS / Open / Libre) office documents.
  class ZippedXmlHandler < FileHandler
    require 'zip'
    require 'nokogiri'

    class SaxDocument < Nokogiri::XML::SAX::Document
      attr_reader :text

      def initialize(text_element, text_namespace, max_size = nil)
        @element = text_element
        @namespace_uri = text_namespace
        @max_size = max_size

        @text = ''.dup
        @is_text = false
      end

      def text_length_exceeded?
        @max_size && (@text.length > @max_size)
      end


      # Handle each element, expecting the name and any attributes
      def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
        if name == @element and
            uri == @namespace_uri and
            !text_length_exceeded?

          @is_text = true
        end
      end

      # Any characters between the start and end element expected as a string
      def characters(string)
        @text << string if @is_text
      end

      # Given the name of an element once its closing tag is reached
      def end_element_namespace(name, prefix = nil, uri = nil)
        if name == @element and
            uri == @namespace_uri and
            @is_text

          @text << ' '
          @is_text = false
        end
      end
    end

    def text(file, options = {})
      max_size = options[:max_size]
      Zip::File.open(file) do |zip_file|
        zip_file.each do |entry|
          if entry.name == @file_name
            return xml_to_text entry.get_input_stream, max_size
          end
        end
      end
    end

    private

    def xml_to_text(io, max_size)
      sax_doc = SaxDocument.new @element, @namespace_uri, max_size
      Nokogiri::XML::SAX::Parser.new(sax_doc).parse(io)
      text = sax_doc.text
      max_size.present? ? text[0, max_size] : text
    end
  end
end

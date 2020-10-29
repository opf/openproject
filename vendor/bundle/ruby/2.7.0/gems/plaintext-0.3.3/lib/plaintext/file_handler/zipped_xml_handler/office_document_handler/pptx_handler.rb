# frozen_string_literal: true

module Plaintext
  class PptxHandler < OfficeDocumentHandler
    CONTENT_TYPES = [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
        'application/vnd.ms-powerpoint.template.macroEnabled.12'
    ]

    def initialize
      super
      @content_types = CONTENT_TYPES
      @namespace_uri = 'http://schemas.openxmlformats.org/drawingml/2006/main'
    end

    def text(file, options = {})
      max_size = options[:max_size]
      slides = []
      result = ''.dup
      Zip::File.open(file) do |zip_file|
        zip_file.each do |entry|
          if entry.name =~ /slide(\d+)\.xml/
            slides << [$1, entry]
          end
        end

        slides.sort!{|a, b| a.first <=> b.first}
        slides.each do |id, entry|
          result << xml_to_text(entry.get_input_stream, max_size)
          break if max_size and result.length >= max_size
        end
      end
      return result
    end
  end
end

# frozen_string_literal: true

module Prawn
  module Markup
    module Builders
      class NestableBuilder
        TEXT_STYLE_OPTIONS = %i[font size style font_style color text_color
                                kerning leading align min_font_size overflow rotate
                                rotate_around single_line valign].freeze

        def initialize(pdf, total_width, options = {})
          @pdf = pdf
          @total_width = total_width
          @options = options
        end

        private

        attr_reader :pdf, :total_width, :options

        def normalize_cell_hash(hash, cell_width, style_options = {})
          if hash.key?(:image)
            compute_image_width(hash, cell_width)
          else
            style_options.merge(hash)
          end
        end

        def text_options
          (options[:text] || {})
        end

        def compute_image_width(hash, max_width)
          hash.dup.tap do |image_hash|
            image_hash.delete(:width)
            image_hash[:image_width] = SizeConverter.new(max_width).parse(hash[:width])
            if max_width
              natural_width, _height = natural_image_dimensions(image_hash)
              image_hash[:fit] = [max_width, 999_999] if max_width < natural_width
            end
          end
        end

        def natural_image_dimensions(hash)
          _obj, info = pdf.build_image_object(hash[:image])
          info.calc_image_dimensions(width: hash[:image_width])
        end

        def extract_text_cell_style(hash)
          TEXT_STYLE_OPTIONS
            .each_with_object({}) { |key, h| h[key] = hash[key] }
            .tap { |options| convert_style_options(options) }
        end

        def convert_style_options(hash)
          hash[:font_style] ||= hash.delete(:style)
          hash[:text_color] ||= hash.delete(:color)
        end

        def type_key(object)
          path = object.class.name.to_s
          i = path.rindex('::')
          if i
            path[(i + 2)..-1].downcase
          else
            path.downcase
          end
        end
      end
    end
  end
end

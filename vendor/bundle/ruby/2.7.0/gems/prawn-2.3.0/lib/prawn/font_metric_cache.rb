# frozen_string_literal: true

# font_metric_cache.rb : The Prawn font class
#
# Copyright Dec 2012, Kenneth Kalmer. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#

module Prawn
  # Cache used internally by Prawn::Document instances to calculate the width
  # of various strings for layout purposes.
  #
  # @private
  class FontMetricCache
    CacheEntry = Struct.new(:font, :options, :string)

    def initialize(document)
      @document = document

      @cache = {}
    end

    def width_of(string, options)
      f = if options[:style]
            # override style with :style => :bold
            @document.find_font(@document.font.family, style: options[:style])
          else
            @document.font
          end

      encoded_string = f.normalize_encoding(string)

      key = CacheEntry.new(f, options, encoded_string)

      @cache[key] ||= f.compute_width_of(encoded_string, options)

      length = @cache[key]

      character_count = @document.font.character_count(encoded_string)
      if character_count.positive?
        length += @document.character_spacing * (character_count - 1)
      end

      length
    end
  end
end

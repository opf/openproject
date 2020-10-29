# encoding: utf-8

# image.rb: Table image cells.
#
# Copyright September 2010, Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
module Prawn
  class Table
    class Cell

      # @private
      class Image < Cell

        def initialize(pdf, point, options={})
          @image_options = {}
          super

          @pdf_object, @image_info = @pdf.build_image_object(@file)
          @natural_width, @natural_height = @image_info.calc_image_dimensions(
            @image_options)
        end

        def image=(file)
          @file = file
        end

        def scale=(s)
          @image_options[:scale] = s
        end

        def fit=(f)
          @image_options[:fit] = f
        end

        def image_height=(h)
          @image_options[:height] = h
        end

        def image_width=(w)
          @image_options[:width] = w
        end

        def position=(p)
          @image_options[:position] = p
        end

        def vposition=(vp)
          @image_options[:vposition] = vp
        end

        def natural_content_width
          @natural_width
        end

        def natural_content_height
          @natural_height
        end

        # Draw the image on the page.
        #
        def draw_content
          @pdf.embed_image(@pdf_object, @image_info, @image_options)
        end

      end
    end
  end
end

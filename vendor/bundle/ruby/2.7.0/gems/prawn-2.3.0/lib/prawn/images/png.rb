# encoding: ASCII-8BIT

# frozen_string_literal: true

# png.rb : Extracts the data from a PNG that is needed for embedding
#
# Based on some similar code in PDF::Writer by Austin Ziegler
#
# Copyright April 2008, James Healy.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'stringio'
module Prawn
  module Images
    # A convenience class that wraps the logic for extracting the parts
    # of a PNG image that we need to embed them in a PDF
    #
    class PNG < Image
      # @group Extension API

      attr_reader :palette, :img_data, :transparency
      attr_reader :width, :height, :bits
      attr_reader :color_type, :compression_method, :filter_method
      attr_reader :interlace_method, :alpha_channel
      attr_accessor :scaled_width, :scaled_height

      def self.can_render?(image_blob)
        image_blob[0, 8].unpack('C*') == [137, 80, 78, 71, 13, 10, 26, 10]
      end

      # Process a new PNG image
      #
      # <tt>data</tt>:: A binary string of PNG data
      #
      def initialize(data)
        data = StringIO.new(data.dup)

        data.read(8) # Skip the default header

        @palette = +''
        @img_data = +''
        @transparency = {}

        loop do
          chunk_size = data.read(4).unpack1('N')
          section = data.read(4)
          case section
          when 'IHDR'
            # we can grab other interesting values from here (like width,
            # height, etc)
            values = data.read(chunk_size).unpack('NNCCCCC')

            @width = values[0]
            @height = values[1]
            @bits = values[2]
            @color_type = values[3]
            @compression_method = values[4]
            @filter_method = values[5]
            @interlace_method = values[6]
          when 'PLTE'
            @palette << data.read(chunk_size)
          when 'IDAT'
            @img_data << data.read(chunk_size)
          when 'tRNS'
            # This chunk can only occur once and it must occur after the
            # PLTE chunk and before the IDAT chunk
            @transparency = {}
            case @color_type
            when 3
              @transparency[:palette] = data.read(chunk_size).unpack('C*')
            when 0
              # Greyscale. Corresponding to entries in the PLTE chunk.
              # Grey is two bytes, range 0 .. (2 ^ bit-depth) - 1
              grayval = data.read(chunk_size).unpack1('n')
              @transparency[:grayscale] = grayval
            when 2
              # True colour with proper alpha channel.
              @transparency[:rgb] = data.read(chunk_size).unpack('nnn')
            end
          when 'IEND'
            # we've got everything we need, exit the loop
            break
          else
            # unknown (or un-important) section, skip over it
            data.seek(data.pos + chunk_size)
          end

          data.read(4) # Skip the CRC
        end

        @img_data = Zlib::Inflate.inflate(@img_data)
      end

      # number of color components to each pixel
      #
      def colors
        case color_type
        when 0, 3, 4
          1
        when 2, 6
          3
        end
      end

      # split the alpha channel data from the raw image data in images
      # where it's required.
      #
      def split_alpha_channel!
        if alpha_channel?
          if color_type == 3
            generate_alpha_channel
          else
            split_image_data
          end
        end
      end

      def alpha_channel?
        return true if color_type == 4 || color_type == 6
        return @transparency.any? if color_type == 3

        false
      end

      # Build a PDF object representing this image in +document+, and return
      # a Reference to it.
      #
      def build_pdf_object(document)
        if compression_method != 0
          raise Errors::UnsupportedImageType,
            'PNG uses an unsupported compression method'
        end

        if filter_method != 0
          raise Errors::UnsupportedImageType,
            'PNG uses an unsupported filter method'
        end

        if interlace_method != 0
          raise Errors::UnsupportedImageType,
            'PNG uses unsupported interlace method'
        end

        # some PNG types store the colour and alpha channel data together,
        # which the PDF spec doesn't like, so split it out.
        split_alpha_channel!

        case colors
        when 1
          color = :DeviceGray
        when 3
          color = :DeviceRGB
        else
          raise Errors::UnsupportedImageType,
            "PNG uses an unsupported number of colors (#{png.colors})"
        end

        # build the image dict
        obj = document.ref!(
          Type: :XObject,
          Subtype: :Image,
          Height: height,
          Width: width,
          BitsPerComponent: bits
        )

        # append the actual image data to the object as a stream
        obj << img_data

        obj.stream.filters << {
          FlateDecode: {
            Predictor: 15,
            Colors: colors,
            BitsPerComponent: bits,
            Columns: width
          }
        }

        # sort out the colours of the image
        if palette.empty?
          obj.data[:ColorSpace] = color
        else
          # embed the colour palette in the PDF as a object stream
          palette_obj = document.ref!({})
          palette_obj << palette

          # build the color space array for the image
          obj.data[:ColorSpace] = [
            :Indexed,
            :DeviceRGB,
            (palette.size / 3) - 1,
            palette_obj
          ]
        end

        # *************************************
        # add transparency data if necessary
        # *************************************

        # For PNG color types 0, 2 and 3, the transparency data is stored in
        # a dedicated PNG chunk, and is exposed via the transparency attribute
        # of the PNG class.
        if transparency[:grayscale]
          # Use Color Key Masking (spec section 4.8.5)
          # - An array with N elements, where N is two times the number of color
          #   components.
          val = transparency[:grayscale]
          obj.data[:Mask] = [val, val]
        elsif transparency[:rgb]
          # Use Color Key Masking (spec section 4.8.5)
          # - An array with N elements, where N is two times the number of color
          #   components.
          rgb = transparency[:rgb]
          obj.data[:Mask] = rgb.collect { |x| [x, x] }.flatten
        end

        # For PNG color types 4 and 6, the transparency data is stored as
        # a alpha channel mixed in with the main image data. The PNG class
        # seperates it out for us and makes it available via the alpha_channel
        # attribute
        if alpha_channel?
          smask_obj = document.ref!(
            Type: :XObject,
            Subtype: :Image,
            Height: height,
            Width: width,
            BitsPerComponent: bits,
            ColorSpace: :DeviceGray,
            Decode: [0, 1]
          )
          smask_obj.stream << alpha_channel

          smask_obj.stream.filters << {
            FlateDecode: {
              Predictor: 15,
              Colors: 1,
              BitsPerComponent: bits,
              Columns: width
            }
          }
          obj.data[:SMask] = smask_obj
        end

        obj
      end

      # Returns the minimum PDF version required to support this image.
      def min_pdf_version
        if bits > 8
          # 16-bit color only supported in 1.5+ (ISO 32000-1:2008 8.9.5.1)
          1.5
        elsif alpha_channel?
          # Need transparency for SMask
          1.4
        else
          1.0
        end
      end

      private

      def split_image_data
        alpha_bytes = bits / 8
        color_bytes = colors * bits / 8

        scanline_length = (color_bytes + alpha_bytes) * width + 1
        scanlines = @img_data.bytesize / scanline_length
        pixels = width * height

        data = StringIO.new(@img_data)
        data.binmode

        color_data = [0x00].pack('C') * (pixels * color_bytes + scanlines)
        color = StringIO.new(color_data)
        color.binmode

        @alpha_channel = [0x00].pack('C') * (pixels * alpha_bytes + scanlines)
        alpha = StringIO.new(@alpha_channel)
        alpha.binmode

        scanlines.times do |line|
          data.seek(line * scanline_length)

          filter = data.getbyte

          color.putc filter
          alpha.putc filter

          width.times do
            color.write data.read(color_bytes)
            alpha.write data.read(alpha_bytes)
          end
        end

        @img_data = color_data
      end

      def generate_alpha_channel
        alpha_palette = Hash.new(0xff)
        0.upto(palette.bytesize / 3) do |n|
          alpha_palette[n] = @transparency[:palette][n] || 0xff
        end

        scanline_length = width + 1
        scanlines = @img_data.bytesize / scanline_length
        pixels = width * height

        data = StringIO.new(@img_data)
        data.binmode

        @alpha_channel = [0x00].pack('C') * (pixels + scanlines)
        alpha = StringIO.new(@alpha_channel)
        alpha.binmode

        scanlines.times do |line|
          data.seek(line * scanline_length)

          filter = data.getbyte

          alpha.putc filter

          width.times do
            color = data.read(1).unpack1('C')
            alpha.putc alpha_palette[color]
          end
        end
      end
    end
  end
end

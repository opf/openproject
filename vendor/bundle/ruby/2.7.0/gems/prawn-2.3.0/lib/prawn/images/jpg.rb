# encoding: ASCII-8BIT

# frozen_string_literal: true

# jpg.rb : Extracts the data from a JPG that is needed for embedding
#
# Copyright April 2008, James Healy.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'stringio'

module Prawn
  module Images
    # A convenience class that wraps the logic for extracting the parts
    # of a JPG image that we need to embed them in a PDF
    #
    class JPG < Image
      # @group Extension API

      attr_reader :width, :height, :bits, :channels
      attr_accessor :scaled_width, :scaled_height

      JPEG_SOF_BLOCKS = [
        0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE,
        0xCF
      ].freeze

      def self.can_render?(image_blob)
        image_blob[0, 3].unpack('C*') == [255, 216, 255]
      end

      # Process a new JPG image
      #
      # <tt>:data</tt>:: A binary string of JPEG data
      #
      def initialize(data)
        @data = data
        d = StringIO.new(@data)
        d.binmode

        c_marker = 0xff # Section marker.
        d.seek(2) # Skip the first two bytes of JPEG identifier.
        loop do
          marker, code, length = d.read(4).unpack('CCn')
          raise 'JPEG marker not found!' if marker != c_marker

          if JPEG_SOF_BLOCKS.include?(code)
            @bits, @height, @width, @channels = d.read(6).unpack('CnnC')
            break
          end

          d.seek(length - 2, IO::SEEK_CUR)
        end
      end

      # Build a PDF object representing this image in +document+, and return
      # a Reference to it.
      #
      def build_pdf_object(document)
        color_space =
          case channels
          when 1
            :DeviceGray
          when 3
            :DeviceRGB
          when 4
            :DeviceCMYK
          else
            raise ArgumentError, 'JPG uses an unsupported number of channels'
          end

        obj = document.ref!(
          Type: :XObject,
          Subtype: :Image,
          ColorSpace: color_space,
          BitsPerComponent: bits,
          Width: width,
          Height: height
        )

        # add extra decode params for CMYK images. By swapping the
        # min and max values from the default, we invert the colours. See
        # section 4.8.4 of the spec.
        if color_space == :DeviceCMYK
          obj.data[:Decode] = [1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0]
        end

        obj.stream << @data
        obj.stream.filters << :DCTDecode
        obj
      end
    end
  end
end

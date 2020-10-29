# frozen_string_literal: true

# ImageHandler provides a way to register image processors with Prawn
#
# Contributed by Evan Sharp in November 2013.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  # @group Extension API

  def self.image_handler
    @image_handler ||= ImageHandler.new
  end

  class ImageHandler
    def initialize
      @handlers = []
    end

    def register(handler)
      @handlers.delete(handler)
      @handlers.push handler
    end

    def register!(handler)
      @handlers.delete(handler)
      @handlers.unshift handler
    end

    def unregister(handler)
      @handlers.reject! { |h| h == handler }
    end

    def find(image_blob)
      handler = @handlers.find { |h| h.can_render? image_blob }

      return handler if handler

      raise Prawn::Errors::UnsupportedImageType,
        'image file is an unrecognised format'
    end
  end
end

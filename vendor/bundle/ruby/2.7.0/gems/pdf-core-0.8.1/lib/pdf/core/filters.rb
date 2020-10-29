# frozen_string_literal: true

# prawn/core/filters.rb : Implements stream filters
#
# Copyright February 2013, Alexander Mankuta.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'zlib'

module PDF
  module Core
    module Filters
      module FlateDecode
        def self.encode(stream, _params = nil)
          Zlib::Deflate.deflate(stream)
        end

        def self.decode(stream, _params = nil)
          Zlib::Inflate.inflate(stream)
        end
      end

      # Pass through stub
      module DCTDecode
        def self.encode(stream, _params = nil)
          stream
        end

        def self.decode(stream, _params = nil)
          stream
        end
      end
    end
  end
end

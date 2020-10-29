# frozen_string_literal: true

module Grape
  module ServeFile
    CHUNK_SIZE = 16_384

    # Class helps send file through API
    class FileBody
      attr_reader :path

      # @param path [String]
      def initialize(path)
        @path = path
      end

      # Need for Rack::Sendfile middleware
      #
      # @return [String]
      def to_path
        path
      end

      def each
        File.open(path, 'rb') do |file|
          while (chunk = file.read(CHUNK_SIZE))
            yield chunk
          end
        end
      end

      def ==(other)
        path == other.path
      end
    end
  end
end

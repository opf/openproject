# frozen_string_literal: true

module Grape
  module ServeFile
    # A simple class used to identify responses which represent files and do not
    # need to be formatted or pre-read by Rack::Response
    class FileResponse
      attr_reader :file

      # @param file [Object]
      def initialize(file)
        @file = file
      end

      # Equality provided mostly for tests.
      #
      # @return [Boolean]
      def ==(other)
        file == other.file
      end
    end
  end
end

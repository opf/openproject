# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # Implementation for parameters that are multipart file objects.
      # Actual handling of these objects is provided by +Rack::Request+;
      # this class is here only to assert that rack's handling has succeeded.
      class File
        class << self
          def parse(input)
            return if input.nil?
            return InvalidValue.new unless parsed?(input)

            # Processing of multipart file objects
            # is already taken care of by Rack::Request.
            # Nothing to do here.
            input
          end

          def parsed?(value)
            # Rack::Request creates a Hash with filename,
            # content type and an IO object. Do a bit of basic
            # duck-typing.
            value.is_a?(::Hash) && value.key?(:tempfile) && value[:tempfile].is_a?(Tempfile)
          end
        end
      end
    end
  end
end

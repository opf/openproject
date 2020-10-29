module Crowdin
  class API

    module Errors
      class Error < StandardError
        attr_reader :error_code
        attr_reader :error_message
        attr_reader :message

        def initialize(error_code, error_message)
          @error_code    = error_code.to_i
          @error_message = error_message
          @message = "#{error_code}: #{error_message}"
        end

        def to_s
          @message
        end
      end
    end

  end
end

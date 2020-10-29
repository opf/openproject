# frozen_string_literal: true

module Grape
  module ServeFile
    # Response should respond to to_path method
    # for using Rack::SendFile middleware
    class SendfileResponse < Rack::Response
      def respond_to?(method_name, include_all = false)
        if method_name == :to_path
          @body.respond_to?(:to_path, include_all)
        else
          super
        end
      end

      def to_path
        @body.to_path
      end
    end
  end
end

# frozen_string_literal: true

module Airbrake
  module Rails
    # Allows measuring request timing.
    module CurlEasy
      def http(verb)
        Airbrake::Rack.capture_timing(:http) do
          super(verb)
        end
      end

      def perform(&block)
        Airbrake::Rack.capture_timing(:http) do
          super(&block)
        end
      end
    end

    # Allows measuring request timing.
    module CurlMulti
      def http(urls_with_config, multi_options = {}, &block)
        Airbrake::Rack.capture_timing(:http) do
          super(urls_with_config, multi_options, &block)
        end
      end
    end
  end
end

Curl::Easy.prepend(Airbrake::Rails::CurlEasy)
Curl::Multi.singleton_class.prepend(Airbrake::Rails::CurlMulti)

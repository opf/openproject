# frozen_string_literal: true

module Airbrake
  module Rails
    # Allow measuring request timing.
    module TyphoeusRequest
      def run
        Airbrake::Rack.capture_timing(:http) do
          super
        end
      end
    end
  end
end

Typhoeus::Request.prepend(Airbrake::Rails::TyphoeusRequest)

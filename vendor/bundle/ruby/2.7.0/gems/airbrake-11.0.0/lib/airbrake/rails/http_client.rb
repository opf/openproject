# frozen_string_literal: true

module Airbrake
  module Rails
    # Allows measuring request timing.
    module HTTPClient
      def do_get_block(request, proxy, connection, &block)
        Airbrake::Rack.capture_timing(:http) do
          super(request, proxy, connection, &block)
        end
      end
    end
  end
end

HTTPClient.prepend(Airbrake::Rails::HTTPClient)

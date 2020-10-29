# frozen_string_literal: true

module HTTP
  # Monkey-patch to measure request timing.
  class Client
    alias perform_without_airbrake perform

    def perform(request, options)
      Airbrake::Rack.capture_timing(:http) do
        perform_without_airbrake(request, options)
      end
    end
  end
end

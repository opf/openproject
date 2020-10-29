# frozen_string_literal: true

module Airbrake
  module Rails
    # BacktraceCleaner is a wrapper around Rails.backtrace_cleaner.
    class BacktraceCleaner
      # @return [Regexp]
      AIRBRAKE_FRAME_PATTERN = %r{/airbrake/lib/airbrake/}.freeze

      def self.clean(backtrace)
        ::Rails.backtrace_cleaner.clean(backtrace).first(1)
      end
    end
  end
end

if defined?(Rails)
  # Silence own frames to let the cleaner proceed to the next line (and probably
  # find the correct call-site coming from the app code rather this library).
  Rails.backtrace_cleaner.add_silencer do |line|
    line =~ Airbrake::Rails::BacktraceCleaner::AIRBRAKE_FRAME_PATTERN
  end
end

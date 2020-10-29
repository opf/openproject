module Airbrake
  # Loggable is included into any class that wants to be able to log.
  #
  # By default, Loggable defines a null logger that doesn't do anything. You are
  # supposed to overwrite it via the {instance} method before calling {logger}.
  #
  # @example
  #   class A
  #     include Loggable
  #
  #     def initialize
  #       logger.debug('Initialized A')
  #     end
  #   end
  #
  # @since v4.0.0
  # @api private
  module Loggable
    class << self
      # @return [Logger]
      attr_writer :instance

      # @return [Logger]
      def instance
        @instance ||= ::Logger.new(File::NULL).tap { |l| l.level = ::Logger::WARN }
      end
    end

    # @return [Logger] standard Ruby logger object
    def logger
      Loggable.instance
    end
  end
end

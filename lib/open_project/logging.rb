require_relative "logging/log_delegator"

module OpenProject
  module Logging
    class << self
      ##
      # Do we use lograge in the end to perform the payload output
      def lograge_enabled?
        OpenProject::Configuration.lograge_enabled?
      end

      ##
      # The lograge class to output the payload object
      def formatter
        @formatter ||= begin
          formatter_setting = OpenProject::Configuration.lograge_formatter || "key_value"
          "Lograge::Formatters::#{formatter_setting.classify}"
            .constantize
            .new
        end
      end

      ##
      # Extend a payload to be logged with additional information
      # @param context {Hash} The context of the log, might contain controller related keys
      def extend_payload!(payload, context)
        payload_extenders.reduce(payload.dup) do |hash, handler|
          res = handler.call(context)
          hash.merge!(res) if res.is_a?(Hash)
          hash
        rescue StandardError => e
          Rails.logger.error "Failed to extend payload in #{handler.inspect}: #{e.message}"
          hash
        end
      end

      ##
      # Get a set of extenders that may add to the logging context payload
      def payload_extenders
        @payload_extenders ||= [
          method(:default_payload)
        ]
      end

      ##
      # Register a new payload extender
      # for all logging purposes
      def add_payload_extender(&block)
        payload_extenders << block
      end

      private

      def default_payload(_context)
        { user: User.current.try(:id) }
      end
    end
  end
end

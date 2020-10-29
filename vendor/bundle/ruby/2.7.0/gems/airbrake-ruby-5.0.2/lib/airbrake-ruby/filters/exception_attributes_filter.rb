module Airbrake
  module Filters
    # ExceptionAttributesFilter attempts to call `#to_airbrake` on the stashed
    # exception and attaches returned data to the notice object.
    #
    # @api private
    # @since v2.10.0
    class ExceptionAttributesFilter
      include Loggable

      def initialize
        @weight = 118
      end

      # @macro call_filter
      def call(notice)
        exception = notice.stash[:exception]
        return unless exception.respond_to?(:to_airbrake)

        attributes = nil
        begin
          attributes = exception.to_airbrake
        rescue StandardError => ex
          logger.error(
            "#{LOG_LABEL} #{exception.class}#to_airbrake failed. #{ex.class}: #{ex}",
          )
        end

        unless attributes.is_a?(Hash)
          logger.error(
            "#{LOG_LABEL} #{self.class}: wanted Hash, got #{attributes.class}",
          )
          return
        end

        attributes.each do |key, attrs|
          if notice[key]
            notice[key].merge!(attrs)
          else
            notice[key] = attrs
          end
        end
      end
    end
  end
end

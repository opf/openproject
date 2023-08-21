module Exports
  module Formatters
    class Default
      include Redmine::I18n

      attr_reader :attribute

      def initialize(attribute)
        @attribute = attribute
      end

      def self.apply?(_attribute, _export_format)
        false
      end

      def self.key
        name.demodulize.underscore.to_sym
      end

      ##
      # Takes a resource and an attribute and returns the value to be exported.
      def format(object, **options)
        value = retrieve_value(object)
        format_value(value, options)
      end

      ##
      # Takes a value and returns the formatted value to be exported.
      def format_value(value, options)
        case value
        when Date
          format_date value
        when Time, DateTime, ActiveSupport::TimeWithZone
          format_time value
        when Array
          value.join options.fetch(:array_separator, ', ')
        when nil
          # ruby >=2.7.1 will return a frozen string for nil.to_s which will cause an error when e.g. trying to
          # force an encoding
          ''
        else
          value.to_s
        end
      end

      ##
      # Takes an attribute and returns format options for it.
      def format_options
        {}
      end

      protected

      # By default, use try as a non-destructive accessor
      # in case that attribute is not available for the cell
      def retrieve_value(object)
        object.try(attribute)
      end
    end
  end
end

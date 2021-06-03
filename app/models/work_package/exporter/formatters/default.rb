module WorkPackage::Exporter
  module Formatters
    class Default
      include Redmine::I18n

      ##
      # Takes a QueryColumn and returns true if this formatter should be used to handle it.
      def self.apply?(column)
        false
      end

      def self.key
        self.name.demodulize.underscore.to_sym
      end

      ##
      # Takes a WorkPackage and a QueryColumn and returns the value to be exported.
      def format(work_package, column, **options)
        value = column.value work_package

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
      # Takes a QueryColumn and returns format options for it.
      def format_options(_column)
        {}
      end
    end
  end
end
require_relative './default'

module WorkPackage::Exporter
  module Formatters
    class EstimatedHours < Default
      def self.apply?(column)
        column.name == :estimated_hours
      end

      ##
      # Takes a WorkPackage and a QueryColumn and returns the value to be exported.
      def format(work_package, column, **options)
        estimated_hours = work_package.estimated_hours
        derived_hours = formatted_derived_hours(work_package)

        if estimated_hours.nil? || derived_hours.nil?
          return estimated_hours || derived_hours
        end

        "#{estimated_hours} #{derived_hours}"
      end

      private

      def formatted_derived_hours(work_package)
        if (derived_estimated_value = work_package.derived_estimated_hours)
          "(#{derived_estimated_value})"
        end
      end
    end
  end
end
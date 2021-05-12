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
        value = work_package.estimated_hours
        derived_estimated_value = work_package.derived_estimated_hours

        if value.nil? && derived_estimated_value.present?
          "(#{derived_estimated_value})"
        else
          value
        end
      end
    end
  end
end
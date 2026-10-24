# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class FiltersComponent < Filter::FilterComponent
      options :allowed_filter_keys

      def turbo_requests? = true

      def allowed_filters
        super
          .select { |filter| allowed_filter_keys.include?(filter.name.to_s) }
          .sort_by(&:human_name)
      end
    end
  end
end

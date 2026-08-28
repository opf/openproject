# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class FilterButtonComponent < Filter::FilterButtonComponent
      HIDDEN_FILTER_KEYS = %w[id subject type_id].freeze

      def filters_count
        @filters_count ||= query.filters.count { |filter| HIDDEN_FILTER_KEYS.exclude?(filter.name.to_s) }
      end
    end
  end
end

# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class SelectFilterComponent < OpPrimer::QuickFilter::SelectPanelComponent
      INTERNAL_FILTER_KEYS = %w[id type_id].freeze

      def initialize(name:, query:, filter_key:, project:, options:)
        super(name:, query:, filter_key:, path_args: [project, :risk_log])

        options.each do |label, value|
          with_item(label:, value:)
        end
      end

      private

      def base_url_params
        super.merge(preserved_query_params)
      end

      def preserved_query_params
        keys = %w[view time_horizon date_from date_to workflow_change workflow_status]
        keys << "risk_cells" unless matrix_filter?
        helpers.request.query_parameters.slice(*keys)
      end

      def matrix_filter?
        %w[risk_likelihood risk_impact].include?(@filter_key.to_s)
      end

      # Work package queries expose their ordering through sort_criteria rather
      # than the #orders API used by the generic Primer quick-filter component.
      # The risk log keeps its fixed ordering, so no sorting parameter needs to
      # be propagated by these filters.
      def sort
        []
      end

      def other_filters
        serialize_filters(
          @query.filters.reject do |filter|
            filter.name.to_s == @filter_key.to_s || INTERNAL_FILTER_KEYS.include?(filter.name.to_s)
          end
        )
      end

      def serialize_filters(filters)
        filters.map do |filter|
          { filter.name.to_s => { "operator" => filter.operator.to_s, "values" => filter.values } }
        end
      end
    end
  end
end

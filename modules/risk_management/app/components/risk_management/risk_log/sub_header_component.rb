# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class SubHeaderComponent < ApplicationComponent
      include ApplicationHelper

      def initialize(project:, query:, owners:)
        super
        @project = project
        @query = query
        @owners = owners
      end

      private

      def active_filters?
        @query.filters.any? { |filter| filter.name.to_s != "type_id" }
      end

      def filter_input_value
        @query.find_active_filter(:subject)&.values&.first
      end

      def sub_header_data_attributes
        {
          controller: "filter--filters-form",
          "filter--filters-form-output-format-value": "json",
          "filter--filters-form-perform-turbo-requests-value": true,
          "filter--filters-form-clear-button-id-value": "risk-log-filters-clear-button",
          "filter--filters-form-display-filters-value": filters_expanded?
        }
      end

      def filters_expanded?
        false
      end

      def advanced_filter_keys
        [
          "author_id",
          "risk_owner_id",
          "risk_category_ids",
          "risk_impact",
          "risk_likelihood",
          "risk_response",
          "status_id"
        ]
      end

      def filter_input_data_attributes
        {
          "filter-name": "subject",
          "filter-type": "string",
          "filter-operator": "~",
          "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
        }
      end

      def response_options
        %w[mitigate accept avoid transfer].map do |response|
          [t("risk_management.risk_responses.#{response}"), response]
        end
      end
    end
  end
end

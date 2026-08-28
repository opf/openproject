# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :subject, :status, :likelihood, :impact, :risk_value, :category, :owner
      main_column :subject
      mobile_columns :subject, :status, :likelihood, :impact, :risk_value, :category, :owner
      mobile_labels :status, :likelihood, :impact, :risk_value, :category, :owner

      attr_reader :project, :configuration, :query_params

      def initialize(project:, configuration:, query_params:, **)
        super(**)
        @project = project
        @configuration = configuration
        @query_params = query_params
      end

      def mobile_title = I18n.t("risk_management.risk_log.list.title")

      def headers
        @headers ||= columns.map do |column|
          [column, { caption: I18n.t("risk_management.risk_log.list.#{column}") }]
        end
      end

      def categories
        @categories ||= RiskManagement::RiskCategory.all.index_by(&:id)
      end

      def blank_title = I18n.t("risk_management.risk_log.list.blank_title")

      def blank_description = I18n.t("risk_management.risk_log.list.blank_description")

      def blank_icon = :shield

      def has_actions? = true
    end
  end
end

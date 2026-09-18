# frozen_string_literal: true

module CostReports
  # Translates a request into a CostReport.
  #
  # Filters use the compact syntax shared with the other query based lists, e.g.
  # `filters=spent_on >d "2026-01-01" & user_id = "me"`. The axes are given as
  # `rows` and `columns`, the selected unit as `unit`.
  class ParamsToReport
    CONFIGURATION_PARAMS = %i[filters rows columns unit].freeze

    def initialize(params, project: nil, user: User.current)
      @params = params
      @project = project
      @user = user
    end

    def call(report = new_report)
      report.query ||= report.build_default_query

      apply_filters(report)
      apply_axes(report)
      apply_unit(report)

      report
    end

    private

    attr_reader :params, :project, :user

    def new_report
      CostReport.new(project:, principal: user, name: I18n.t(:label_new_report))
    end

    def apply_filters(report)
      report.query.filters = []

      filter_definitions.each do |definition|
        report.query.where(definition[:attribute].to_s, definition[:operator], Array(definition[:values]))
      end
    end

    def apply_axes(report)
      report.apply_pivot_configuration(rows: axis(:rows), columns: axis(:columns))
    end

    def apply_unit(report)
      report.unit_id = params[:unit].to_i if params[:unit].present?
    end

    def filter_definitions
      return default_filters unless params.key?(:filters)

      ::Queries::ParamsParser.parse(filters: params[:filters])[:filters] || []
    end

    # An axis the request does not mention is empty rather than the default, as
    # long as the request says anything about what to show at all. That way an
    # empty axis can be left out of the url.
    def axis(name)
      return default_axis(name) unless configured?

      params[name].to_s.split(",").compact_blank
    end

    def configured?
      CONFIGURATION_PARAMS.any? { |key| params.key?(key) }
    end

    def default_filters
      definitions = [{ attribute: "spent_on", operator: ">d", values: [30.days.ago.strftime("%Y-%m-%d")] }]

      definitions << { attribute: "project_id", operator: "=", values: [project.id.to_s] } if project
      definitions << { attribute: "user_id", operator: "=", values: [::Queries::Filters::MeValue::KEY] } if user.logged?

      definitions
    end

    def default_axis(name)
      case name
      when :columns then %w[week]
      else [project ? "work_package_id" : "project_id"]
      end
    end
  end
end

# frozen_string_literal: true

module RiskManagement
  class RiskLogsController < ApplicationController
    include WorkPackages::WithSplitView

    DASHBOARD_VIEWS = {
      "monitored" => %i[metrics monitored],
      "highest_exposure" => %i[metrics highest_exposure],
      "attention" => %i[metrics requiring_attention],
      "without_mitigation" => %i[attention without_mitigation],
      "without_owner" => %i[attention without_owner],
      "without_response" => %i[attention without_response],
      "mitigation_pending" => %i[attention mitigation_pending],
      "not_evaluated" => %i[attention not_evaluated],
      "owner_assigned" => %i[coverage owner_assigned],
      "response_defined" => %i[coverage response_defined],
      "mitigation_planned" => %i[coverage mitigation_planned],
      "mitigation_completed" => %i[coverage mitigation_completed]
    }.freeze

    before_action :find_project_by_project_id
    before_action :load_configuration
    authorize_with_permission :view_risk_log

    menu_item :risk_log

    def index
      load_risk_log
    end

    def details
      @work_package = WorkPackage.visible.find(params.expect(:work_package_id))
      render_404 and return unless @work_package.project == @project && @work_package.type_id == @risk_type.id

      if turbo_frame_request?
        render "work_packages/split_view", layout: false
      else
        load_risk_log
        render :index
      end
    end

    private

    def load_configuration
      @configuration = Configuration.load
      return unless @configuration.valid?

      @risk_type = @configuration.risk_type
    end

    def load_risk_log
      return unless @configuration.valid?

      @query = build_query
      load_risks
      load_dashboard
      load_owners
    end

    def load_risks
      risks = @query.results.work_packages.includes(:status, :risk_owner).to_a
      @risks = params[:view] == "last_updated" ? risks : risks.sort_by { |risk| risk_sort_key(risk) }
    end

    def load_dashboard
      @matrix_counts = matrix_counts
      @dashboard = summary.dashboard
    end

    def load_owners
      @owners = risk_scope.where.not(risk_owner_id: nil).includes(:risk_owner).map(&:risk_owner).uniq.sort_by(&:name)
    end

    def build_query(except: [], include_cells: true)
      Query.new(project: @project, user: current_user, include_subprojects: false).tap do |query|
        query.set_default_sort
        apply_requested_filters(query, except:)
        apply_named_view(query)
        apply_default_status_filter(query)
        apply_selected_cells(query) if include_cells
        query.add_filter("type_id", "=", [@risk_type.id.to_s])
      end
    end

    def apply_default_status_filter(query)
      query.add_filter("status_id", "o", [""]) unless query.find_active_filter(:status_id)
    end

    def apply_named_view(query)
      dashboard_view = DASHBOARD_VIEWS[params[:view]]
      return apply_dashboard_filter(query, *dashboard_view) if dashboard_view

      apply_list_view(query)
    end

    def apply_list_view(query)
      case params[:view]
      when "newly_added"
        apply_id_filter(query, newly_added_risk_ids)
      when "occurred"
        apply_closed_status_filter(query)
        apply_id_filter(query, occurred_risk_ids)
      when "closed"
        apply_closed_status_filter(query)
      when "last_updated"
        query.sort_criteria = [%w[updated_at desc]]
      when "created_by_me"
        query.add_filter("author_id", "=", [current_user.id.to_s])
      end
    end

    def apply_dashboard_filter(query, section, key)
      apply_id_filter(query, summary.dashboard.fetch(section).fetch(key).fetch(:risk_ids))
    end

    def apply_id_filter(query, ids)
      query.add_filter("id", "=", ids.presence || ["0"])
    end

    def apply_closed_status_filter(query)
      query.add_filter("status_id", "c", [""])
    end

    def newly_added_risk_ids
      risk_scope.where(created_at: 7.days.ago..).pluck(:id).map(&:to_s)
    end

    def apply_selected_cells(query)
      return if selected_cell_pairs.empty?

      query.add_filter("id", "=", selected_risk_ids.presence || ["0"])
    end

    def apply_requested_filters(query, except:)
      requested_filters.each do |filter|
        key = filter[:attribute].to_s
        next unless allowed_filter_keys.include?(key) && except.exclude?(key)

        query.add_filter(key, filter[:operator], Array(filter[:values]))
      end
    end

    def requested_filters
      @requested_filters ||= Array(Queries::ParamsParser.parse(params)[:filters])
    rescue JSON::ParserError, TypeError
      []
    end

    def allowed_filter_keys
      @allowed_filter_keys ||= [
        "status_id",
        "author_id",
        "risk_owner_id",
        "subject",
        "risk_likelihood",
        "risk_impact",
        "risk_category_ids",
        "risk_response",
        "created_at"
      ]
    end

    def matrix_counts
      monitored_scope
        .each_with_object(Hash.new(0)) do |risk, counts|
          coordinate = risk_coordinate(risk)
          counts[coordinate] += 1 if coordinate
        end
    end

    def risk_coordinate(risk)
      assessment_for(risk).coordinate&.map(&:to_s)
    end

    def risk_scope
      WorkPackage.visible.where(project: @project, type: @risk_type)
    end

    def selected_cell_pairs
      @selected_cell_pairs ||= params[:risk_cells].to_s.split(",").filter_map do |cell|
        cell.split(":", 2) if cell.match?(/\A[1-5]:[1-5]\z/)
      end.first(25)
    end

    def selected_risk_ids
      @selected_risk_ids ||= risk_scope.filter_map do |risk|
        risk.id if selected_cell_pairs.include?(risk_coordinate(risk))
      end
    end

    def high_risk_ids
      risk_scope.filter_map do |risk|
        risk.id.to_s if assessment_for(risk).high_or_critical?
      end
    end

    def monitored_scope
      risk_scope.joins(:status).where(statuses: { name: RiskLog::Summary::MONITORING_STATUS_NAMES })
    end

    def assessment_for(risk)
      RiskLog::Assessment.new(
        likelihood: risk.risk_likelihood,
        impact: risk.risk_impact,
        configuration: @configuration
      )
    end

    def risk_sort_key(risk)
      assessment = assessment_for(risk)
      level = RiskLog::Assessment::RISK_LEVELS.index(assessment.risk_level) || -1
      [-level, -(assessment.risk_value || -1), -risk.updated_at.to_i]
    end

    def occurred_risk_ids
      occurred_status_id = Status.find_by(name: "Occurred")&.id
      return [] unless occurred_status_id

      journals = Journal.where(journable_type: "WorkPackage", journable_id: risk_scope.select(:id)).includes(:data)
      journals.filter_map do |journal|
        journal.journable_id.to_s if journal.data&.status_id == occurred_status_id
      end.uniq
    end

    def summary
      @summary ||= RiskLog::Summary.new(scope: risk_scope)
    end

    def risk_status_ids
      @risk_status_ids ||= Status.where(name: BasicData::RiskManagement::Seeder::RISK_STATUSES.keys).pluck(:id)
    end

    def split_view_base_route
      project_risk_log_path(@project, request.query_parameters.except(:work_package_id, :tab))
    end
  end
end

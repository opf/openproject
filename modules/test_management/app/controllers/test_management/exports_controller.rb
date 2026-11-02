# frozen_string_literal: true

module TestManagement
  # Synchronous PDF / CSV / Excel downloads of the cases list and of a test run.
  class ExportsController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :check_format

    # GET …/test_management/exports/test_cases?export_format=csv&scope=folder&suite_id=3
    def test_cases
      query = TestManagement::TestCasesQuery.new(@project, params)
      send_export TestManagement::Exports::TestCasesExporter.new(
        query,
        format: export_format,
        scope: params[:scope].presence || query.current_scope,
        project: @project,
        current_user:
      )
    end

    # GET …/test_management/exports/test_runs/:id?export_format=pdf
    def test_run
      run = @project.tm_test_runs.find(params.expect(:id))
      send_export TestManagement::Exports::TestRunExporter.new(run, format: export_format, current_user:)
    end

    # GET …/test_management/exports/milestones/:id?export_format=xls
    def milestone
      return render_404 unless TestManagement::ProjectSetting.milestones_enabled?(@project)

      milestone = @project.tm_milestones.find(params.expect(:id))
      send_export TestManagement::Exports::MilestoneExporter.new(milestone, format: export_format, current_user:)
    end

    # GET …/test_management/exports/test_plans/:id?export_format=csv
    def test_plan
      return render_404 unless TestManagement::TestPlan.enabled_for?(@project)

      plan = @project.tm_test_plans.find(params.expect(:id))
      send_export TestManagement::Exports::TestPlanExporter.new(plan, format: export_format, current_user:)
    end

    private

    def export_format
      params[:export_format].to_s
    end

    def check_format
      return if TestManagement::Exports::BaseExporter.valid_format?(export_format)

      render_400(message: I18n.t("test_management.exports.invalid_format"))
    end

    def send_export(exporter)
      result = exporter.export!
      send_data result.content,
                filename: result.title,
                type: result.mime_type,
                disposition: "attachment"
    end
  end
end

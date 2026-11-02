# frozen_string_literal: true

module TestManagement
  # "Run in CI" (0011): GET …/ci_triggers/new?run_id= | suite_id= | test_case_id= shows the form
  # (connection, mode, target run, ref); POST …/ci_triggers pre-creates the run / iteration and
  # triggers the CI job. Requires :trigger_test_automation.
  class CiTriggersController < ApplicationController
    menu_item :test_management
    helper TestManagement::MilestonesHelper

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :load_scope

    def new
      @trigger = CiTriggers::Request.new(project: @project, run: @scope_run, suite: @suite, test_case: @test_case,
                                         mode: @scope_run&.active? ? "new_iteration" : "new_run",
                                         milestone: @scope_run&.milestone,
                                         connection: trigger_connections.find(&:trigger_ready?))
      load_form_data
    end

    def create
      call = CiTriggers::TriggerService.new(user: current_user).call(trigger_params)
      if call.success?
        outcome = call.result
        if outcome.triggered?
          flash[:notice] = I18n.t("test_management.ci_triggers.triggered", run: outcome.run.name,
                                                                           number: outcome.iteration.number)
        elsif outcome.manual?
          flash[:notice] = I18n.t("test_management.ci_triggers.prepared_manual", run: outcome.run.name,
                                                                                 number: outcome.iteration.number)
        else
          flash[:error] = I18n.t("test_management.ci_triggers.failed", error: outcome.error)
        end
        redirect_to project_test_management_test_run_path(@project, outcome.run,
                                                          anchor: outcome.manual? ? "tm-ci-manual-start" : nil),
                    status: :see_other
      else
        @trigger = call.result
        flash.now[:error] = call.errors.full_messages.join(", ")
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    private

    # Scope: where the cases come from (hidden fields of the form / query of the "Run in CI" links).
    def load_scope
      source = params[:ci_trigger].presence || params
      @scope_run = @project.tm_test_runs.find(source[:run_id]) if source[:run_id].present?
      @suite = @project.tm_suites.find(source[:suite_id]) if source[:suite_id].present?
      @test_case = @project.tm_test_cases.not_deleted.find(source[:test_case_id]) if source[:test_case_id].present?
    end

    def trigger_params
      values = params.fetch(:ci_trigger, {}).permit(:connection_id, :mode, :target_run_id, :ref, :name, :milestone_id)
      mode = values[:mode].presence || "new_run"
      target = if mode == "new_iteration"
                 values[:target_run_id].present? ? @project.tm_test_runs.find_by(id: values[:target_run_id]) : @scope_run
               else
                 @scope_run
               end
      {
        project: @project,
        connection: CiConnection.where(project_id: @project.id).find_by(id: values[:connection_id]),
        mode:, run: target, suite: @suite, test_case: @test_case,
        ref: values[:ref], name: values[:name],
        # Only a new run gets a milestone; the field is ignored for a new iteration.
        milestone: mode == "new_run" ? trigger_milestone(values[:milestone_id]) : nil
      }
    end

    # Unknown ids give a (later rejected) foreign stand-in rather than silently dropping the choice.
    def trigger_milestone(id)
      return nil if id.blank?

      Milestone.where(project_id: @project.id).find_by(id:) || Milestone.new(project_id: 0, name: "?")
    end

    def trigger_connections
      @trigger_connections ||= CiConnection.where(project_id: @project.id).active.ordered.to_a
    end

    def load_form_data
      @connections = trigger_connections
      @target_runs = @project.tm_test_runs.active.newest_first.limit(200).to_a
      @automated_count = @trigger.automated_cases.count
      @case_count = @trigger.cases.count
      @milestones_enabled = Milestone.enabled_for?(@project)
    end
  end
end

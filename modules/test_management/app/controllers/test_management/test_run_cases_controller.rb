# frozen_string_literal: true

module TestManagement
  # One case inside a run.
  # - show (0020): the run case view with the latest error, the step results, the result history
  #   and (for executors of an active run) the form to record a result step by step;
  # - update: status / assignee changes from the run page (plain form posts from Primer
  #   ActionMenu items; no custom JS) and the run case form (comment, error, step results).
  class TestRunCasesController < ApplicationController
    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper

    HISTORY_LIMIT = 50

    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_run_case

    def show
      @test_case = @run_case.test_case
      @case_steps = @test_case.steps.to_a
      @results = @run_case.results.includes(:user, :iteration, :step_results).order(id: :desc).limit(HISTORY_LIMIT).to_a
      @latest = @results.first
      @can_execute = @test_run.active? &&
                     (current_user.allowed_in_project?(:execute_test_runs, @project) ||
                      current_user.allowed_in_project?(:add_test_runs, @project))
    end

    def update
      call = TestManagement::RunCases::UpdateService
               .new(user: current_user, model: @run_case)
               .call(run_case_params)

      if call.success?
        flash[:notice] = I18n.t("test_management.runs.status_updated")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to return_path, status: :see_other
    end

    private

    def find_run_case
      @test_run = @project.tm_test_runs.find(params.expect(:test_run_id))
      @run_case = @test_run.run_cases.find(params.expect(:id))
    end

    def return_path
      if params[:return_to] == "run_case"
        project_test_management_test_run_run_case_path(@project, @test_run, @run_case)
      else
        project_test_management_test_run_path(@project, @test_run, anchor: "run-case-#{@run_case.id}")
      end
    end

    def run_case_params
      permitted = params.expect(run_case: [:status, :assigned_to_id, :comment, :error_message, { step_results: {} }])
      permitted.to_h
    end
  end
end

# frozen_string_literal: true

module TestManagement
  # "Start new iteration" on the run page (POST …/test_runs/:test_run_id/iterations).
  class TestRunIterationsController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_test_run

    def create
      call = TestManagement::TestRunIterations::StartService.new(user: current_user, run: @test_run)
                                                           .call(name: params.dig(:iteration, :name))
      if call.success?
        flash[:notice] = I18n.t("test_management.runs.iterations.started_notice", number: call.result.number)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_run_path(@project, @test_run), status: :see_other
    end

    private

    def find_test_run
      @test_run = @project.tm_test_runs.find(params.expect(:test_run_id))
    end
  end
end

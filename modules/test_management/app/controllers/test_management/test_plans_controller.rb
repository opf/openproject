# frozen_string_literal: true

module TestManagement
  class TestPlansController < ApplicationController
    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper
    helper TestManagement::MilestonesHelper
    helper TestManagement::TestPlansHelper

    menu_item :test_management

    FILTERS = %w[active completed all].freeze

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_plans_enabled
    before_action :find_plan, except: %i[index new create]
    before_action :load_form_data, only: %i[new create edit update]

    def index
      @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "active"
      all = @project.tm_test_plans.includes(:milestone, :assigned_to).newest_first.to_a
      @filter_counts = {
        "active" => all.count(&:active?),
        "completed" => all.count(&:completed?),
        "all" => all.size
      }
      @plans = case @filter
               when "active" then all.select(&:active?)
               when "completed" then all.select(&:completed?)
               else all
               end
      TestManagement::TestPlan.preload_summaries(@plans)
    end

    def show
      TestManagement::TestPlan.preload_summaries([@plan])
      @entries = @plan.entries.includes(:assigned_to, test_runs: :assigned_to).to_a
      @runs = @plan.test_runs.includes(:assigned_to, :test_plan_entry).newest_first.to_a
      @run_status_counts = status_counts_for(@runs.map(&:id))
      @visible_work_packages = @plan.work_packages.visible(current_user).includes(:type).order(:id).to_a
      @configuration_groups = @project.tm_configuration_groups.includes(:configurations).ordered.to_a
    end

    def new
      @plan = @project.tm_test_plans.build(state: "active")
    end

    def edit; end

    def create
      call = TestManagement::Plans::CreateService
               .new(user: current_user)
               .call(plan_params.merge(project: @project))

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_test_management_test_plan_path(@project, call.result)
      else
        @plan = call.result
        render action: :new, status: :unprocessable_entity
      end
    end

    def update
      call = TestManagement::Plans::UpdateService
               .new(user: current_user, model: @plan)
               .call(plan_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_test_management_test_plan_path(@project, @plan)
      else
        render action: :edit, status: :unprocessable_entity
      end
    end

    def destroy
      call = TestManagement::Plans::DeleteService.new(user: current_user, model: @plan).call
      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
        redirect_to project_test_management_test_plans_path(@project)
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_test_plan_path(@project, @plan)
      end
    end

    def complete
      transition(TestManagement::Plans::CompleteService, "test_management.plans.completed_notice")
    end

    def reopen
      transition(TestManagement::Plans::ReopenService, "test_management.plans.reopened_notice")
    end

    def rerun
      call = TestManagement::Plans::RerunService
               .new(user: current_user, model: @plan, params: rerun_params)
               .call
      if call.success?
        flash[:notice] = I18n.t("test_management.plans.rerun_notice")
        redirect_to project_test_management_test_plan_path(@project, call.result)
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_test_plan_path(@project, @plan)
      end
    end

    private

    def require_plans_enabled
      render_404 unless TestManagement::TestPlan.enabled_for?(@project)
    end

    def find_plan
      @plan = @project.tm_test_plans.find(params.expect(:id))
    end

    def load_form_data
      @milestone_options = @project.tm_milestones.not_completed.ordered.to_a
      @configuration_groups = @project.tm_configuration_groups.includes(:configurations).ordered.to_a
      @assignees = TestManagement::Assignees.scope(@project).ordered_by_name.to_a
    end

    def status_counts_for(run_ids)
      raw = TestManagement::TestRunCase
              .where(test_run_id: run_ids)
              .group(:test_run_id, TestManagement::TestRunCase.effective_status_sql)
              .count
      run_ids.index_with do |id|
        TestManagement::TestRunCase::STATUSES.index_with { |status| raw[[id, status]].to_i }
      end
    end

    def transition(service_class, notice_key)
      call = service_class.new(user: current_user, model: @plan).call
      if call.success?
        flash[:notice] = I18n.t(notice_key)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_plan_path(@project, @plan)
    end

    def plan_params
      params.expect(test_plan: [:name, :description, :start_date, :end_date, :milestone_id,
                                :assigned_to_id, :work_package_ids, { work_package_ids: [] }])
    end

    def rerun_params
      params.fetch(:rerun, {}).permit(:name, :milestone_id, :copy_assignees, status_ids: [])
    end
  end
end

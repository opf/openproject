# frozen_string_literal: true

module TestManagement
  class TestPlanEntriesController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_plans_enabled
    before_action :find_plan
    before_action :find_entry, only: %i[update destroy]

    def create
      call = Plans::Entries::CreateService
               .new(user: current_user)
               .call(entry_params.merge(test_plan: @plan))
      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_plan_path(@project, @plan)
    end

    def update
      call = Plans::Entries::UpdateService
               .new(user: current_user, model: @entry)
               .call(entry_params)
      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_plan_path(@project, @plan)
    end

    def destroy
      call = Plans::Entries::DeleteService.new(user: current_user, model: @entry).call
      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_plan_path(@project, @plan)
    end

    private

    def require_plans_enabled
      render_404 unless TestPlan.enabled_for?(@project)
    end

    def find_plan
      @plan = @project.tm_test_plans.find(params.expect(:test_plan_id))
    end

    def find_entry
      @entry = @plan.entries.find(params.expect(:id))
    end

    def entry_params
      params.expect(
        test_plan_entry: [:name, :description, :selection_mode, :assigned_to_id, :position,
                          {
                            case_ids: [], configuration_ids: [],
                            filter_options: [:automation, { label_ids: [], suite_ids: [] }]
                          }]
      )
    end
  end
end

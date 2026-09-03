# frozen_string_literal: true

module RiskManagement
  class PlansController < ApplicationController
    before_action :find_project_by_project_id
    before_action :find_plan
    authorize_with_permission :view_risk_log, only: [:show]
    authorize_with_permission :manage_risk_management_plan, only: %i[edit update]

    menu_item :risk_log

    def show
      @tasks = task_summary.attention_items
    end

    def edit; end

    def update
      @plan.updated_by = current_user
      if @plan.update(plan_params)
        redirect_to project_risk_management_plan_path(@project), notice: I18n.t(:notice_successful_update)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def find_plan
      @plan = Plan.find_or_initialize_by(project: @project)
      @plan.author ||= current_user
      @plan.updated_by ||= current_user
    end

    def task_summary
      risk_type = Type.find_by(builtin_identifier: "risk")
      scope = WorkPackage.visible.where(project: @project, type: risk_type)
      RiskLog::Summary.new(scope:)
    end

    def plan_params
      params.expect(risk_management_plan: %i[body lock_version])
    end
  end
end

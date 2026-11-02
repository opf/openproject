# frozen_string_literal: true

module TestManagement
  class SuitesController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize

    def index
      redirect_to project_test_management_test_cases_path(@project)
    end

    def create
      call = TestManagement::Suites::CreateService
               .new(user: current_user)
               .call(suite_params.merge(project: @project))

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        # Select the new folder so it is visible (its ancestors are expanded).
        redirect_to project_test_management_test_cases_path(@project, suite_id: call.result.id)
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_test_cases_path(@project, suite_id: suite_params[:parent_id].presence)
      end
    end

    def update
      suite = @project.tm_suites.find(params.expect(:id))
      call = TestManagement::Suites::UpdateService
               .new(user: current_user, model: suite)
               .call(suite_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to project_test_management_test_cases_path(@project, suite_id: suite.id)
    end

    def destroy
      suite = @project.tm_suites.find(params.expect(:id))
      call = TestManagement::Suites::DeleteService
               .new(user: current_user, model: suite)
               .call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to project_test_management_test_cases_path(@project)
    end

    private

    def suite_params
      params.expect(suite: %i[name parent_id position])
    end
  end
end

# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  class TestCasesController < ApplicationController
    menu_item :test_management

    include PaginationHelper
    include OpTurbo::ComponentStream

    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_test_case, only: %i[show edit update destroy delete_dialog]
    before_action :load_project_setting
    before_action :load_suites_tree, only: %i[index new create show edit update]

    helper_method :suite_breadcrumb_name, :folder_tree_layout, :split_pane_layout?

    def index
      @query = TestManagement::TestCasesQuery.new(@project, params, suites: @suites)
      @current_suite = @query.suite
      @filter_root = @query.unfiled?

      @test_cases = @query.results
                          .includes(:suite)
                          .order(id: :desc)
                          .paginate(page: page_param, per_page: per_page_param)
    end

    SHOW_TABS = %w[overview runs].freeze

    def show
      @tab = SHOW_TABS.include?(params[:tab]) ? params[:tab] : "overview"
      return unless @tab == "runs"

      @run_cases = @test_case.run_cases
                             .joins(:test_run)
                             .includes(:test_run, :assigned_to)
                             .order("tm_test_runs.id DESC")
                             .to_a
    end

    def new
      @test_case = @project.tm_test_cases.build(
        suite_id: params[:suite_id].presence,
        status: "ready",
        priority: "medium"
      )
      ensure_blank_step
    end

    def edit
      ensure_blank_step
    end

    def create
      call = TestManagement::TestCases::CreateService
               .new(user: current_user)
               .call(test_case_params.merge(project: @project))

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_test_management_test_case_path(@project, call.result)
      else
        @test_case = call.result
        ensure_blank_step
        render action: :new, status: :unprocessable_entity
      end
    end

    def update
      call = TestManagement::TestCases::UpdateService
               .new(user: current_user, model: @test_case)
               .call(test_case_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_test_management_test_case_path(@project, @test_case)
      else
        ensure_blank_step
        render action: :edit, status: :unprocessable_entity
      end
    end

    def delete_dialog
      respond_with_dialog TestManagement::TestCases::DeleteDialogComponent.new(
        test_case: @test_case,
        project: @project
      )
    end

    def destroy
      call = TestManagement::TestCases::DeleteService
               .new(user: current_user, model: @test_case)
               .call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to project_test_management_test_cases_path(@project)
    end

    private

    def find_test_case
      @test_case = @project.tm_test_cases.find(params.expect(:id))
    end

    def load_project_setting
      @tm_setting = TestManagement::ProjectSetting.for_project(@project)
    end

    def load_suites_tree
      @suites = @project.tm_suites.ordered.to_a
      @suite_roots = @suites.select { |s| s.parent_id.nil? }
      @all_cases_count = @project.tm_test_cases.count
      @suite_counts = @project.tm_test_cases.group(:suite_id).count
    end

    def ensure_blank_step
      return if @test_case.steps.any?(&:new_record?)

      @test_case.steps.build(position: @test_case.steps.size)
    end

    def test_case_params
      params.expect(
        test_case: [:title,
                    :description,
                    :preconditions,
                    :priority,
                    :status,
                    :automated,
                    :automation_reference,
                    :suite_id,
                    { steps_attributes: [%i[id position action expected_result data _destroy]] }]
      )
    end

    def suite_breadcrumb_name
      return t("test_management.suites.unfiled") if @filter_root
      return @current_suite.name if @current_suite

      t("test_management.suites.all_cases")
    end

    def folder_tree_layout
      @tm_setting.effective_folder_tree_layout
    end

    def split_pane_layout?
      @tm_setting.split_pane_layout?
    end
  end
end

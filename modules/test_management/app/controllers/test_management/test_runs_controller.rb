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
  class TestRunsController < ApplicationController
    include PaginationHelper
    include OpTurbo::ComponentStream

    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper

    menu_item :test_management

    FILTERS = %w[active completed cancelled all].freeze
    HISTORY_LIMIT = 50

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_test_run, except: %i[index new create]
    before_action :load_form_data, only: %i[new create edit update]

    def index
      @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "active"
      scope = @project.tm_test_runs.includes(:author, :assigned_to).newest_first
      @filter_counts = filter_counts
      scope = filter_scope(scope, @filter)
      @test_runs = scope.paginate(page: page_param, per_page: per_page_param)
      @run_status_counts = status_counts_for(@test_runs.map(&:id))
    end

    def show # rubocop:disable Metrics/AbcSize
      @status_counts = @test_run.status_counts
      @run_cases = @test_run.run_cases
                            .joins(:test_case)
                            .includes(:assigned_to, test_case: :suite)
                            .order("tm_test_cases.id")
                            .to_a
      @suites = @project.tm_suites.ordered.to_a
      @possible_assignees = possible_assignees
      load_iterations
      load_last_results
    end

    def new
      @test_run = @project.tm_test_runs.build(selection_mode: "specific", state: "new")
      @test_run.selected_case_ids = []
    end

    def edit
      @test_run.selected_case_ids = @test_run.run_cases.pluck(:test_case_id)
    end

    def create # rubocop:disable Metrics/AbcSize
      if refresh_selection?
        @test_run = @project.tm_test_runs.build
        assign_without_saving(TestManagement::TestRuns::CreateContract)
        return render(:new)
      end

      call = TestManagement::TestRuns::CreateService
               .new(user: current_user)
               .call(test_run_params.merge(project: @project))

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_test_management_test_run_path(@project, call.result)
      else
        @test_run = call.result
        render action: :new, status: :unprocessable_entity
      end
    end

    def update
      if refresh_selection?
        assign_without_saving(TestManagement::TestRuns::UpdateContract)
        return render(:edit)
      end

      call = TestManagement::TestRuns::UpdateService
               .new(user: current_user, model: @test_run)
               .call(test_run_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_test_management_test_run_path(@project, @test_run)
      else
        render action: :edit, status: :unprocessable_entity
      end
    end

    def complete_dialog
      run_confirm_dialog("tm-test-run-complete-dialog", "tm-run-complete-dialog",
                         "test_management.runs.complete_dialog",
                         complete_project_test_management_test_run_path(@project, @test_run), :post)
    end

    def complete
      transition(TestManagement::TestRuns::CompleteService, "test_management.runs.completed_notice")
    end

    def cancel_dialog
      run_confirm_dialog("tm-test-run-cancel-dialog", "tm-run-cancel-dialog",
                         "test_management.runs.cancel_dialog",
                         cancel_project_test_management_test_run_path(@project, @test_run), :post)
    end

    def cancel
      transition(TestManagement::TestRuns::CancelService, "test_management.runs.cancelled_notice")
    end

    def reopen
      transition(TestManagement::TestRuns::ReopenService, "test_management.runs.reopened_notice")
    end

    def delete_dialog
      run_confirm_dialog("tm-test-run-delete-dialog", "tm-run-delete-dialog",
                         "test_management.runs.delete_dialog",
                         project_test_management_test_run_path(@project, @test_run), :delete)
    end

    def destroy
      call = TestManagement::TestRuns::DeleteService.new(user: current_user, model: @test_run).call
      if call.success?
        flash[:notice] = I18n.t("test_management.runs.deleted_notice")
        redirect_to project_test_management_test_runs_path(@project)
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_test_run_path(@project, @test_run)
      end
    end

    private

    def load_iterations # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      @iterations = @test_run.iterations.includes(:connection, :created_by).to_a
      @current_iteration = @iterations.last
      @shown_iteration = @current_iteration
      if params[:iteration].present?
        requested = @iterations.find { |iteration| iteration.number == params[:iteration].to_i }
        if requested
          @shown_iteration = requested
        else
          flash.now[:error] = I18n.t("test_management.runs.iterations.not_found", number: params[:iteration].to_i)
        end
      end
      @viewing_past_iteration = @shown_iteration.present? && @shown_iteration != @current_iteration
      run_case_ids = @run_cases.map(&:id)
      if @viewing_past_iteration
        @iteration_statuses = @shown_iteration.run_case_statuses(run_case_ids)
        @status_counts = TestManagement::TestRunCase::STATUSES.index_with { |s| @iteration_statuses.values.count(s) }
      end
      history = @iterations.last(HISTORY_LIMIT)
      past_counts = TestManagement::TestRunIteration.status_counts_for(history - [@current_iteration], run_case_ids)
      current_counts = @current_iteration && @test_run.status_counts
      @iteration_counts = history.to_h do |iteration|
        [iteration.id, iteration == @current_iteration ? current_counts : past_counts[iteration.id]]
      end
    end

    def load_last_results
      iteration_id = @viewing_past_iteration ? @shown_iteration.id : nil
      @last_results = TestManagement::TestResult.latest_by_run_case(@run_cases.map(&:id), iteration_id:)
    end

    def find_test_run
      @test_run = @project.tm_test_runs.find(params.expect(:id))
    end

    def run_confirm_dialog(id, test_selector, i18n_scope, action, method)
      respond_with_dialog TestManagement::ConfirmDialogComponent.new(
        id:, test_selector:, i18n_scope:,
        form_arguments: { action:, method: },
        label: "#{@test_run.formatted_id} #{@test_run.name}"
      )
    end

    def transition(service_class, notice_key)
      call = service_class.new(user: current_user, model: @test_run).call
      if call.success?
        flash[:notice] = I18n.t(notice_key)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_run_path(@project, @test_run)
    end

    def refresh_selection?
      params[:refresh_selection].present?
    end

    def assign_without_saving(contract_class)
      TestManagement::TestRuns::SetAttributesService
        .new(user: current_user, model: @test_run, contract_class:)
        .call(test_run_params.merge(project: @project))
      @test_run.errors.clear
      @test_run.selection_mode = "specific"
    end

    def load_form_data
      @suites = @project.tm_suites.ordered.to_a
      @selectable_cases = @project.tm_test_cases.order(:id).to_a
      @possible_assignees = possible_assignees
    end

    def possible_assignees
      TestManagement::Assignees.scope(@project).ordered_by_name.to_a
    end

    def filter_scope(scope, filter)
      case filter
      when "active" then scope.active
      when "completed", "cancelled" then scope.in_state(filter)
      else scope
      end
    end

    def filter_counts
      by_state = @project.tm_test_runs.group(:state).count
      {
        "active" => by_state.slice(*TestManagement::TestRun::ACTIVE_STATES).values.sum,
        "completed" => by_state["completed"].to_i,
        "cancelled" => by_state["cancelled"].to_i,
        "all" => by_state.values.sum
      }
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

    def test_run_params
      permitted = params.expect(
        test_run: [:name,
                   :description,
                   :assigned_to_id,
                   :start_date,
                   :end_date,
                   :selection_mode,
                   :selection_submitted,
                   {
                     test_case_ids: [],
                     selection_suite_ids: [],
                     filter_options: [:automation, { suite_ids: [] }]
                   }]
      )
      submitted = permitted.delete(:selection_submitted)
      permitted[:test_case_ids] ||= [] if submitted.present?
      permitted
    end
  end
end

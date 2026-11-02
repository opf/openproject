# frozen_string_literal: true

module TestManagement
  class TestRunsController < ApplicationController
    include PaginationHelper
    include OpTurbo::ComponentStream

    helper TestManagement::TestCasesHelper
    helper TestManagement::HotkeysHelper
    helper TestManagement::TestRunsHelper
    helper TestManagement::MilestonesHelper
    helper TestManagement::TestPlansHelper

    menu_item :test_management

    FILTERS = %w[active completed cancelled all].freeze
    HISTORY_LIMIT = 50

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_test_run, except: %i[index new create]
    before_action :load_form_data, only: %i[new create edit update]

    def index
      @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "active"
      scope = @project.tm_test_runs.includes(:author, :assigned_to, :test_plan).newest_first
      @filter_counts = filter_counts
      scope = filter_scope(scope, @filter)
      @test_runs = scope.paginate(page: page_param, per_page: per_page_param)
      @run_status_counts = status_counts_for(@test_runs.map(&:id))
    end

    def show
      @status_counts = @test_run.status_counts
      @run_cases = @test_run.run_cases
                            .joins(:test_case)
                            .merge(TestManagement::TestCase.not_deleted)
                            .includes(:assigned_to, :attachments, test_case: %i[labels suite])
                            .order("tm_test_cases.id")
                            .to_a
      @suites = @project.tm_suites.ordered.to_a
      @possible_assignees = possible_assignees
      load_iterations
      @manual_start = manual_start
      load_last_results
      load_visible_work_packages
      imports = @test_run.automation_imports.newest_first.limit(20)
      imports = imports.where(iteration_id: @shown_iteration.id) if @shown_iteration
      @imports = imports.to_a
    end

    def new
      @test_run = @project.tm_test_runs.build(selection_mode: "specific", state: "new")
      @test_run.selected_case_ids = []
    end

    def edit
      @test_run.selected_case_ids = @test_run.run_cases.pluck(:test_case_id)
    end

    def create
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
      respond_with_dialog TestManagement::TestRuns::CompleteDialogComponent.new(
        test_run: @test_run,
        project: @project
      )
    end

    def complete
      transition(TestManagement::TestRuns::CompleteService, "test_management.runs.completed_notice")
    end

    def cancel_dialog
      respond_with_dialog TestManagement::TestRuns::CancelDialogComponent.new(
        test_run: @test_run,
        project: @project
      )
    end

    def cancel
      transition(TestManagement::TestRuns::CancelService, "test_management.runs.cancelled_notice")
    end

    def reopen
      transition(TestManagement::TestRuns::ReopenService, "test_management.runs.reopened_notice")
    end

    def delete_dialog
      respond_with_dialog TestManagement::TestRuns::DeleteDialogComponent.new(
        test_run: @test_run,
        project: @project
      )
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

    # Iteration switcher (?iteration=N). Past iterations are shown read-only with the statuses
    # they ended with (last result per case within the iteration).
    # Inbound-only "Run in CI" (0015): values to start the pipeline by hand, while the run's
    # current iteration is the one that was prepared and has not received an upload yet.
    def manual_start
      iteration = @current_iteration
      return nil unless @test_run.ci_trigger_status == "manual" && iteration&.connection
      return nil unless iteration.ci_info.dig("trigger", "status") == "manual" && @test_run.active?
      return nil if @test_run.automation_imports.exists?(iteration_id: iteration.id)

      TestManagement::CiTriggers::ManualStart.new(connection: iteration.connection, run: @test_run, iteration:,
                                                  op_url: root_url)
    end

    def load_iterations
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

    # Latest result per run case (comment, automation badge), for the shown past
    # iteration or over the whole run. One query, instead of preloading every result of
    # every iteration (unbounded for long-lived runs such as a nightly Smoke run).
    def load_last_results
      iteration_id = @viewing_past_iteration ? @shown_iteration.id : nil
      @last_results = TestManagement::TestResult.latest_by_run_case(@run_cases.map(&:id), iteration_id:)
    end

    # Linked work packages the current user may see (the section is hidden when none are).
    def load_visible_work_packages
      @visible_work_packages = @test_run.work_packages.visible(current_user).includes(:type).order(:id).to_a
    end

    def find_test_run
      @test_run = @project.tm_test_runs.find(params.expect(:id))
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

    # "Apply selection" in the case selection dialog re-renders the form with the
    # new selection (server-side, nothing is saved).
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
      @selectable_cases = @project.tm_test_cases.not_deleted.order(:id).to_a
      @labels = TestManagement::Label.where(project_id: @project.id).ordered.to_a
      @possible_assignees = possible_assignees
      @milestones_enabled = TestManagement::ProjectSetting.milestones_enabled?(@project)
      @configuration_groups = @project.tm_configuration_groups.includes(:configurations).ordered.to_a
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
                   :milestone_id,
                   :start_date,
                   :end_date,
                   :selection_mode,
                   :selection_submitted,
                   :work_package_ids,
                   {
                     work_package_ids: [],
                     test_case_ids: [],
                     selection_suite_ids: [],
                     configuration_ids: [],
                     filter_options: [:automation, { label_ids: [], suite_ids: [] }]
                   }]
      )
      # The selection dialog always posts a sentinel so an empty selection is explicit.
      submitted = permitted.delete(:selection_submitted)
      permitted[:test_case_ids] ||= [] if submitted.present?
      permitted
    end
  end
end

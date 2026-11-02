# frozen_string_literal: true

module TestManagement
  class TestCasesController < ApplicationController
    menu_item :test_management

    include PaginationHelper
    include OpTurbo::ComponentStream

    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper
    helper TestManagement::HotkeysHelper

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_test_case, only: %i[show edit update destroy delete_dialog]
    before_action :find_deleted_test_case, only: %i[restore]
    before_action :load_project_setting
    before_action :load_suites_tree, only: %i[index new create show edit update restore]

    helper_method :suite_breadcrumb_name, :folder_tree_layout, :split_pane_layout?, :deleted_view?

    def index
      @query = TestManagement::TestCasesQuery.new(@project, params, suites: @suites)
      @current_suite = @query.suite
      @filter_root = @query.unfiled?
      @deleted_view = @query.deleted?

      @test_cases = @query.results("filter")
                          .includes(:suite, :labels)
                          .order(id: :desc)
                          .paginate(page: page_param, per_page: per_page_param)
    end

    SHOW_TABS = %w[overview runs defects history].freeze

    def show
      @tab = SHOW_TABS.include?(params[:tab]) ? params[:tab] : "overview"
      @linked_work_packages = helpers.tm_visible_linked_work_packages(@test_case).to_a
      @defects = @linked_work_packages.select { |wp| helpers.tm_defect_work_package?(wp) }
      @history_events = @test_case.events.includes(:user).to_a if @tab == "history"
      if @tab == "runs"
        @run_cases = @test_case.run_cases
                               .joins(:test_run)
                               .includes(:test_run, :assigned_to)
                               .order("tm_test_runs.id DESC")
                               .to_a
      end
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

    def restore
      suite_id = if params.key?(:suite_id)
                   params[:suite_id]
                 else
                   :keep
                 end

      call = TestManagement::TestCases::RestoreService
               .new(user: current_user, model: @test_case)
               .call(suite_id:)

      if call.success?
        flash[:notice] = t("test_management.cases.restored")
        redirect_to project_test_management_test_case_path(@project, @test_case)
      elsif @test_case.restore_needs_folder? && !params.key?(:suite_id)
        load_suites_tree
        render "test_management/test_cases/restore", status: :unprocessable_entity
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_test_cases_path(@project, suite_id: "deleted")
      end
    end

    private

    def find_test_case
      @test_case = @project.tm_test_cases.not_deleted.find(params.expect(:id))
    end

    def find_deleted_test_case
      @test_case = @project.tm_test_cases.deleted.find(params.expect(:id))
    end

    def load_project_setting
      @tm_setting = TestManagement::ProjectSetting.for_project(@project)
    end

    def load_suites_tree
      @suites = @project.tm_suites.ordered.to_a
      @suite_roots = @suites.select { |s| s.parent_id.nil? }
      @all_cases_count = @project.tm_test_cases.not_deleted.count
      @suite_counts = @project.tm_test_cases.not_deleted.group(:suite_id).count
      @deleted_cases_count = @project.tm_test_cases.deleted.count
    end

    # Always render one empty step row so users can add a step; blank rows are
    # dropped by TestCase's nested-attributes reject_if.
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
                    :label_names,
                    :work_package_ids,
                    {
                      work_package_ids: [],
                      steps_attributes: %i[id position action expected_result data _destroy]
                    }]
      )
    end

    def suite_breadcrumb_name
      return t("test_management.suites.deleted") if deleted_view?
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

    def deleted_view?
      !!@deleted_view
    end
  end
end

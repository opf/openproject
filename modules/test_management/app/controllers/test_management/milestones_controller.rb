# frozen_string_literal: true

module TestManagement
  # Project milestones (0012): list with progress, detail page with the assigned runs
  # (own and of sub-milestones), create/edit, start/complete/reopen, delete.
  class MilestonesController < ApplicationController
    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper
    helper TestManagement::MilestonesHelper

    menu_item :test_management

    FILTERS = %w[open completed all].freeze

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_milestones_enabled
    before_action :find_milestone, except: %i[index new create]
    before_action :load_form_data, only: %i[new create edit update]

    def index
      @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "open"
      all = @project.tm_milestones.includes(:version, :parent).ordered.to_a
      @filter_counts = {
        "open" => all.count { |m| !m.completed? },
        "completed" => all.count(&:completed?),
        "all" => all.size
      }
      shown = case @filter
              when "open" then all.reject(&:completed?)
              when "completed" then all.select(&:completed?)
              else all
              end
      TestManagement::Milestone.preload_summaries(shown)
      @rows = tree_rows(shown)
    end

    def show
      @children = @milestone.children.includes(:version).ordered.to_a
      TestManagement::Milestone.preload_summaries([@milestone] + @children)
      @runs = TestManagement::TestRun
                .where(milestone_id: [@milestone.id] + @children.map(&:id))
                .includes(:milestone, :assigned_to, :test_plan)
                .newest_first
                .to_a
      @run_status_counts = status_counts_for(@runs.map(&:id))
      @plans = @milestone.test_plans.includes(:assigned_to).newest_first.to_a
      TestManagement::TestPlan.preload_summaries(@plans) if @plans.any?
      @visible_work_packages = @milestone.work_packages.visible(current_user).includes(:type).order(:id).to_a
    end

    def new
      @milestone = @project.tm_milestones.build(parent_id: params[:parent_id].presence)
    end

    def edit; end

    def create
      call = TestManagement::Milestones::CreateService
               .new(user: current_user)
               .call(milestone_params.merge(project: @project))

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_test_management_milestone_path(@project, call.result)
      else
        @milestone = call.result
        render action: :new, status: :unprocessable_entity
      end
    end

    def update
      call = TestManagement::Milestones::UpdateService
               .new(user: current_user, model: @milestone)
               .call(milestone_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_test_management_milestone_path(@project, @milestone)
      else
        render action: :edit, status: :unprocessable_entity
      end
    end

    def destroy
      call = TestManagement::Milestones::DeleteService.new(user: current_user, model: @milestone).call
      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
        redirect_to project_test_management_milestones_path(@project)
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_milestone_path(@project, @milestone)
      end
    end

    def start
      transition(TestManagement::Milestones::StartService, "test_management.milestones.started_notice")
    end

    def complete
      transition(TestManagement::Milestones::CompleteService, "test_management.milestones.completed_notice")
    end

    def reopen
      transition(TestManagement::Milestones::ReopenService, "test_management.milestones.reopened_notice")
    end

    private

    def require_milestones_enabled
      render_404 unless TestManagement::ProjectSetting.milestones_enabled?(@project)
    end

    def find_milestone
      @milestone = @project.tm_milestones.find(params.expect(:id))
    end

    def load_form_data
      milestone_id = params[:id].to_i
      @parent_options = @project.tm_milestones.roots.ordered.reject { |m| m.id == milestone_id }
      @version_options = @project.shared_versions.order(:name).to_a
    end

    # [[milestone, depth]]: roots followed by their sub-milestones; a sub-milestone whose
    # parent is filtered out is shown at the top level.
    def tree_rows(milestones)
      ids = milestones.to_set(&:id)
      by_parent = milestones.group_by(&:parent_id)
      roots = milestones.select { |m| m.parent_id.nil? || ids.exclude?(m.parent_id) }
      roots.flat_map { |root| [[root, 0]] + by_parent.fetch(root.id, []).map { |child| [child, 1] } }
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
      call = service_class.new(user: current_user, model: @milestone).call
      if call.success?
        flash[:notice] = I18n.t(notice_key)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_milestone_path(@project, @milestone)
    end

    def milestone_params
      params.expect(milestone: [:name, :description, :start_date, :due_date, :parent_id, :version_id,
                                :work_package_ids, { work_package_ids: [] }])
    end
  end
end

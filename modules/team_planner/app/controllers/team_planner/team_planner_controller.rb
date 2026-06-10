# frozen_string_literal: true

module ::TeamPlanner
  class TeamPlannerController < BaseController
    include EnterpriseHelper
    include Layout
    include WorkPackages::WithSplitView

    before_action :load_and_authorize_in_optional_project
    before_action :build_plan_view, only: %i[new]
    before_action :find_plan_view, only: %i[destroy split_view]
    authorize_with_permission :add_work_packages, only: %i[split_create]

    guard_enterprise_feature(:team_planner_view, except: %i[index overview]) do
      redirect_to action: :index
    end

    menu_item :team_planner_view

    def index
      @views = visible_plans(@project)
    end

    def overview
      @views = visible_plans
      render layout: "global"
    end

    def show; end
    def new; end

    def create
      service_result = create_service_class.new(user: User.current)
                                           .call(plan_view_params)

      @view = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_team_planner_path(@project, @view.query)
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def split_view
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_view", layout: false
          else
            render :show
          end
        end
      end
    end

    def split_create
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_create", layout: false
          else
            render :show
          end
        end
      end
    end

    def upsell; end

    def destroy
      if @view.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t(:error_can_not_delete_entry)
      end

      redirect_to action: :index, status: :see_other
    end

    current_menu_item :index do
      :team_planner_view
    end

    current_menu_item :overview do
      :team_planners
    end

    private

    def split_view_base_route
      # Unsaved team planners use the /new collection path (no :id).
      # In that case @view is nil and we return the /new path as the base route
      # so that the split view close button navigates back correctly.
      if @view
        project_team_planner_path(@project, @view, request.query_parameters)
      else
        new_project_team_planners_path(@project, request.query_parameters)
      end
    end

    def create_service_class
      TeamPlanner::Views::GlobalCreateService
    end

    def plan_view_params
      params.expect(query: %i[name public starred]).merge(project_id: @project&.id)
    end

    def build_plan_view
      @view = Query.new
    end

    def find_plan_view
      # The split_view action is also reachable via the /new collection path
      # (e.g. /team_planners/new/details/:wp_id) which carries no :id.
      # In that case @view remains nil and split_view_base_route handles it.
      return if params[:id].blank?

      query_scope = Query.visible(current_user)
      query_scope = query_scope.where(project_id: @project.id) if @project

      @view = query_scope.find(params[:id])
    end

    def visible_plans(project = nil)
      query = Query
        .visible(current_user)
        .includes(:project)
        .joins(:views)
        .references(:projects)
        .where("views.type" => "team_planner")
        .order("queries.name ASC")

      if project
        query = query.where("queries.project_id" => project.id)
      else
        allowed_projects = Project.allowed_to(User.current, :view_team_planner)
        query = query.where(queries: { project: allowed_projects })
      end

      query
    end
  end
end

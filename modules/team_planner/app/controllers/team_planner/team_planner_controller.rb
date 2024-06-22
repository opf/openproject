module ::TeamPlanner
  class TeamPlannerController < BaseController
    include EnterpriseTrialHelper
    include Layout
    before_action :load_and_authorize_in_optional_project
    before_action :build_plan_view, only: %i[new]
    before_action :require_ee_token, except: %i[upsale]
    before_action :find_plan_view, only: %i[destroy]

    menu_item :team_planner_view

    def index
      @views = visible_plans(@project)
    end

    def overview
      @views = visible_plans
      render layout: "global"
    end

    def new; end

    def create
      service_result = create_service_class.new(user: User.current)
                                           .call(plan_view_params)

      @view = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_team_planner_path(@project, @view.query)
      else
        render action: :new
      end
    end

    def show
      render layout: "angular/angular"
    end

    def upsale; end

    def destroy
      if @view.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t(:error_can_not_delete_entry)
      end

      redirect_to action: :index
    end

    def require_ee_token
      unless EnterpriseToken.allows_to?(:team_planner_view)
        redirect_to action: :upsale
      end
    end

    current_menu_item :index do
      :team_planner_view
    end

    current_menu_item :overview do
      :team_planners
    end

    private

    def create_service_class
      TeamPlanner::Views::GlobalCreateService
    end

    def plan_view_params
      params.require(:query).permit(:name, :public, :starred).merge(project_id: @project&.id)
    end

    def build_plan_view
      @view = Query.new
    end

    def find_plan_view
      @view = Query
        .visible(current_user)
        .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
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

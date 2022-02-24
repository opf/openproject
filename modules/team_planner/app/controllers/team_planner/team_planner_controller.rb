module ::TeamPlanner
  class TeamPlannerController < BaseController
    include EnterpriseTrialHelper
    before_action :find_optional_project
    before_action :authorize, only: %i[index]
    before_action :require_ee_token, only: %i[index]
    before_action :redirect_to_first_plan, only: :index

    menu_item :team_planner_view

    def index
      render layout: 'angular/angular'
    end

    def upsale; end

    def require_ee_token
      unless EnterpriseToken.allows_to?(:team_planner_view)
        redirect_to project_team_planner_upsale_path
      end
    end

    current_menu_item :index do
      :team_planner_view
    end

    private

    def redirect_to_first_plan
      return unless @project
      return if team_planner_query_params?

      if (query_id = find_existing_plan)
        redirect_to action: :index, query_id: query_id
      end
    end

    def find_existing_plan
      Query
        .visible(current_user)
        .joins(:views)
        .where('views.type' => 'team_planner')
        .where('queries.project_id' => @project.id)
        .order('queries.name ASC')
        .pick('queries.id')
    end

    def team_planner_query_params?
      params[:query_id] || params[:query_props]
    end
  end
end

module ::TeamPlanner
  class TeamPlannerController < BaseController
    before_action :find_optional_project
    before_action :authorize, only: %i[index]
    before_action :require_ee_token, only: %i[index]

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
  end
end

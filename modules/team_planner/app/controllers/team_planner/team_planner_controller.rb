module ::TeamPlanner
  class TeamPlannerController < BaseController
    before_action :find_optional_project
    before_action :authorize

    menu_item :team_planner_view

    def index
      render layout: 'angular/angular'
    end

    current_menu_item :index do
      :team_planner_view
    end
  end
end

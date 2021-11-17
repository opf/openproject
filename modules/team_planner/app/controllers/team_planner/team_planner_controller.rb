module ::TeamPlanner
  class TeamPlannerController < BaseController
    before_action :find_optional_project
    before_action :authorize

    # The team planner permission alone does not suffice
    # to view work packages
    before_action :authorize_work_package_permission

    menu_item :team_planner_view

    def index
      render layout: 'angular/angular'
    end

    current_menu_item :index do
      :team_planner_view
    end

    private

    def authorize_work_package_permission
      unless current_user.allowed_to?(:view_work_packages, @project, global: @project.nil?)
        deny_access
      end
    end
  end
end

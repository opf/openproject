module ::TeamPlanner
  class TeamPlannerController < BaseController
    include EnterpriseTrialHelper
    before_action :find_optional_project
    before_action :authorize, except: %i[overview upsale]
    before_action :authorize_global, only: %i[overview]
    before_action :require_ee_token, except: %i[upsale]
    before_action :find_plan_view, only: %i[destroy]

    menu_item :team_planner_view

    def index
      @views = visible_plans(@project)
    end

    def overview
      @views = visible_plans
    end

    def show
      render layout: 'angular/angular'
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

    private

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
        .where('views.type' => 'team_planner')
        .order('queries.name ASC')

      if project
        query = query.where('queries.project_id' => project.id)
      end

      query
    end
  end
end

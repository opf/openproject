module Api
  module V2

    class PlanningElementStatusesController < PlanningElementStatusesController
      unloadable
      helper :timelines

      accept_key_auth :index, :show

      def index
        @planning_element_statuses = PlanningElementStatus.active
        respond_to do |format|
          format.api
        end
      end

      def show
        @planning_element_status = PlanningElementStatus.active.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end


module Api
  module V2

    class PlanningElementTypesController < PlanningElementTypesController

      include ::Api::V2::ApiController

      def index
        @planning_element_types = @base.all
        respond_to do |format|
          format.api
        end
      end

      def show
        @planning_element_type = @base.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end

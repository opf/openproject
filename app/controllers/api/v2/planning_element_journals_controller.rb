module Api
  module V2

    class PlanningElementJournalsController < PlanningElementJournalsController

      include ::Api::V2::ApiController

      def index
        @journals = @planning_element.journals
        respond_to do |format|
          format.api
        end
      end
    end

  end
end


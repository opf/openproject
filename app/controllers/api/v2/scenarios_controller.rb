module Api
  module V2

    class ScenariosController < ScenariosController

      include ::Api::V2::ApiController

      def index
        @scenarios = @project.scenarios
        respond_to do |format|
          format.api
        end
      end

      def show
        @scenario = @project.scenarios.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end

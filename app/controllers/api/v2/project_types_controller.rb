module Api
  module V2

    class ProjectTypesController < ProjectTypesController

      include ::Api::V2::ApiController

      def index
        @project_types = ProjectType.all
        respond_to do |format|
          format.api
        end
      end

      def show
        @project_type = ProjectType.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end

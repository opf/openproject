module Api
  module V2

    class ReportedProjectStatusesController < ReportedProjectStatusesController

      include ::Api::V2::ApiController

      def index
        @reported_project_statuses = @base.all
        respond_to do |format|
          format.api
        end
      end

      def show
        @reported_project_status = @base.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end

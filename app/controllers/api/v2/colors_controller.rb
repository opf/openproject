module Api
  module V2

    class ColorsController < ColorsController

      include ::Api::V2::ApiController

      def index
        @colors = Color.all
        respond_to do |format|
          format.api
        end
      end

      def show
        @color = Color.find(params[:id])
        respond_to do |format|
          format.api
        end
      end

    end
  end
end

module Api
  module V2

    class UsersController < UsersController
      include ::Api::V2::ApiController

      skip_filter :require_admin, :only => :index

      def index
        @users = []
        @users = UserSearchService.new(params).search if params[:ids] and not params[:ids].empty?

        respond_to do |format|
          format.api
        end
      end

    end

  end



end

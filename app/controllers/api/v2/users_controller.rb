module Api
  module V2

    class UsersController < UsersController
      include ::Api::V2::ApiController

      skip_filter :require_admin, :only => :index

      def index
        @users = UserSearchService.new(params).search.visible_by(User.current)

        respond_to do |format|
          format.api
        end
      end

    end

  end



end

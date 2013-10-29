module Api
  module V2

    class UsersController < UsersController
      include ::Api::V2::ApiController


      def index
        @users = UserSearchService.new(params).search

        respond_to do |format|
          format.api
        end
      end

    end

  end



end

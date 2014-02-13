module Api
  module V2

    class UsersController < UsersController
      include ::Api::V2::ApiController

      skip_filter :require_admin, :only => :index

      before_filter :check_scope_supplied

      def index
        @users = UserSearchService.new(params).search

        respond_to do |format|
          format.api
        end
      end

      private

      def check_scope_supplied
        render_400 if params.select { |k,v| UserSearchService::SEARCH_SCOPES.include? k }
                            .select { |k,v| not v.blank? }
                            .empty?
      end

    end
  end
end

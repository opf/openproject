

module Api
  module V3

    class QueriesController < ApplicationController
      unloadable

      include PaginationHelper
      include QueriesHelper
      include ::Api::V3::ApiController
      include ExtendedHTTP

      before_filter :authorize_and_setup_project

      def available_columns
        query = retrieve_query
        @available_columns = query.available_columns

        respond_to do |format|
          format.api
        end
      end

      private

      def authorize_and_setup_project
        find_project_by_project_id         unless performed?
        # authorize                          unless performed?
      end
    end

  end
end
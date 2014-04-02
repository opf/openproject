

module Api::V3
  class QueriesController < ApplicationController
    unloadable

    include ApiController
    include Concerns::ColumnData

    include QueriesHelper
    include ExtendedHTTP

    before_filter :find_optional_project

    def available_columns
      query = retrieve_query
      @available_columns = get_columns_for_json(query.available_columns)

      respond_to do |format|
        format.api
      end
    end
  end
end

# frozen_string_literal: true

module Boards
  class BasicBoardCreateService < BaseCreateService
    private

    def query_name
      "Unnamed list"
    end

    def query_filters
      [{ manual_sort: { operator: "ow", values: [] } }]
    end

    def options_for_widgets(params)
      [
        Grids::Widget.new(
          start_row: 1,
          start_column: 1,
          end_row: 2,
          end_column: 2,
          identifier: "work_package_query",
          options: {
            "queryId" => params[:query_id],
            "filters" => query_filters
          }
        )
      ]
    end
  end
end

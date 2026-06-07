# frozen_string_literal: true

module Boards
  # Scrum Base style board. Phase 0: behaves like the Status/Kanban board
  # (columns are workflow statuses, dragging a card changes its status), but
  # is stored under its own action attribute ("scrum_base") so later phases can
  # diverge (swimlanes, WIP limits, multi-status columns) without affecting
  # the plain Status board.
  class ScrumBaseBoardCreateService < BaseCreateService
    private

    def query_name
      default_status.name
    end

    def query_filters
      [{ status_id: { operator: "=", values: [default_status.id.to_s] } }]
    end

    def default_status
      @default_status ||= ::Status.default
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

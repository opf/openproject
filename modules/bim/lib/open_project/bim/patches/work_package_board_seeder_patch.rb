module OpenProject::Bim::Patches::WorkPackageBoardSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_data!
      super

      return unless OpenProject::Configuration.bim?

      if board_data = project_data.lookup("boards.bcf")
        print_status "    ↳ Creating demo BCF board" do
          seed_bcf_board(board_data)
          Setting.boards_demo_data_available = "true"
        end
      end
    end

    def seed_bcf_board(board_data)
      widgets = seed_bcf_board_widgets
      board =
        ::Boards::Grid.new(
          project:,
          name: board_data.lookup("name"),
          options: { "type" => "action", "attribute" => "status", "highlightingMode" => "type" },
          widgets:,
          column_count: widgets.count,
          row_count: 1
        )
      board.save!
    end

    def seed_bcf_board_widgets
      seed_bcf_board_queries.each_with_index.map do |query, i|
        Grids::Widget.new start_row: 1, end_row: 2,
                          start_column: i + 1, end_column: i + 2,
                          options: { query_id: query.id,
                                     filters: [{ status: { operator: "=", values: query.filters[0].values } }] },
                          identifier: "work_package_query"
      end
    end

    def seed_bcf_board_queries
      statuses(
        :default_status_new,
        :default_status_in_progress,
        :default_status_resolved,
        :default_status_closed
      ).map do |status|
        Query.new_default(project:, user: admin_user).tap do |query|
          # Make it public so that new members can see it too
          query.public = true

          query.name = status.name
          # Set filter by this status
          query.add_filter("status_id", "=", [status.id])

          # Set manual sort filter
          query.sort_criteria = [[:manual_sorting, "asc"]]

          query.save!
        end
      end
    end
  end
end

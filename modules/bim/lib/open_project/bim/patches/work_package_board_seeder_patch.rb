module OpenProject::Bim::Patches::WorkPackageBoardSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_data!
      super

      if OpenProject::Configuration.bim? && project_has_data_for?(key, 'boards.bcf')
        print '    ↳ Creating demo BCF board'
        seed_bcf_board
        puts
      end
    end

    def seed_bcf_board
      board = ::Boards::Grid.new project: project

      board.name = project_data_for(key, 'boards.bcf.name')
      board.options = { 'type' => 'action', 'attribute' => 'status', 'highlightingMode' => 'type' }

      board.widgets = seed_bcf_board_queries.each_with_index.map do |query, i|
        Grids::Widget.new start_row: 1, end_row: 2,
                          start_column: i + 1, end_column: i + 2,
                          options: { query_id: query.id,
                                     filters: [{ status: { operator: '=', values: query.filters[0].values } }] },
                          identifier: 'work_package_query'
      end

      board.column_count = board.widgets.count
      board.row_count = 1

      board.save!

      Setting.boards_demo_data_available = 'true'
    end

    def seed_bcf_board_queries
      admin = User.admin.first
      status_names = ['New', 'In progress', 'Resolved', 'Closed']
      statuses = Status.where(name: status_names).to_a

      if statuses.size < status_names.size
        raise StandardError.new "Not all statuses needed for seeding a BCF board are present. Check that they get seeded."
      end

      statuses.to_a.map do |status|
        Query.new_default(project: project, user: admin).tap do |query|
          # Hide the query in the main menu
          query.hidden = true

          # Make it public so that new members can see it too
          query.is_public = true

          query.name = status.name
          # Set filter by this status
          query.add_filter('status_id', '=', [status.id])

          # Set manual sort filter
          query.sort_criteria = [[:manual_sorting, 'asc']]

          query.save!
        end
      end
    end
  end
end

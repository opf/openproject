#-- copyright

# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
module DemoData
  class WorkPackageBoardSeeder < Seeder
    attr_reader :project
    alias_method :project_data, :seed_data

    include ::DemoData::References

    def initialize(project, project_data)
      super(project_data)
      @project = project
    end

    def seed_data!
      # Seed only for those projects that provide a `kanban` key, i.e. 'demo-project' in standard edition.
      if board_data = project_data.lookup('boards.kanban')
        print_status '    ↳ Creating demo status board' do
          seed_kanban_board(board_data)
        end
        Setting.boards_demo_data_available = 'true'
      end

      if board_data = project_data.lookup('boards.basic')
        print_status '    ↳ Creating demo basic board' do
          seed_basic_board(board_data)
        end
      end

      if board_data = project_data.lookup('boards.parent_child')
        print_status '    ↳ Creating demo parent child board' do
          seed_parent_child_board(board_data)
        end
        Setting.boards_demo_data_available = 'true'
      end
    end

    private

    def seed_kanban_board(board_data)
      widgets = seed_kanban_board_widgets
      board =
        ::Boards::Grid.new(
          project:,
          name: board_data.lookup('name'),
          options: { 'type' => 'action', 'attribute' => 'status', 'highlightingMode' => 'priority' },
          widgets:,
          column_count: widgets.count,
          row_count: 1
        )
      set_board_filters(board, board_data)
      board.save!
    end

    def seed_kanban_board_widgets
      seed_kanban_board_queries.each_with_index.map do |query, i|
        Grids::Widget.new start_row: 1, end_row: 2,
                          start_column: i + 1, end_column: i + 2,
                          options: { query_id: query.id,
                                     filters: [{ status: { operator: '=', values: query.filters[0].values } }] },
                          identifier: 'work_package_query'
      end
    end

    def set_board_filters(board, board_data)
      filters_conf = board_data.lookup('filters')
      return if filters_conf.blank?

      board.options[:filters] = []
      filters_conf.each do |filter|
        if filter['type']
          type = seed_data.find_reference(filter['type'])
          board.options[:filters] << { type: { operator: '=', values: [type.id.to_s] } }
        end
      end
    end

    def seed_kanban_board_queries
      statuses(
        :default_status_new,
        :default_status_in_progress,
        :default_status_closed,
        :default_status_rejected
      ).map do |status|
        Query.new_default(project:, user: admin_user).tap do |query|
          # Make it public so that new members can see it too
          query.public = true

          query.name = status.name
          # Set filter by this status
          query.add_filter('status_id', '=', [status.id])

          # Set manual sort filter
          query.sort_criteria = [[:manual_sorting, 'asc']]

          query.save!
        end
      end
    end

    def statuses(*status_references)
      statuses = seed_data.find_references(status_references)

      if statuses.size < status_references.size
        raise StandardError, "Not all statuses needed for seeding a board are present. Check that they got seeded."
      end

      statuses
    end

    def seed_basic_board(board_data)
      widgets = seed_basic_board_widgets(board_data)
      board =
        ::Boards::Grid.new(
          project:,
          name: board_data.lookup('name'),
          options: { 'highlightingMode' => 'priority' },
          widgets:,
          column_count: widgets.count,
          row_count: 1
        )
      board.save!
    end

    def seed_basic_board_widgets(board_data)
      seed_basic_board_queries(board_data).each_with_index.map do |query, i|
        Grids::Widget.new start_row: 1, end_row: 2,
                          start_column: i + 1, end_column: i + 2,
                          options: { query_id: query.id,
                                     filters: [{ manualSort: { operator: 'ow', values: [] } }] },
                          identifier: 'work_package_query'
      end
    end

    def seed_basic_board_queries(board_data)
      lists = board_data.lookup('lists')
      lists.map do |list|
        create_basic_board_query_from_list(list)
      end
    end

    def create_basic_board_query_from_list(list)
      Query.new(
        project:,
        user: admin_user,
        # Make it public so that new members can see it too
        public: true,
        include_subprojects: true,
        name: list['name']
      ).tap do |query|
        # Set manual sort filter
        query.add_filter('manual_sort', 'ow', [])
        query.sort_criteria = [[:manual_sorting, 'asc']]

        list['work_packages'].each_with_index do |wp_reference, i|
          work_package_id = seed_data.find_reference(wp_reference).id
          query.ordered_work_packages.build(work_package_id:, position: i)
        end

        query.save!
      end
    end

    def seed_parent_child_board(board_data)
      widgets = seed_parent_child_board_widgets
      board =
        ::Boards::Grid.new(
          project:,
          name: board_data.lookup('name'),
          options: { 'type' => 'action', 'attribute' => 'subtasks' },
          widgets:,
          column_count: widgets.count,
          row_count: 1
        )
      board.save!
    end

    def seed_parent_child_board_widgets
      seed_parent_child_board_queries.each_with_index.map do |query, i|
        Grids::Widget.new start_row: 1, end_row: 2,
                          start_column: i + 1, end_column: i + 2,
                          options: { query_id: query.id,
                                     filters: [{ parent: { operator: '=', values: query.filters[1].values } }] },
                          identifier: 'work_package_query'
      end
    end

    def seed_parent_child_board_queries
      parents = [seed_data.find_reference(:organize_open_source_conference),
                 seed_data.find_reference(:follow_up_tasks)]

      parents.map do |parent|
        Query.new_default(project:, user: admin_user).tap do |query|
          # Make it public so that new members can see it too
          query.public = true

          query.name = parent.subject
          # Set filter by this status
          query.add_filter('parent', '=', [parent.id])

          # Set manual sort filter
          query.sort_criteria = [[:manual_sorting, 'asc']]

          query.save!
        end
      end
    end
  end
end

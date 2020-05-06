#-- encoding: UTF-8

#-- copyright

# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
module DemoData
  class WorkPackageBoardSeeder < Seeder
    attr_accessor :project, :key

    include ::DemoData::References

    def initialize(project, key)
      self.project = project
      self.key = key
    end

    def seed_data!
      # Seed only for those projects that provide a `kanban` key, i.e. 'demo-project' in standard edition.
      if project_has_data_for?(key, 'boards.kanban')
        print '    ↳ Creating demo status board'
        seed_kanban_board
        puts
      end

      if project_has_data_for?(key, 'boards.basic')
        print '    ↳ Creating demo basic board'
        seed_basic_board
        puts
      end
    end

    private

    def seed_kanban_board
      board = ::Boards::Grid.new project: project

      board.name = project_data_for(key, 'boards.kanban.name')
      board.options = { 'type' => 'action', 'attribute' => 'status', 'highlightingMode' => 'priority' }

      board.widgets = seed_kanban_board_queries.each_with_index.map do |query, i|
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

    def seed_kanban_board_queries
      admin = User.admin.first

      status_names = ['New', 'In progress', 'Closed', 'Rejected']
      statuses = Status.where(name: status_names).to_a

      if statuses.size < status_names.size
        raise StandardError.new "Not all statuses needed for seeding a KANBAN board are present. Check that they get seeded."
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

    def seed_basic_board
      board = ::Boards::Grid.new project: project
      board.name = project_data_for(key, 'boards.basic.name')
      board.options = { 'highlightingMode' => 'priority' }

      board.widgets = seed_basic_board_queries.each_with_index.map do |query, i|
        Grids::Widget.new start_row: 1, end_row: 2,
                          start_column: i + 1, end_column: i + 2,
                          options: { query_id: query.id,
                                     filters: [{ manualSort: { operator: 'ow', values: [] } }] },
                          identifier: 'work_package_query'
      end

      board.column_count = board.widgets.count
      board.row_count = 1

      board.save!
    end

    def seed_basic_board_queries
      admin = User.admin.first

      wps = if project.name === 'Scrum project'
              scrum_query_work_packages
            else
              basic_query_work_packages
            end

      lists = [{ name: 'Today', wps: wps[0] },
               { name: 'Tomorrow', wps: wps[1] },
               { name: 'Later', wps: wps[2] },
               { name: 'Never', wps: wps[3] }]

      lists.map do |list|
        Query.new(project: project, user: admin).tap do |query|
          # Hide the query in the main menu
          query.hidden = true

          # Make it public so that new members can see it too
          query.is_public = true

          query.name = list[:name]

          # Set manual sort filter
          query.add_filter('manual_sort', 'ow', [])
          query.sort_criteria = [[:manual_sorting, 'asc']]

          list[:wps].each_with_index do |wp_id, i|
            query.ordered_work_packages.build(work_package_id: wp_id, position: i)
          end

          query.save!
        end
      end
    end

    def scrum_query_work_packages
      [
        [WorkPackage.find_by(subject: 'New website').id,
         WorkPackage.find_by(subject: 'SSL certificate').id,
         WorkPackage.find_by(subject: 'Choose a content management system').id],
        [WorkPackage.find_by(subject: 'New login screen').id],
        [WorkPackage.find_by(subject: 'Set-up Staging environment').id],
        [WorkPackage.find_by(subject: 'Wrong hover color').id]
      ]
    end

    def basic_query_work_packages
      [
        [WorkPackage.find_by(subject: 'Create a new project').id,
         WorkPackage.find_by(subject: 'Edit a work package').id,
         WorkPackage.find_by(subject: 'Create work packages').id,
         WorkPackage.find_by(subject: 'Activate further modules').id],
        [WorkPackage.find_by(subject: 'Create a project plan').id],
        [WorkPackage.find_by(subject: 'Invite new team members').id],
        [WorkPackage.find_by(subject: 'Customize project overview page').id]
      ]
    end
  end
end

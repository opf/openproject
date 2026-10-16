#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Bim::Patches::WorkPackageBoardSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    BCF_BOARD_STATUS_REFERENCES = %i[
      default_status_new
      default_status_in_progress
      default_status_resolved
      default_status_closed
    ].freeze

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

    def all_required_references
      required_refs = super
      if OpenProject::Configuration.bim? && project_data.lookup("boards.bcf")
        required_refs += BCF_BOARD_STATUS_REFERENCES
        required_refs.uniq!
      end
      required_refs
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
      seed_data.find_references(BCF_BOARD_STATUS_REFERENCES).map do |status|
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

# frozen_string_literal: true

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

require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s
Dir[File.join(__dir__, "tables/*.rb")].each { |file| require file }

class AggregatedBacklogsMigrations < SquashedMigration
  squashed_migrations *%w[
    20180323151208_to_v710_aggregated_backlogs_migrations
    20230717104700_drop_export_card_configurations
  ].freeze

  tables Tables::DoneStatusesForProject,
         Tables::VersionSettings

  modifications do
    add_column :work_packages, :position, :integer
    add_column :work_packages, :story_points, :integer
    add_column :work_packages, :remaining_hours, :float

    add_column :work_package_journals, :story_points, :integer
    add_column :work_package_journals, :remaining_hours, :float

    add_index :work_package_journals,
              %i[version_id
                 status_id
                 project_id
                 type_id],
              name: "work_package_journal_on_burndown_attributes"
  end
end

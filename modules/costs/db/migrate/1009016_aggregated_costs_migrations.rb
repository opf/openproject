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
require_relative "tables/cost_entries"
require_relative "tables/cost_types"
require_relative "tables/rates"
require_relative "tables/time_entries"
require_relative "tables/time_entry_activities_projects"
require_relative "tables/time_entry_journals"

class AggregatedCostsMigrations < SquashedMigration
  squashed_migrations *%w[
    1009015_aggregated_costs_migrations
    20241120103858_add_start_end_times_to_time_entries
    20241125104347_add_timezone_identifier_to_time_entry
    20250219103939_make_time_entry_comment_text_field
  ].freeze

  tables Tables::CostEntries,
         Tables::CostTypes,
         Tables::Rates,
         Tables::TimeEntries,
         Tables::TimeEntryActivitiesProjects,
         Tables::TimeEntryJournals
end

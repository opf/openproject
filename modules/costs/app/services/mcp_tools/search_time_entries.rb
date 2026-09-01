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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  class SearchTimeEntries < SearchTool
    default_title "Search time entries"
    default_description "Search time entries matching all of the passed input parameters. " \
                        "Parameters not passed are ignored. Results are limited to a maximum " \
                        "of #{page_size} time entries. To get the rest of the results, call the tool again with a " \
                        "page number of 2 or higher."

    name "search_time_entries"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    filter :id
    filter :user_id
    filter :work_package_id, filter_proc: ->(entries, v) { entries.where(entity_type: "WorkPackage", entity_id: v) }
    filter :spent_since, filter_proc: ->(entries, v) { entries.where(spent_on: v..) }
    filter :spent_until, filter_proc: ->(entries, v) { entries.where(spent_on: ..v) }

    input_schema(
      additionalProperties: false,
      properties: {
        id: { type: "number", description: "The ID of the time entry." },
        user_id: { type: "number", description: "The ID of the user that the time entry tracks expenditures for." },
        work_package_id: { type: "number", description: "The ID of the work package that the time entry is created on." },
        spent_since: {
          type: :string,
          format: :date,
          description: "Lower limit of the date for which returned time entries are booked for. Defaults to today."
        },
        spent_until: {
          type: :string,
          format: :date,
          description: "Upper limit of the date for which returned time entries are booked for. Defaults to today."
        }
      }
    )

    def base_scope = Success(TimeEntry.visible)

    def default_filters = { spent_since: Date.current, spent_until: Date.current }

    def format_item(item)
      API::V3::TimeEntries::TimeEntryRepresenter.create(item, current_user:)
    end
  end
end

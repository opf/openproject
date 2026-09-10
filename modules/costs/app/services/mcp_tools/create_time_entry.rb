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
  class CreateTimeEntry < Base
    default_title "Create time entry"
    default_description "Create a new time entry."

    name "create_time_entry"
    annotations read_only: false, idempotent: false, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[data],
      properties: {
        data: {
          type: :object,
          description: "JSON Representation of the time entry to be created. The format is the same as accepted by APIv3.",
          properties: {
            _links: {
              description: "Contains related resources, such as the entity that this entry is associated to.",
              properties: {
                entity: { type: :object },
                user: { type: :object }
              }
            },
            hours: {
              type: :string,
              format: :duration,
              description: "The time quantifying the expenditure."
            },
            spentOn: {
              type: :string,
              format: :date,
              description: "The date the expenditure is booked for."
            },
            comment: {
              type: :object,
              description: "A comment to the time entry. Passed as a formattable property",
              properties: {
                raw: { type: :string, description: "The raw markdown formatted text." }
              }
            }
          }
        }
      }
    )

    def call(data:)
      parsed = parse_time_entry(data).on_failure { |result| return Failure(result.message) }.result
      parsed = parsed.reverse_merge(user_id: current_user.id, spent_on: Date.current)
      result = TimeEntries::CreateService.new(user: current_user).call(**parsed)

      format_result(result)
    end

    private

    def parse_time_entry(data)
      ::API::V3::ParseResourceParamsService.new(current_user, model: TimeEntry).call(data.deep_stringify_keys)
    end

    def format_result(result)
      if result.success?
        Success(API::V3::TimeEntries::TimeEntryRepresenter.create(result.result, current_user:))
      else
        Failure(result.message)
      end
    end
  end
end

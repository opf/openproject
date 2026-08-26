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
  class SearchCustomFields < SearchTool
    default_title "Search custom fields"
    default_description "Show details of the custom fields matching given criteria."

    name "search_custom_fields"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    filter :id
    filter :name, filter_proc: ->(cfs, v) { cfs.where("name ILIKE '%#{OpenProject::SqlSanitization.quoted_sanitized_sql_like(v)}%'") }

    input_schema(
      additionalProperties: false,
      properties: {
        id: {
          type: %i[number array],
          description: "The ID of the custom field that shall be fetched. Can also be an array of IDs to fetch " \
                       "multiple custom fields at once."
        },
        name: {
          type: :string,
          description: "The name of the custom field that shall be fetched. Matches partially and case-insensitive."
        }
      }
    )

    def base_scope
      Success(CustomField.visible)
    end

    def format_item(item)
      ::API::V3::CustomFields::CustomFieldRepresenter.create(item, current_user:)
    end
  end
end

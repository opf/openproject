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
  class SearchUsers < SearchTool
    default_title "Search users"
    default_description "Search users matching all of the passed input parameters. " \
                        "Parameters not passed are ignored. Results are limited to a maximum of #{page_size} users. " \
                        "To get the rest of the results, call the tool again with a page number of 2 or higher."

    name "search_users"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    filter :search_term, filter_class: "Queries::Users::Filters::AnyNameAttributeFilter", operator: "~"

    input_schema(
      additionalProperties: false,
      properties: {
        search_term: {
          type: "string",
          description: "A search term to find the user by. Accepts first name and last name. Also accepts email address, " \
                       "if instance settings allow it."
        }
      }
    )

    def base_scope
      Success(User.visible.not_builtin)
    end

    def format_item(item)
      API::V3::Users::UserRepresenter.create(item, current_user:)
    end
  end
end

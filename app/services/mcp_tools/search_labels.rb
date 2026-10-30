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

module McpTools
  class SearchLabels < SearchTool
    default_title "Search labels"
    default_description "Search work package labels matching all of the passed input parameters. " \
                        "Parameters not passed are ignored. Results are limited to a maximum " \
                        "of #{page_size} labels. To get the rest of the results, call the tool again with a " \
                        "page number of 2 or higher."

    name "search_labels"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    filter :name, filter_class: "Queries::Labels::Filters::NameFilter", operator: "~"

    input_schema(
      additionalProperties: false,
      properties: {
        name: { type: "string", description: "Name of the label. Accepts partial label names, not case-sensitive." }
      }
    )

    def base_scope
      return Success(Label.none) unless labels_visible?

      Success(Label.order("LOWER(labels.name) ASC"))
    end

    def format_item(item)
      API::V3::Labels::LabelRepresenter.create(item, current_user:)
    end

    private

    def labels_visible?
      current_user.allowed_in_any_work_package?(:view_work_packages)
    end
  end
end

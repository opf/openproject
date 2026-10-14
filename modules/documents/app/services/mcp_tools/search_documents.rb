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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  class SearchDocuments < SearchTool
    default_title "Search documents"
    default_description "Search documents matching all of the passed input parameters. " \
                        "Parameters not passed are ignored. Results are limited to a maximum " \
                        "of #{page_size} documents. To get the rest of the results, call the tool again with a " \
                        "page number of 2 or higher. The content of collaborative documents can be read with read_document."

    name "search_documents"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    filter :project_id
    filter :title, filter_class: "Queries::Documents::Filters::TitleFilter", operator: "~"

    input_schema(
      additionalProperties: false,
      properties: {
        project_id: { type: "number", description: "The ID of the project that this document belongs to." },
        title: { type: "string", description: "The title of the document. Accepts partial titles, not case-sensitive." }
      }
    )

    def base_scope
      Success(Document.visible(current_user).order(updated_at: :desc))
    end

    def format_item(item)
      API::V3::Documents::DocumentRepresenter
        .new(item, current_user:)
        .as_json
        .merge("collaborative" => item.collaborative?)
    end

    def condensed_attributes
      @condensed_attributes ||= %w[_links id title collaborative createdAt updatedAt].to_set
    end

    def condensed_links
      @condensed_links ||= %w[self project].to_set
    end
  end
end

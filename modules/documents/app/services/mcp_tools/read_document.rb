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
  class ReadDocument < DocumentContentTool
    default_title "Read document"
    default_description "Reads the current content of a collaborative document as BlockNote blocks, including edits " \
                        "of users who are editing it right now. The returned revision is needed to update the content. " \
                        "The blocks follow the schema returned by get_document_schema."

    name "read_document"
    annotations read_only: true, idempotent: true, destructive: false

    input_schema(
      additionalProperties: false,
      required: %w[id],
      properties: {
        id: {
          type: %w[string number],
          description: "The ID of the document."
        }
      }
    )

    def call(id:)
      find_document(id).bind do |document|
        to_result(collaboration_server(document).content).fmap { |content| document_content(document, content) }
      end
    end
  end
end

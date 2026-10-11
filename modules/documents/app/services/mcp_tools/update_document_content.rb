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
  class UpdateDocumentContent < DocumentContentTool
    default_title "Update document content"
    default_description "Replaces the content of a collaborative document with the given BlockNote blocks. " \
                        "Users currently editing the document see the change immediately. " \
                        "Only the differences to the current content are applied. Edits that others made in the meantime " \
                        "are kept, unless they touch the same blocks. In that case the update is rejected; read the document " \
                        "again and reapply your changes."

    name "update_document_content"
    annotations read_only: false, idempotent: true, destructive: true

    input_schema(
      additionalProperties: false,
      required: %w[id revision blocks],
      properties: {
        id: {
          type: %w[string number],
          description: "The ID of the document."
        },
        revision: {
          type: "string",
          description: "The revision returned by read_document (or by the last update) that your changes are based on."
        },
        blocks: {
          type: "array",
          items: { type: "object" },
          description: "The complete new content of the document as BlockNote blocks, following the schema returned by " \
                       "get_document_schema. Keep the id of every block you keep or change, omit the id for new blocks. " \
                       "Blocks that are left out are deleted."
        }
      }
    )

    def call(id:, revision:, blocks:)
      find_document(id).bind do |document|
        next Failure("You are not allowed to edit this document.") unless editable?(document)

        to_result(collaboration_server(document).update_content(revision:, blocks: blocks.as_json))
          .fmap { |content| document_content(document, content) }
      end
    end

    private

    def editable?(document)
      current_user.allowed_in_project?(:manage_documents, document.project)
    end
  end
end

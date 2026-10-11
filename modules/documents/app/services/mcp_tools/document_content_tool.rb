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
  class DocumentContentTool < Base
    private

    def find_document(id)
      return Failure("Real-time collaboration on documents is not enabled.") unless Setting.real_time_text_collaboration_enabled?

      document = Document.visible(current_user).find_by(id:)
      return Failure("The given document could not be found.") if document.nil?
      return Failure("Only the content of collaborative documents can be accessed as blocks.") unless document.collaborative?

      Success(document)
    end

    def collaboration_server(document = nil)
      Documents::CollaborationServer::Client.new(user: current_user, document:)
    end

    def to_result(service_result)
      service_result.success? ? Success(service_result.result) : Failure(service_result.message)
    end

    def document_content(document, content)
      {
        id: document.id,
        title: document.title,
        project: { id: document.project.id, name: document.project.name },
        revision: content["revision"],
        blocks: content["blocks"]
      }
    end
  end
end

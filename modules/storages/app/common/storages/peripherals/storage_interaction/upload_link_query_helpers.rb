#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module Storages::Peripherals::StorageInteraction
  module UploadLinkQueryHelpers
    using Storages::Peripherals::ServiceResultRefinements

    def validate_request_body(body)
      case body.transform_keys(&:to_sym)
      in { projectId: project_id, fileName: file_name, parent: parent }
        authorize(:manage_file_links, context: Project.find(project_id))
        ServiceResult.success(result: { fileName: file_name, parent: }.transform_keys(&:to_s))
      else
        ServiceResult.failure(
          errors: Storages::StorageError.new(code: :bad_request, log_message: 'Request body malformed!')
        )
      end
    end

    def upload_link_query(storage, user)
      Storages::Peripherals::StorageRequests
        .new(storage:)
        .upload_link_query(user:)
    end

    def execute_upload_link_query(request_body)
      ->(query) { validate_request_body(request_body) >> query }
    end
  end
end

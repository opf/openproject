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

require "api/v3/attachments/attachment_collection_representer"

module API
  module V3
    module Attachments
      module AttachmentsByContainerAPI
        module Helpers
          # Global helper to set allowed content_types
          # This may be overridden when multipart is allowed (file uploads)
          def allowed_content_types
            if post_request?
              %w(multipart/form-data)
            else
              super
            end
          end

          def post_request?
            request.env["REQUEST_METHOD"] == "POST"
          end

          ##
          # Additionally to what would be checked by the contract,
          # we need to restrict permissions in some use cases of the mounts of this endpoint.
          def restrict_permissions(permissions)
            return if permissions.empty?

            if container.is_a?(WorkPackage)
              authorize_in_work_package(permissions, work_package: container)
            else
              authorize_in_project(permissions, project: container.project)
            end
          end
        end

        def self.parse_multipart(request)
          request.params.tap do |params|
            params[:metadata] = JSON.parse(params[:metadata]) if params.key?(:metadata)
          end
        rescue JSON::ParserError
          raise ::API::Errors::InvalidRequestBody.new(I18n.t("api_v3.errors.invalid_json"))
        end

        def self.read
          -> do
            attachments = container.attachments
            AttachmentCollectionRepresenter.new(attachments,
                                                self_link: get_attachment_self_path,
                                                current_user:)
          end
        end

        def self.create(permissions = [])
          ::API::V3::Utilities::Endpoints::Create
            .new(model: ::Attachment,
                 parse_representer: AttachmentParsingRepresenter,
                 params_source: method(:parse_multipart),
                 before_hook: ->(request:) { request.restrict_permissions(permissions) },
                 params_modifier: ->(params) do
                   params.merge(container:)
                 end)
            .mount
        end

        def self.prepare(permissions = [])
          ::API::V3::Utilities::Endpoints::Create
            .new(model: ::Attachment,
                 parse_representer: AttachmentParsingRepresenter,
                 render_representer: AttachmentUploadRepresenter,
                 process_service: ::Attachments::PrepareUploadService,
                 process_contract: ::Attachments::PrepareUploadContract,
                 params_source: method(:parse_multipart),
                 before_hook: ->(request:) { request.restrict_permissions(permissions) },
                 params_modifier: ->(params) do
                   params.merge(container:)
                 end)
            .mount
        end
      end
    end
  end
end

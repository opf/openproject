#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/attachments/attachment_collection_representer'

module API
  module V3
    module Attachments
      module AttachmentsByContainerAPI
        module Helpers
          # Global helper to set allowed content_types
          # This may be overriden when multipart is allowed (file uploads)
          def allowed_content_types
            if post_request?
              %w(multipart/form-data)
            else
              super
            end
          end

          def post_request?
            request.env['REQUEST_METHOD'] == 'POST'
          end

          def parse_and_prepare
            metadata = nil

            unless metadata
              raise ::API::Errors::InvalidRequestBody.new(I18n.t('api_v3.errors.multipart_body_error'))
            end

            create_attachment metadata
          end

          def create_attachment(metadata)
            Attachment.create_pending_direct_upload(
              file_name: metadata.file_name,
              container: container,
              author: current_user,
              content_type: metadata.content_type,
              file_size: metadata.file_size
            )
          end

          ##
          # Additionally to what would be checked by the contract,
          # we need to restrict permissions in some use cases of the mounts of this endpoint.
          def restrict_permissions(permissions)
            authorize_any(permissions, projects: container.project) unless permissions.empty?
          end

          def require_direct_uploads
            unless OpenProject::Configuration.direct_uploads?
              raise API::Errors::NotFound, message: "Only available if direct uploads are enabled."
            end
          end

          def parse_multipart(request)
            request.params.tap do |params|
              params[:metadata] = JSON.parse(params[:metadata]) if params.key?(:metadata)
            end
          end
        end

        def self.read
          -> do
            attachments = container.attachments
            AttachmentCollectionRepresenter.new(attachments,
                                                self_link: get_attachment_self_path,
                                                current_user: current_user)
          end
        end

        def self.create(permissions = [])
          -> do
            restrict_permissions permissions

            instance_exec &::API::V3::Utilities::Endpoints::Create
              .new(model: ::Attachment,
                   parse_representer: AttachmentParsingRepresenter,
                   params_getter: method(:parse_multipart),
                   params_modifier: ->(params) do
                     params.merge(container: container)
                   end)
              .mount
          end
        end

        def self.prepare(permissions = [])
          -> do
            require_direct_uploads
            restrict_permissions permissions

            instance_exec &::API::V3::Utilities::Endpoints::Create
               .new(model: ::Attachment,
                    parse_representer: AttachmentParsingRepresenter,
                    process_service: nil, # TODO prepare service
                    params_getter: ->(request) { request.params },
                    params_modifier: ->(params) do
                      params.merge(container: container)
                    end)
               .mount
          end
        end
      end
    end
  end
end

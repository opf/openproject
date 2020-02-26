#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

          def parse_metadata(json)
            return nil unless json

            metadata = OpenStruct.new
            ::API::V3::Attachments::AttachmentMetadataRepresenter.new(metadata).from_json(json)

            unless metadata.file_name
              raise ::API::Errors::Validation.new(
                :file_name,
                "fileName #{I18n.t('activerecord.errors.messages.blank')}."
              )
            end

            metadata
          end

          def parse_and_create
            metadata = parse_metadata params[:metadata]
            file = params[:file]

            unless metadata && file
              raise ::API::Errors::InvalidRequestBody.new(I18n.t('api_v3.errors.multipart_body_error'))
            end

            build_and_attach(metadata, file)
          end

          def build_and_attach(metadata, file)
            uploaded_file = OpenProject::Files.build_uploaded_file file[:tempfile],
                                                                   file[:type],
                                                                   file_name: metadata.file_name.to_s

            service = ::Attachments::CreateService.new(container, author: current_user)

            with_handled_create_errors do
              service.call uploaded_file: uploaded_file,
                           description: metadata.description
            end
          end

          def with_handled_create_errors
            yield
          rescue ActiveRecord::RecordInvalid => error
            raise ::API::Errors::ErrorBase.create_and_merge_errors(error.record.errors)
          rescue StandardError => error
            log_attachment_saving_error(error)
            message =
              if error&.class&.to_s == 'Errno::EACCES'
                I18n.t('api_v3.errors.unable_to_create_attachment_permissions')
              else
                I18n.t('api_v3.errors.unable_to_create_attachment')
              end
            raise ::API::Errors::InternalError.new(message)
          end

          def log_attachment_saving_error(error)
            container_message = if container
                                  "on #{container.class} with ID #{container.id}"
                                else
                                  "without container"
                                end
            message = "Failed to save attachment #{container_message}: #{error&.class} - #{error&.message || 'Unknown error'}"

            Rails.logger.error message
          end
        end

        def self.read
          -> do
            attachments = container.attachments
            AttachmentCollectionRepresenter.new(attachments,
                                                get_attachment_self_path,
                                                current_user: current_user)
          end
        end

        def self.create(permissions = [])
          -> do
            if permissions.empty?
              raise API::Errors::Unauthorized unless container.attachments_addable?(current_user)
            else
              authorize_any(permissions, projects: container.project)
            end

            ::API::V3::Attachments::AttachmentRepresenter.new(parse_and_create,
                                                              current_user: current_user)
          end
        end
      end
    end
  end
end

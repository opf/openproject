#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/attachments/attachment_collection_representer'

module API
  module V3
    module Attachments
      class AttachmentsByWorkPackageAPI < ::API::OpenProjectAPI
        resources :attachments do
          helpers do
            def parse_metadata(json)
              return nil unless json

              metadata = OpenStruct.new
              ::API::V3::Attachments::AttachmentMetadataRepresenter.new(metadata).from_json(json)

              unless metadata.file_name
                raise ::API::Errors::Validation.new(
                  :file_name,
                  "fileName #{I18n.t('activerecord.errors.messages.blank')}.")
              end

              metadata
            end
          end

          get do
            self_path = api_v3_paths.attachments_by_work_package(@work_package.id)
            attachments = @work_package.attachments
            AttachmentCollectionRepresenter.new(attachments,
                                                self_path,
                                                current_user: current_user)
          end

          post do
            authorize_any [:edit_work_packages, :add_work_packages], projects: @work_package.project

            metadata = parse_metadata params[:metadata]
            file = params[:file]

            unless metadata && file
              raise ::API::Errors::InvalidRequestBody.new(
                I18n.t('api_v3.errors.multipart_body_error'))
            end

            uploaded_file = OpenProject::Files.build_uploaded_file file[:tempfile],
                                                                   file[:type],
                                                                   file_name: metadata.file_name

            begin
              service = AddAttachmentService.new(@work_package, author: current_user)
              attachment = service.add_attachment uploaded_file: uploaded_file,
                                                  description: metadata.description
            rescue ActiveRecord::RecordInvalid => error
              raise ::API::Errors::ErrorBase.create_and_merge_errors(error.record.errors)
            end

            ::API::V3::Attachments::AttachmentRepresenter.new(attachment,
                                                              current_user: current_user)
          end
        end
      end
    end
  end
end

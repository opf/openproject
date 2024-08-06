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

module API::V3::StorageFiles
  class StorageFilesAPI < ::API::OpenProjectAPI
    using Storages::Peripherals::ServiceResultRefinements
    helpers Storages::Peripherals::StorageErrorHelper,
            Storages::Peripherals::StorageFileInfoConverter,
            Storages::Peripherals::StorageParentFolderExtractor

    helpers do
      def validate_upload_request(body)
        if Storages::Storage::one_drive_without_ee_token?(@storage.provider_type)
          log_message = "The request can not be handled due to invalid or missing Enterprise token."
          return ServiceResult.failure(errors: Storages::StorageError.new(code: :missing_ee_token_for_one_drive, log_message:))
        end

        case body.transform_keys(&:to_sym)
        in { projectId: project_id, fileName: file_name, parent: parent }
          authorize_in_project(:manage_file_links, project: Project.find(project_id))
          ServiceResult.success(result: Storages::UploadData.new(folder_id: parent, file_name:))
        else
          ServiceResult.failure(errors: Storages::StorageError.new(code: :bad_request,
                                                                   log_message: "Request body malformed!"))
        end
      end

      def fetch_upload_link
        ->(upload_data) do
          Storages::Peripherals::Registry
            .resolve("#{@storage.short_provider_type}.queries.upload_link")
            .call(storage: @storage, auth_strategy:, upload_data:)
        end
      end

      def auth_strategy
        Storages::Peripherals::Registry
          .resolve("#{@storage.short_provider_type}.authentication.userbound")
          .call(user: current_user)
      end
    end

    resources :files do
      get do
        Storages::Peripherals::Registry
          .resolve("#{@storage.short_provider_type}.queries.files")
          .call(storage: @storage, auth_strategy:, folder: extract_parent_folder(params))
          .match(
            on_success: ->(files) { API::V3::StorageFiles::StorageFilesRepresenter.new(files, @storage, current_user:) },
            on_failure: ->(error) { raise_error(error) }
          )
      end

      route_param :file_id, type: String, desc: "Storage file id" do
        get do
          Storages::Peripherals::Registry
            .resolve("#{@storage.short_provider_type}.queries.file_info")
            .call(storage: @storage, auth_strategy:, file_id: params[:file_id])
            .map { |file_info| to_storage_file(file_info) }
            .match(
              on_success: ->(storage_file) {
                API::V3::StorageFiles::StorageFileRepresenter.new(storage_file, @storage, current_user:)
              },
              on_failure: ->(error) { raise_error(error) }
            )
        end
      end

      post :prepare_upload do
        result = validate_upload_request(request_body) >> fetch_upload_link
        result.match(
          on_success: ->(link) { API::V3::StorageFiles::StorageUploadLinkRepresenter.new(link, current_user:) },
          on_failure: ->(error) { raise_error(error) }
        )
      end
    end
  end
end

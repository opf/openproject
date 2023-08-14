#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
    helpers Storages::Peripherals::StorageErrorHelper, Storages::Peripherals::StorageFileInfoConverter

    resources :files do
      get do
        Storages::Peripherals::StorageRequests
          .new(storage: @storage)
          .files_query
          .call(user: current_user, folder: params[:parent])
          .match(
            on_success: ->(files) { API::V3::StorageFiles::StorageFilesRepresenter.new(files, @storage, current_user:) },
            on_failure: ->(error) { raise_error(error) }
          )
      end

      route_param :file_id, type: String, desc: 'Storage file id' do
        get do
          service_result = Storages::Peripherals::StorageRequests
                             .new(storage: @storage)
                             .files_info_query
                             .call(user: current_user, file_ids: [params[:file_id]]).map(&:first)

          if service_result.success? && service_result.result.status_code == 403
            storage_error = Storages::StorageError.new(code: :forbidden, log_message: 'no access to file', data: nil)
            service_result = ServiceResult.failure(result: :forbidden, errors: storage_error)
          end

          service_result.map { |file_info| to_storage_file(file_info) }
                        .match(
                          on_success: ->(storage_file) {
                            API::V3::StorageFiles::StorageFileRepresenter.new(storage_file, @storage, current_user:)
                          },
                          on_failure: ->(error) { raise_error(error) }
                        )
        end
      end

      post :prepare_upload do
        validate = ->(_body) do
          case request_body.transform_keys(&:to_sym)
          in { projectId: project_id, fileName: file_name, parent: parent }
            authorize(:manage_file_links, context: Project.find(project_id))
            ServiceResult.success(result: { fileName: file_name, parent: }.transform_keys(&:to_s))
          else
            ServiceResult.failure(errors: Storages::StorageError.new(code: :bad_request, log_message: 'Request body malformed!'))
          end
        end

        validate.call(request_body) >> ->(data) do
          Storages::Peripherals::StorageRequests
            .new(storage: @storage)
            .upload_link_query
            .call(user: current_user, data:)
            .match(
              on_success: ->(link) { API::V3::StorageFiles::StorageUploadLinkRepresenter.new(link, current_user:) },
              on_failure: ->(error) { raise_error(error) }
            )
        end
      end
    end
  end
end

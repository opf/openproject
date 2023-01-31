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
    helpers Storages::Peripherals::StorageErrorHelper
    helpers Storages::Peripherals::StorageInteraction::UploadLinkQueryHelpers
    helpers Storages::Peripherals::StorageInteraction::FilesQueryHelpers

    resources :files do
      get do
        (files_query(@storage, current_user) >> execute_files_query(params[:parent]))
          .match(
            on_success: ->(files) do
              API::V3::StorageFiles::StorageFilesRepresenter.new(
                files,
                current_user:
              )
            end,
            on_failure: ->(error) { raise_error(error) }
          )
      end

      post :prepare_upload do
        raise API::Errors::NotFound unless OpenProject::FeatureDecisions.storage_file_upload_active?

        (upload_link_query(@storage, current_user) >> execute_upload_link_query(request_body))
          .match(
            on_success: ->(link) { API::V3::StorageFiles::StorageUploadLinkRepresenter.new(link, current_user:) },
            on_failure: ->(error) { raise_error(error) }
          )
      end
    end
  end
end

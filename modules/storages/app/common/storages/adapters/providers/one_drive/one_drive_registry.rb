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

module Storages
  module Adapters
    module Providers
      module OneDrive
        OneDriveRegistry = Dry::Core::Container::Namespace.new("one_drive") do
          namespace("authentication") do
            register(:userless, ->(use_cache = true) { Input::Strategy.build(key: :oauth_client_credentials, use_cache:) })
            register(:user_bound, ->(user, storage = nil) { Input::Strategy.build(key: :oauth_user_token, user:, storage:) })
          end

          namespace("commands") do
            register(:copy_template_folder, Commands::CopyTemplateFolderCommand)
            register(:create_folder, Commands::CreateFolderCommand)
            register(:delete_folder, Commands::DeleteFolderCommand)
            register(:rename_file, Commands::RenameFileCommand)
            register(:set_permissions, Commands::SetPermissionsCommand)
          end

          namespace("components") do
            namespace("forms") do
              register(:access_management, Admin::Forms::AccessManagementFormComponent)
              register(:general_information, Admin::Forms::GeneralInfoFormComponent)
              register(:oauth_client, Admin::Forms::OAuthClientFormComponent)
              register(:redirect_uri, Admin::Forms::RedirectUriFormComponent)
            end

            register(:setup_wizard, StorageWizard)

            register(:access_management, Admin::AccessManagementComponent)
            register(:general_information, Admin::GeneralInfoComponent)
            register(:oauth_client, Admin::OAuthClientInfoComponent)
            register(:redirect_uri, Admin::RedirectUriComponent)
          end

          namespace("contracts") do
            register(:storage, OneDriveContract)
            register(:general_information, OneDriveContract)
          end

          namespace("models") do
            register(:managed_folder_identifier, ManagedFolderIdentifier)
          end

          namespace("queries") do
            register(:download_link, Queries::DownloadLinkQuery)
            register(:file_info, Queries::FileInfoQuery)
            register(:file_path_to_id_map, Queries::FilePathToIdMapQuery)
            register(:files, Queries::FilesQuery)
            register(:files_info, Queries::FilesInfoQuery)
            register(:open_file_link, Queries::OpenFileLinkQuery)
            register(:open_storage, Queries::OpenStorageQuery)
            register(:upload_link, Queries::UploadLinkQuery)
            register(:user, Queries::UserQuery)
          end

          namespace("services") do
            register(:upkeep_managed_folders, OneDriveManagedFolderCreateService)
            register(:upkeep_managed_folder_permissions, OneDriveManagedFolderPermissionsService)
          end

          namespace("validators") do
            register(:connection, Validators::ConnectionValidator)
          end
        end
      end
    end
  end
end

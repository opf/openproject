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
  module Peripherals
    OneDriveRegistry = Dry::Container::Namespace.new("one_drive") do
      namespace("queries") do
        register(:auth_check, StorageInteraction::OneDrive::AuthCheckQuery)
        register(:download_link, StorageInteraction::OneDrive::DownloadLinkQuery)
        register(:files, StorageInteraction::OneDrive::FilesQuery)
        register(:file_info, StorageInteraction::OneDrive::FileInfoQuery)
        register(:files_info, StorageInteraction::OneDrive::FilesInfoQuery)
        register(:open_file_link, StorageInteraction::OneDrive::OpenFileLinkQuery)
        register(:file_path_to_id_map, StorageInteraction::OneDrive::FilePathToIdMapQuery)
        register(:open_storage, StorageInteraction::OneDrive::OpenStorageQuery)
        register(:upload_link, StorageInteraction::OneDrive::UploadLinkQuery)
      end

      namespace("commands") do
        register(:copy_template_folder, StorageInteraction::OneDrive::CopyTemplateFolderCommand)
        register(:create_folder, StorageInteraction::OneDrive::CreateFolderCommand)
        register(:delete_folder, StorageInteraction::OneDrive::DeleteFolderCommand)
        register(:rename_file, StorageInteraction::OneDrive::RenameFileCommand)
        register(:set_permissions, StorageInteraction::OneDrive::SetPermissionsCommand)
      end

      namespace("contracts") do
        register(:storage, ::Storages::Storages::OneDriveContract)
      end

      namespace("models") do
        register(:managed_folder_identifier, ManagedFolderIdentifier::OneDrive)
      end

      namespace("authentication") do
        register(:userless, StorageInteraction::AuthenticationStrategies::OneDriveStrategies::UserLess, call: false)
        register(:userbound, StorageInteraction::AuthenticationStrategies::OneDriveStrategies::UserBound)
      end
    end
  end
end

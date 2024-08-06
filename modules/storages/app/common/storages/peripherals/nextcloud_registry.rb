# frozen_string_literal:true

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
    NextcloudRegistry = Dry::Container::Namespace.new("nextcloud") do
      namespace("queries") do
        register(:auth_check, StorageInteraction::Nextcloud::AuthCheckQuery)
        register(:capabilities, StorageInteraction::Nextcloud::CapabilitiesQuery)
        register(:download_link, StorageInteraction::Nextcloud::DownloadLinkQuery)
        register(:file_ids, StorageInteraction::Nextcloud::FileIdsQuery)
        register(:file_info, StorageInteraction::Nextcloud::FileInfoQuery)
        register(:files_info, StorageInteraction::Nextcloud::FilesInfoQuery)
        register(:files, StorageInteraction::Nextcloud::FilesQuery)
        register(:file_path_to_id_map, StorageInteraction::Nextcloud::FilePathToIdMapQuery)
        register(:propfind, StorageInteraction::Nextcloud::Internal::PropfindQuery)
        register(:group_users, StorageInteraction::Nextcloud::GroupUsersQuery)
        register(:upload_link, StorageInteraction::Nextcloud::UploadLinkQuery)
        register(:open_file_link, StorageInteraction::Nextcloud::OpenFileLinkQuery)
        register(:open_storage, StorageInteraction::Nextcloud::OpenStorageQuery)
      end

      namespace("commands") do
        register(:add_user_to_group, StorageInteraction::Nextcloud::AddUserToGroupCommand)
        register(:copy_template_folder, StorageInteraction::Nextcloud::CopyTemplateFolderCommand)
        register(:create_folder, StorageInteraction::Nextcloud::CreateFolderCommand)
        register(:delete_entity, StorageInteraction::Nextcloud::Internal::DeleteEntityCommand)
        register(:delete_folder, StorageInteraction::Nextcloud::DeleteFolderCommand)
        register(:remove_user_from_group, StorageInteraction::Nextcloud::RemoveUserFromGroupCommand)
        register(:rename_file, StorageInteraction::Nextcloud::RenameFileCommand)
        register(:set_permissions, StorageInteraction::Nextcloud::SetPermissionsCommand)
      end

      namespace("contracts") do
        register(:storage, ::Storages::Storages::NextcloudContract)
      end

      namespace("models") do
        register(:managed_folder_identifier, ManagedFolderIdentifier::Nextcloud)
      end

      namespace("authentication") do
        register(:userless, StorageInteraction::AuthenticationStrategies::NextcloudStrategies::UserLess, call: false)
        register(:userbound, StorageInteraction::AuthenticationStrategies::NextcloudStrategies::UserBound)
      end
    end
  end
end

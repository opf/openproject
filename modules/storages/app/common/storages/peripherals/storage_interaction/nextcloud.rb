# frozen_string_literal:true

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

module Storages
  module Peripherals
    module StorageInteraction
      module Nextcloud
        Queries = Dry::Container::Namespace.new('queries') do
          namespace('nextcloud') do
            register(:download_link_query, DownloadLinkQuery)
            register(:file_ids_query, FileIdsQuery)
            register(:files_info_query, FilesInfoQuery)
            register(:files_query, FilesQuery)
            register(:folder_files_file_ids_deep_query, FolderFilesFileIdsDeepQuery)
            register(:propfind_query, Internal::PropfindQuery)
            register(:group_users_query, GroupUsersQuery)
            register(:upload_link_query, UploadLinkQuery)
          end
        end

        Commands = Dry::Container::Namespace.new('commands') do
          namespace('nextcloud') do
            register(:delete_entity_command, Internal::DeleteEntityCommand)
            register(:add_user_to_group_command, AddUserToGroupCommand)
            register(:copy_template_folder_command, CopyTemplateFolderCommand)
            register(:create_folder_command, CreateFolderCommand)
            register(:delete_folder_command, DeleteFolderCommand)
            register(:set_permissions_command, SetPermissionsCommand)
            register(:remove_user_from_group_command, RemoveUserFromGroupCommand)
            register(:rename_file_command, RenameFileCommand)
          end
        end
      end
    end
  end
end

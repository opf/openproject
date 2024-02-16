# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
      module OneDrive
        Queries = Dry::Container::Namespace.new('queries') do
          namespace('one_drive') do
            register(:download_link, DownloadLinkQuery)
            register(:files, FilesQuery)
            register(:file_info, FileInfoQuery)
            register(:files_info, FilesInfoQuery)
            register(:open_file_link, OpenFileLinkQuery)
            register(:open_storage, OpenStorageQuery)
            register(:upload_link, UploadLinkQuery)
          end
        end

        Commands = Dry::Container::Namespace.new('commands') do
          namespace('one_drive') do
            register(:create_folder, CreateFolderCommand)
            register(:delete_folder, DeleteFolderCommand)
            register(:rename_file, RenameFileCommand)
            register(:set_permissions, SetPermissionsCommand)
          end
        end
      end
    end
  end
end

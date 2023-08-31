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

module Storages::Peripherals
  class StorageRequests
    COMMANDS = %i[
      set_permissions_command
      create_folder_command
      add_user_to_group_command
      delete_folder_command
      remove_user_from_group_command
      rename_file_command
      copy_template_folder_command
    ].freeze

    QUERIES = %i[
      download_link_query
      files_info_query
      files_query
      file_ids_query
      folder_files_file_ids_deep_query
      upload_link_query
      group_users_query
    ].freeze

    def initialize(storage:)
      @storage = storage
    end

    (COMMANDS + QUERIES).each do |request|
      define_method(request) do
        clazz = "::Storages::Peripherals::StorageInteraction::" \
                "#{@storage.short_provider_type.capitalize}::#{request.to_s.classify}".constantize
        clazz.new(@storage).method(:call).to_proc
      end
    end
  end
end

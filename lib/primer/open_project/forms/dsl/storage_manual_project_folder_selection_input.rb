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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Primer
  module OpenProject
    module Forms
      module Dsl
        class StorageManualProjectFolderSelectionInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label

          def initialize(name:, label:, project_storage:, last_project_folders: {}, storage_login_button_options: {},
                         select_folder_button_options: {}, wrapper_arguments: {}, **system_arguments)
            @name = name
            @label = label
            @project_storage = project_storage
            @last_project_folders = last_project_folders
            @storage_login_button_options = storage_login_button_options
            @select_folder_button_options = select_folder_button_options
            @wrapper_arguments = wrapper_arguments

            super(**system_arguments)
          end

          def to_component
            StorageManualProjectFolderSelection.new(
              input: self,
              project_storage: @project_storage,
              last_project_folders: @last_project_folders,
              storage_login_button_options: @storage_login_button_options,
              select_folder_button_options: @select_folder_button_options,
              wrapper_arguments: @wrapper_arguments
            )
          end

          def type
            :storage_manual_project_folder_selection
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end

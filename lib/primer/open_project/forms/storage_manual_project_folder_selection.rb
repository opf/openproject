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
      # :nodoc:
      class StorageManualProjectFolderSelection < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, to: :@input

        def initialize(input:, project_storage:, last_project_folders: {},
                       storage_login_button_options: {}, select_folder_button_options: {}, wrapper_arguments: {})
          super()
          @input = input

          @storage = project_storage.storage
          @last_project_folders = last_project_folders

          @storage_login_button_options = storage_login_button_options
          @selected_folder_label_options = select_folder_button_options.delete(:selected_folder_label_options) { {} }
          @select_folder_button_options = select_folder_button_options

          @wrapper_data_attributes = wrapper_arguments.delete(:data) { {} }
          @wrapper_classes = wrapper_arguments.delete(:classes) { [] }
        end
      end
    end
  end
end

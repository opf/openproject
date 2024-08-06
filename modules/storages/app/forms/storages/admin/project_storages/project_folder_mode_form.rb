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
  module Admin
    module ProjectStorages
      class ProjectFolderModeForm < ApplicationForm
        form do |radio_form|
          radio_form.radio_button_group(name: :project_folder_mode) do |radio_group|
            if @project_storage.project_folder_mode_possible?("inactive")
              radio_group.radio_button(value: "inactive", label: I18n.t(:"storages.label_no_specific_folder"),
                                       caption: I18n.t(:"storages.instructions.no_specific_folder"))
            end

            if @project_storage.project_folder_mode_possible?("automatic")
              radio_group.radio_button(value: "automatic", label: I18n.t(:"storages.label_automatic_folder"),
                                       caption: I18n.t(:"storages.instructions.automatic_folder"))
            end
          end
        end

        def initialize(project_storage:)
          super()
          @project_storage = project_storage
        end
      end
    end
  end
end

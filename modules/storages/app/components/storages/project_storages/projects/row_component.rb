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

# Purpose: Defines how to format the components within a table row of Projects
# associated with a Storage
module Storages::ProjectStorages::Projects
  class RowComponent < Projects::RowComponent
    include OpTurbo::Streamable

    def project_folder_type
      project_folder_mode = table.project_storages[project.id].project_folder_mode
      I18n.t("project_storages.project_folder_mode.#{project_folder_mode}")
    end

    def more_menu_items
      @more_menu_items ||= [more_menu_detach_project].compact
    end

    private

    def more_menu_detach_project
      project = model.first
      if User.current.admin && project.active?
        {
          scheme: :danger,
          icon: :trash,
          label: I18n.t("project_storages.remove_project.label"),
          href: destroy_confirmation_dialog_admin_settings_storage_project_storage_path(
            id: table.project_storages[project.id].id
          ),
          data: {
            controller: "async-dialog"
          }
        }
      end
    end
  end
end

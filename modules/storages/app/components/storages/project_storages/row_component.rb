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

# Purpose: Defines how to format the components within a table row of ProjectStorages
# associated with a project
module Storages::ProjectStorages
  class RowComponent < ::RowComponent
    def project_storage
      row
    end

    delegate :created_at, to: :project_storage

    def name
      project_storage.storage.name
    end

    def provider_type
      I18n.t(:"storages.provider_types.#{project_storage.storage.short_provider_type}.name")
    end

    def creator
      helpers.avatar project_storage.creator, hide_name: false, size: :mini
    end

    def button_links
      links = [edit_link, delete_link]
      links.prepend(members_connection_status_link) if project_storage.project_folder_automatic?

      links
    end

    def members_connection_status_link
      link_to "",
              project_settings_project_storage_members_path(project_id: project_storage.project,
                                                            project_storage_id: project_storage),
              class: "icon icon-group",
              title: I18n.t(:"storages.page_titles.project_settings.members_connection_status")
    end

    def edit_link
      link_to "",
              edit_project_settings_project_storage_path(project_id: project_storage.project, id: project_storage),
              class: "icon icon-edit",
              title: I18n.t(:button_edit)
    end

    def delete_link
      link_to "",
              confirm_destroy_project_settings_project_storage_path(project_id: project_storage.project, id: project_storage),
              class: "icon icon-delete",
              title: I18n.t(:button_delete),
              method: :get
    end
  end
end

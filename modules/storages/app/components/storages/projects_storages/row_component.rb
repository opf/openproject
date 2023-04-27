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

# Purpose: Defines how to format the cells within a table row of ProjectStorages
# associated with a project
module Storages::ProjectsStorages
  class RowComponent < ::RowComponent
    include ::IconsHelper
    include ::AvatarHelper
    include ::Redmine::I18n
    def project_storage
      row
    end

    delegate :created_at, to: :project_storage

    def name
      project_storage.storage.name
    end

    def provider_type
      project_storage.storage.short_provider_type
    end

    def creator
      icon = avatar project_storage.creator, size: :mini
      icon + project_storage.creator.name
    end

    def button_links
      [delete_link]
    end

    def delete_link
      link_to '',
              project_settings_projects_storage_path(project_id: project_storage.project, id: project_storage),
              class: 'icon icon-delete',
              data: { confirm: I18n.t('storages.delete_warning.project_storage') },
              title: I18n.t(:button_delete),
              method: :delete
    end
  end
end

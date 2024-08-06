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

# Purpose: Defines a table based on TableComponent for listing the
# Storages::ProjectStorage per project in the projects' settings
# page.
# See also: row_component.rb, which contains a method
# for every "column" defined below.
module Storages::ProjectStorages
  class TableComponent < ::TableComponent
    columns :name,
            :provider_type,
            :creator,
            :created_at

    def initial_sort
      %i[created_at asc]
    end

    def sortable?
      false
    end

    def inline_create_link
      link_to(new_project_settings_project_storage_path,
              class: "wp-inline-create--add-link",
              title: I18n.t("storages.label_new_storage")) do
        helpers.op_icon("icon icon-add")
      end
    end

    def empty_row_message
      I18n.t "storages.no_results"
    end

    def headers
      [
        ["name", { caption: ::Storages::Storage.human_attribute_name(:name) }],
        ["provider_type", { caption: I18n.t("storages.provider_types.label") }],
        ["creator", { caption: I18n.t("storages.label_creator") }],
        ["created_at", { caption: ::Storages::ProjectStorage.human_attribute_name(:created_at) }]
      ]
    end
  end
end

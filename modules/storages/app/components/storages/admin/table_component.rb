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

# Purpose: Defines a table with the list of Storages::Storage
# objects in the global admin section of OpenProject
# Used by: the admin list of all storages in the system
# (storages/app/views/storages/admin/index.html.erb)
# See also: row_component.rb defining the rows of the table
module Storages::Admin
  class TableComponent < ::TableComponent
    # Defines the list of columns in the table using symbols.
    # These symbols are used below to define header (top of the table)
    # and contents of the components
    columns :name, :provider_type, :host, :creator, :created_at

    # Default sort order (overwritten by user)
    def initial_sort
      %i[created_at asc]
    end

    # Should the TableComponent show ^/v icons in the header to allow custom sorting?
    def sortable?
      false
    end

    # Used by: app/components/table_component.html.erb
    # Purpose: return the link to be used to create the storage
    def inline_create_link
      link_to(new_admin_settings_storage_path,
              class: "wp-inline-create--add-link",
              title: I18n.t("storages.label_new_storage")) do
        helpers.op_icon("icon icon-add")
      end
    end

    # Show this pretty message if there are now Storages::Storage objects in the system
    def empty_row_message
      I18n.t "storages.no_results"
    end

    # Definition of the table header using the keys from columns above.
    def headers
      [
        ["name", { caption: ::Storages::Storage.human_attribute_name(:name) }],
        ["provider_type", { caption: I18n.t("storages.provider_types.label") }],
        ["host", { caption: I18n.t("storages.label_host") }],
        ["creator", { caption: I18n.t("storages.label_creator") }],
        ["created_at", { caption: ::Storages::Storage.human_attribute_name(:created_at) }]
      ]
    end
  end
end

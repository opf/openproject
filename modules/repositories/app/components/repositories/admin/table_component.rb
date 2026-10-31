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

module Repositories::Admin
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :provider_type, :created_at
    main_column :name
    mobile_columns :name, :provider_type
    mobile_labels :provider_type

    def row_class
      ::Repositories::Admin::RowComponent
    end

    def headers
      [
        [:name, { caption: Repositories::Provider.human_attribute_name(:name) }],
        [:provider_type, { caption: I18n.t("repositories.admin.table.provider_type") }],
        [:created_at, { caption: Repositories::Provider.human_attribute_name(:created_at) }]
      ]
    end

    def container_id
      "repository-providers-table"
    end

    def mobile_title
      I18n.t("repositories.admin.menu")
    end

    def blank_icon
      :repo
    end

    def blank_title
      I18n.t("repositories.admin.table.blank_title")
    end

    def blank_description
      I18n.t("repositories.admin.table.blank_description")
    end
  end
end

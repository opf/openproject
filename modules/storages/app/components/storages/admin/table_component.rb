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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
#

module Storages::Admin
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :provider_type, :creator, :created_at
    main_column :name
    mobile_columns :name, :creator, :created_at

    def row_class
      ::Storages::Admin::RowComponent
    end

    def headers
      [
        [:name, { caption: I18n.t("storages.label_name") }],
        [:provider_type, { caption: I18n.t("storages.label_provider") }],
        [:creator, { caption: I18n.t("storages.label_creator") }],
        [:created_at, { caption: I18n.t("storages.label_creation_time") }]
      ]
    end

    def container_id
      "storages-table"
    end

    def mobile_title
      ::Storages::Storage.model_name.human(count: 2)
    end

    def blank_icon
      :cloud
    end

    def blank_title
      I18n.t("storages.storage_list_blank_slate.heading")
    end

    def blank_description
      I18n.t("storages.storage_list_blank_slate.description")
    end
  end
end

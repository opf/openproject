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

module Admin::ScimClients
  class TableComponent < OpPrimer::ResponsiveDataTableComponent
    columns :name, :user_count, :authentication_method, :created_at
    mobile_labels :user_count, :authentication_method, :created_at

    def mobile_title
      ScimClient.model_name.human(count: 2)
    end

    def row_class
      RowComponent
    end

    def headers
      [
        [:name, { caption: ScimClient.human_attribute_name(:name) }],
        [:user_count, { caption: t(".user_count") }],
        [:authentication_method, { caption: ScimClient.human_attribute_name(:authentication_method) }],
        [:created_at, { caption: ScimClient.human_attribute_name(:created_at) }]
      ]
    end

    def blank_title
      t(".blank_slate.title")
    end

    def blank_description
      t(".blank_slate.description")
    end

    def blank_icon
      :key
    end
  end
end

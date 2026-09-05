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

module Groups
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :user_count, :created_at
    mobile_labels :user_count, :created_at

    def mobile_title
      Group.model_name.human(count: 2)
    end

    def row_class
      RowComponent
    end

    def headers
      [
        [:name, { caption: Group.human_attribute_name(:name) }],
        [:user_count, { caption: t(".user_count") }],
        [:created_at, { caption: Group.human_attribute_name(:created_at) }]
      ]
    end

    def render_blank_slate
      render(Primer::Beta::Blankslate.new(border: false)) do |component|
        component.with_visual_icon(icon: blank_icon, size: :medium) if blank_icon
        component.with_heading(tag: :h2) { blank_title }
        component.with_description { blank_description }
        component.with_primary_action(label: t(:label_group_new), href: new_group_path) do |button|
          button.with_leading_visual_icon(icon: :plus)
          Group.model_name.human
        end
      end
    end

    def blank_title
      t(".blank_slate.title")
    end

    def blank_description
      t(".blank_slate.description")
    end

    def blank_icon
      :people
    end
  end
end

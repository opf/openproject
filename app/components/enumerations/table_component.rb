# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Enumerations
  class TableComponent < ::TableComponent
    def columns
      %i[name is_default active sort].tap do |default|
        if with_colors
          default.insert 3, :color
        end
      end
    end

    def sortable?
      false
    end

    def headers
      [
        ['name', { caption: Enumeration.human_attribute_name(:name) }],
        ['is_default', { caption: Enumeration.human_attribute_name(:is_default) }],
        ['active', { caption: Enumeration.human_attribute_name(:active) }],
        ['sort', { caption: I18n.t(:label_sort) }]
      ].tap do |default|
        if with_colors
          default.insert 3, ['color', { caption: Enumeration.human_attribute_name(:color) }]
        end
      end
    end

    def with_colors
      rows.colored?
    end

    def inline_create_link
      link_to new_enumeration_path(type: rows.name),
              aria: { label: t(:label_enumeration_new) },
              class: 'wp-inline-create--add-link',
              data: { 'test-selector': "create-enumeration-#{rows.name.underscore.dasherize}" },
              title: t(:label_enumeration_new) do
        helpers.op_icon('icon icon-add')
      end
    end
  end
end

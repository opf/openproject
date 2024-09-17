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

module Enumerations
  class RowComponent < ::RowComponent
    def enumeration
      row
    end

    def name
      link_to enumeration.name, edit_enumeration_path(enumeration)
    end

    def is_default # rubocop:disable Naming/PredicateName
      checkmark(enumeration.is_default?)
    end

    def color
      helpers.icon_for_color enumeration.color
    end

    def active
      checkmark(enumeration.active?)
    end

    def sort
      helpers.reorder_links("enumeration", { action: "move", id: enumeration }, method: :post)
    end

    def button_links
      [
        delete_link
      ]
    end

    def delete_link
      helpers.link_to(
        helpers.op_icon("icon icon-delete"),
        helpers.enumeration_path(enumeration),
        method: :delete,
        data: { confirm: I18n.t(:text_are_you_sure) },
        title: t(:button_delete)
      )
    end
  end
end

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

module Roles
  class RowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :role, :model

    def row_css_id
      "role-#{role.id}"
    end

    def name
      link = render(Primer::Beta::Link.new(href: edit_role_path(role), font_weight: :bold)) { role.name }

      role.builtin? ? tag.em { link } : link
    end

    def global
      checkmark(role.is_a?(GlobalRole))
    end

    def sort
      return if role.builtin?

      helpers.reorder_links("role", { action: "update", id: role }, method: :put)
    end

    def button_links
      return [] if role.builtin?

      [delete_button]
    end

    private

    def delete_button
      render(
        Primer::Beta::IconButton.new(
          icon: :trash,
          scheme: :invisible,
          tag: :a,
          href: role_path(role),
          "aria-label": t(:button_delete),
          data: { turbo_method: :delete, turbo_confirm: t(:text_are_you_sure) },
          test_selector: "role-delete-button"
        )
      )
    end
  end
end

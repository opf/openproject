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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module HourlyRates
  class RowComponent < OpPrimer::BorderBoxRowComponent
    def valid_from
      helpers.format_date(model.valid_from)
    end

    def rate
      helpers.number_to_currency(model.rate)
    end

    # The rate in effect today can be a default rate, which no row in this
    # project-scoped table matches.
    def current
      checkmark(model == table.current_rate)
    end

    def button_links
      return [] unless table.manageable?

      [action_menu]
    end

    private

    def action_menu
      render(Primer::Alpha::ActionMenu.new(test_selector: "rate-action-menu")) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", "aria-label": t(:label_more), scheme: :invisible)

        with_item_group(menu) { edit_action_item(menu) }
        with_item_group(menu) { delete_action_item(menu) }
      end
    end

    def edit_action_item(menu)
      menu.with_item(
        content_arguments: { data: { controller: "async-dialog" } },
        tag: :a,
        label: t(:button_edit),
        href: edit_path,
        test_selector: "edit-rate-action"
      ) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_action_item(menu)
      menu.with_item(
        content_arguments: { data: { controller: "async-dialog" } },
        scheme: :danger,
        tag: :a,
        label: t(:button_delete),
        href: deletion_dialog_path,
        test_selector: "delete-rate-action"
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def edit_path
      if model.is_a?(DefaultHourlyRate)
        edit_default_hourly_rate_path(model)
      else
        edit_hourly_rate_path(model)
      end
    end

    def deletion_dialog_path
      if model.is_a?(DefaultHourlyRate)
        deletion_dialog_default_hourly_rate_path(model)
      else
        deletion_dialog_hourly_rate_path(model)
      end
    end
  end
end

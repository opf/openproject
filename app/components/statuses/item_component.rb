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

module Statuses
  class ItemComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    options :status
    options :max_position
    options :page_args

    private

    def wrapper_uniq_by
      status.id
    end

    def first_item?
      status.position == 1
    end

    def last_item?
      status.position == max_position
    end

    def show_done_ratio?
      WorkPackage.status_based_mode?
    end

    def grid_modifier_class
      "op-statuses-list--item_without-done-ratio" unless show_done_ratio?
    end

    def done_ratio
      helpers.number_to_percentage(status.default_done_ratio, precision: 0)
    end

    def checkmark(flagged, label:)
      return unless flagged

      render(Primer::Beta::Octicon.new(icon: :check, "aria-label": label))
    end

    def build_status_menu(menu)
      with_item_group(menu) { edit_status(menu) }
      with_item_group(menu) do
        unless first_item?
          move_status(menu, :highest, I18n.t(:label_sort_highest), "move-to-top")
          move_status(menu, :higher, I18n.t(:label_sort_higher), "chevron-up")
        end
        unless last_item?
          move_status(menu, :lower, I18n.t(:label_sort_lower), "chevron-down")
          move_status(menu, :lowest, I18n.t(:label_sort_lowest), "move-to-bottom")
        end
      end
      with_item_group(menu) { delete_status(menu) }
    end

    def edit_status(menu)
      menu.with_item(label: I18n.t(:button_edit),
                     tag: :a,
                     href: edit_status_path(status)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def move_status(menu, move_to, label, icon)
      menu.with_item(label:,
                     tag: :button,
                     href: move_status_path(status, **page_args.to_h),
                     form_arguments: { method: :put, inputs: [{ name: "move_to", value: move_to.to_s }] }) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def delete_status(menu)
      menu.with_item(label: I18n.t(:button_delete),
                     tag: :button,
                     scheme: :danger,
                     href: status_path(status),
                     content_arguments: { data: { turbo_confirm: I18n.t(:text_are_you_sure) } },
                     form_arguments: { method: :delete }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end

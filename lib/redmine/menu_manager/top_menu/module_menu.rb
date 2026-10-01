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

module Redmine::MenuManager::TopMenu::ModuleMenu
  def render_module_top_menu_node(item_groups = module_top_menu_item_groups)
    unless item_groups.empty?
      render Primer::Alpha::Dialog.new(classes: "op-app-menu--item",
                                       title: I18n.t("label_global_modules"),
                                       visually_hide_title: true,
                                       size: :small,
                                       position: :left) do |dialog|
        dialog.with_show_button(icon: "op-grid-menu",
                                scheme: :invisible,
                                classes: "op-app-header--primer-button",
                                test_selector: "op-app-header--modules-menu-button",
                                "aria-controls": "op-app-header--modules-menu-list",
                                "aria-label": I18n.t("label_global_modules"))
        dialog.with_header(classes: "op-app-header--modules-menu-header") do
          render_waffle_menu_logo_icon
        end

        dialog.with_body do
          concat call_hook(:module_menu_dialog_content_before)

          item_groups.each do |item_group|
            concat render_dialog_item_group(item_group)
          end

          concat call_hook(:module_menu_dialog_content_after)
        end
      end
    end
  end

  private

  def render_dialog_item_group(item_group)
    render Primer::Alpha::ActionList.new(
      classes: "op-app-menu--items",
      id: "op-app-header--modules-menu-list"
    ) do |list|
      list.with_heading(title: item_group[:title], align_items: :flex_start) if item_group[:title]

      my_items, remaining_items = item_group[:items].partition { |item| item.context == :my }

      render_action_list_items(list, my_items)

      list.with_divider if my_items.any? && remaining_items.any?

      render_action_list_items(list, remaining_items)
    end
  end

  def render_action_list_items(list, items)
    items.each do |item|
      label =
        if item.enterprise_feature_missing?
          h(item.caption) + upsell_icon
        else
          item.caption
        end

      list.with_item(
        href: url_for(item.url),
        label:,
        test_selector: "op-menu--item-action"
      ) do |menu_item|
        menu_item.with_leading_visual_icon(icon: item.icon) if item.icon
      end
    end
  end

  def upsell_icon
    render(Primer::Beta::Octicon.new(icon: "op-enterprise-addons", classes: "upsell-colored", ml: 2))
  end

  def module_top_menu_item_groups
    items = more_top_menu_items
    item_groups = []

    # add untitled group, if no heading is present
    unless items.first.heading?
      item_groups = [default_module_menu_group]
    end

    # create item groups
    items.reduce(item_groups) do |groups, item|
      if item.heading?
        groups << { title: item.caption, items: [] }
      else
        groups.last[:items] << item
      end

      groups
    end
  end

  def default_module_menu_group
    { title: nil, items: [] }
  end

  # Menu items for the modules top menu
  def more_top_menu_items
    split = split_top_menu_into_main_or_more_menus
    split[:modules] + split[:my]
  end
end

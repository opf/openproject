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

module Redmine::MenuManager::TopMenu::QuickAddMenu
  include OpenProject::StaticRouting::UrlHelpers
  include OpPrimer::ComponentHelpers

  def render_quick_add_menu
    return unless show_quick_add_menu?

    render_quick_add_dropdown
  end

  private

  def render_quick_add_dropdown
    render Primer::Alpha::ActionMenu.new(classes: "op-app-menu--item",
                                         menu_id: "op-app-header--quick-add-menu",
                                         anchor_align: :end) do |menu|
      menu.with_show_button(scheme: :primary,
                            classes: "op-app-header--primer-button",
                            test_selector: "quick-add-menu-button",
                            px: 2) do |button|
        button.with_leading_visual_icon(icon: :plus)
        button.with_tooltip(text: I18n.t("menus.quick_add.label"))
        render(Primer::Beta::Octicon.new(icon: "triangle-down", aria: { label: I18n.t("menus.quick_add.label") }))
      end

      with_item_group(menu) { add_quick_add_items(menu) }
      with_item_group(menu) { add_named_item(menu, :invite_user) }
    end
  end

  def add_quick_add_items(menu)
    add_work_package_item(menu)
    add_named_item(menu, :new_project)
    add_named_item(menu, :new_board)
    add_named_item(menu, :new_meeting)
    add_named_item(menu, :new_document)
  end

  def add_named_item(menu, name)
    item = quick_add_menu_items[name]
    return unless item

    menu.with_item(
      href: named_item_href(item),
      content_arguments: named_item_content_arguments(item),
      label_arguments: { id: id_for_name(item.caption) },
      label: item.caption,
      test_selector: "op-menu--item-action"
    ) do |menu_item|
      menu_item.with_leading_visual_icon(icon: item.icon)
    end
  end

  def named_item_href(item)
    return "#" if item.url.blank?

    allowed_node_url(item, @project)
  end

  def named_item_content_arguments(item)
    html_options = item.html_options
    html_options[:aria] = { labelledby: id_for_name(item.caption) } if html_options[:aria].blank?

    {
      target: html_options.fetch(:target, "_top"),
      **html_options,
      test_selector: "quick-add-menu-item"
    }
  end

  def quick_add_menu_items
    @quick_add_menu_items ||= first_level_menu_items_for(:quick_add_menu, @project).index_by(&:name)
  end

  def add_work_package_item(menu)
    return if work_package_quick_add_items.blank?

    label = I18n.t(:label_work_package)

    menu.with_sub_menu_item(
      label:,
      content_arguments: {
        aria: { labelledby: id_for_name(label) },
        test_selector: "quick-add-menu-item"
      },
      label_arguments: { id: id_for_name(label) },
      test_selector: "op-menu--item-action"
    ) do |sub_menu_item|
      sub_menu_item.with_leading_visual_icon(icon: "op-view-list")

      work_package_quick_add_items.each { |item| add_work_package_type_item(sub_menu_item, item) }
    end
  end

  def add_work_package_type_item(sub_menu_item, item)
    sub_menu_item.with_item(
      href: item[:href],
      label: item[:caption],
      content_arguments: {
        target: "_top",
        aria: { labelledby: id_for_name(item[:caption]) },
        test_selector: "quick-add-menu-item"
      },
      label_arguments: { id: id_for_name(item[:caption]), classes: item[:classes] },
      test_selector: "op-menu--item-action"
    )
  end

  def work_package_quick_add_items
    return unless any_types?

    visible_types
      .map { |type| work_package_create_link(type.id, type.name) }
  end

  def visible_types
    @visible_types ||= begin
      if user_can_create_work_package?
        if in_project_context?
          @project.enabled_types
        else
          Type.enabled_in(Project.allowed_to(User.current, :add_work_packages))
        end
      else
        Type.none
      end
    end.to_a
  end

  def work_package_create_link(type_id, type_name)
    classes = "__hl_uppercase #{hl_foreground_class('type', type_id)}"

    if in_project_context?
      { caption: type_name,
        href: new_project_work_packages_path(project_id: @project.identifier, type: type_id),
        classes: }
    else
      { caption: type_name,
        href: new_work_package_path(type: type_id),
        classes: }
    end
  end

  def user_can_create_work_package?
    if in_project_context?
      User.current.allowed_in_project?(:add_work_packages, @project)
    else
      User.current.allowed_in_any_project?(:add_work_packages)
    end
  end

  def show_quick_add_menu?
    !anonymous_and_login_required? &&
      (quick_add_menu_items.any? || any_types?)
  end

  def in_project_context?
    @project&.persisted?
  end

  def anonymous_and_login_required?
    Setting.login_required? && User.current.anonymous?
  end

  def any_types?
    visible_types.any?
  end

  def id_for_name(name)
    "quick-add-menu-item--item-#{name.parameterize(separator: '_')}"
  end
end

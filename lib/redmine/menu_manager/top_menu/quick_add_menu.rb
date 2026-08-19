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

      with_item_group(menu) { add_first_level_items(menu) }
      with_item_group(menu) { add_second_level_items(menu) }
    end
  end

  def add_first_level_items(menu) # rubocop:disable Metrics/AbcSize
    first_level_menu_items_for(:quick_add_menu, @project).each do |item|
      html_options = item.html_options
      html_options[:aria] = { labelledby: id_for_name(item.caption) } if html_options[:aria].blank?

      menu.with_item(
        href: item.url.present? ? allowed_node_url(item, @project) : "#",
        content_arguments: {
          target: html_options.fetch(:target, "_top"),
          **html_options,
          test_selector: "quick-add-menu-item"
        },
        label_arguments: { id: id_for_name(item.caption) },
        label: item.caption,
        test_selector: "op-menu--item-action"
      ) do |menu_item|
        menu_item.with_leading_visual_icon(icon: item.icon)
      end
    end
  end

  def add_second_level_items(menu)
    if work_package_quick_add_items.present?
      menu.with_group do |menu_group|
        menu_group.with_heading(title: I18n.t(:label_work_package_plural), align_items: :flex_start)

        work_package_quick_add_items.each do |item|
          menu_group.with_item(
            href: item[:href],
            label: item[:caption],
            content_arguments: {
              target: "_top",
              aria: { labelledby: id_for_name(item[:caption]) }
            },
            label_arguments: { id: id_for_name(item[:caption]),
                               classes: item[:classes] },
            test_selector: "op-menu--item-action"
          )
        end
      end
    end
  end

  def work_package_quick_add_items
    return unless any_types?

    visible_types
      .pluck(:id, :name)
      .uniq
      .map do |id, name|
      work_package_create_link(id, name)
    end
  end

  def visible_types
    @visible_types ||= begin
      if user_can_create_work_package?
        in_project_context? ? @project.types : Type.enabled_in(Project.allowed_to(User.current, :add_work_packages))
      else
        Type.none
      end
    end.to_a
  end

  def work_package_create_link(type_id, type_name)
    if in_project_context?
      { caption: type_name,
        href: new_project_work_packages_path(project_id: @project.identifier, type: type_id),
        classes: "__hl_inline_type_#{type_id}" }
    else
      { caption: type_name,
        href: new_work_package_path(type: type_id),
        classes: "__hl_inline_type_#{type_id}" }
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
      (global_add_permissions? || add_subproject_permission? || any_types?)
  end

  def in_project_context?
    @project&.persisted?
  end

  def anonymous_and_login_required?
    Setting.login_required? && User.current.anonymous?
  end

  def global_add_permissions?
    User.current.allowed_globally?(:add_project) ||
      User.current.allowed_in_any_project?(:manage_members)
  end

  def add_subproject_permission?
    in_project_context? &&
      User.current.allowed_in_project?(:add_subprojects, @project)
  end

  def any_types?
    visible_types.any?
  end

  def id_for_name(name)
    "quick-add-menu-item--item-#{name.parameterize(separator: '_')}"
  end
end

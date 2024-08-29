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

  def render_quick_add_menu
    return unless show_quick_add_menu?

    render_quick_add_dropdown
  end

  private

  def render_quick_add_dropdown
    render_menu_dropdown_with_items(
      label: "",
      label_options: {
        title: I18n.t("menus.quick_add.label"),
        icon: "icon-add op-quick-add-menu--icon",
        class: "op-quick-add-menu--button"
      },
      items: first_level_menu_items_for(:quick_add_menu, @project),
      options: {
        drop_down_id: "quick-add-menu",
        menu_item_class: "op-quick-add-menu"
      },
      project: @project
    ) do
      work_package_quick_add_items
      # Return nil as the yield result is concat as well
      nil
    end
  end

  def work_package_quick_add_items
    return unless any_types?

    concat content_tag(:hr, "", class: "op-menu--separator")
    concat work_package_type_heading

    visible_types
      .pluck(:id, :name)
      .uniq
      .each do |id, name|
      concat work_package_create_link(id, name)
    end
  end

  def work_package_type_heading
    content_tag(:li, class: "op-menu--item") do
      content_tag :span,
                  I18n.t(:label_work_package_plural),
                  class: "op-menu--headline"
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
    content_tag(:li, class: "op-menu--item") do
      if in_project_context?
        link_to type_name,
                new_project_work_packages_path(project_id: @project.identifier, type: type_id),
                class: "__hl_inline_type_#{type_id} op-menu--item-action"
      else
        link_to type_name,
                new_work_packages_path(type: type_id),
                class: "__hl_inline_type_#{type_id} op-menu--item-action"
      end
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
end

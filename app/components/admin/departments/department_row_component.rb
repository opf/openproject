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

module Admin
  module Departments
    class DepartmentRowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers

      def initialize(department:)
        super()
        @department = department
      end

      def call
        flex_layout(align_items: :center, justify_content: :space_between) do |row|
          row.with_column do
            render(Primer::Beta::Link.new(href: admin_department_path(@department))) { @department.name }
          end

          row.with_column do
            if @department.ldap_managed?
              render(Primer::Beta::Label.new(scheme: :accent)) { I18n.t(:label_managed_by_ldap) }
            else
              render(Primer::Alpha::ActionMenu.new) do |menu|
                menu.with_show_button(
                  icon: "kebab-horizontal",
                  scheme: :invisible,
                  "aria-label": I18n.t(:label_actions)
                )
                menu_items(menu)
              end
            end
          end
        end
      end

      private

      def menu_items(menu)
        with_item_group(menu) { edit_item(menu) }
        with_item_group(menu) do
          add_sub_department_item(menu)
          add_user_item(menu)
        end
        with_item_group(menu) { change_parent_item(menu) }
        with_item_group(menu) { delete_item(menu) }
      end

      def edit_item(menu)
        menu.with_item(
          label: I18n.t(:button_edit),
          tag: :a,
          href: edit_admin_department_path(@department)
        ) { it.with_leading_visual_icon(icon: :pencil) }
      end

      def add_sub_department_item(menu)
        menu.with_item(
          label: I18n.t("departments.context_menu.add_sub_department"),
          tag: :a,
          href: new_department_admin_departments_path(parent_id: @department.id),
          content_arguments: { data: { turbo_frame: Admin::Departments::HierarchyLayoutComponent.wrapper_key } }
        ) { it.with_leading_visual_icon(icon: "op-arrow-in") }
      end

      def add_user_item(menu)
        menu.with_item(
          label: I18n.t("departments.context_menu.add_user"),
          tag: :a,
          href: new_user_admin_department_path(@department),
          content_arguments: { data: { turbo_frame: Admin::Departments::HierarchyLayoutComponent.wrapper_key } }
        ) { it.with_leading_visual_icon(icon: "person-add") }
      end

      def change_parent_item(menu)
        menu.with_item(
          label: I18n.t(:label_change_parent),
          tag: :a,
          href: change_parent_admin_department_path(@department),
          content_arguments: { data: { controller: "async-dialog" } }
        ) { it.with_leading_visual_icon(icon: "arrow-switch") }
      end

      def delete_item(menu)
        menu.with_item(
          label: I18n.t(:button_delete),
          scheme: :danger,
          tag: :a,
          href: admin_department_path(@department),
          content_arguments: {
            data: {
              turbo_confirm: I18n.t(:text_are_you_sure),
              turbo_method: :delete,
              turbo_frame: "_top"
            }
          }
        ) { it.with_leading_visual_icon(icon: :trash) }
      end
    end
  end
end

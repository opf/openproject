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

module WorkPackageTypes
  module ProjectsTab
    # The deferred list of a project row's menu (MenusController#show), acting on +projects+:
    # the selection the menu opened on, or the invoking project alone.
    class RowMenuComponent < ApplicationComponent
      include WorkPackageTypes::VariantRoutes

      def self.menu_id(project) = "type-projects-row-menu-#{project.id}"

      def initialize(variant:, invoker:, projects:)
        super()

        @variant = variant
        @invoker = invoker
        @projects = projects
      end

      def call
        render(Primer::Alpha::ActionMenu::List.new(menu_id: self.class.menu_id(@invoker), data: list_data)) do |list|
          switch_item(list) if switchable?
          remove_item(list)
        end
      end

      private

      def list_data
        { sortable_lists__menu_source_target: "menu", sortable_lists_scope_count: @projects.size }
      end

      def switchable? = @variant.type.variants.many?

      def project_ids = @projects.map(&:id)

      def switch_item(list)
        list.with_item(
          label: t("types.edit.projects.actions.switch_variant"),
          tag: :a,
          href: new_variant_projects_switch_path(@variant, project_ids:),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :"list-ordered")
        end
      end

      def remove_item(list)
        list.with_item(
          label: t("types.edit.projects.actions.#{@projects.many? ? :remove_from_projects : :remove_from_project}"),
          scheme: :danger,
          tag: :a,
          href: new_variant_projects_link_deletion_path(@variant, project_ids:),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end
    end
  end
end

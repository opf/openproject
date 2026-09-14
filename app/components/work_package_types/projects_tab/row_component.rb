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

module WorkPackageTypes
  module ProjectsTab
    class RowComponent < ::Projects::RowComponent
      include OpTurbo::Streamable

      def wrapper_uniq_by
        "project-#{project.id}"
      end

      def menu_items
        @menu_items ||= [switch_variant_item, remove_item].compact
      end

      private

      def variant = @table.variant

      def switch_variant_item
        return unless variant.type.variants.many?

        {
          scheme: :default,
          icon: :"list-ordered",
          label: I18n.t("types.edit.projects.actions.switch_variant"),
          href: url_helpers.new_switch_type_projects_path(**variant.path_args, project_id: project.id),
          data: { controller: "async-dialog" }
        }
      end

      def remove_item
        {
          scheme: :danger,
          icon: :trash,
          label: I18n.t("types.edit.projects.actions.remove_from_project"),
          href: url_helpers.unlink_type_projects_path(**variant.path_args,
                                                      project_id: project.id,
                                                      page: current_page),
          data: { turbo_method: :delete, turbo_confirm: confirm_removal }
        }
      end

      def confirm_removal
        I18n.t("types.edit.projects.actions.confirm_remove",
               project: project.name,
               type: variant.type.name)
      end
    end
  end
end

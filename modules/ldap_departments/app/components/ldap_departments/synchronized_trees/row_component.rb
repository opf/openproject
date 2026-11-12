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

module LdapDepartments
  module SynchronizedTrees
    class RowComponent < OpPrimer::BorderBoxRowComponent
      def name
        render(Primer::Beta::Link.new(
                 href: ldap_departments_synchronized_tree_path(tree_id: model.id),
                 font_weight: :bold
               )) { model.name }
      end

      def ldap_auth_source
        model.ldap_auth_source&.name
      end

      delegate :base_dn, to: :model

      def departments
        model.synchronized_departments.size
      end

      def button_links
        [actions_menu]
      end

      private

      def actions_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", scheme: :invisible, "aria-label": I18n.t(:label_actions))
          add_edit_item(menu)
          add_delete_item(menu)
        end
      end

      def add_edit_item(menu)
        menu.with_item(
          label: I18n.t(:button_edit),
          tag: :a,
          href: edit_ldap_departments_synchronized_tree_path(tree_id: model.id)
        ) { it.with_leading_visual_icon(icon: :pencil) }
      end

      def add_delete_item(menu)
        menu.with_item(
          label: I18n.t(:button_delete),
          scheme: :danger,
          tag: :a,
          href: deletion_dialog_ldap_departments_synchronized_tree_path(tree_id: model.id),
          content_arguments: { data: { controller: "async-dialog" } }
        ) { it.with_leading_visual_icon(icon: :trash) }
      end
    end
  end
end

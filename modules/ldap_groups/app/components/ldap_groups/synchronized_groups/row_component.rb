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

module LdapGroups
  module SynchronizedGroups
    class RowComponent < ::RowComponent
      def synchronized_group
        model
      end

      def dn
        link_to synchronized_group.dn, ldap_groups_synchronized_group_path(synchronized_group)
      end

      def ldap_auth_source
        link_to synchronized_group.ldap_auth_source.name, edit_ldap_auth_source_path(synchronized_group.ldap_auth_source)
      end

      def group
        link_to synchronized_group.group.name, edit_group_path(synchronized_group.group)
      end

      def sync_users
        helpers.checked_image synchronized_group.sync_users
      end

      def users
        synchronized_group.users.size
      end

      def button_links
        [delete_link].compact
      end

      def delete_link
        return if table.options[:deletable] == false

        link_to I18n.t(:button_delete),
                { controller: table.target_controller, ldap_group_id: model.id, action: :destroy_info },
                class: "icon icon-delete",
                title: t(:button_delete)
      end
    end
  end
end

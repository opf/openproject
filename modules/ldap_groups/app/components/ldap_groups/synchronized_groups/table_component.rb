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
    class TableComponent < ::TableComponent
      columns :dn, :ldap_auth_source, :group, :users, :sync_users

      def initial_sort
        %i[id asc]
      end

      def target_controller
        "ldap_groups/synchronized_groups"
      end

      def sortable?
        true
      end

      def sortable_column?(_column)
        false
      end

      def inline_create_link
        link_to({ controller: target_controller, action: :new },
                class: "budget-add-row wp-inline-create--add-link",
                title: I18n.t("ldap_groups.synchronized_groups.add_new")) do
          helpers.op_icon("icon icon-add")
        end
      end

      def empty_row_message
        I18n.t "ldap_groups.synchronized_groups.no_results"
      end

      def headers
        [
          ["dn", { caption: ::LdapGroups::SynchronizedGroup.human_attribute_name("dn") }],
          ["ldap_auth_source", { caption: ::LdapGroups::SynchronizedGroup.human_attribute_name("ldap_auth_source") }],
          ["group", { caption: I18n.t(:label_group) }],
          ["users", { caption: I18n.t(:label_user_plural) }],
          ["sync_users", { caption: ::LdapGroups::SynchronizedFilter.human_attribute_name("sync_users") }]
        ]
      end
    end
  end
end

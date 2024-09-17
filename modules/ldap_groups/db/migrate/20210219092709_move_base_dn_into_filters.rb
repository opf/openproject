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

class MoveBaseDnIntoFilters < ActiveRecord::Migration[6.1]
  class MigratingAuthSource < ApplicationRecord
    self.table_name = "auth_sources"
  end

  def change
    add_column :ldap_groups_synchronized_filters, :base_dn, :text, null: true

    # Add sync_users option to filters
    add_column :ldap_groups_synchronized_filters,
               :sync_users,
               :boolean,
               null: false,
               default: false

    # Add sync_users option to groups
    add_column :ldap_groups_synchronized_groups,
               :sync_users,
               :boolean,
               null: false,
               default: false

    LdapGroups::SynchronizedFilter.reset_column_information
    LdapGroups::SynchronizedGroup.reset_column_information

    # Take over the connection's onthefly setting
    # for whether to sync users for filters and groups
    MigratingAuthSource
      .pluck(:id, :onthefly_register)
      .each do |id, onthefly|
      LdapGroups::SynchronizedFilter
        .where(ldap_auth_source_id: id)
        .update_all(sync_users: onthefly)

      LdapGroups::SynchronizedGroup
        .where(ldap_auth_source_id: id)
        .update_all(sync_users: onthefly)
    end
  end
end

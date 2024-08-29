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

class MakeSynchronizedGroupDn < ActiveRecord::Migration[6.0]
  def up
    add_column :ldap_groups_synchronized_groups, :dn, :text, index: true
    add_column :ldap_groups_synchronized_groups,
               :users_count,
               :integer,
               default: 0,
               null: false

    LdapGroups::SynchronizedGroup.find_each do |group|
      dn = ::OpenProject::LdapGroups.group_dn(Net::LDAP::DN.escape(group.entry))
      group.update_column(:dn, dn)
    end

    remove_column :ldap_groups_synchronized_groups, :entry, :text
  end

  def down
    add_column :ldap_groups_synchronized_groups, :entry, :text

    warn "Removing synchronized groups"
    LdapGroups::SynchronizedGroup.destroy_all

    remove_column :ldap_groups_synchronized_groups, :dn
    remove_column :ldap_groups_synchronized_groups, :users_count
  end
end

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

class CreateLdapDepartmentsTables < ActiveRecord::Migration[8.1]
  def change
    create_synchronized_trees
    create_synchronized_departments
    create_memberships
  end

  private

  def create_synchronized_trees
    create_table :ldap_departments_synchronized_trees do |t|
      t.string :name
      t.references :ldap_auth_source
      t.text :base_dn
      t.string :structure_filter_string, null: false, default: "(objectClass=organizationalUnit)"
      t.string :ou_name_attribute, null: false, default: "ou"
      t.string :guid_attribute, null: true
      t.text :user_filter_string, null: true
      t.boolean :sync_users, null: false, default: false

      t.timestamps
    end
  end

  def create_synchronized_departments
    create_table :ldap_departments_synchronized_departments do |t|
      t.belongs_to :synchronized_tree,
                   foreign_key: { to_table: :ldap_departments_synchronized_trees }
      t.references :ldap_auth_source
      t.references :group
      t.text :dn
      t.string :ldap_entry_uuid, null: true
      t.integer :users_count, null: false, default: 0

      t.timestamps

      t.index :dn, unique: true
      t.index :ldap_entry_uuid
    end
  end

  def create_memberships
    create_table :ldap_departments_memberships do |t|
      t.references :user
      t.belongs_to :synchronized_department,
                   foreign_key: { to_table: :ldap_departments_synchronized_departments }

      t.timestamps

      t.index %i[user_id synchronized_department_id], unique: true
    end
  end
end

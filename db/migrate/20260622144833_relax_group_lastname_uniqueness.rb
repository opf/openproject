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

class RelaxGroupLastnameUniqueness < ActiveRecord::Migration[8.1]
  # Group name uniqueness is now enforced in the application (Group#uniqueness_of_name):
  # globally for regular groups, but only among siblings for organizational units (departments),
  # since LDAP directories repeat the same OU name across branches. The database-level unique
  # index can therefore no longer span all groups, so we restrict it to placeholder users.
  #
  # Indexes on the (potentially large) users table are built/removed concurrently to avoid locking.
  disable_ddl_transaction!

  def up
    remove_index :users, name: "unique_lastname_for_groups_and_placeholder_users", algorithm: :concurrently
    add_index :users,
              %i[lastname type],
              name: "unique_lastname_for_placeholder_users",
              unique: true,
              where: "(type = 'PlaceholderUser')",
              algorithm: :concurrently
  end

  def down
    remove_index :users, name: "unique_lastname_for_placeholder_users", algorithm: :concurrently
    add_index :users,
              %i[lastname type],
              name: "unique_lastname_for_groups_and_placeholder_users",
              unique: true,
              where: "(type = 'Group' OR type = 'PlaceholderUser')",
              algorithm: :concurrently
  end
end

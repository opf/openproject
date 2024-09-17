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

require_relative "tables/forums"

class RenameBoardsToForums < ActiveRecord::Migration[5.2]
  def up
    # Create the new table, then copy from the oldt table to ensure indexes are correct
    ::Tables::Forums.create(self)

    execute "INSERT INTO forums SELECT * FROM boards"

    rename_column :messages, :board_id, :forum_id
    rename_column :message_journals, :board_id, :forum_id

    # Rename string references in DB to forums
    EnabledModule.where(name: "boards").update_all(name: "forums")
    RolePermission.where(permission: "manage_boards").update_all(permission: "manage_forums")
    Watcher.where(watchable_type: "Board").update_all(watchable_type: "Forum")

    # Finally, drop the old table
    drop_table :boards
  end

  def down
    rename_table :forums, :boards

    rename_column :messages, :forum_id, :board_id
    rename_column :message_journals, :forum_id, :board_id

    # Rename back items
    EnabledModule.where(name: "forums").update_all(name: "boards")
    RolePermission.where(permission: "manage_forums").update_all(permission: "manage_boards")
    Watcher.where(watchable_type: "Forum").update_all(watchable_type: "Board")
  end
end

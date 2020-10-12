require_relative './tables/forums'

class RenameBoardsToForums < ActiveRecord::Migration[5.2]

  def up
    # Create the new table, then copy from the oldt table to ensure indexes are correct
    ::Tables::Forums.create(self)

    execute "INSERT INTO forums SELECT * FROM boards";

    rename_column :messages, :board_id, :forum_id
    rename_column :message_journals, :board_id, :forum_id

    # Rename string references in DB to forums
    EnabledModule.where(name: 'boards').update_all(name: 'forums')
    RolePermission.where(permission: 'manage_boards').update_all(permission: 'manage_forums')
    Watcher.where(watchable_type: 'Board').update_all(watchable_type: 'Forum')

    # Finally, drop the old table
    drop_table :boards
  end

  def down
    rename_table :forums, :boards

    rename_column :messages, :forum_id, :board_id
    rename_column :message_journals, :forum_id, :board_id

    # Rename back items
    EnabledModule.where(name: 'forums').update_all(name: 'boards')
    RolePermission.where(permission: 'manage_forums').update_all(permission: 'manage_boards')
    Watcher.where(watchable_type: 'Forum').update_all(watchable_type: 'Board')
  end
end



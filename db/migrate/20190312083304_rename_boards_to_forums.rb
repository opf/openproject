require_relative './migration_utils/utils'

class RenameBoardsToForums < ActiveRecord::Migration[5.2]
  def up
    # Rename manually to ensure indexes need not be dropped
    execute "ALTER TABLE boards RENAME TO forums;"

    rename_column :messages, :board_id, :forum_id
    rename_column :message_journals, :board_id, :forum_id

    # Rename string references in DB to forums
    EnabledModule.where(name: 'boards').update_all(name: 'forums')
    RolePermission.where(permission: 'manage_boards').update_all(permission: 'manage_forums')
    Watcher.where(watchable_type: 'Board').update_all(watchable_type: 'Forum')
  end


  def down
    # Rename manually to ensure indexes need not be dropped
    execute "ALTER TABLE forums RENAME TO boards;"

    rename_column :messages, :forum_id, :board_id
    rename_column :message_journals, :forum_id, :board_id

    # Rename back items
    EnabledModule.where(name: 'forums').update_all(name: 'boards')
    RolePermission.where(permission: 'manage_forums').update_all(permission: 'manage_boards')
    Watcher.where(watchable_type: 'Forum').update_all(watchable_type: 'Board')
  end
end



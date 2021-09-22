class NotificationForeignKeyConstraint < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :notifications, :journals
    add_index :notifications, :journal_id
  end
end

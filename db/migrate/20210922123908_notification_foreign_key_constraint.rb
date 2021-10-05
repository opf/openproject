class NotificationForeignKeyConstraint < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        cleanup_invalid_notifications
      end
    end

    add_foreign_key :notifications, :journals
    add_index :notifications, :journal_id
  end

  private

  def cleanup_invalid_notifications
    execute <<~SQL.squish
      DELETE FROM notifications to_delete
      USING notifications to_identify
        LEFT JOIN journals ON to_identify.journal_id = journals.id
      WHERE to_delete.id = to_identify.id AND journals.id IS NULL
    SQL
  end
end

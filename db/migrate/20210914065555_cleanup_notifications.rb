class CleanupNotifications < ActiveRecord::Migration[6.1]
  def up
    change_table :notifications, bulk: true do |t|
      t.remove :read_mail, :reason_mail, :reason_mail_digest
      t.rename :reason_ian, :reason
    end
  end

  def down
    change_table :notifications, bulk: true do |t|
      t.boolean :read_email, default: false, index: true
      t.integer :reason_mail, limit: 1
      t.integer :reason_mail_digest, limit: 1
      t.rename :reason, :reason_ian
    end
  end
end

class AddDigestToNotification < ActiveRecord::Migration[6.1]
  def change
    change_table :notifications, bulk: true do |t|
      t.column :read_mail_digest, :boolean, default: false, index: true
      t.column :reason_mail, :integer, limit: 1
      t.column :reason_mail_digest, :integer, limit: 1
    end

    rename_column :notifications, :reason, :reason_ian
    rename_column :notifications, :read_email, :read_mail
  end
end

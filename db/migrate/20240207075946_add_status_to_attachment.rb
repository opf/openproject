class AddStatusToAttachment < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :status, :integer, default: 0, null: false
  end
end

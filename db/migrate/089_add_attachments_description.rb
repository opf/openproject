class AddAttachmentsDescription < ActiveRecord::Migration
  def self.up
    add_column :attachments, :description, :string
  end

  def self.down
    remove_column :attachments, :description
  end
end

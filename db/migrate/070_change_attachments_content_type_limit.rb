class ChangeAttachmentsContentTypeLimit < ActiveRecord::Migration
  def self.up
    change_column :attachments, :content_type, :string
  end

  def self.down
    change_column :attachments, :content_type, :string, :limit => 60
  end
end

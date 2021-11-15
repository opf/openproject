class ChangeAttachmentFilesizeToBigInt < ActiveRecord::Migration[6.0]
  def up
    change_column :attachments, :filesize, :integer, limit: 8
    change_column :attachment_journals, :filesize, :integer, limit: 8
  end

  def down
    change_column :attachments, :filesize, :integer, limit: 4
    change_column :attachment_journals, :filesize, :integer, limit: 4
  end
end

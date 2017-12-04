class AddFulltextToAttachments < ActiveRecord::Migration[5.0]
  def change
    # room for at least 1 million characters / approx. 80 pages of english text
    add_column :attachments, :fulltext, :text, limit: 4.megabytes
  end
end

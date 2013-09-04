class CreateAttachmentJournals < ActiveRecord::Migration
  def change
    create_table :attachment_journals do |t|
      t.integer  :journal_id,                                   :null => false
      t.integer  :container_id,                 :default => 0,  :null => false
      t.string   :container_type, :limit => 30, :default => "", :null => false
      t.string   :filename,                     :default => "", :null => false
      t.string   :disk_filename,                :default => "", :null => false
      t.integer  :filesize,                     :default => 0,  :null => false
      t.string   :content_type,                 :default => ""
      t.string   :digest,         :limit => 40, :default => "", :null => false
      t.integer  :downloads,                    :default => 0,  :null => false
      t.integer  :author_id,                    :default => 0,  :null => false
      t.datetime :created_on
      t.string   :description
    end
  end
end

class RemoveDocuments < ActiveRecord::Migration
  def self.up
    unless Redmine::Plugin.registered_plugins.include?(:openproject_documents)
      if  Document.any? || Attachment.where(:container_type => ['Document']).any?
        raise "There are still documents and/or attachments attached to documents, please remove them."
      else
        drop_table :documents
        DocumentCategory.destroy_all
        Attachment.where(:container_type => ['Document']).destroy_all
      end
    end
  end

  def self.down
    unless ActiveRecord::Base.connection.table_exists 'Documents'
      create_table "documents", :force => true do |t|
        t.integer  "project_id",                :default => 0,  :null => false
        t.integer  "category_id",               :default => 0,  :null => false
        t.string   "title",       :limit => 60, :default => "", :null => false
        t.text     "description"
        t.datetime "created_on"
      end
      DocumentCategory.create!(:name => l(:default_doc_category_user), :position => 1)
      DocumentCategory.create!(:name => l(:default_doc_category_tech), :position => 2)
    end
  end
end

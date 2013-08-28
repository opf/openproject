class RemoveDocuments < ActiveRecord::Migration
  def up
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

  def down
    unless ActiveRecord::Base.connection.table_exists? 'Documents'
      create_table "documents", :force => true do |t|
        t.integer  "project_id",                :default => 0,  :null => false
        t.integer  "category_id",               :default => 0,  :null => false
        t.string   "title",       :limit => 60, :default => "", :null => false
        t.text     "description"
        t.datetime "created_on"
      end
      add_index "documents", ["category_id"], :name => "index_documents_on_category_id"
      add_index "documents", ["created_on"], :name => "index_documents_on_created_on"
      add_index "documents", ["project_id"], :name => "documents_project_id"
    end
  end
end

class Document < ActiveRecord::Base
  belongs_to :project
  belongs_to :category, :class_name => "DocumentCategory", :foreign_key => "category_id"
end

class DocumentCategory < Enumeration
  has_many :documents, :foreign_key => 'category_id'
end

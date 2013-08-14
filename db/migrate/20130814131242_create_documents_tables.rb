class CreateDocumentsTables < ActiveRecord::Migration
  def up
    unless ActiveRecord::Base.connection.table_exists? 'documents'
      create_table "documents" do |t|
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

  def down
    drop_table :documents
  end
end

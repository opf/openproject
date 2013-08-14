class CreateDocumentsTables < ActiveRecord::Migration
  def up
    unless ActiveRecord::Base.connection.table_exists? 'documents'
      create_table "documents", :force => true do |t|
        t.integer  "project_id",                :default => 0,  :null => false
        t.integer  "category_id",               :default => 0,  :null => false
        t.string   "title",       :limit => 60, :default => "", :null => false
        t.text     "description"
        t.datetime "created_on"
      end
    end
  end

  def down
    drop_table :documents
  end
end

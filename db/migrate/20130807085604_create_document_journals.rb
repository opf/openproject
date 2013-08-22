class CreateDocumentJournals < ActiveRecord::Migration
  def change
    create_table :document_journals do |t|
      t.integer  :journal_id,                                :null => false
      t.integer  :project_id,                :default => 0,  :null => false
      t.integer  :category_id,               :default => 0,  :null => false
      t.string   :title,       :limit => 60, :default => "", :null => false
      t.text     :description
      t.datetime :created_on
    end
  end
end

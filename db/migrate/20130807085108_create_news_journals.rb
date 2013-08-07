class CreateNewsJournals < ActiveRecord::Migration
  def change
    create_table :news_journals do |t|
      t.integer  :journal_id,                                   :null => false
      t.integer  :project_id
      t.string   :title,          :limit => 60, :default => "", :null => false
      t.string   :summary,                      :default => ""
      t.text     :description
      t.integer  :author_id,                    :default => 0,  :null => false
      t.datetime :created_on
      t.integer  :comments_count,               :default => 0,  :null => false
    end
  end
end

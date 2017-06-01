class AddIndexesForLatestActivity < ActiveRecord::Migration[4.2]
  def change
    add_index :work_packages, [:project_id, :updated_at]
    add_index :news, [:project_id, :created_on]
    add_index :changesets, [:repository_id, :committed_on]
    add_index :wiki_contents, [:page_id, :updated_on]
    add_index :messages, [:board_id, :updated_on]
    add_index :time_entries, [:project_id, :updated_on]
  end
end

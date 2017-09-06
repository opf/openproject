class AddIndexesForLatestActivity < ActiveRecord::Migration[4.2]
  def change
    add_index :work_packages, %i[project_id updated_at]
    add_index :news, %i[project_id created_on]
    add_index :changesets, %i[repository_id committed_on]
    add_index :wiki_contents, %i[page_id updated_on]
    add_index :messages, %i[board_id updated_on]
    add_index :time_entries, %i[project_id updated_on]
  end
end

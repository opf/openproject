class AddTimestampsToWiki < ActiveRecord::Migration[5.1]
  def change
    add_timestamps :wikis, default: DateTime.now
    change_column_default :wikis, :created_at, nil
    change_column_default :wikis, :updated_at, nil

    add_column :wiki_pages, :updated_at, :datetime, default: DateTime.now, null: false
    change_column_default :wiki_pages, :updated_at, nil
  end
end

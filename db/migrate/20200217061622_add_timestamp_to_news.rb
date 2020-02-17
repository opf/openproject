class AddTimestampToNews < ActiveRecord::Migration[6.0]
  def change
    add_column :news, :updated_at, :datetime
    rename_column :news, :created_on, :created_at

    reversible do |change|
      change.up { News.update_all("updated_at = created_at") }
    end
  end
end

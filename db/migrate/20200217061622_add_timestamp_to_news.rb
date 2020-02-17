class AddTimestampToNews < ActiveRecord::Migration[6.0]
  def change
    add_column :news, :updated_on, :datetime

    reversible do |change|
      change.up { News.update_all("updated_on = created_on") }
    end
  end
end

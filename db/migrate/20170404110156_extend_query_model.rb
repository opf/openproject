class ExtendQueryModel < ActiveRecord::Migration[5.0]
  def change
    add_column :queries, :timeline_visible, :boolean, default: false
  end
end

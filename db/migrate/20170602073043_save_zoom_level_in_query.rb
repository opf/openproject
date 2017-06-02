class SaveZoomLevelInQuery < ActiveRecord::Migration[5.0]
  def change
    add_column :queries, :timeline_zoom_level, :integer, default: 0
  end
end

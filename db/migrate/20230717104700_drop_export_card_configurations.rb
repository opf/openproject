class DropExportCardConfigurations < ActiveRecord::Migration[7.0]
  def change
    drop_table :export_card_configurations, if_exists: true do |t|
      t.string :name
      t.integer :per_page
      t.string :page_size
      t.string :orientation
      t.text :rows
      t.text :description
      t.boolean :active, default: true
    end
  end
end

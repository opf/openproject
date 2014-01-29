class CreateExportCardConfiguration < ActiveRecord::Migration
  def change
    create_table :export_card_configurations do |t|
      t.string :name
      t.integer :per_page
      t.string :page_size
      t.string :orientation
      t.text :rows
    end
  end
end

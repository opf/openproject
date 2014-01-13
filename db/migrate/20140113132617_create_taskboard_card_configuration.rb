class CreateTaskboardCardConfiguration < ActiveRecord::Migration
  def change
    create_table :taskboard_card_configurations do |t|
      t.string :identifier
      t.string :name
      t.text :rows
      t.integer :per_page
      t.string :page_size
    end
  end
end

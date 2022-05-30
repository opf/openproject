class CreateHotBoards < ActiveRecord::Migration[7.0]
  def change
    create_table :hot_boards do |t|
      t.string :title

      t.timestamps
    end

    create_table :hot_lists do |t|
      t.belongs_to :hot_board
      t.string :title

      t.timestamps
    end

    create_table :hot_items do |t|
      t.belongs_to :hot_list
      t.belongs_to :work_package
      t.integer :position

      t.timestamps
    end
  end
end

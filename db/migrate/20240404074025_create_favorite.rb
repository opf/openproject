class CreateFavorite < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :favored, null: false, polymorphic: true

      t.timestamps
    end

    add_index :favorites, %i[favored_type favored_id]
    add_index :favorites, %i[user_id favored_type favored_id], unique: true
  end
end

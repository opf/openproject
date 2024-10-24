class CreateEmojiReactions < ActiveRecord::Migration[7.1]
  def change
    create_table :emoji_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reactable, polymorphic: true, null: false
      t.string :reaction, null: false
      t.timestamps
    end

    add_index :emoji_reactions, :reaction
    add_index :emoji_reactions, %i[user_id reactable_type reactable_id reaction],
              unique: true,
              name: "index_emoji_reactions_uniqueness"
  end
end

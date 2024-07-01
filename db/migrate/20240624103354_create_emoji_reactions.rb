class CreateEmojiReactions < ActiveRecord::Migration[7.1]
  def change
    create_table :emoji_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reactable, polymorphic: true, null: false
      t.string :emoji, null: false
      t.timestamps
    end

    add_index :emoji_reactions, [:user_id, :reactable_type, :reactable_id, :emoji], unique: true, name: 'index_emoji_reactions_uniqueness'
  end
end

# frozen_string_literal: true

class CreateBimCommentMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_comment_mentions do |t|
      t.references :comment,
                   null: false,
                   foreign_key: { to_table: :bcf_comments, on_delete: :cascade },
                   index: true
      t.references :user,
                   null: false,
                   foreign_key: { to_table: :users, on_delete: :cascade },
                   index: true

      t.timestamps null: false
    end

    # Composite unique constraint: each user can only be mentioned once per comment
    add_index :bim_comment_mentions,
              [:comment_id, :user_id],
              unique: true,
              name: 'idx_unique_comment_mention'

    add_index :bim_comment_mentions, :created_at, name: 'idx_comment_mentions_created_at'
  end
end

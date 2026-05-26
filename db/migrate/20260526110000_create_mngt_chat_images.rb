# frozen_string_literal: true

class CreateMngtChatImages < ActiveRecord::Migration[7.1]
  def change
    create_table :mngt_chat_images do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }, index: true
      t.timestamps
    end
  end
end

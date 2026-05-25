# frozen_string_literal: true

class CreateMngtPushSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :mngt_push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :endpoint, null: false
      t.string :p256dh,  null: false
      t.string :auth,    null: false
      t.timestamps
    end

    add_index :mngt_push_subscriptions, :endpoint, unique: true
  end
end

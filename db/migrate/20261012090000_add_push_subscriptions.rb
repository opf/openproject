# frozen_string_literal: true

class AddPushSubscriptions < ActiveRecord::Migration[8.1]
  def up
    adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    previous = adapter.create_unlogged_tables
    adapter.create_unlogged_tables = true

    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :session, null: false, foreign_key: { on_delete: :cascade }
      t.text :endpoint, null: false

      t.timestamps

      t.index :endpoint, unique: true
    end
  ensure
    adapter.create_unlogged_tables = previous
  end

  def down
    drop_table :push_subscriptions
  end
end

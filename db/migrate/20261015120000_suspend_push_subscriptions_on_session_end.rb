# frozen_string_literal: true

class SuspendPushSubscriptionsOnSessionEnd < ActiveRecord::Migration[8.1]
  def change
    change_table :push_subscriptions, bulk: true do |t|
      t.change_null :session_id, true
      t.remove_foreign_key :sessions, on_delete: :cascade
      t.foreign_key :sessions, on_delete: :nullify
      t.string :browser_name
      t.string :browser_version
      t.string :platform
      t.datetime :suspended_at
    end
  end
end

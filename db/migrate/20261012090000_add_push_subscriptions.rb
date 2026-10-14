# frozen_string_literal: true

require_relative "tables/push_subscriptions"

class AddPushSubscriptions < ActiveRecord::Migration[8.1]
  def up
    Tables::PushSubscriptions.table(self)
  end

  def down
    drop_table :push_subscriptions
  end
end

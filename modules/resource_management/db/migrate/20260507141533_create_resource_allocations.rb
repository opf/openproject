# frozen_string_literal: true

class CreateResourceAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :resource_allocations do |t|
      t.references :entity, polymorphic: true, null: false
      t.references :principal, foreign_key: { to_table: :users }, null: true
      t.jsonb :user_filter, default: []
      t.string :state, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :allocated_time, null: false

      t.timestamps

      t.index :state
      t.index %i[start_date end_date]
    end
  end
end

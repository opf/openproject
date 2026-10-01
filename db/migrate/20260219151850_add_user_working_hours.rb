# frozen_string_literal: true

class AddUserWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :user_working_hours do |t|
      t.references :user, null: false, foreign_key: true

      t.date :valid_from, null: false, index: true
      t.integer :monday, null: false
      t.integer :tuesday, null: false
      t.integer :wednesday, null: false
      t.integer :thursday, null: false
      t.integer :friday, null: false
      t.integer :saturday, null: false
      t.integer :sunday, null: false
      t.integer :availability_factor, null: false, default: 100

      t.timestamps
    end
  end
end

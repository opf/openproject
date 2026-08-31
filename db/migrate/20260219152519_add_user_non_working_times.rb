# frozen_string_literal: true

class AddUserNonWorkingTimes < ActiveRecord::Migration[8.1]
  def change
    create_table :user_non_working_times do |t|
      t.references :user, null: false, foreign_key: true

      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          ALTER TABLE user_non_working_times
          ADD CONSTRAINT no_overlapping_non_working_times
          EXCLUDE USING gist (
            user_id WITH =,
            daterange(start_date, end_date, '[]') WITH &&
          );
        SQL
      end
    end
  end
end

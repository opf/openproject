# frozen_string_literal: true

class CreateRecurringMeetingHistoricSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :recurring_meeting_historic_schedules do |t|
      t.references :recurring_meeting, foreign_key: true, index: true, null: false
      t.string :uid, null: false
      t.jsonb :snapshot, null: false

      t.timestamps

      t.index :uid, unique: true
    end
  end
end

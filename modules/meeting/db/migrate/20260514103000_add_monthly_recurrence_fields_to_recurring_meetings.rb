# frozen_string_literal: true

class AddMonthlyRecurrenceFieldsToRecurringMeetings < ActiveRecord::Migration[8.0]
  def change
    add_column :recurring_meetings, :monthly_day, :integer, null: true
    add_column :recurring_meetings, :monthly_ordinal, :integer, null: true
    add_column :recurring_meetings, :monthly_weekday, :string, null: true
  end
end

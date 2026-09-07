# frozen_string_literal: true

class AddICalSequenceToRecurringMeetings < ActiveRecord::Migration[8.0]
  def change
    add_column :recurring_meetings, :ical_sequence, :integer, null: false, default: 0

    up_only do
      # The current value for sequence is the template's lock_version.
      # we use this as the seed for the current version to ensure the ICS output remains the same.
      execute <<~SQL.squish
        UPDATE recurring_meetings
        SET ical_sequence = COALESCE(
          (SELECT meetings.lock_version
           FROM meetings
           WHERE meetings.recurring_meeting_id = recurring_meetings.id
             AND meetings.template
           LIMIT 1),
          0
        )
      SQL
    end
  end
end

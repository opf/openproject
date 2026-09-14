# frozen_string_literal: true

class RemoveDeletedUserMeetingParticipants < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      DELETE FROM meeting_participant_journals
      USING users
      WHERE meeting_participant_journals.user_id = users.id
        AND users.type = 'DeletedUser'
    SQL

    execute <<~SQL.squish
      DELETE FROM meeting_participants
      USING users
      WHERE meeting_participants.user_id = users.id
        AND users.type = 'DeletedUser'
    SQL
  end

  def down
    # Nothing to do here
  end
end

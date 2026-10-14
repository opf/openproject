# frozen_string_literal: true

class RemoveDeletedUsersFromMeetingParticipantJournals < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL.squish)
      DELETE FROM meeting_participant_journals
      WHERE NOT EXISTS (SELECT 1 FROM users WHERE users.id = meeting_participant_journals.user_id)
    SQL
  end

  def down; end
end

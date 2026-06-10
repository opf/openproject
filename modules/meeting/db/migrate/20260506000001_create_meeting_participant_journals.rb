# frozen_string_literal: true

class CreateMeetingParticipantJournals < ActiveRecord::Migration[8.0]
  def change
    create_table :meeting_participant_journals do |t|
      t.integer :journal_id, null: false
      t.integer :user_id, null: false
      t.boolean :invited, default: false, null: false
      t.boolean :attended, default: false, null: false
      t.string :participation_status
    end

    add_index :meeting_participant_journals,
              %i[journal_id user_id],
              unique: true,
              name: :idx_meeting_participant_journals_journal_user
  end
end
